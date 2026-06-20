import json
import os
import random
import string
import boto3

# Connect to DynamoDB using the table name passed in as an environment variable.
# This means I can deploy the same code to different environments (pr-123, pr-456)
# just by changing the TABLE_NAME variable, without touching the code itself.
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])


def lambda_handler(event, context):
    # API Gateway passes every HTTP request to this single function.
    # I read the method (GET, POST) and the path (/shorten, /abc123) from the event
    # to decide what to do.
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    path = event.get("rawPath", "")

    # --- Route 1: POST /shorten ---
    # The caller sends a long URL in the request body.
    # I generate a short 6-character ID, save the mapping to DynamoDB, and return the ID.
    if method == "POST" and path == "/shorten":
        body = json.loads(event.get("body") or "{}")
        long_url = body.get("url")

        # Reject the request early if no URL was provided.
        if not long_url:
            return {"statusCode": 400, "body": "Missing url field"}

        # random.choices picks 6 characters from letters and digits, giving 62^6
        # possible IDs. That is more than 56 billion combinations, enough for this project.
        short_id = "".join(random.choices(string.ascii_letters + string.digits, k=6))

        # Store the mapping: short ID points to the original long URL.
        table.put_item(Item={"id": short_id, "url": long_url})

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
            return {"statusCode": 404, "body": "Not found"}

        # 301 tells the browser to permanently redirect to the original URL.
        # The browser will follow the Location header automatically.
        return {"statusCode": 301, "headers": {"Location": item["url"]}, "body": ""}

    # Anything that does not match the two routes above is a bad request.
    return {"statusCode": 400, "body": "Bad request"}
