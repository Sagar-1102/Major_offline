import os
import datetime
import json
from sqlalchemy import create_engine, Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import sessionmaker, relationship, declarative_base
from sqlalchemy import MetaData, Table
from sqlalchemy.sql import text  # Import text for raw SQL

db_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'main_database.db')
engine = create_engine(f'sqlite:///{db_path}')
Session = sessionmaker(bind=engine)
Base = declarative_base()

class User(Base):
    __tablename__ = 'users'
    id = Column(Integer, primary_key=True)
    name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    password_hash = Column(String(128), nullable=False)
    role = Column(String(10), nullable=False, default='student')
    department = Column(String(50), nullable=False)
    year = Column(Integer)
    embeddings = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)
    
    notices = relationship("Notice", back_populates="author", cascade="all, delete", passive_deletes=True)
    attendance_records = relationship("Attendance", back_populates="user", cascade="all, delete", passive_deletes=True)

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'role': self.role,
            'department': self.department,
            'year': self.year,
            'avatarUrl': f'https://i.pravatar.cc/150?u={self.id}',
            'embeddings': json.loads(self.embeddings) if self.embeddings else []
        }

class Schedule(Base):
    __tablename__ = 'schedules'
    id = Column(Integer, primary_key=True)
    department = Column(String(50), nullable=False)
    year = Column(Integer, nullable=False)
    subject_name = Column(String(100), nullable=False)
    day_of_week = Column(Integer, nullable=False)
    start_time = Column(String(5), nullable=False)
    end_time = Column(String(5), nullable=False)
    cr_author_id = Column(Integer, ForeignKey('users.id', ondelete="CASCADE"))
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)
    
    attendance_records = relationship("Attendance", back_populates="schedule", cascade="all, delete", passive_deletes=True)

    def to_dict(self):
        return {
            'id': self.id,
            'subject_name': self.subject_name,
            'day_of_week': self.day_of_week,
            'start_time': self.start_time,
            'end_time': self.end_time,
            'department': self.department,
            'year': self.year
        }

class Notice(Base):
    __tablename__ = 'notices'
    id = Column(Integer, primary_key=True)
    department = Column(String(50), nullable=False)
    year = Column(Integer, nullable=True)
    message = Column(Text, nullable=False)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    author_id = Column(Integer, ForeignKey('users.id', ondelete="CASCADE"))
    author = relationship("User", back_populates="notices")

    def to_dict(self):
        return {
            'id': self.id,
            'message': self.message,
            'timestamp': self.timestamp.isoformat(),
            'author': self.author.to_dict() if self.author else {},
            'department': self.department,
            'year': self.year
        }

class Attendance(Base):
    __tablename__ = 'attendance'
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id', ondelete="CASCADE"))
    schedule_id = Column(Integer, ForeignKey('schedules.id', ondelete="CASCADE"))
    timestamp = Column(DateTime, nullable=False)
    status = Column(String(10), default='present')

    user = relationship("User", back_populates="attendance_records")
    schedule = relationship("Schedule", back_populates="attendance_records")

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'schedule_id': self.schedule_id,
            'timestamp': self.timestamp.isoformat(),
            'status': self.status
        }

def migrate_database():
    metadata = MetaData()
    metadata.reflect(bind=engine)
    with engine.connect() as connection:
        # Check if schedules table exists and if cr_author_id column is missing
        if 'schedules' in metadata.tables:
            schedules_table = Table('schedules', metadata, autoload_with=engine)
            if 'cr_author_id' not in schedules_table.c:
                print("Adding cr_author_id column to schedules table...")
                connection.execute(
                    text('ALTER TABLE schedules ADD COLUMN cr_author_id INTEGER REFERENCES users(id) ON DELETE CASCADE')
                )
                print("cr_author_id column added successfully.")
            else:
                print("cr_author_id column already exists in schedules table.")
        else:
            print("schedules table does not exist, will be created.")

def create_db():
    migrate_database()  # Apply migrations before creating tables
    Base.metadata.create_all(engine)
    print("Database tables created or updated successfully.")

if __name__ == '__main__':
    create_db()
