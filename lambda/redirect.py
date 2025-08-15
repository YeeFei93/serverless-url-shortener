import json
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('UrlTable')

def lambda_handler(event, context):
    short_id = event['pathParameters']['short_id']
    response = table.get_item(Key={'short_id': short_id})

    if 'Item' in response:
        original_url = response['Item']['original_url']
        return {
            'statusCode': 302,
            'headers': {'Location': original_url}
        }
    else:
        return {'statusCode': 404, 'body': 'Not found'}
