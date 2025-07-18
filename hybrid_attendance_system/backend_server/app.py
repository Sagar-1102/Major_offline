import os
import datetime
import json
import re
from flask import Flask, jsonify, request
from flask_cors import CORS
from werkzeug.security import check_password_hash, generate_password_hash
from sqlalchemy import or_
from sqlalchemy.orm import joinedload
from database import Session, User, Notice, Schedule, Attendance

app = Flask(__name__)
CORS(app)

@app.route('/')
def home():
    return jsonify({'message': 'Flask API is running at 2:40 PM IST, July 18, 2025!'})

@app.route('/api/login', methods=['POST'])
def login():
    print("Login request received:", request.json)
    data = request.json
    db_session = Session()
    try:
        user = db_session.query(User).filter_by(email=data.get('email')).first()
        if user and check_password_hash(user.password_hash, data.get('password')):
            return jsonify(user.to_dict()), 200
        return jsonify({'error': 'Invalid credentials'}), 401
    except Exception as e:
        print(f"Error in login: {str(e)}")
        return jsonify({'error': str(e)}), 500
    finally:
        db_session.close()

@app.route('/api/signup', methods=['POST'])
def signup():
    print("Signup request received:", request.json)
    data = request.json
    db_session = Session()
    try:
        if db_session.query(User).filter_by(email=data.get('email')).first():
            return jsonify({'error': 'Email already exists'}), 409
        role = data.get('role', 'student')
        if role not in ['student', 'admin']:
            return jsonify({'error': 'Invalid role specified'}), 400
        new_user = User(
            name=data.get('name'),
            email=data.get('email'),
            password_hash=generate_password_hash(data.get('password')),
            department=data.get('department'),
            year=int(data.get('year')) if data.get('year') else None,
            role=role,
            embeddings=json.dumps(data.get('embeddings', []))
        )
        db_session.add(new_user)
        db_session.commit()
        return jsonify(new_user.to_dict()), 201
    except Exception as e:
        db_session.rollback()
        print(f"Error in signup: {str(e)}")
        return jsonify({'error': str(e)}), 500
    finally:
        db_session.close()

@app.route('/api/admin/users/<int:admin_id>')
def get_users_for_admin(admin_id):
    print("Admin users request for ID:", admin_id)
    db_session = Session()
    try:
        admin = db_session.get(User, admin_id)
        if not admin or admin.role != 'admin':
            return jsonify({'error': 'Admin not found or invalid privileges'}), 403
        users = db_session.query(User).filter(User.department == admin.department, User.id != admin.id).all()
        return jsonify([u.to_dict() for u in users]), 200
    except Exception as e:
        print(f"Error in get_users_for_admin: {str(e)}")
        return jsonify({'error': str(e)}), 500
    finally:
        db_session.close()

@app.route('/api/admin/toggle_cr/<int:user_id>', methods=['POST'])
def toggle_cr_status(user_id):
    print("Toggle CR request for ID:", user_id)
    db_session = Session()
    try:
        user = db_session.get(User, user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        user.role = 'cr' if user.role == 'student' else 'student'
        db_session.commit()
        return jsonify({'success': True, 'new_role': user.role}), 200
    except Exception as e:
        db_session.rollback()
        print(f"Error in toggle_cr_status: {str(e)}")
        return jsonify({'error': str(e)}), 500
    finally:
        db_session.close()

@app.route('/api/notices/<int:user_id>')
def get_notices(user_id):
    print("Notices request for user ID:", user_id)
    db_session = Session()
    try:
        user = db_session.get(User, user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        notices = (
            db_session.query(Notice)
            .options(joinedload(Notice.author))
            .filter(
                Notice.department == user.department,
                or_(Notice.year == None, Notice.year == user.year)
            )
            .order_by(Notice.timestamp.desc())
            .all()
        )
        return jsonify([n.to_dict() for n in notices]), 200
    except Exception as e:
        print(f"Error in get_notices: {str(e)}")
        return jsonify({'error': str(e)}), 500
    finally:
        db_session.close()

@app.route('/api/notices', methods=['POST'])
def send_notice():
    print("Send notice request:", request.json)
    data = request.json
    db_session = Session()
    try:
        author = db_session.get(User, data.get('author_id'))
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
        return jsonify(new_notice.to_dict()), 201
    except Exception as e:
        db_session.rollback()
        print(f"Error in send_notice: {str(e)}")
        return jsonify({'error': str(e)}), 500
    finally:
        db_session.close()

@app.route('/api/schedules/<int:user_id>')
def get_schedules(user_id):
    print("Schedules request for user ID:", user_id)
    db_session = Session()
    try:
        user = db_session.get(User, user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        schedules = db_session.query(Schedule).filter_by(department=user.department, year=user.year).all()
        return jsonify([s.to_dict() for s in schedules]), 200
    except Exception as e:
        print(f"Error in get_schedules: {str(e)}")
        return jsonify({'error': str(e)}), 500
    finally:
        db_session.close()

@app.route('/api/schedules', methods=['POST'])
def add_schedule():
    print("Add schedule request:", request.json)
    data = request.json
    db_session = Session()
    try:
        author = db_session.get(User, data.get('author_id'))
        if not author or author.role != 'cr':
            return jsonify({'error': 'Unauthorized'}), 403

        # Handle JSON key variations
        subject_name = data.get('subject_name') or data.get('subject')
        day_of_week = data.get('day_of_week') or data.get('dayOfWeek')
        start_time = data.get('start_time') or data.get('startTime')
        end_time = data.get('end_time') or data.get('endTime')

        # Validate inputs
        if not all([subject_name, day_of_week is not None, start_time, end_time]):
            return jsonify({'error': 'Missing required fields'}), 400

        # Validate day_of_week
        if not isinstance(day_of_week, int) or not (0 <= day_of_week <= 6):
            return jsonify({'error': 'Invalid day_of_week, must be 0-6'}), 400

        # Validate time format (HH:MM) or convert from H:MM AM/PM
        time_pattern = re.compile(r'^\d{1,2}:\d{2}$')
        am_pm_pattern = re.compile(r'^\d{1,2}:\d{2}\s?(AM|PM)$', re.IGNORECASE)

        def convert_time(time_str):
            if time_pattern.match(time_str):
                return time_str
            if am_pm_pattern.match(time_str):
                try:
                    dt = datetime.datetime.strptime(time_str, '%I:%M %p')
                    return dt.strftime('%H:%M')
                except ValueError:
                    pass
            return None

        start_time_converted = convert_time(start_time)
        end_time_converted = convert_time(end_time)

        if not (start_time_converted and end_time_converted):
            return jsonify({'error': 'Invalid time format, use HH:MM or H:MM AM/PM'}), 400

        # Validate that end_time is after start_time
        start_dt = datetime.datetime.strptime(start_time_converted, '%H:%M')
        end_dt = datetime.datetime.strptime(end_time_converted, '%H:%M')
        if end_dt <= start_dt:
            return jsonify({'error': 'End time must be after start time'}), 400

        new_schedule = Schedule(
            department=author.department,
            year=author.year,
            subject_name=subject_name,
            day_of_week=day_of_week,
            start_time=start_time_converted,
            end_time=end_time_converted,
            cr_author_id=author.id
        )
        db_session.add(new_schedule)
        db_session.commit()
        return jsonify(new_schedule.to_dict()), 201
    except Exception as e:
        db_session.rollback()
        print(f"Error in add_schedule: {str(e)}")
        return jsonify({'error': str(e)}), 500
    finally:
        db_session.close()

@app.route('/api/attendance/<int:user_id>')
def get_attendance(user_id):
    print("Attendance request for user ID:", user_id)
    db_session = Session()
    try:
        user = db_session.get(User, user_id)
        if not user:
            return jsonify({'error': 'User not found'}), 404
        attendance_records = db_session.query(Attendance).filter_by(user_id=user_id).all()
        return jsonify([rec.to_dict() for rec in attendance_records]), 200
    except Exception as e:
        print(f"Error in get_attendance: {str(e)}")
        return jsonify({'error': str(e)}), 500
    finally:
        db_session.close()

@app.route('/api/sync/attendance', methods=['POST'])
def sync_attendance():
    print("Sync attendance request:", request.json)
    data = request.json
    records = data.get('records', [])
    if not records:
        return jsonify({'error': 'No records to sync'}), 400
    db_session = Session()
    try:
        for rec in records:
            new_attendance = Attendance(
                user_id=rec['user_id'],
                schedule_id=rec['schedule_id'],
                timestamp=datetime.datetime.fromisoformat(rec['timestamp']),
                status=rec.get('status', 'present')
            )
            db_session.add(new_attendance)
        db_session.commit()
        return jsonify({'success': True, 'synced_records': len(records)}), 200
    except Exception as e:
        db_session.rollback()
        print(f"Error in sync_attendance: {str(e)}")
        return jsonify({'error': f'Failed to sync attendance: {e}'}), 500
    finally:
        db_session.close()

@app.route('/api/sync/get_updates', methods=['GET'])
def get_updates():
    print("Get updates request with last_sync_time:", request.args.get('last_sync_time'))
    last_sync_time_str = request.args.get('last_sync_time')
    db_session = Session()
    try:
        last_sync_time = datetime.datetime.fromisoformat(last_sync_time_str) if last_sync_time_str else datetime.datetime(1970, 1, 1)
        updated_users = db_session.query(User).filter(User.updated_at > last_sync_time).all()
        updated_schedules = db_session.query(Schedule).filter(Schedule.updated_at > last_sync_time).all()
        updates = {
            'users': [user.to_dict() for user in updated_users],
            'schedules': [schedule.to_dict() for schedule in updated_schedules]
        }
        return jsonify({
            'updates': updates,
            'server_time': datetime.datetime.utcnow().isoformat()
        }), 200
    except Exception as e:
        print(f"Error in get_updates: {str(e)}")
        return jsonify({'error': str(e)}), 500
    finally:
        db_session.close()

if __name__ == '__main__':
    if not os.path.exists('main_database.db'):
        from database import create_db
        create_db()
    app.run(host='0.0.0.0', port=5000, debug=True)
