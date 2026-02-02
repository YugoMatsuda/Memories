from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field


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


class MemoryBase(BaseModel):
    title: str
    image_local_uri: Optional[str] = None
    image_remote_url: Optional[str] = None


class MemoryOut(MemoryBase):
    id: int
    album_id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


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
