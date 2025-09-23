from sqlalchemy import Column, Integer, String, Boolean, DateTime 
from sqlalchemy.sql import func 
from ..core.database import Base 
 
class Organization(Base): 
    __tablename__ = "organizations" 
    id = Column(Integer, primary_key=True) 
    name = Column(String, nullable=False) 
    email = Column(String, unique=True, nullable=False) 
