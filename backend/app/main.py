from fastapi import FastAPI 
from .api.auth import router as auth_router 
 
app = FastAPI(title="Physiotech API") 
app.include_router(auth_router) 
 
@app.get("/") 
async def root(): 
    return {"message": "Physiotech API is running", "version": "1.0.0"} 
