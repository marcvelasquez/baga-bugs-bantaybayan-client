# BantayBayan FastAPI Server

A FastAPI backend server for the BantayBayan flood monitoring and incident reporting system.

## Features

- 🔐 **Authentication & Authorization** - JWT-based authentication
- 📍 **Incident Reporting** - Create and manage flood incident reports with geolocation
- 📊 **Statistics** - Real-time reporting statistics
- 🗺️ **Geo-location Support** - Latitude/longitude based incident tracking
- 🔄 **RESTful API** - Clean and documented API endpoints
- 💾 **SQLite Database** - Lightweight database (easily switchable to PostgreSQL/MySQL)

## Quick Start

### Prerequisites

- Python 3.10 or higher
- pip (Python package manager)

### Installation

1. Navigate to the server directory:
```bash
cd server
```

2. Install dependencies using uv:
```bash
uv pip install -r requirements.txt
```

3. Create environment file (optional, defaults work for development):
```bash
cp .env.example .env
```

### Running the Server

**Recommended way (using uv):**
```bash
uv run python run.py
```

This will start the server at http://localhost:8000

The API will be available at:
- API: http://localhost:8000
- Interactive API docs (Swagger): http://localhost:8000/docs
- Alternative API docs (ReDoc): http://localhost:8000/redoc

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login and get access token

### Users
- `GET /api/users/` - Get all users
- `GET /api/users/{user_id}` - Get user by ID

### Reports
- `POST /api/reports/` - Create a new report
- `GET /api/reports/` - Get all reports (with filters)
- `GET /api/reports/stats` - Get report statistics
- `GET /api/reports/{report_id}` - Get specific report
- `PUT /api/reports/{report_id}` - Update a report
- `DELETE /api/reports/{report_id}` - Delete a report

### Incidents
- `POST /api/incidents/` - Create a new incident
- `GET /api/incidents/` - Get all incidents (with filters)
- `GET /api/incidents/active` - Get active incidents only
- `GET /api/incidents/{incident_id}` - Get specific incident
- `PUT /api/incidents/{incident_id}` - Update an incident
- `DELETE /api/incidents/{incident_id}` - Delete an incident

## Project Structure

```
server/
├── app/
│   ├── api/              # API route handlers
│   │   ├── auth.py       # Authentication endpoints
│   │   ├── users.py      # User management
│   │   ├── reports.py    # Report endpoints
│   │   └── incidents.py  # Incident endpoints
│   ├── core/             # Core functionality
│   │   ├── config.py     # Configuration settings
│   │   ├── database.py   # Database connection
│   │   └── security.py   # Security utilities
│   ├── models/           # Database models
│   │   └── models.py     # SQLAlchemy models
│   ├── schemas/          # Pydantic schemas
│   │   └── schemas.py    # Request/response schemas
│   └── main.py           # Application entry point
├── requirements.txt      # Python dependencies
├── .env.example         # Environment template
└── README.md            # This file
```

## Database Models

### User
- Email, username, password (hashed)
- Creation timestamp
- Active status

### Report
- User reference
- Incident type (info/critical/warning)
- Latitude/longitude
- Description
- Timestamps
- Verification status

### Incident
- Title and description
- Incident type
- Latitude/longitude
- Severity score
- Affected area radius
- Report count
- Active status

## Configuration

Edit the `.env` file to configure:

- `DATABASE_URL` - Database connection string
- `SECRET_KEY` - JWT secret key (generate with: `openssl rand -hex 32`)
- `ACCESS_TOKEN_EXPIRE_MINUTES` - Token expiration time
- `ALLOWED_ORIGINS` - CORS allowed origins

## Production Deployment

For production deployment:

1. Use a production-grade database (PostgreSQL recommended)
2. Update `DATABASE_URL` in `.env`
3. Set a strong `SECRET_KEY`
4. Use a production ASGI server (Gunicorn with Uvicorn workers)
5. Set up HTTPS/SSL
6. Configure proper CORS origins
7. Enable logging and monitoring

Example production start command:
```bash
gunicorn app.main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

## Integration with Flutter App

Update your Flutter app's API base URL to point to this server:

```dart
const String apiBaseUrl = 'http://localhost:8000/api';
```

For mobile testing, use your computer's IP address:
```dart
const String apiBaseUrl = 'http://192.168.1.X:8000/api';
```

## Testing

Access the interactive API documentation at http://localhost:8000/docs to test all endpoints directly in your browser.

## License

Copyright © 2025 BantayBayan Team
