import boto3
import os
import json
import base64

s3 = boto3.client('s3')
UPLOAD_BUCKET = os.environ['UPLOAD_BUCKET']

def lambda_handler(event, context):
    try:
        body = json.loads(event['body'])
        file_name = body['fileName']
        file_data = body['fileData']
        
        # Decode and upload to S3
        audio_bytes = base64.b64decode(file_data)
        s3.put_object(Bucket=UPLOAD_BUCKET, Key=file_name, Body=audio_bytes)
        
        return {
            'statusCode': 200,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({
                'success': True,
                'message': f'File {file_name} uploaded successfully',
                'fileName': file_name
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'error': str(e)})
        }