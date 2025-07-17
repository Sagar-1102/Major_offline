import os
import datetime
import json
from sqlalchemy import create_engine, Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import sessionmaker, relationship, declarative_base
from werkzeug.security import generate_password_hash

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
    year = Column(Integer) # Represents admission year
    embeddings = Column(Text, nullable=True) 
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)
    
    # Relationships with cascading deletes
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
    updated_at = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)
    
    # Relationship with cascading deletes
    attendance_records = relationship("Attendance", back_populates="schedule", cascade="all, delete", passive_deletes=True)

    def to_dict(self):
        return {
            'id': self.id, 
            'subject_name': self.subject_name, 
            'day_of_week': self.day_of_week,
            'start_time': self.start_time, 
            'end_time': self.end_time
        }

class Notice(Base):
    __tablename__ = 'notices'
    id = Column(Integer, primary_key=True)
    department = Column(String(50), nullable=False)
    year = Column(Integer, nullable=True)
    message = Column(Text, nullable=False)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    # Added ondelete="CASCADE" to the foreign key
    author_id = Column(Integer, ForeignKey('users.id', ondelete="CASCADE"))
    author = relationship("User", back_populates="notices")

    def to_dict(self):
        return {
            'id': self.id, 
            'message': self.message, 
            'timestamp': self.timestamp.isoformat(),
            'author': self.author.to_dict()
        }

class Attendance(Base):
    __tablename__ = 'attendance'
    id = Column(Integer, primary_key=True)
    # Added ondelete="CASCADE" to foreign keys
    user_id = Column(Integer, ForeignKey('users.id', ondelete="CASCADE"))
    schedule_id = Column(Integer, ForeignKey('schedules.id', ondelete="CASCADE"))
    timestamp = Column(DateTime, nullable=False)
    status = Column(String(10), default='present')

    # Added back-populating relationships
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

def create_db():
    Base.metadata.create_all(engine)
    print("Database tables created successfully.")

if __name__ == '__main__':
    create_db()