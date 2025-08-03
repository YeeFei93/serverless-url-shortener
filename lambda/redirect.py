import json
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
    short_id = event['pathParameters']['short_id']
    
    # Get request metadata for analytics
    user_agent = event.get('headers', {}).get('user-agent', 'Unknown')
    source_ip = event.get('headers', {}).get('x-forwarded-for', 'Unknown')
    referer = event.get('headers', {}).get('referer', 'Direct')
    
    with xray_recorder.in_subsegment('dynamodb_lookup'):
        response = table.get_item(Key={'short_id': short_id})
    
    if 'Item' in response:
        original_url = response['Item']['original_url']
        
        # Send analytics data to Kinesis Data Firehose
        analytics_data = {
            'timestamp': datetime.datetime.utcnow().isoformat(),
            'short_id': short_id,
            'original_url': original_url,
            'source_ip': source_ip,
            'user_agent': user_agent,
            'referer': referer,
            'event_type': 'redirect'
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
            # Don't fail the redirect if analytics fails
        
        return {
            'statusCode': 302,
            'headers': {'Location': original_url}
        }
    else:
        # Log 404 events for analytics
        analytics_data = {
            'timestamp': datetime.datetime.utcnow().isoformat(),
            'short_id': short_id,
            'source_ip': source_ip,
            'user_agent': user_agent,
            'referer': referer,
            'event_type': '404_error'
        }
        
        try:
            firehose_stream_name = os.environ.get('FIREHOSE_STREAM_NAME', 'url-shortener-analytics')
            firehose.put_record(
                DeliveryStreamName=firehose_stream_name,
                Record={'Data': json.dumps(analytics_data) + '\n'}
            )
        except Exception as e:
            print(f"Failed to send analytics: {str(e)}")
        
        return {'statusCode': 404, 'body': 'Not found'}
