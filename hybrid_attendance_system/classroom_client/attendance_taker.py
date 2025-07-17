import cv2
import time
import datetime
import sqlite3
import json
from deepface import DeepFace
from recognition_core import FaceRecognitionCore

LOCAL_DB_PATH = 'local_database.db'
RECOGNITION_INTERVAL = 3 # seconds

def setup_local_db():
    conn = sqlite3.connect(LOCAL_DB_PATH)
    cursor = conn.cursor()
    cursor.execute('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT, embeddings TEXT)')
    cursor.execute('CREATE TABLE IF NOT EXISTS schedules (id INTEGER PRIMARY KEY, subject_name TEXT, day_of_week INTEGER, start_time TEXT, end_time TEXT)')
    cursor.execute('CREATE TABLE IF NOT EXISTS attendance (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, schedule_id INTEGER, timestamp TEXT, synced INTEGER DEFAULT 0)')
    conn.commit()
    conn.close()

def get_data_from_local_db(query, params=()):
    conn = sqlite3.connect(LOCAL_DB_PATH)
    cursor = conn.cursor()
    cursor.execute(query, params)
    result = cursor.fetchall()
    conn.close()
    return result

def get_current_schedule():
    now = datetime.datetime.now()
    query = "SELECT id, end_time FROM schedules WHERE day_of_week = ? AND start_time <= ? AND end_time >= ?"
    schedule = get_data_from_local_db(query, (now.weekday(), now.strftime("%H:%M"), now.strftime("%H:%M")))
    return schedule[0] if schedule else None

def mark_local_attendance(user_id, schedule_id):
    conn = sqlite3.connect(LOCAL_DB_PATH)
    cursor = conn.cursor()
    cursor.execute("INSERT INTO attendance (user_id, schedule_id, timestamp) VALUES (?, ?, ?)",
                   (user_id, schedule_id, datetime.datetime.now().isoformat()))
    conn.commit()
    conn.close()
    print(f"✅ Attendance marked for user ID {user_id}")

def run_attendance_system():
    setup_local_db()
    
    recognizer = FaceRecognitionCore()
    user_rows = get_data_from_local_db("SELECT id, name, embeddings FROM users")
    users = [(row[0], row[1], json.loads(row[2])) for row in user_rows]
    recognizer.load_known_faces(users)

    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("❌ Error: Cannot open camera.")
        return
        
    print("🚀 Automated attendance system is running...")
    
    current_class_session = None
    students_marked_this_session = set()

    while True:
        schedule_info = get_current_schedule()

        if schedule_info:
            schedule_id, end_time_str = schedule_info
            
            if schedule_id != current_class_session:
                current_class_session = schedule_id
                students_marked_this_session.clear()
                print(f"🔔 New class session started: ID {schedule_id}. Scanning until {end_time_str}.")

            ret, frame = cap.read()
            if not ret: 
                print("⚠️ Warning: Failed to capture frame from camera.")
                time.sleep(1)
                continue

            try:
                # Use a more specific model and backend for consistency
                results = DeepFace.represent(img_path=frame, model_name='FaceNet', detector_backend='mtcnn', enforce_detection=False)
                for face_data in results:
                    # 'embedding' is the key for the vector
                    embedding = face_data.get('embedding')
                    if not embedding:
                        continue
                        
                    user_id, user_name = recognizer.find_matching_face(embedding)
                    
                    if user_id and user_id not in students_marked_this_session:
                        mark_local_attendance(user_id, schedule_id)
                        students_marked_this_session.add(user_id)
            except Exception as e:
                # Log the error instead of passing silently
                print(f"❗️ Error during face recognition process: {e}")
        
        else:
            if current_class_session is not None:
                print("🔕 Class session ended. Pausing until next scheduled class.")
                current_class_session = None
            time.sleep(10) # Sleep longer when no class is active
            continue
            
        time.sleep(RECOGNITION_INTERVAL)

    cap.release()
    cv2.destroyAllWindows()

if __name__ == '__main__':
    run_attendance_system()