# Memories API (FastAPI + SQLite)

This is a lightweight backend to support the take-home mobile app. It includes auth, profile, albums, and memory uploads with pagination.

## Setup

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Swagger UI is available at `http://localhost:8000/docs` and ReDoc at `http://localhost:8000/redoc`.

The app creates `data.db` and an `uploads/` folder on startup.

Default seeded user:
- username: `demo`
- password: `password`

## Architecture Overview

- `app/main.py`: FastAPI routes, pagination, and upload handling.
- `app/models.py`: SQLAlchemy models.
- `app/schemas.py`: Pydantic request/response models.
- `app/auth.py`: Simple bearer-token auth backed by SQLite.
- `app/db.py`: Database setup and session dependency.

## API Usage

### Auth
`POST /auth/login`

```json
{
  "username": "demo",
  "password": "password"
}
```

Response:

```json
{ "token": "..." }
```

Use `Authorization: Bearer <token>` for all other endpoints.

### Profile
- `GET /me`
- `PUT /me` (name, birthday, avatar_url)

### Albums
- `GET /albums?page=1&page_size=20`
- `POST /albums`
- `PUT /albums/{id}`

### Memories
- `GET /albums/{id}/memories?page=1&page_size=20`
- `POST /upload` (multipart form)

Example upload request:

```bash
curl -X POST http://localhost:8000/upload \
  -H "Authorization: Bearer <token>" \
  -F "album_id=1" \
  -F "title=Beach Day" \
  -F "file=@/path/to/photo.jpg"
```

## Pagination
All list endpoints accept `page` and `page_size` and return:

```json
{
  "items": [ ... ],
  "page": 1,
  "page_size": 20,
  "total": 42
}
```

## Tradeoffs & Future Improvements

- Passwords are stored in plain text for simplicity; use hashing (bcrypt/argon2) in production.
- Tokens are opaque DB records; consider JWT or expiring tokens.
- Uploads are stored on disk locally; add object storage and signed URLs for production.
