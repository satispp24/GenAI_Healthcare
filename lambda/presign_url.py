import boto3
import os
import json

def lambda_handler(event, context):
    try:
        s3 = boto3.client('s3')
        bucket_name = os.environ['UPLOAD_BUCKET']
        
        # Validate query parameters
        if not event.get('queryStringParameters') or not event['queryStringParameters'].get('fileName'):
            return {
                'statusCode': 400,
                'headers': {
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'GET, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type'
                },
                'body': json.dumps({'error': 'fileName parameter is required'})
            }
        
        file_name = event['queryStringParameters']['fileName']
        
        # Generate presigned URL
        presigned_url = s3.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': bucket_name,
                'Key': file_name,
                'ContentType': 'audio/wav'
            },
            ExpiresIn=300
        )

        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps({'url': presigned_url})
        }
    
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps({'error': f'Failed to generate presigned URL: {str(e)}'})
        }
