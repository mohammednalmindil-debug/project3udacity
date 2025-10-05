import logging
import os
import threading
import time
from datetime import datetime, timedelta

from apscheduler.schedulers.background import BackgroundScheduler
from flask import jsonify, request
from sqlalchemy import and_, text
from random import randint

from config import app, db

# Configure logging to output to stdout for CloudWatch
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s in %(module)s: %(message)s',
    handlers=[
        logging.StreamHandler()  # This ensures logs go to stdout
    ]
)
logger = logging.getLogger(__name__)

port_number = int(os.environ.get("APP_PORT", 5153))


@app.route("/health_check")
def health_check():
    """Health check endpoint"""
    try:
        # Test database connection
        db.session.execute(text("SELECT 1"))
        logger.info("Health check: Database connection OK")
        return "ok"
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return "failed", 500


@app.route("/readiness_check")
def readiness_check():
    """Readiness check endpoint"""
    try:
        # Test database connection and basic queries
        db.session.execute(text("SELECT 1"))
        result = db.session.execute(text("SELECT COUNT(*) FROM tokens"))
        token_count = result.scalar()
        logger.info(f"Readiness check: Database OK, {token_count} tokens in database")
        return "ok"
    except Exception as e:
        logger.error(f"Readiness check failed: {str(e)}")
        return "failed", 500


def periodic_database_check():
    """Periodic database health check and data logging"""
    try:
        with app.app_context():
            # Test database connection
            db.session.execute(text("SELECT 1"))
            logger.info("Database connected successfully")
            
            # Get table counts
            tables_to_check = ['tokens', 'users']
            for table in tables_to_check:
                try:
                    result = db.session.execute(text(f"SELECT COUNT(*) FROM {table}"))
                    count = result.scalar()
                    logger.info(f"Fetched {count} records from {table} table")
                except Exception as e:
                    logger.warning(f"Could not query {table} table: {str(e)}")
            
            # Get daily visits data (existing functionality)
            result = db.session.execute(text("""
            SELECT Date(created_at) AS date,
                Count(*)         AS visits
            FROM   tokens
            WHERE  used_at IS NOT NULL
            GROUP  BY Date(created_at)
            ORDER BY date DESC
            LIMIT 5
            """))

            daily_data = {}
            for row in result:
                daily_data[str(row[0])] = row[1]
            
            if daily_data:
                logger.info(f"Daily visits data: {daily_data}")
            else:
                logger.info("No daily visits data found")
                
            # Get recent activity
            result = db.session.execute(text("""
            SELECT COUNT(*) as recent_tokens
            FROM tokens 
            WHERE created_at >= NOW() - INTERVAL '1 hour'
            """))
            recent_count = result.scalar()
            logger.info(f"Recent activity: {recent_count} tokens created in last hour")
            
    except Exception as e:
        logger.error(f"Database check failed: {str(e)}")

def get_daily_visits():
    """Original function - now calls the enhanced periodic check"""
    periodic_database_check()
    
    with app.app_context():
        result = db.session.execute(text("""
        SELECT Date(created_at) AS date,
            Count(*)         AS visits
        FROM   tokens
        WHERE  used_at IS NOT NULL
        GROUP  BY Date(created_at)
        """))

        response = {}
        for row in result:
            response[str(row[0])] = row[1]

        logger.info(f"Daily visits summary: {response}")
        return response


@app.route("/api/reports/daily_usage", methods=["GET"])
def daily_visits():
    return jsonify(get_daily_visits)


@app.route("/api/reports/user_visits", methods=["GET"])
def all_user_visits():
    result = db.session.execute(text("""
    SELECT t.user_id,
        t.visits,
        users.joined_at
    FROM   (SELECT tokens.user_id,
                Count(*) AS visits
            FROM   tokens
            GROUP  BY user_id) AS t
        LEFT JOIN users
                ON t.user_id = users.id;
    """))

    response = {}
    for row in result:
        response[row[0]] = {
            "visits": row[1],
            "joined_at": str(row[2])
        }
    
    return jsonify(response)


def startup_database_test():
    """Test database connection on startup"""
    try:
        with app.app_context():
            # Test basic connection
            db.session.execute(text("SELECT 1"))
            logger.info("Startup: Database connected successfully")
            
            # Get initial table counts
            tables = ['tokens', 'users']
            for table in tables:
                try:
                    result = db.session.execute(text(f"SELECT COUNT(*) FROM {table}"))
                    count = result.scalar()
                    logger.info(f"Startup: Found {count} records in {table} table")
                except Exception as e:
                    logger.warning(f"Startup: Could not query {table} table: {str(e)}")
                    
    except Exception as e:
        logger.error(f"Startup: Database connection failed: {str(e)}")

# Initialize scheduler for periodic database checks
scheduler = BackgroundScheduler()
# Run periodic database check every 30 seconds
job = scheduler.add_job(periodic_database_check, 'interval', seconds=30, id='db_check')
scheduler.start()

# Log startup information
logger.info(f"Application starting on port {port_number}")
logger.info("Periodic database checks enabled (every 30 seconds)")

# Test database connection on startup
startup_database_test()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=port_number)