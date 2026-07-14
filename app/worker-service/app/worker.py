"""Worker Service — processa inscrições de forma assíncrona.

Fluxo:
1. Faz long-polling à fila SQS.
2. Para cada mensagem, lê a inscrição na BD.
3. Decide CONFIRMED (há vaga) ou REJECTED (evento cheio) comparando o número
   de inscrições já confirmadas com a capacidade do evento.
4. Atualiza a BD e apaga a mensagem da fila.

Se o processamento levantar exceção, a mensagem NÃO é apagada: a SQS volta a
entregá-la e, ao fim de `maxReceiveCount` tentativas, é enviada para a DLQ.
"""
import json
import logging
import time

from sqlalchemy import func, select

from .config import settings
from .database import Base, SessionLocal, engine
from .models import Event, Registration
from .sqs_client import get_sqs_client

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(settings.service_name)


def process_registration(registration_id: int) -> None:
    """Aplica a lógica de negócio a uma inscrição."""
    db = SessionLocal()
    try:
        registration = db.get(Registration, registration_id)
        if registration is None:
            # Mensagem inválida: levanta exceção para acabar na DLQ.
            raise ValueError(f"Inscrição {registration_id} não existe")

        if registration.status != "PENDING":
            logger.info("Inscrição %s já processada (%s).", registration_id,
                        registration.status)
            return

        event = db.get(Event, registration.event_id)
        confirmed = db.scalar(
            select(func.count())
            .select_from(Registration)
            .where(
                Registration.event_id == registration.event_id,
                Registration.status == "CONFIRMED",
            )
        )

        if event is not None and confirmed < event.capacity:
            registration.status = "CONFIRMED"
        else:
            registration.status = "REJECTED"

        db.commit()
        logger.info("Inscrição %s -> %s", registration_id, registration.status)
    finally:
        db.close()


def main() -> None:
    # Garante que as tabelas existem (caso o Worker arranque antes da API).
    Base.metadata.create_all(bind=engine)
    sqs = get_sqs_client()
    logger.info("Worker iniciado. A consumir de %s", settings.sqs_queue_url)

    while True:
        response = sqs.receive_message(
            QueueUrl=settings.sqs_queue_url,
            MaxNumberOfMessages=10,
            WaitTimeSeconds=settings.wait_time_seconds,
        )
        messages = response.get("Messages", [])
        if not messages:
            continue

        for msg in messages:
            try:
                body = json.loads(msg["Body"])
                process_registration(int(body["registration_id"]))
            except Exception:  # noqa: BLE001 - deixa a SQS reentregar / DLQ
                logger.exception("Falha a processar mensagem; será reentregue.")
                continue

            # Só apaga se processou com sucesso.
            sqs.delete_message(
                QueueUrl=settings.sqs_queue_url,
                ReceiptHandle=msg["ReceiptHandle"],
            )


if __name__ == "__main__":
    # Pequena espera inicial para a BD/LocalStack ficarem prontos em local.
    time.sleep(5)
    main()
