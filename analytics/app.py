from flask import Flask, jsonify
import psycopg2
import os
from datetime import datetime

app = Flask(__name__)

# Database configuration from environment variables
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': os.getenv('DB_PORT', '5432'),
    'database': os.getenv('DB_NAME', 'mydatabase'),
    'user': os.getenv('DB_USERNAME', 'myuser'),
    'password': os.getenv('DB_PASSWORD', 'mypassword')
}

def get_db_connection():
    """Create and return a database connection"""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        return conn
    except psycopg2.Error as e:
        print(f"Database connection error: {e}")
        return None

@app.route('/health_check')
def health_check():
    """Health check endpoint"""
    conn = get_db_connection()
    if conn:
        conn.close()
        return jsonify({"status": "healthy", "timestamp": datetime.now().isoformat()}), 200
    else:
        return jsonify({"status": "unhealthy", "timestamp": datetime.now().isoformat()}), 500

@app.route('/readiness_check')
def readiness_check():
    """Readiness check endpoint"""
    conn = get_db_connection()
    if conn:
        conn.close()
        return jsonify({"status": "ready", "timestamp": datetime.now().isoformat()}), 200
    else:
        return jsonify({"status": "not ready", "timestamp": datetime.now().isoformat()}), 500

@app.route('/api/reports/daily_usage')
def daily_usage_report():
    """Generate report for check-ins grouped by dates"""
    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Database connection failed"}), 500
    
    try:
        cursor = conn.cursor()
        # Sample query - adjust based on your actual table structure
        cursor.execute("""
            SELECT DATE(check_in_time) as date, COUNT(*) as check_ins
            FROM user_checkins 
            GROUP BY DATE(check_in_time)
            ORDER BY date DESC
            LIMIT 30
        """)
        
        results = cursor.fetchall()
        data = [{"date": str(row[0]), "check_ins": row[1]} for row in results]
        
        cursor.close()
        conn.close()
        
        return jsonify({
            "report_type": "daily_usage",
            "data": data,
            "timestamp": datetime.now().isoformat()
        }), 200
        
    except psycopg2.Error as e:
        conn.close()
        return jsonify({"error": f"Database query failed: {str(e)}"}), 500

@app.route('/api/reports/user_visits')
def user_visits_report():
    """Generate report for check-ins grouped by users"""
    conn = get_db_connection()
    if not conn:
        return jsonify({"error": "Database connection failed"}), 500
    
    try:
        cursor = conn.cursor()
        # Sample query - adjust based on your actual table structure
        cursor.execute("""
            SELECT u.username, COUNT(c.id) as visit_count
            FROM users u
            LEFT JOIN user_checkins c ON u.id = c.user_id
            GROUP BY u.id, u.username
            ORDER BY visit_count DESC
            LIMIT 50
        """)
        
        results = cursor.fetchall()
        data = [{"username": row[0], "visit_count": row[1]} for row in results]
        
        cursor.close()
        conn.close()
        
        return jsonify({
            "report_type": "user_visits",
            "data": data,
            "timestamp": datetime.now().isoformat()
        }), 200
        
    except psycopg2.Error as e:
        conn.close()
        return jsonify({"error": f"Database query failed: {str(e)}"}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5153, debug=False)


