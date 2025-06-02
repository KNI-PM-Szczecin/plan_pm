import os
import json
from firebase_admin import credentials, firestore, initialize_app
from dotenv import load_dotenv

load_dotenv()

firebase_credentials_json = os.getenv("FIREBASE_CREDENTIALS_JSON")
firebase_credentials = credentials.Certificate(json.loads(firebase_credentials_json))

firebase_app = initialize_app(firebase_credentials)
db = firestore.client()