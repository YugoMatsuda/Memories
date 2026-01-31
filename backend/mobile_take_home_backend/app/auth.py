from uuid import uuid4

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from . import models
from .db import get_db

bearer_scheme = HTTPBearer(auto_error=False)


def create_token(db: Session, user: models.User) -> str:
    token = uuid4().hex
    db_token = models.Token(token=token, user=user)
    db.add(db_token)
    db.commit()
    return token


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme),
    db: Session = Depends(get_db),
) -> models.User:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
        )
    token = (
        db.query(models.Token)
        .filter(models.Token.token == credentials.credentials)
        .first()
    )
    if token is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        )
    return token.user
