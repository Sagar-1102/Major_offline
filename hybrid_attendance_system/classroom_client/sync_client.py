import requests
import sqlite3
import json
import time
import datetime

CENTRAL_SERVER_URL = "http://127.0.0.1:5000"
LOCAL_DB_PATH = 'local_database.db'
CONFIG_FILE = 'sync_config.json'
SYNC_INTERVAL = 900

def get_last_sync_time():
    try:
        with open(CONFIG_FILE, 'r') as f: return json.load(f).get('last_sync_time')
    except: return None

def set_last_sync_time(sync_time):
    with open(CONFIG_FILE, 'w') as f: json.dump({'last_sync_time': sync_time}, f)

def sync_data():
    conn = sqlite3.connect(LOCAL_DB_PATH)
    cursor = conn.cursor()
    # PUSH attendance
    cursor.execute("SELECT id, user_id, schedule_id, timestamp FROM attendance WHERE synced = 0")
    records = cursor.fetchall()
    if records:
        payload = {'records': [{'id': r[0], 'user_id': r[1], 'schedule_id': r[2], 'timestamp': r[3]} for r in records]}
        try:
            response = requests.post(f"{CENTRAL_SERVER_URL}/api/sync/attendance", json=payload, timeout=10)
            if response.status_code == 200:
                ids = tuple(r[0] for r in records)
                cursor.execute(f"UPDATE attendance SET synced = 1 WHERE id IN {ids}")
                conn.commit()
        except: pass
    
    # PULL updates
    params = {'last_sync_time': get_last_sync_time()}
    try:
        response = requests.get(f"{CENTRAL_SERVER_URL}/api/sync/get_updates", params=params, timeout=10)
        if response.status_code == 200:
            updates = response.json().get('updates', {})
            if updates.get('users'):
                for user in updates['users']:
                    cursor.execute("INSERT OR REPLACE INTO users (id, name, embeddings) VALUES (?, ?, ?)", (user['id'], user['name'], json.dumps(user['embeddings'])))
            if updates.get('schedules'):
                for s in updates['schedules']:
                    cursor.execute("INSERT OR REPLACE INTO schedules (id, subject_name, day_of_week, start_time, end_time) VALUES (?, ?, ?, ?, ?)", (s['id'], s['subject_name'], s['day_of_week'], s['start_time'], s['end_time']))
            conn.commit()
            set_last_sync_time(response.json().get('server_time'))
    except: pass
    conn.close()

if __name__ == '__main__':
    while True:
        sync_data()
        time.sleep(SYNC_INTERVAL)