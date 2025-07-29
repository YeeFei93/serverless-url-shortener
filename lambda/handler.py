import json
import boto3
import os
import uuid

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def lambda_handler(event, context):
    body = json.loads(event['body'])

    original_url = body.get("url")
    if not original_url:
        return {"statusCode": 400, "body": json.dumps({"error": "URL required"})}

    short_id = str(uuid.uuid4())[:8]
    table.put_item(Item={"short_id": short_id, "original_url": original_url})

    return {
        "statusCode": 200,
        "body": json.dumps({"short_url": f"https://short.ly/{short_id}"})
    }