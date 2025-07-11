import os
from flask import Flask, jsonify, request
from flask_cors import CORS
from werkzeug.security import check_password_hash, generate_password_hash
from sqlalchemy import or_
from database import Session, User, Notice, Schedule, Attendance

app = Flask(__name__)
CORS(app) 

# --- AUTHENTICATION & USER ROUTES ---

@app.route('/api/login', methods=['POST'])
def login():
    data = request.json
    db_session = Session()
    user = db_session.query(User).filter_by(email=data.get('email')).first()
    db_session.close()
    
    if user and check_password_hash(user.password_hash, data.get('password')):
        return jsonify(user.to_dict())
    
    return jsonify({'error': 'Invalid credentials'}), 401

@app.route('/api/signup', methods=['POST'])
def signup():
    data = request.json
    db_session = Session()

    if db_session.query(User).filter_by(email=data.get('email')).first():
        return jsonify({'error': 'Email already exists'}), 409

    new_user = User(
        name=data.get('name'),
        email=data.get('email'),
        password_hash=generate_password_hash(data.get('password')),
        department=data.get('department'),
        year=int(data.get('year')),
        role='student'
    )
    db_session.add(new_user)
    db_session.commit()
    
    user_dict = new_user.to_dict()
    db_session.close()
    return jsonify(user_dict), 201

# --- NOTICE ROUTES ---

@app.route('/api/notices/<int:user_id>')
def get_notices(user_id):
    db_session = Session()
    user = db_session.query(User).filter_by(id=user_id).first()
    if not user:
        return jsonify({'error': 'User not found'}), 404
        
    notices = db_session.query(Notice).filter(
        Notice.department == user.department,
        or_(Notice.year == None, Notice.year == user.year)
    ).order_by(Notice.timestamp.desc()).all()
    
    db_session.close()
    return jsonify([n.to_dict() for n in notices])

# --- ADMIN-ONLY ROUTES ---

@app.route('/api/admin/clear-data', methods=['POST'])
def clear_data():
    # In a real app, you would add a token check here to ensure only an admin can call this.
    data = request.json
    admin_id = data.get('admin_id')

    db_session = Session()
    admin = db_session.query(User).filter_by(id=admin_id, role='admin').first()

    if not admin:
        db_session.close()
        return jsonify({'error': 'Unauthorized access'}), 403

    try:
        # Clear transactional data, but leave users intact
        num_notices = db_session.query(Notice).delete()
        num_schedules = db_session.query(Schedule).delete()
        num_attendance = db_session.query(Attendance).delete()
        db_session.commit()
        
        message = f"Successfully cleared {num_notices} notices, {num_schedules} schedules, and {num_attendance} attendance records."
        return jsonify({'message': message}), 200
    except Exception as e:
        db_session.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        db_session.close()


if __name__ == '__main__':
    if not os.path.exists('main_database.db'):
        from database import create_db
        create_db()
        
    app.run(host='0.0.0.0', port=5000, debug=True)