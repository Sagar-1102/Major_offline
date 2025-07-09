import os
from flask import Flask, render_template, request, redirect, url_for, flash, session
from werkzeug.security import generate_password_hash, check_password_hash
from sqlalchemy import or_
from database import Session, User, Notice

app = Flask(__name__)
app.secret_key = os.urandom(24)
DEPARTMENTS = ["BCT", "BEI", "BCE", "BAG", "BAR", "BME", "BEL"]

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        db_session = Session()
        user = db_session.query(User).filter_by(email=request.form['email']).first()
        if user and check_password_hash(user.password_hash, request.form['password']):
            session['student_id'] = user.id
            session['student_name'] = user.name
            session['student_department'] = user.department
            session['student_year'] = user.year
            return redirect(url_for('dashboard'))
        flash('Invalid credentials.', 'danger')
        db_session.close()
    return render_template('student_login.html')

@app.route('/signup', methods=['GET', 'POST'])
def signup():
    if request.method == 'POST':
        db_session = Session()
        if db_session.query(User).filter_by(email=request.form['email']).first():
            flash('Email already exists.', 'danger')
            return redirect(url_for('signup'))
        new_user = User(
            name=request.form['name'],
            email=request.form['email'],
            password_hash=generate_password_hash(request.form['password']),
            department=request.form['department'],
            year=int(request.form['year']),
            role='student'
        )
        db_session.add(new_user)
        db_session.commit()
        flash('Account created successfully. Please log in.', 'success')
        db_session.close()
        return redirect(url_for('login'))
    return render_template('signup.html', departments=DEPARTMENTS)

@app.route('/')
@app.route('/dashboard')
def dashboard():
    if 'student_id' not in session: return redirect(url_for('login'))
    db_session = Session()
    notices = db_session.query(Notice).filter(
        Notice.department == session['student_department'],
        or_(Notice.year == None, Notice.year == session['student_year'])
    ).order_by(Notice.timestamp.desc()).all()
    db_session.close()
    return render_template('student_dashboard.html', notices=notices)

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))