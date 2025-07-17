import requests
import sqlite3
import json
import time
import datetime

CENTRAL_SERVER_URL = "http://127.0.0.1:5000"
LOCAL_DB_PATH = 'local_database.db'
CONFIG_FILE = 'sync_config.json'
SYNC_INTERVAL = 900 # 15 minutes

def get_last_sync_time():
    try:
        with open(CONFIG_FILE, 'r') as f:
            return json.load(f).get('last_sync_time')
    except (FileNotFoundError, json.JSONDecodeError):
        return None

def set_last_sync_time(sync_time):
    with open(CONFIG_FILE, 'w') as f:
        json.dump({'last_sync_time': sync_time}, f)

def sync_data():
    print(f"[{datetime.datetime.now()}] Starting sync process...")
    conn = sqlite3.connect(LOCAL_DB_PATH)
    cursor = conn.cursor()
    
    # --- PUSH local attendance records to the central server ---
    cursor.execute("SELECT id, user_id, schedule_id, timestamp FROM attendance WHERE synced = 0")
    records_to_push = cursor.fetchall()
    if records_to_push:
        payload = {'records': [{'id': r[0], 'user_id': r[1], 'schedule_id': r[2], 'timestamp': r[3]} for r in records_to_push]}
        try:
            response = requests.post(f"{CENTRAL_SERVER_URL}/api/sync/attendance", json=payload, timeout=15)
            if response.status_code == 200:
                print(f"Successfully pushed {len(records_to_push)} attendance records.")
                ids_to_update = tuple(r[0] for r in records_to_push)
                placeholders = ', '.join('?' for _ in ids_to_update)
                query = f"UPDATE attendance SET synced = 1 WHERE id IN ({placeholders})"
                cursor.execute(query, ids_to_update)
                conn.commit()
            else:
                print(f"Error pushing attendance data: {response.status_code} - {response.text}")
        except requests.exceptions.RequestException as e:
            print(f"Network error while pushing attendance: {e}")

    # --- PULL updates (users, schedules) from the central server ---
    params = {'last_sync_time': get_last_sync_time()}
    try:
        response = requests.get(f"{CENTRAL_SERVER_URL}/api/sync/get_updates", params=params, timeout=15)
        if response.status_code == 200:
            data = response.json()
            updates = data.get('updates', {})
            
            # Update local users table
            users_to_update = updates.get('users', [])
            if users_to_update:
                for user in users_to_update:
                    cursor.execute("INSERT OR REPLACE INTO users (id, name, embeddings) VALUES (?, ?, ?)", 
                                   (user['id'], user['name'], json.dumps(user.get('embeddings', []))))
                print(f"Synced {len(users_to_update)} user records.")
            
            # Update local schedules table
            schedules_to_update = updates.get('schedules', [])
            if schedules_to_update:
                for s in schedules_to_update:
                    cursor.execute("INSERT OR REPLACE INTO schedules (id, subject_name, day_of_week, start_time, end_time) VALUES (?, ?, ?, ?, ?)", 
                                   (s['id'], s['subject_name'], s['day_of_week'], s['start_time'], s['end_time']))
                print(f"Synced {len(schedules_to_update)} schedule records.")

            conn.commit()
            set_last_sync_time(data.get('server_time'))
            print("Sync successful. Updated last sync time.")
        else:
            print(f"Error pulling updates: {response.status_code} - {response.text}")
    except requests.exceptions.RequestException as e:
        print(f"Network error while pulling updates: {e}")
    except Exception as e:
        print(f"An unexpected error occurred during sync: {e}")
    finally:
        conn.close()

if __name__ == '__main__':
    while True:
        sync_data()
        print(f"Next sync in {SYNC_INTERVAL} seconds.")
        time.sleep(SYNC_INTERVAL)