from fastapi import FastAPI 
from .api.auth import router as auth_router 
 
app = FastAPI(title="Physiotech API") 
app.include_router(auth_router) 
