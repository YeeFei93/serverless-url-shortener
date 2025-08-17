# Enhanced CloudFront Cleanup for Daily Deployments

This document explains the improved CloudFront cleanup process designed to handle CNAME conflicts in daily automated deployments.

## The Problem

CloudFront distributions with custom domain names (CNAMEs) like `ui.sctp-sandbox.com` can cause deployment conflicts because:

1. **Slow deletion process**: CloudFront distributions take 15-45 minutes to fully delete
2. **CNAME persistence**: The CNAME remains associated even during deletion
3. **AWS eventual consistency**: Changes take time to propagate across AWS regions
4. **Deployment timing**: Daily deployments may start before previous resources are fully cleaned up

## Enhanced Solution

### Automated Cleanup (GitHub Actions)

The GitHub Actions workflow now includes:

1. **Intelligent distribution detection**: Finds distributions by CNAME aliases
2. **Proper disable sequence**: Disables distributions before attempting deletion  
3. **Status monitoring**: Waits up to 15 minutes for distributions to reach "Deployed" status
4. **Safe deletion**: Only attempts deletion when distribution is properly disabled
5. **Pre-deployment verification**: Checks for conflicts before running Terraform

### Key Improvements

- **Extended wait times**: Up to 15 minutes for CloudFront operations vs. 30 seconds previously
- **Status checking**: Monitors distribution status throughout the process
- **Error handling**: Continues deployment even if some cleanup steps fail
- **Better logging**: Detailed progress indicators and status reporting

### Manual Fallback

If the automated cleanup fails, use the manual cleanup script:

```bash
./scripts/manual-cloudfront-cleanup.sh
```

This script provides:
- Interactive prompts for safety
- Extended wait times (up to 20 minutes)
- Detailed progress reporting
- Step-by-step manual control

## Process Flow

### Automated Daily Deployment

1. **Resource Detection**: Find existing CloudFront distributions with target CNAMEs
2. **Disable Distributions**: Set `Enabled: false` for any found distributions
3. **Wait for Deployment**: Monitor status until distributions reach "Deployed" state
4. **Attempt Deletion**: Try to delete disabled distributions
5. **Verification**: Check for remaining conflicts before Terraform deployment
6. **Proceed with Deployment**: Continue with normal Terraform apply

### Manual Intervention (if needed)

1. Run `./scripts/manual-cloudfront-cleanup.sh`
2. Review found distributions
3. Confirm cleanup action
4. Wait for completion (up to 20 minutes)
5. Verify cleanup success
6. Retry daily deployment

## Timeline Expectations

- **Disable operation**: 1-2 minutes
- **Status propagation**: 5-15 minutes  
- **Deletion initiation**: 1-2 minutes
- **Complete deletion**: 15-45 minutes (background process)

## Monitoring

### Success Indicators
- ✅ "Successfully initiated deletion of distribution"
- ✅ "No conflicting CloudFront distribution found"
- ✅ Terraform apply completes without CNAME errors

### Warning Signs
- ⚠️ "Distribution did not reach deployed state within timeout"
- ⚠️ "Failed to delete distribution - may still have dependencies"
- ⚠️ "Found existing CloudFront distribution" in pre-deployment check

## Troubleshooting

### If Daily Deployment Still Fails

1. **Check distribution status**:
   ```bash
   aws cloudfront list-distributions --query "DistributionList.Items[?Aliases.Items && (contains(Aliases.Items, 'ui.sctp-sandbox.com') || contains(Aliases.Items, 'short.sctp-sandbox.com'))]"
   ```

2. **Run manual cleanup**:
   ```bash
   ./scripts/manual-cloudfront-cleanup.sh
   ```

3. **Wait additional time**: CloudFront deletions can take up to 24 hours

4. **Force deletion** (last resort):
   - Manually disable distributions in AWS Console
   - Wait for "Deployed" status
   - Delete manually
   - Wait for complete removal

### Alternative: Temporary Workaround

If cleanup continues to fail, you can temporarily:

1. **Use different domain names**: Change CNAMEs in Terraform to avoid conflicts
2. **Skip CloudFront temporarily**: Comment out CloudFront resources for emergency deployments
3. **Deploy to different region**: Use a different AWS region temporarily

## Configuration

### GitHub Actions Settings

The workflow includes these timeouts:
- CloudFront status wait: 15 minutes
- Overall consistency wait: 60 seconds
- Distribution verification: Before each deployment

### Customization

To adjust timeouts, modify these values in the workflow:
- `wait_for_cloudfront_status "$CF_ID" "Deployed" 15` - Change `15` to desired minutes
- `sleep 60` - Change final wait time

## Best Practices

1. **Monitor first few deployments**: Watch logs carefully after implementing changes
2. **Keep manual script ready**: Have `manual-cloudfront-cleanup.sh` available for emergencies  
3. **Check AWS Console**: Verify distribution status if deployments fail
4. **Consider off-peak hours**: CloudFront operations may be faster during low-traffic periods
5. **Document incidents**: Keep track of any cleanup failures for pattern analysis
