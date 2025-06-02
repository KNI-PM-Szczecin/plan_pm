# pmPlan ⛅ #

> This project uses FastAPI to provide a backend service that automatically collects and distributes student lesson schedules from the official website. It ensures clients always receive the most up-to-date schedule information through reliable and timely updates.

## Table of Contents ##
- [About the Project](#about-the-project-)
- [Features](#features-)
- [Tech Stack](#tech-stack-)
- [Getting Started](#getting-started-)
  - [Prerequisites](#prerequisites-)
  - [Installation](#installation-)
- [API Endpoints](#api-endpoints-)
- [Contact](#contact-)

## About the Project 📝

> This project provides a backend API for a mobile app that delivers student lesson schedules. It automatically scrapes the official school website using Requests and BeautifulSoup4 to gather up-to-date schedule information. The data scraping process is automated and scheduled with APScheduler to run at regular intervals. Extracted schedules are stored securely in Firebase Firestore, enabling real-time syncing with the mobile app. The backend API is built with FastAPI, ensuring high performance and easy scalability. Configuration management is handled using python-dotenv for secure and flexible environment variables. The codebase is tested using pytest to maintain reliability. Overall, the system ensures students have timely access to accurate lesson schedules through an automated and efficient backend.

## Features ✨ ##
- Automated web scraping of schedules from the official site.
- Scheduled tasks with APScheduler for regular data updates.
- FastAPI-based high-performance RESTful API.
- Real-time data storage and syncing with Firebase Firestore.
- Secure configuration management using python-dotenv.
- CRUD operations for managing resources.
- Firebase-based authentication and authorization.
- Validation of request data using Pydantic.
- OpenAPI documentation available at /docs.
- Integration-ready with firebase.

## Tech Stack 🛠️ ##

- Framework: FastAPI
- Language: Python 3.8+
- Database: 
- Authentication: 
- Unit Tests:
- Scrapping Scheduler:  
- Other Tools: Uvicorn, Pydantic

## Getting Started 🚀 ##

Follow these instructions to set up the project locally.

### Prerequisites 🔧 ###
- Python 3.8 or higher
- Pipenv

### Installation ⚙️ ###

1. Clone the repository:

```git clone https://github.com/KNI-PM-Szczecin/plan_pm```

```cd backend```

2. Create and activate a virtual environment:

```python -m venv venv```

For Linux/Mac

```source venv/bin/activate```  

For Windows

```venv\Scripts\activate```     

3. Install dependencies:

```pip install -r requirements.txt```


4. Start the development server:

```uvicorn app.main:app --reload```

## API Endpoints 🌐 ##

Base URL: http://localhost:8000

### Other Endpoints ###

| Method | Endpoint              | Description                    | Auth Required              |
|--------|-----------------------|--------------------------------|----------------------------|
| GET    | /                     | Default page                   | No                         |

### Extra info: ### 

Detailed documentation and interactive API docs available at /docs (Swagger UI).