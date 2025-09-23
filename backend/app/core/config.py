import os 
from pydantic_settings import BaseSettings 
 
class Settings(BaseSettings): 
    database_url: str = "postgresql://user:pass@localhost/db" 
 
settings = Settings() 
