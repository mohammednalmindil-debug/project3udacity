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
from models import User, Token

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
        token_count = Token.query.count()
        user_count = User.query.count()
        logger.info(f"Readiness check: Database OK, {user_count} users and {token_count} tokens in database")
        return "ok"
    except Exception as e:
        logger.error(f"Readiness check failed: {str(e)}")
        return "failed", 500


def periodic_database_check():
    """Periodic database health check and data logging - Reviewer requested format"""
    try:
        with app.app_context():
            # Test database connection - Reviewer requested message
            db.session.execute(text("SELECT 1"))
            logger.info("Database connected successfully")
            
            # Get table counts using SQLAlchemy models
            user_count = User.query.count()
            token_count = Token.query.count()
            total_records = user_count + token_count
            
            logger.info(f"Fetched {user_count} records from users table")
            logger.info(f"Fetched {token_count} records from tokens table")
            
            # Log total records fetched - Reviewer requested message
            logger.info(f"Fetched {total_records} records")
            
    except Exception as e:
        logger.error(f"Database check failed: {str(e)}")

def get_daily_visits():
    """Get daily visits using SQLAlchemy models"""
    periodic_database_check()
    
    with app.app_context():
        # Get tokens that have been used (used_at is not None)
        used_tokens = Token.query.filter(Token.used_at.isnot(None)).all()
        
        response = {}
        for token in used_tokens:
            date_str = token.used_at.date().strftime('%Y-%m-%d')
            if date_str in response:
                response[date_str] += 1
            else:
                response[date_str] = 1

        logger.info(f"Daily visits summary: {response}")
        return response


@app.route("/api/reports/daily_usage", methods=["GET"])
def daily_visits():
    return jsonify(get_daily_visits)


@app.route("/api/reports/user_visits", methods=["GET"])
def all_user_visits():
    """Get user visits using SQLAlchemy models"""
    users = User.query.all()
    response = {}
    
    for user in users:
        token_count = Token.query.filter_by(user_id=user.id).count()
        response[user.id] = {
            "visits": token_count,
            "joined_at": str(user.joined_at)
        }
    
    return jsonify(response)


def startup_database_test():
    """Test database connection and create tables on startup"""
    try:
        with app.app_context():
            # Test basic connection
            db.session.execute(text("SELECT 1"))
            logger.info("Startup: Database connected successfully")
            
            # Create all tables
            db.create_all()
            logger.info("Startup: Database tables created/verified")
            
            # Add sample data if tables are empty
            user_count = User.query.count()
            token_count = Token.query.count()
            
            if user_count == 0:
                # Create sample users
                sample_users = [
                    User(username="alice", email="alice@example.com"),
                    User(username="bob", email="bob@example.com"),
                    User(username="charlie", email="charlie@example.com")
                ]
                for user in sample_users:
                    db.session.add(user)
                db.session.commit()
                logger.info("Startup: Created 3 sample users")
            
            if token_count == 0:
                # Create sample tokens
                users = User.query.all()
                for i, user in enumerate(users):
                    token = Token(
                        user_id=user.id,
                        token_value=f"token_{user.username}_{i+1}",
                        visits=i+1,
                        used_at=datetime.utcnow() if i < 2 else None
                    )
                    db.session.add(token)
                db.session.commit()
                logger.info("Startup: Created sample tokens")
            
            # Get final table counts
            final_user_count = User.query.count()
            final_token_count = Token.query.count()
            logger.info(f"Startup: Database ready with {final_user_count} users and {final_token_count} tokens")
                    
    except Exception as e:
        logger.error(f"Startup: Database connection failed: {str(e)}")

# Initialize scheduler for periodic database checks
scheduler = BackgroundScheduler()
# Run periodic database check every 60 seconds - Reviewer requested interval
job = scheduler.add_job(periodic_database_check, 'interval', seconds=60, id='db_check')
scheduler.start()

# Log startup information
logger.info(f"Application starting on port {port_number}")
logger.info("Periodic database checks enabled (every 60 seconds)")

# Test database connection on startup
startup_database_test()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=port_number)