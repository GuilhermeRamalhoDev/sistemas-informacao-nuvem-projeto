"""API Service — sistema de inscrições em eventos.

Responsabilidades:
- Criar e listar eventos.
- Criar inscrições: grava na BD com estado PENDING e publica uma mensagem
  na fila SQS para processamento assíncrono pelo Worker.
- Listar inscrições (para ver a evolução PENDING -> CONFIRMED/REJECTED).
"""
import json
import logging

from fastapi import Depends, FastAPI, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from .config import settings
from .database import Base, engine, get_db
from .models import Event, Registration
from .schemas import (
    EventCreate,
    EventOut,
    RegistrationCreate,
    RegistrationOut,
)
from .sqs_client import get_sqs_client

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(settings.service_name)

app = FastAPI(title="Event Registration API")


@app.on_event("startup")
def on_startup() -> None:
    # Cria as tabelas se ainda não existirem (simples para o âmbito do projeto).
    Base.metadata.create_all(bind=engine)
    logger.info("Tabelas verificadas/criadas.")


@app.get("/health")
def health() -> dict:
    # region permite identificar qual ambiente (primário/standby) respondeu,
    # essencial para observar o failover do Global Accelerator.
    return {
        "status": "ok",
        "service": settings.service_name,
        "region": settings.aws_region,
    }


@app.post("/events", response_model=EventOut, status_code=201)
def create_event(payload: EventCreate, db: Session = Depends(get_db)) -> Event:
    event = Event(name=payload.name, capacity=payload.capacity)
    db.add(event)
    db.commit()
    db.refresh(event)
    return event


@app.get("/events", response_model=list[EventOut])
def list_events(db: Session = Depends(get_db)) -> list[Event]:
    return list(db.scalars(select(Event).order_by(Event.id)))


@app.post("/registrations", response_model=RegistrationOut, status_code=201)
def create_registration(
    payload: RegistrationCreate, db: Session = Depends(get_db)
) -> Registration:
    event = db.get(Event, payload.event_id)
    if event is None:
        raise HTTPException(status_code=404, detail="Evento não encontrado")

    registration = Registration(
        event_id=payload.event_id,
        participant_name=payload.participant_name,
        email=payload.email,
        status="PENDING",
    )
    db.add(registration)
    db.commit()
    db.refresh(registration)

    # Publica o evento na SQS para processamento assíncrono pelo Worker.
    sqs = get_sqs_client()
    sqs.send_message(
        QueueUrl=settings.sqs_queue_url,
        MessageBody=json.dumps({"registration_id": registration.id}),
    )
    logger.info("Inscrição %s publicada na SQS.", registration.id)

    return registration


@app.get("/registrations", response_model=list[RegistrationOut])
def list_registrations(db: Session = Depends(get_db)) -> list[Registration]:
    return list(db.scalars(select(Registration).order_by(Registration.id)))
