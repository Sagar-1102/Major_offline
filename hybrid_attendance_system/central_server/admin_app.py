import os
from flask import Flask, render_template, request, redirect, url_for, flash, session
from werkzeug.security import check_password_hash
from database import Session, User, Notice

app = Flask(__name__)
app.secret_key = os.urandom(24)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        db_session = Session()
        admin = db_session.query(User).filter_by(email=request.form['email'], role='admin').first()
        if admin and check_password_hash(admin.password_hash, request.form['password']):
            session['admin_id'] = admin.id
            session['admin_name'] = admin.name
            session['admin_department'] = admin.department
            return redirect(url_for('dashboard'))
        flash('Invalid admin credentials.', 'danger')
        db_session.close()
    return render_template('admin_login.html')

@app.route('/dashboard')
def dashboard():
    if 'admin_id' not in session: return redirect(url_for('login'))
    db_session = Session()
    users = db_session.query(User).filter(User.department == session['admin_department'], User.id != session['admin_id']).all()
    db_session.close()
    return render_template('admin_dashboard.html', users=users, department=session['admin_department'])

@app.route('/promote/<int:user_id>')
def promote(user_id):
    if 'admin_id' not in session: return redirect(url_for('login'))
    db_session = Session()
    user = db_session.query(User).filter_by(id=user_id, department=session['admin_department']).first()
    if user:
        user.role = 'cr' if user.role == 'student' else 'student'
        db_session.commit()
        flash(f"{user.name}'s role changed to {user.role.upper()}.", 'success')
    db_session.close()
    return redirect(url_for('dashboard'))

@app.route('/send_notice', methods=['POST'])
def send_notice():
    if 'admin_id' not in session: return redirect(url_for('login'))
    db_session = Session()
    new_notice = Notice(
        department=session['admin_department'],
        year=None,
        message=request.form['message'],
        author_id=session['admin_id']
    )
    db_session.add(new_notice)
    db_session.commit()
    flash('Notice sent to the department.', 'success')
    db_session.close()
    return redirect(url_for('dashboard'))

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))