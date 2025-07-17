import datetime
from sqlalchemy import or_
from database import Session, User

def delete_graduated_students():
    """
    Checks for students who have completed their college journey and deletes their records.
    - 4-year journey for all faculties except BAR.
    - 5-year journey for BAR faculty.
    Deletion occurs if the current year is past their graduation year.
    """
    db_session = Session()
    current_year = datetime.datetime.now().year
    print(f"[{datetime.datetime.now()}] Running cleanup job for year {current_year}...")
    
    deleted_count = 0
    try:
        # Fetch all users who are students or CRs
        students_to_check = db_session.query(User).filter(
            or_(User.role == 'student', User.role == 'cr')
        ).all()

        for student in students_to_check:
            # Ensure the student record has an admission year and department
            if not student.year or not student.department:
                continue

            # Determine the course duration based on faculty
            duration = 5 if student.department.upper() == 'BAR' else 4
            
            # The year the student is expected to have graduated
            expiry_year = student.year + duration

            # If the current year is past the student's expiry year, delete them
            if current_year >= expiry_year:
                print(f"DELETING -> User: {student.name} (ID: {student.id}), Admission: {student.year}, Dept: {student.department}. Expiry Year was {expiry_year}.")
                db_session.delete(student)
                deleted_count += 1
        
        if deleted_count > 0:
            db_session.commit()
            print(f"✅ Successfully deleted {deleted_count} graduated student(s).")
        else:
            print("✅ No students found for deletion at this time.")

    except Exception as e:
        db_session.rollback()
        print(f"❌ An error occurred during cleanup: {e}")
    finally:
        db_session.close()

if __name__ == '__main__':
    delete_graduated_students()