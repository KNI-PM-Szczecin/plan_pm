import os
import json
import motor.motor_asyncio
from dotenv import load_dotenv

load_dotenv()

mongoDB_url = os.getenv("MONGODB_URL")
db_name = os.getenv("DB_NAME")

client = motor.motor_asyncio.AsyncIOMotorClient(mongoDB_url) 
db = client.get_database(db_name)
