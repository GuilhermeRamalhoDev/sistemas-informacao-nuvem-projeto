"""Configuração da ligação à base de dados (SQLAlchemy)."""
from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

from .config import settings

engine = create_engine(settings.database_url, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)
Base = declarative_base()


def get_db():
    """Dependência FastAPI: fornece uma sessão e garante o fecho."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
