from fastapi import APIRouter, HTTPException, Depends 
from sqlalchemy.orm import Session 
from .schemas import OrganizationSignup 
from ..models.auth import Organization 
 
router = APIRouter(prefix="/auth", tags=["authentication"]) 
 
@router.post("/signup") 
async def signup(org_data: OrganizationSignup): 
    return {"message": "Signup endpoint", "data": org_data} 
 
@router.post("/login") 
async def login(): 
    return {"message": "Login endpoint"} 
