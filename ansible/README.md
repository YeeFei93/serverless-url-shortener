# Ansible Deployment for Serverless URL Shortener

This folder contains Ansible playbooks for deploying, monitoring, and cleaning up the serverless URL shortener infrastructure.

## 📁 Structure

```
ansible/
├── deploy.yml           # Main deployment playbook
├── monitor.yml          # Monitoring and health check playbook
├── cleanup.yml          # Infrastructure cleanup playbook
├── inventory            # Host inventory configuration
├── group_vars/
│   └── all.yml         # Centralized variables
└── README.md           # This file
```

## 🚀 Quick Start

### Prerequisites

1. **Ansible installed** (version 2.9+)
2. **AWS CLI configured** with appropriate credentials
3. **jq installed** for JSON parsing
4. **Terraform** (for the underlying deployment)

### Deployment

```bash
# Deploy the complete infrastructure
ansible-playbook -i inventory deploy.yml

# Deploy with custom variables
ansible-playbook -i inventory deploy.yml -e "environment=staging aws_region=us-west-2"

# Dry run (plan only, no apply)
ansible-playbook -i inventory deploy.yml -e "deploy=false"
```

### Monitoring

```bash
# Check infrastructure health
ansible-playbook -i inventory monitor.yml

# Monitor specific region
ansible-playbook -i inventory monitor.yml -e "aws_region=us-west-2"
```

### Cleanup

```bash
# Clean up all resources (careful!)
ansible-playbook -i inventory cleanup.yml

# Cleanup with confirmation
ansible-playbook -i inventory cleanup.yml --check --diff
ansible-playbook -i inventory cleanup.yml
```

## 🔧 Configuration

### Variables

All configuration is centralized in `group_vars/all.yml`. Key variables include:

- `aws_region`: Target AWS region (default: us-east-1)
- `project_name`: Project identifier
- `lambda_functions`: List of Lambda function names
- `domains`: API and frontend domain names
- `deploy_timeout`: Deployment timeout in seconds

### Overriding Variables

You can override variables in several ways:

1. **Command line**: `-e "variable=value"`
2. **Inventory**: Add to `[local:vars]` section
3. **Host variables**: Create `host_vars/localhost.yml`
4. **Environment specific**: Create `group_vars/staging.yml`, etc.

## 📚 Playbook Details

### deploy.yml

**Purpose**: Complete infrastructure deployment using Terraform

**Key Features**:
- ✅ Variable validation
- ✅ AWS credential verification
- ✅ Lambda package building
- ✅ Terraform execution (init, plan, apply)
- ✅ Health checks with robust error handling
- ✅ Deployment result summary

**Variables**:
- `deploy`: Set to `false` for plan-only mode
- `environment`: Deployment environment (prod/staging/dev)

### monitor.yml

**Purpose**: Infrastructure monitoring and health reporting

**Key Features**:
- ✅ Lambda function status checks
- ✅ DynamoDB table health
- ✅ CloudWatch alarms monitoring
- ✅ Log group analysis
- ✅ Automated monitoring reports

**Outputs**:
- Console status display
- Markdown monitoring report: `monitoring-report-{timestamp}.md`

### cleanup.yml

**Purpose**: Infrastructure cleanup and resource removal

**Key Features**:
- ✅ S3 bucket cleanup (empty and delete)
- ✅ Lambda function removal
- ✅ DynamoDB table deletion
- ✅ CloudWatch log group cleanup
- ✅ API Gateway domain cleanup
- ✅ CloudFront detection (manual cleanup required)
- ✅ Comprehensive cleanup summary

**Outputs**:
- Console cleanup status
- Cleanup summary: `ansible-cleanup-summary-{timestamp}.md`

**⚠️ Warning**: Some resources (CloudFront, Route53, ACM certificates) require manual cleanup or use of the GitHub Actions workflow for complete removal.

## 🔄 Integration with Other Deployment Methods

This Ansible deployment is consistent with:

- **GitHub Actions**: Uses same resource names and structure
- **Terraform**: Calls Terraform for actual infrastructure deployment
- **Docker**: Can be combined with containerized Lambda deployment

## 🛡️ Best Practices

### Security

1. **Never commit credentials** to version control
2. **Use IAM roles** when possible instead of access keys
3. **Limit permissions** to minimum required for deployment
4. **Enable AWS CloudTrail** for audit logging

### Reliability

1. **Always run in check mode first** for destructive operations
2. **Use specific resource names** to avoid conflicts
3. **Implement proper error handling** in custom playbooks
4. **Backup important data** before cleanup operations

### Maintenance

1. **Keep variables centralized** in `group_vars/all.yml`
2. **Use consistent naming** across all deployment methods
3. **Document any custom modifications**
4. **Test playbooks** in non-production environments first

## 🆘 Troubleshooting

### Common Issues

1. **AWS CLI not configured**
   ```bash
   aws configure
   # or
   export AWS_PROFILE=your-profile
   ```

2. **Terraform not found**
   ```bash
   # Install Terraform
   # https://terraform.io/downloads
   ```

3. **Permission denied errors**
   - Check AWS IAM permissions
   - Ensure proper AWS credentials configuration

4. **Resource already exists**
   - Run cleanup playbook first
   - Use GitHub Actions cleanup for comprehensive cleanup

5. **Health checks fail**
   - Wait a few minutes after deployment
   - Check AWS Console for resource status
   - Review CloudWatch logs

### Debug Mode

```bash
# Run with verbose output
ansible-playbook -i inventory deploy.yml -vvv

# Check mode (dry run)
ansible-playbook -i inventory cleanup.yml --check --diff
```

## 🔗 Related Files

- `../scripts/docker-build.sh`: Lambda Docker image builder
- `../terraform/`: Infrastructure as Code definitions
- `../.github/workflows/daily-deploy.yml`: GitHub Actions deployment
- `../scripts/manual-cleanup.sh`: Manual cleanup script

## 📋 Examples

### Development Deployment

```bash
ansible-playbook -i inventory deploy.yml -e "
  environment=dev
  aws_region=us-west-2
  s3_bucket_name=dev-url-shortener-frontend
"
```

### Production Monitoring

```bash
ansible-playbook -i inventory monitor.yml -e "
  environment=prod
  alert_email=admin@example.com
"
```

### Safe Cleanup

```bash
# First check what would be deleted
ansible-playbook -i inventory cleanup.yml --check --diff

# Then proceed with actual cleanup
ansible-playbook -i inventory cleanup.yml
```
