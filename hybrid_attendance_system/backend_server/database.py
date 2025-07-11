import os
import datetime
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
    year = Column(Integer)
    
    def to_dict(self):
        return {
            'id': self.id, 'name': self.name, 'email': self.email,
            'role': self.role, 'department': self.department, 'year': self.year,
            'avatarUrl': f'https://i.pravatar.cc/150?u={self.id}'
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
    
    def to_dict(self):
        return {
            'id': self.id, 'subject': self.subject_name, 'dayOfWeek': self.day_of_week,
            'startTime': self.start_time, 'endTime': self.end_time
        }

class Notice(Base):
    __tablename__ = 'notices'
    id = Column(Integer, primary_key=True)
    department = Column(String(50), nullable=False)
    year = Column(Integer, nullable=True)
    message = Column(Text, nullable=False)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    author_id = Column(Integer, ForeignKey('users.id'))
    author = relationship("User")

    def to_dict(self):
        return {
            'id': self.id, 'message': self.message, 
            'timestamp': self.timestamp.isoformat(),
            'author': self.author.to_dict()
        }

def create_db():
    """Creates the database tables if they don't exist."""
    Base.metadata.create_all(engine)
    print("Database tables created successfully.")

if __name__ == '__main__':
    create_db()