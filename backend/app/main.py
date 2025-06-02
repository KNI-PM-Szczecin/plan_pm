from fastapi import FastAPI
from . import firebase_config
# Create instance of an FastApi app
app = FastAPI()

# Default route
@app.get("/")
def default():
    return {"message": "Welcome to the FastAPI app!"}