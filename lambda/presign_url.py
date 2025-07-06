import boto3
import os
import json

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    bucket_name = os.environ['UPLOAD_BUCKET']
    file_name = event['queryStringParameters']['fileName']

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
        'headers': {'Access-Control-Allow-Origin': '*'},
        'body': json.dumps({'url': presigned_url})
    }
