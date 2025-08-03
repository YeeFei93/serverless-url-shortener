import json
import uuid
import boto3
import os
import datetime
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all

# Patch AWS SDK calls for X-Ray tracing
patch_all()

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('UrlTable')
firehose = boto3.client('firehose')

@xray_recorder.capture('lambda_handler')
def lambda_handler(event, context):
    body = json.loads(event['body'])
    original_url = body.get('url')
    short_id = str(uuid.uuid4())[:8]
    
    # Get request metadata for analytics
    user_agent = event.get('headers', {}).get('user-agent', 'Unknown')
    source_ip = event.get('headers', {}).get('x-forwarded-for', 'Unknown')
    referer = event.get('headers', {}).get('referer', 'Direct')

    with xray_recorder.in_subsegment('dynamodb_write'):
        table.put_item(Item={'short_id': short_id, 'original_url': original_url})

    # Get the actual domain name and stage from the event
    domain = event['headers'].get('host')
    stage = event['requestContext'].get('stage')  # For HTTP API v2, this might be "$default"
    
    short_url = f"https://{domain}/{short_id}"
    
    # Send analytics data to Kinesis Data Firehose
    analytics_data = {
        'timestamp': datetime.datetime.utcnow().isoformat(),
        'short_id': short_id,
        'original_url': original_url,
        'short_url': short_url,
        'source_ip': source_ip,
        'user_agent': user_agent,
        'referer': referer,
        'event_type': 'create'
    }
    
    try:
        with xray_recorder.in_subsegment('send_analytics'):
            firehose_stream_name = os.environ.get('FIREHOSE_STREAM_NAME', 'url-shortener-analytics')
            firehose.put_record(
                DeliveryStreamName=firehose_stream_name,
                Record={'Data': json.dumps(analytics_data) + '\n'}
            )
    except Exception as e:
        print(f"Failed to send analytics: {str(e)}")
        # Don't fail the URL creation if analytics fails

    return {
        'statusCode': 200,
        'body': json.dumps({
            'short_url': short_url
        })
    }
