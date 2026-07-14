"""Schemas Pydantic (validação de entrada/saída da API)."""
from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field


class EventCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    capacity: int = Field(ge=0)


class EventOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    capacity: int
    created_at: datetime


class RegistrationCreate(BaseModel):
    event_id: int
    participant_name: str = Field(min_length=1, max_length=120)
    email: EmailStr


class RegistrationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    event_id: int
    participant_name: str
    email: str
    status: str
    created_at: datetime
