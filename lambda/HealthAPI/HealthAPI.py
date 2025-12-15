import json

def lambda_handler(event, context):
    # Simple success response
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*', # Required for CORS
            'Access-Control-Allow-Methods': 'GET, OPTIONS'
        },
        'body': json.dumps({
            'status': 'healthy',
            'service': 'PlasticProphet-Backend',
            'message': 'Connectivity confirmed!'
        })
    }