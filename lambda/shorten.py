
import json
import uuid
import boto3
import os
import logging
import re

dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('URL_TABLE_NAME', 'UrlTable')
table = dynamodb.Table(table_name)
logger = logging.getLogger()
logger.setLevel(logging.INFO)

URL_REGEX = re.compile(r'^(https?|ftp)://[\w.-]+(?:\.[\w\.-]+)+[/\w\.-]*$')

# Helper: Validate URL
def is_valid_url(url):
    if not url or len(url) > 2048:
        return False
    return bool(URL_REGEX.match(url))

def lambda_handler(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        original_url = body.get('url')
        if not is_valid_url(original_url):
            logger.warning(f"Invalid URL submitted: {original_url}")
            return {
                'statusCode': 400,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'POST,OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type'
                },
                'body': json.dumps({'error': 'Invalid URL'})
            }
        short_id = str(uuid.uuid4())[:8]
        # Store in DynamoDB
        table.put_item(Item={'short_id': short_id, 'original_url': original_url})
        # Get domain name from event
        domain = event.get('headers', {}).get('host', 'short.sctp-sandbox.com')
        short_url = f"https://{domain}/{short_id}"
        logger.info(f"Shortened {original_url} to {short_url}")
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST,OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps({
                'short_url': short_url,
                'original_url': original_url,
                'short_id': short_id
            })
        }
    except Exception as e:
        logger.error(f"Error in shorten lambda: {e}")
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST,OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps({'error': 'Internal server error'})
        }
