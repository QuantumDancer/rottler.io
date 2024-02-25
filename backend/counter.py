import json
import os

import boto3

dynamodb = boto3.resource("dynamodb")


def lambda_handler(event, context):
    path = event.get("path")
    if not path:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Path parameter is required"}),
        }

    table_name = os.environ.get("TABLE_NAME")
    if not table_name:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "TABLE_NAME environment variable is not set"}),
        }

    try:
        table = dynamodb.Table(table_name)
        response = table.update_item(
            Key={"path": path},
            UpdateExpression="SET viewCount = if_not_exists(viewCount, :start) + :inc",
            ExpressionAttributeValues={":start": 0, ":inc": 1},
            ReturnValues="UPDATED_NEW",
        )

        if response["ResponseMetadata"]["HTTPStatusCode"] != 200:
            print("Error calling update_item()", response)
            return {
                "statusCode": 500,
                "body": json.dumps({"error": "Failed to update dynamodb item"}),
            }

        # DynamoDB returns all numbers as Decimal, but weknow it's an int
        new_view_count = int(response["Attributes"]["viewCount"])

        return {"statusCode": 200, "body": json.dumps({"viewCount": new_view_count})}

    except Exception as error:
        print("Error updating view count:", error)
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "Failed to update view count"}),
        }
