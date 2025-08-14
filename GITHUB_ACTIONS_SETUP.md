# GitHub Actions Auto-Deployment Setup

This document explains how to set up automated daily deployment of your AWS serverless URL shortener infrastructure using GitHub Actions.

## Overview

The GitHub Actions workflow will:
- Run daily at 8:00 AM UTC (configurable)
- Build Lambda deployment packages
- Deploy infrastructure using Terraform
- Perform health checks on deployed resources
- Provide deployment status notifications

## Setup Options

You have two authentication methods to choose from:

### Option 1: AWS OIDC (Recommended for Security)

**File**: `.github/workflows/daily-deploy.yml`

This method uses OpenID Connect (OIDC) to assume an AWS IAM role without storing long-lived credentials.

#### Setup Steps:

1. **Create an OIDC Identity Provider in AWS:**
   ```bash
   aws iam create-open-id-connect-provider \
     --url https://token.actions.githubusercontent.com \
     --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
     --client-id-list sts.amazonaws.com
   ```

2. **Create an IAM Role for GitHub Actions:**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
             "token.actions.githubusercontent.com:sub": "repo:YeeFei93/serverless-url-shortener:ref:refs/heads/main"
           }
         }
       }
     ]
   }
   ```

3. **Attach Necessary Policies to the Role:**
   - `AmazonAPIGatewayAdministrator`
   - `AWSLambda_FullAccess`
   - `AmazonDynamoDBFullAccess`
   - `AmazonS3FullAccess`
   - `CloudFrontFullAccess`
   - `AmazonRoute53FullAccess`
   - `AWSCertificateManagerFullAccess`
   - `IAMFullAccess`
   - `CloudWatchFullAccess`

4. **Add GitHub Repository Secret:**
   - Go to your repository Settings → Secrets and variables → Actions
   - Add secret: `AWS_ROLE_ARN` with value: `arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsRole`

### Option 2: AWS Access Keys (Simpler Setup)

**File**: `.github/workflows/daily-deploy-with-secrets.yml`

This method uses traditional AWS access keys stored as GitHub secrets.

#### Setup Steps:

1. **Create an IAM User for GitHub Actions:**
   ```bash
   aws iam create-user --user-name github-actions-deploy
   ```

2. **Attach Necessary Policies (same as above)**

3. **Create Access Keys:**
   ```bash
   aws iam create-access-key --user-name github-actions-deploy
   ```

4. **Add GitHub Repository Secrets:**
   - Go to your repository Settings → Secrets and variables → Actions  
   - Add secrets:
     - `AWS_ACCESS_KEY_ID`: Your access key ID
     - `AWS_SECRET_ACCESS_KEY`: Your secret access key

## Required IAM Permissions

The AWS role/user needs the following permissions to deploy your infrastructure:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "apigateway:*",
        "lambda:*",
        "dynamodb:*",
        "s3:*",
        "cloudfront:*",
        "route53:*",
        "acm:*",
        "iam:*",
        "logs:*",
        "cloudwatch:*",
        "wafv2:*",
        "xray:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## Terraform State Management (Optional but Recommended)

For production deployments, configure remote state storage:

1. **Create an S3 bucket for Terraform state:**
   ```bash
   aws s3 mb s3://your-terraform-state-bucket
   ```

2. **Create a DynamoDB table for state locking:**
   ```bash
   aws dynamodb create-table \
     --table-name terraform-locks \
     --attribute-definitions AttributeName=LockID,AttributeType=S \
     --key-schema AttributeName=LockID,KeyType=HASH \
     --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
   ```

3. **Uncomment and configure the backend block in `terraform/backend.tf`**

## Workflow Configuration

### Schedule Configuration

The workflow runs daily at 8:00 AM UTC by default. To change the schedule, modify the cron expression:

```yaml
schedule:
  - cron: '0 8 * * *'  # 8:00 AM UTC daily
  # Examples:
  # - cron: '0 0 * * *'    # Midnight UTC daily  
  # - cron: '0 12 * * 1'   # Noon UTC every Monday
  # - cron: '0 6 * * 1-5'  # 6:00 AM UTC weekdays only
```

### Manual Triggers

Both workflows support manual triggering with an optional "destroy first" parameter:

1. Go to your repository → Actions tab
2. Select the workflow
3. Click "Run workflow"
4. Optionally check "Destroy existing resources first"

## Monitoring and Notifications

### Built-in Monitoring

The workflow includes:
- Deployment status summary in GitHub Actions
- Health checks after deployment
- Terraform output display
- Success/failure notifications

### Adding Custom Notifications

To add Slack, Discord, or email notifications, modify the notification steps:

```yaml
- name: Send Slack notification
  if: needs.deploy.result == 'success'
  uses: 8398a7/action-slack@v3
  with:
    status: success
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## Troubleshooting

### Common Issues:

1. **Permission Denied Errors**: Ensure the AWS role/user has all required permissions
2. **State Lock Errors**: If using remote state, ensure the DynamoDB table exists
3. **Terraform Init Failures**: Check that the backend configuration is correct
4. **Lambda Build Failures**: Ensure the `build.sh` script is executable

### Debug Mode

To enable verbose logging, add to the workflow environment:

```yaml
env:
  TF_LOG: DEBUG
  AWS_REGION: us-east-1
```

## Security Best Practices

1. **Use OIDC instead of long-lived access keys when possible**
2. **Apply least privilege principle to IAM permissions**
3. **Enable CloudTrail logging for AWS API calls**
4. **Use remote state with encryption enabled**
5. **Regularly rotate access keys if using Option 2**
6. **Monitor GitHub Actions logs for any security issues**

## Testing the Setup

1. **Test the workflow manually first:**
   - Go to Actions tab → Select workflow → Run workflow
   - Monitor the execution and check for any errors

2. **Verify the schedule is working:**
   - Check the Actions history after the scheduled time
   - Ensure resources are deployed successfully

3. **Test the destroy functionality:**
   - Run workflow manually with "destroy first" checked
   - Verify resources are cleaned up and redeployed

## Cost Considerations

- The workflow runs daily, which means daily AWS resource provisioning
- Most resources in this project fall under AWS Free Tier
- Monitor AWS billing to ensure costs remain within expectations
- Consider running less frequently (weekly) if daily is too frequent

## Next Steps

1. Choose your authentication method (OIDC recommended)
2. Set up the required AWS resources and permissions
3. Configure GitHub repository secrets
4. Test the workflow manually
5. Monitor the first few scheduled runs
6. Customize notifications and monitoring as needed
