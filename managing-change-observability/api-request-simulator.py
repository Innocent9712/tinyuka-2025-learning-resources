import json
import random
import time
import logging
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Adjustable weights (can also come from env vars)
RESPONSE_WEIGHTS = {
    200: int(os.getenv("WEIGHT_200", "60")),
    201: int(os.getenv("WEIGHT_201", "15")),
    400: int(os.getenv("WEIGHT_400", "15")),
    500: int(os.getenv("WEIGHT_500", "10")),
}

LATENCY_PROBABILITY = float(os.getenv("LATENCY_PROBABILITY", "0.2"))
ERROR_PROBABILITY = float(os.getenv("ERROR_PROBABILITY", "0.1"))


def weighted_choice(weights: dict):
    statuses = list(weights.keys())
    values = list(weights.values())
    return random.choices(statuses, weights=values, k=1)[0]


def lambda_handler(event, context):
    request_id = context.aws_request_id
    start_time = time.time()

    # Simulate latency
    if random.random() < LATENCY_PROBABILITY:
        sleep_time = random.uniform(0.5, 2.5)
        time.sleep(sleep_time)

    status_code = weighted_choice(RESPONSE_WEIGHTS)

    # Simulate application exception
    if random.random() < ERROR_PROBABILITY:
        logger.error(json.dumps({
            "type": "application_error",
            "request_id": request_id,
            "message": "Simulated unhandled exception"
        }))
        raise Exception("Simulated application crash")

    duration_ms = int((time.time() - start_time) * 1000)

    log_entry = {
        "type": "http_transaction",
        "request_id": request_id,
        "method": "GET",
        "path": "/demo",
        "status_code": status_code,
        "duration_ms": duration_ms,
        "source": "observability-demo-lambda"
    }

    if status_code >= 500:
        logger.error(json.dumps(log_entry))
    elif status_code >= 400:
        logger.warning(json.dumps(log_entry))
    else:
        logger.info(json.dumps(log_entry))

    return {
        "statusCode": status_code,
        "body": json.dumps({
            "message": "Request processed",
            "status": status_code
        })
    }
