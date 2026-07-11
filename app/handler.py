import json
import logging
import os
import random
import string
import time

import boto3

# I configure the logger to output plain strings.
# The actual structure comes from my log() helper below, which always
# writes a JSON object. CloudWatch Logs Insights can then query specific
# fields like filter statusCode = 500 instead of parsing free-form text.
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Connect to DynamoDB using the table name passed in as an environment variable.
# This means I can deploy the same code to different environments (pr-123, pr-456)
# just by changing TABLE_NAME, without touching the code itself.
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])


def log(level, message, **extra):
    # I always emit a JSON object so CloudWatch Logs Insights can filter on
    # individual fields rather than parsing free-form strings.
    # Example query: filter statusCode = 404 | stats count() by bin(5m)
    record = {"level": level, "message": message}
    record.update(extra)
    logger.info(json.dumps(record))


def lambda_handler(event, context):
    start = time.time()

    # API Gateway passes every HTTP request to this single function.
    # I read the method (GET, POST) and the path (/shorten, /abc123) from the event
    # to decide what to do.
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    path = event.get("rawPath", "")

    log("INFO", "request received", method=method, path=path)

    # --- Route 1: POST /shorten ---
    # The caller sends a long URL in the request body.
    # I generate a short 6-character ID, save the mapping to DynamoDB, and return the ID.
    if method == "POST" and path == "/shorten":
        body = json.loads(event.get("body") or "{}")
        long_url = body.get("url")

        # Reject the request early if no URL was provided.
        if not long_url:
            log("WARN", "missing url field in request body", statusCode=400)
            return {"statusCode": 400, "body": "Missing url field"}

        # random.choices picks 6 characters from letters and digits, giving 62^6
        # possible IDs. That is more than 56 billion combinations.
        short_id = "".join(random.choices(string.ascii_letters + string.digits, k=6))

        # Store the mapping: short ID points to the original long URL.
        table.put_item(Item={"id": short_id, "url": long_url})

        duration_ms = round((time.time() - start) * 1000)
        log("INFO", "short URL created", short_id=short_id, durationMs=duration_ms, statusCode=200)

        return {"statusCode": 200, "body": json.dumps({"short_id": short_id})}

    # --- Route 2: GET /{id} ---
    # The caller hits the short URL. I look up the ID in DynamoDB and
    # send back a 301 redirect to the original long URL.
    if method == "GET" and len(path) > 1:
        # Strip the leading slash to get just the ID, e.g. "/abc123" becomes "abc123".
        short_id = path.lstrip("/")

        response = table.get_item(Key={"id": short_id})
        item = response.get("Item")

        # If the ID does not exist in the table, return 404.
        if not item:
            duration_ms = round((time.time() - start) * 1000)
            log("WARN", "short ID not found", short_id=short_id, durationMs=duration_ms, statusCode=404)
            return {"statusCode": 404, "body": "Not found"}

        duration_ms = round((time.time() - start) * 1000)
        log("INFO", "redirect served", short_id=short_id, durationMs=duration_ms, statusCode=301)

        # 301 tells the browser to permanently redirect to the original URL.
        return {"statusCode": 301, "headers": {"Location": item["url"]}, "body": ""}

    # Anything that does not match the two routes above is a bad request.
    log("WARN", "unmatched route", method=method, path=path, statusCode=400)
    return {"statusCode": 400, "body": "Bad request"}
