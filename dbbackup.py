import json
import boto3
import datetime
import time

# Initialize clients for RDS and SNS
rds_client = boto3.client('rds')
sns_client = boto3.client('sns')

# SNS Topic ARN for notifications
sns_topic_arn = 'arn:aws:sns:us-east-1:364075929774:RDS-Backup-Notifications'  # Replace with your SNS Topic ARN

# RDS instance details
rds_instance_id = 'empdb'  # Replace with your RDS instance ID

def lambda_handler(event, context):
    # Create a timestamped snapshot identifier
    timestamp = datetime.datetime.now().strftime('%Y-%m-%d-%H-%M')
    snapshot_id = f'rds-snapshot-{rds_instance_id}-{timestamp}'
    
    try:
        # Start the snapshot process
        response = rds_client.create_db_snapshot(
            DBSnapshotIdentifier=snapshot_id,
            DBInstanceIdentifier=rds_instance_id
        )
        print(f'Snapshot initiated: {snapshot_id}')
        
        # Check snapshot status until it is completed
        while True:
            snapshot_status = rds_client.describe_db_snapshots(
                DBSnapshotIdentifier=snapshot_id
            )['DBSnapshots'][0]['Status']
            
            print(f'Snapshot status: {snapshot_status}')
            if snapshot_status == 'available':
                # If snapshot is successful, break the loop
                break
            elif snapshot_status == 'failed':
                raise Exception(f'Snapshot failed: {snapshot_id}')
            time.sleep(10)  # Wait 10 seconds before checking status again

        # Send SNS notification on successful backup
        sns_client.publish(
            TopicArn=sns_topic_arn,
            Subject='RDS Backup Success',
            Message=f'Successfully created snapshot: {snapshot_id} for RDS instance: {rds_instance_id}'
        )
        print(f'SNS notification sent for successful backup of {snapshot_id}')
        
        return {
            'statusCode': 200,
            'body': json.dumps(f'Backup completed successfully for snapshot: {snapshot_id}')
        }

    except Exception as e:
        # If there is an error, send an SNS notification
        sns_client.publish(
            TopicArn=sns_topic_arn,
            Subject='RDS Backup Failure',
            Message=f'Failed to create snapshot for RDS instance: {rds_instance_id}. Error: {str(e)}'
        )
        print(f'SNS notification sent for failed backup: {str(e)}')
        
        return {
            'statusCode': 500,
            'body': json.dumps(f'Backup failed. Error: {str(e)}')
        }
