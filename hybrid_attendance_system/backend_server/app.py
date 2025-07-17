import os
import datetime
import json
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
        role='student',
        embeddings=json.dumps(data.get('embeddings', [])) # Assume embeddings are sent on signup
    )
    db_session.add(new_user)
    db_session.commit()
    user_dict = new_user.to_dict()
    db_session.close()
    return jsonify(user_dict), 201

# --- ADMIN ROUTES ---
@app.route('/api/admin/users/<int:admin_id>')
def get_users_for_admin(admin_id):
    db_session = Session()
    admin = db_session.query(User).filter_by(id=admin_id, role='admin').first()
    if not admin:
        return jsonify({'error': 'Admin not found or invalid privileges'}), 404
    users = db_session.query(User).filter(User.department == admin.department, User.id != admin.id).all()
    db_session.close()
    return jsonify([u.to_dict() for u in users])

@app.route('/api/admin/toggle_cr/<int:user_id>', methods=['POST'])
def toggle_cr_status(user_id):
    db_session = Session()
    user = db_session.query(User).get(user_id)
    if not user:
        return jsonify({'error': 'User not found'}), 404
    user.role = 'cr' if user.role == 'student' else 'student'
    db_session.commit()
    db_session.close()
    return jsonify({'success': True, 'new_role': user.role})

# --- NOTICE ROUTES ---
@app.route('/api/notices/<int:user_id>')
def get_notices(user_id):
    db_session = Session()
    user = db_session.query(User).get(user_id)
    if not user:
        return jsonify({'error': 'User not found'}), 404
    notices = db_session.query(Notice).filter(
        Notice.department == user.department,
        or_(Notice.year == None, Notice.year == user.year)
    ).order_by(Notice.timestamp.desc()).all()
    db_session.close()
    return jsonify([n.to_dict() for n in notices])

@app.route('/api/notices', methods=['POST'])
def send_notice():
    data = request.json
    db_session = Session()
    author = db_session.query(User).get(data.get('author_id'))
    if not author or author.role not in ['admin', 'cr']:
        return jsonify({'error': 'Unauthorized'}), 403
    
    new_notice = Notice(
        department=author.department,
        year=author.year if author.role == 'cr' else None,
        message=data.get('message'),
        author_id=author.id
    )
    db_session.add(new_notice)
    db_session.commit()
    notice_dict = new_notice.to_dict()
    db_session.close()
    return jsonify(notice_dict), 201

# --- SCHEDULE ROUTES ---
@app.route('/api/schedules/<int:user_id>')
def get_schedules(user_id):
    db_session = Session()
    user = db_session.query(User).get(user_id)
    if not user:
        return jsonify({'error': 'User not found'}), 404
    schedules = db_session.query(Schedule).filter_by(department=user.department, year=user.year).all()
    db_session.close()
    return jsonify([s.to_dict() for s in schedules])

@app.route('/api/schedules', methods=['POST'])
def add_schedule():
    data = request.json
    db_session = Session()
    author = db_session.query(User).get(data.get('author_id'))
    if not author or author.role != 'cr':
        return jsonify({'error': 'Unauthorized'}), 403
        
    new_schedule = Schedule(
        department=author.department, year=author.year,
        subject_name=data.get('subject'), 
        day_of_week=data.get('dayOfWeek'),
        start_time=data.get('startTime'), 
        end_time=data.get('endTime')
    )
    db_session.add(new_schedule)
    db_session.commit()
    schedule_dict = new_schedule.to_dict()
    db_session.close()
    return jsonify(schedule_dict), 201

# --- ATTENDANCE VIEW ROUTE ---
@app.route('/api/attendance/<int:user_id>')
def get_attendance(user_id):
    db_session = Session()
    user = db_session.query(User).get(user_id)
    if not user:
        return jsonify({'error': 'User not found'}), 404
    
    attendance_records = db_session.query(Attendance).filter_by(user_id=user_id).all()
    db_session.close()
    return jsonify([rec.to_dict() for rec in attendance_records])

# --- CORRECTED: ADDED MISSING SYNC ENDPOINTS ---
@app.route('/api/sync/attendance', methods=['POST'])
def sync_attendance():
    data = request.json
    records = data.get('records', [])
    if not records:
        return jsonify({'error': 'No records to sync'}), 400

    db_session = Session()
    try:
        for rec in records:
            # The client should prevent duplicates, but we can double-check here if needed
            new_attendance = Attendance(
                user_id=rec['user_id'],
                schedule_id=rec['schedule_id'],
                timestamp=datetime.datetime.fromisoformat(rec['timestamp'])
            )
            db_session.add(new_attendance)
        db_session.commit()
    except Exception as e:
        db_session.rollback()
        return jsonify({'error': f'Failed to sync attendance: {e}'}), 500
    finally:
        db_session.close()
        
    return jsonify({'success': True, 'synced_records': len(records)}), 200

@app.route('/api/sync/get_updates', methods=['GET'])
def get_updates():
    last_sync_time_str = request.args.get('last_sync_time')
    
    # Parse last sync time, or use a very old date if it's the first sync
    if last_sync_time_str:
        last_sync_time = datetime.datetime.fromisoformat(last_sync_time_str)
    else:
        last_sync_time = datetime.datetime(1970, 1, 1)

    db_session = Session()
    
    # Find all users and schedules updated since the last sync
    updated_users = db_session.query(User).filter(User.updated_at > last_sync_time).all()
    updated_schedules = db_session.query(Schedule).filter(Schedule.updated_at > last_sync_time).all()
    
    updates = {
        'users': [user.to_dict() for user in updated_users],
        'schedules': [schedule.to_dict() for schedule in updated_schedules]
    }
    
    db_session.close()
    
    return jsonify({
        'updates': updates,
        'server_time': datetime.datetime.utcnow().isoformat()
    })

if __name__ == '__main__':
    if not os.path.exists('main_database.db'):
        from database import create_db
        create_db()
    app.run(host='0.0.0.0', port=5000, debug=True)