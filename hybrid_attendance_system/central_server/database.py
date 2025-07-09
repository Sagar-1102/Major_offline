import os
import datetime
from sqlalchemy import create_engine, Column, Integer, String, Text, DateTime, ForeignKey
from sqlalchemy.orm import sessionmaker, relationship
from sqlalchemy.ext.declarative import declarative_base

db_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'central_database.db')
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
    face_embeddings = relationship("FaceEmbedding", back_populates="user", cascade="all, delete-orphan")
    last_updated = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

class FaceEmbedding(Base):
    __tablename__ = 'face_embeddings'
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'))
    embedding = Column(Text, nullable=False)
    user = relationship("User", back_populates="face_embeddings")

class Schedule(Base):
    __tablename__ = 'schedules'
    id = Column(Integer, primary_key=True)
    department = Column(String(50), nullable=False)
    year = Column(Integer, nullable=False)
    subject_name = Column(String(100), nullable=False)
    day_of_week = Column(Integer, nullable=False)
    start_time = Column(String(5), nullable=False)
    end_time = Column(String(5), nullable=False)
    cr_author_id = Column(Integer, ForeignKey('users.id'))
    last_updated = Column(DateTime, default=datetime.datetime.utcnow, onupdate=datetime.datetime.utcnow)

class Notice(Base):
    __tablename__ = 'notices'
    id = Column(Integer, primary_key=True)
    department = Column(String(50), nullable=False)
    year = Column(Integer, nullable=True)
    message = Column(Text, nullable=False)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    author_id = Column(Integer, ForeignKey('users.id'))

def create_db():
    Base.metadata.create_all(engine)
    print("Central database and tables created.")

if __name__ == '__main__':
    create_db()