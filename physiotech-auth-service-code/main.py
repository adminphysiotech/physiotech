from fastapi import FastAPI
import os

app = FastAPI()

@app.get("/")
async def root():
    project_id = os.getenv("GCP_PROJECT_ID", "unknown")
    return {"message": f"Hello from Physiotech Auth Service in project {project_id}!"}
