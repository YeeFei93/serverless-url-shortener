import json
import uuid
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('UrlTable')

def lambda_handler(event, context):
    body = json.loads(event['body'])
    original_url = body.get('url')
    short_id = str(uuid.uuid4())[:8]

    table.put_item(Item={'short_id': short_id, 'original_url': original_url})

    # Get the actual domain name and stage from the event
    domain = event['headers'].get('host')
    stage = event['requestContext'].get('stage')  # For HTTP API v2, this might be "$default"

    return {
        'statusCode': 200,
        'body': json.dumps({
            'short_url': f"https://{domain}/{short_id}"
        })
    }
