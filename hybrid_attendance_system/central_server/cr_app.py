import os
from flask import Flask, render_template, request, redirect, url_for, flash, session
from werkzeug.security import check_password_hash
from database import Session, User, Schedule, Notice

app = Flask(__name__)
app.secret_key = os.urandom(24)

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        db_session = Session()
        cr = db_session.query(User).filter_by(email=request.form['email'], role='cr').first()
        if cr and check_password_hash(cr.password_hash, request.form['password']):
            session['cr_id'] = cr.id
            session['cr_name'] = cr.name
            session['cr_department'] = cr.department
            session['cr_year'] = cr.year
            return redirect(url_for('dashboard'))
        flash('Invalid CR credentials.', 'danger')
        db_session.close()
    return render_template('cr_login.html')

@app.route('/dashboard')
def dashboard():
    if 'cr_id' not in session: return redirect(url_for('login'))
    return render_template('cr_dashboard.html')

@app.route('/update_schedule', methods=['POST'])
def update_schedule():
    if 'cr_id' not in session: return redirect(url_for('login'))
    db_session = Session()
    new_schedule = Schedule(
        department=session['cr_department'],
        year=session['cr_year'],
        subject_name=request.form['subject_name'],
        day_of_week=int(request.form['day_of_week']),
        start_time=request.form['start_time'],
        end_time=request.form['end_time'],
        cr_author_id=session['cr_id']
    )
    db_session.add(new_schedule)
    db_session.commit()
    flash('Class schedule updated.', 'success')
    db_session.close()
    return redirect(url_for('dashboard'))

@app.route('/send_notice', methods=['POST'])
def send_notice():
    if 'cr_id' not in session: return redirect(url_for('login'))
    db_session = Session()
    new_notice = Notice(
        department=session['cr_department'],
        year=session['cr_year'],
        message=request.form['message'],
        author_id=session['cr_id']
    )
    db_session.add(new_notice)
    db_session.commit()
    flash('Notice sent to your class.', 'success')
    db_session.close()
    return redirect(url_for('dashboard'))

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))