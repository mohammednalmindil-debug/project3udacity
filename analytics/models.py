from datetime import datetime
from config import db

class User(db.Model):
    """User model for the coworking application"""
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    joined_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    def __repr__(self):
        return f'<User {self.username}>'

class Token(db.Model):
    """Token model for tracking visits"""
    __tablename__ = 'tokens'
    
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    token_value = db.Column(db.String(255), unique=True, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    used_at = db.Column(db.DateTime, nullable=True)
    visits = db.Column(db.Integer, default=0)
    
    # Relationship
    user = db.relationship('User', backref=db.backref('tokens', lazy=True))
    
    def __repr__(self):
        return f'<Token {self.token_value}>'
