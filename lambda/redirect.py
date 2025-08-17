
import json
import boto3
import os
import logging

dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('URL_TABLE_NAME', 'UrlTable')
table = dynamodb.Table(table_name)
logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    try:
        short_id = event.get('pathParameters', {}).get('short_id')
        if not short_id or len(short_id) > 16:
            logger.warning(f"Invalid short_id: {short_id}")
            return {
                'statusCode': 400,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'GET,OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type'
                },
                'body': json.dumps({'error': 'Invalid short_id'})
            }
        response = table.get_item(Key={'short_id': short_id})
        if 'Item' in response:
            original_url = response['Item']['original_url']
            logger.info(f"Redirecting short_id {short_id} to {original_url}")
            return {
                'statusCode': 302,
                'headers': {
                    'Location': original_url,
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'GET,OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type'
                }
            }
        else:
            logger.warning(f"short_id not found: {short_id}")
            return {
                'statusCode': 404,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'GET,OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type'
                },
                'body': json.dumps({'error': 'Not found'})
            }
    except Exception as e:
        logger.error(f"Error in redirect lambda: {e}")
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET,OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps({'error': 'Internal server error'})
        }
