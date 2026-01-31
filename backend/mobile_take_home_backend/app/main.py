from datetime import datetime
from pathlib import Path
from typing import Optional

from fastapi import Depends, FastAPI, File, Form, HTTPException, UploadFile, status
from fastapi.staticfiles import StaticFiles
from PIL import Image
from sqlalchemy.orm import Session

from . import auth, models, schemas
from .db import Base, SessionLocal, engine, get_db

UPLOAD_DIR = Path("uploads")
DEFAULT_PAGE_SIZE = 20

app = FastAPI(
    title="Memories API",
    description="Backend API for the Memories offline-first photo album app.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

app.mount("/uploads", StaticFiles(directory=UPLOAD_DIR), name="uploads")


@app.on_event("startup")
def on_startup() -> None:
    Base.metadata.create_all(bind=engine)
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

    with SessionLocal() as db:
        existing = db.query(models.User).first()
        if existing is None:
            demo_user = models.User(
                username="demo",
                name="Demo User",
                password="password",
            )
            db.add(demo_user)
            db.commit()


@app.post("/auth/login", response_model=schemas.TokenResponse)
def login(payload: schemas.LoginRequest, db: Session = Depends(get_db)):
    user = (
        db.query(models.User)
        .filter(models.User.username == payload.username)
        .first()
    )
    if user is None or user.password != payload.password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials",
        )
    token = auth.create_token(db, user)
    return schemas.TokenResponse(token=token)


@app.get("/me", response_model=schemas.UserOut)
def get_me(current_user: models.User = Depends(auth.get_current_user)):
    return current_user


@app.put("/me", response_model=schemas.UserOut)
def update_me(
    payload: schemas.UserUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user),
):
    if payload.name is not None:
        current_user.name = payload.name
    if payload.birthday is not None:
        current_user.birthday = payload.birthday
    if payload.avatar_url is not None:
        current_user.avatar_url = payload.avatar_url

    db.add(current_user)
    db.commit()
    db.refresh(current_user)
    return current_user


@app.get("/albums", response_model=schemas.PaginatedAlbums)
def list_albums(
    page: int = 1,
    page_size: int = DEFAULT_PAGE_SIZE,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user),
):
    if page < 1 or page_size < 1:
        raise HTTPException(status_code=400, detail="Invalid pagination")
    query = (
        db.query(models.Album)
        .filter(models.Album.owner_id == current_user.id)
        .order_by(models.Album.created_at.desc())
    )
    total = query.count()
    items = (
        query.offset((page - 1) * page_size).limit(page_size).all()
    )
    return schemas.PaginatedAlbums(
        items=items, page=page, page_size=page_size, total=total
    )


@app.post("/albums", response_model=schemas.AlbumOut, status_code=201)
def create_album(
    payload: schemas.AlbumCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user),
):
    album = models.Album(
        title=payload.title,
        cover_image_url=payload.cover_image_url,
        owner_id=current_user.id,
    )
    db.add(album)
    db.commit()
    db.refresh(album)
    return album


@app.put("/albums/{album_id}", response_model=schemas.AlbumOut)
def update_album(
    album_id: int,
    payload: schemas.AlbumUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user),
):
    album = (
        db.query(models.Album)
        .filter(
            models.Album.id == album_id,
            models.Album.owner_id == current_user.id,
        )
        .first()
    )
    if album is None:
        raise HTTPException(status_code=404, detail="Album not found")
    if payload.title is not None:
        album.title = payload.title
    if payload.cover_image_url is not None:
        album.cover_image_url = payload.cover_image_url
    db.add(album)
    db.commit()
    db.refresh(album)
    return album


@app.get("/albums/{album_id}/memories", response_model=schemas.PaginatedMemories)
def list_memories(
    album_id: int,
    page: int = 1,
    page_size: int = DEFAULT_PAGE_SIZE,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user),
):
    album = (
        db.query(models.Album)
        .filter(
            models.Album.id == album_id,
            models.Album.owner_id == current_user.id,
        )
        .first()
    )
    if album is None:
        raise HTTPException(status_code=404, detail="Album not found")
    query = (
        db.query(models.Memory)
        .filter(models.Memory.album_id == album_id)
        .order_by(models.Memory.created_at.desc())
    )
    total = query.count()
    items = (
        query.offset((page - 1) * page_size).limit(page_size).all()
    )
    return schemas.PaginatedMemories(
        items=items, page=page, page_size=page_size, total=total
    )


@app.post("/upload", response_model=schemas.MemoryOut, status_code=201)
def upload_memory(
    album_id: int = Form(...),
    title: str = Form(...),
    image_remote_url: Optional[str] = Form(None),
    file: Optional[UploadFile] = File(None),
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user),
):
    album = (
        db.query(models.Album)
        .filter(
            models.Album.id == album_id,
            models.Album.owner_id == current_user.id,
        )
        .first()
    )
    if album is None:
        raise HTTPException(status_code=404, detail="Album not found")

    image_local_uri = None
    if file is not None:
        filename = f"{datetime.utcnow().strftime('%Y%m%d%H%M%S')}_{file.filename}"
        destination = UPLOAD_DIR / filename
        with destination.open("wb") as buffer:
            buffer.write(file.file.read())
        image_local_uri = str(destination)

        thumb_path = UPLOAD_DIR / f"thumb_{filename}"
        with Image.open(destination) as img:
            img.thumbnail((300, 300))
            img.save(thumb_path)

    memory = models.Memory(
        album_id=album_id,
        title=title,
        image_local_uri=image_local_uri,
        image_remote_url=image_remote_url,
    )
    db.add(memory)
    db.commit()
    db.refresh(memory)
    return memory
