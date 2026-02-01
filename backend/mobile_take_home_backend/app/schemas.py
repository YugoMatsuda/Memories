import os
from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator

BASE_URL = os.getenv("BASE_URL", "http://localhost:8000")


class LoginRequest(BaseModel):
    username: str = Field(min_length=1)
    password: str = Field(min_length=1)


class TokenResponse(BaseModel):
    token: str
    user_id: int


class UserBase(BaseModel):
    name: str
    username: str
    birthday: Optional[date] = None
    avatar_url: Optional[str] = None


class UserOut(UserBase):
    id: int

    model_config = ConfigDict(from_attributes=True)

    @field_validator('avatar_url', mode='before')
    @classmethod
    def make_absolute_url(cls, v: Optional[str]) -> Optional[str]:
        if v and v.startswith('/'):
            return f"{BASE_URL}{v}"
        return v


class UserUpdate(BaseModel):
    name: Optional[str] = None
    birthday: Optional[date] = None
    avatar_url: Optional[str] = None


class AlbumBase(BaseModel):
    title: str
    cover_image_url: Optional[str] = None


class AlbumCreate(AlbumBase):
    pass


class AlbumUpdate(BaseModel):
    title: Optional[str] = None
    cover_image_url: Optional[str] = None


class AlbumOut(AlbumBase):
    id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

    @field_validator('cover_image_url', mode='before')
    @classmethod
    def make_absolute_url(cls, v: Optional[str]) -> Optional[str]:
        if v and v.startswith('/'):
            return f"{BASE_URL}{v}"
        return v


class MemoryBase(BaseModel):
    title: str
    image_local_uri: Optional[str] = None
    image_remote_url: Optional[str] = None


class MemoryOut(MemoryBase):
    id: int
    album_id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

    @field_validator('image_local_uri', mode='before')
    @classmethod
    def make_absolute_url(cls, v: Optional[str]) -> Optional[str]:
        if v and v.startswith('/') or (v and v.startswith('uploads/')):
            path = v if v.startswith('/') else f"/{v}"
            return f"{BASE_URL}{path}"
        return v


class PaginatedAlbums(BaseModel):
    items: list[AlbumOut]
    page: int
    page_size: int
    total: int


class PaginatedMemories(BaseModel):
    items: list[MemoryOut]
    page: int
    page_size: int
    total: int
