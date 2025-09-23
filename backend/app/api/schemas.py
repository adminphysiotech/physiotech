from pydantic import BaseModel, EmailStr 
from typing import Optional 
 
class OrganizationSignup(BaseModel): 
    name: str 
    email: EmailStr 
    phone: Optional[str] = None 
