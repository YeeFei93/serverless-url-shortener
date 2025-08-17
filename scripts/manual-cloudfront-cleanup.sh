#!/bin/bash

# Manual CloudFront cleanup script
# Use this if the automated GitHub Actions cleanup fails
# This script provides more detailed output and manual confirmation steps

set -e

echo "🚨 Manual CloudFront Cleanup Script"
echo "====================================="
echo ""
echo "This script will help you manually clean up CloudFront distributions"
echo "that might be causing CNAME conflicts in your daily deployments."
echo ""

# Function to wait for CloudFront distribution status with progress
wait_for_cloudfront_status() {
  local cf_id=$1
  local target_status=$2
  local max_wait_minutes=$3
  local wait_seconds=0
  local max_wait_seconds=$((max_wait_minutes * 60))
  
  echo "⏳ Waiting for CloudFront distribution $cf_id to reach status: $target_status"
  echo "   Maximum wait time: ${max_wait_minutes} minutes"
  echo ""
  
  while [ $wait_seconds -lt $max_wait_seconds ]; do
    local current_status=$(aws cloudfront get-distribution --id "$cf_id" --query 'Distribution.Status' --output text 2>/dev/null || echo "NotFound")
    
    if [ "$current_status" = "$target_status" ]; then
      echo "✅ CloudFront distribution $cf_id is now $target_status"
      return 0
    elif [ "$current_status" = "NotFound" ]; then
      echo "✅ CloudFront distribution $cf_id no longer exists"
      return 0
    fi
    
    local minutes_waited=$((wait_seconds / 60))
    local remaining_minutes=$(((max_wait_seconds - wait_seconds) / 60))
    printf "\r   Status: %-15s | Waited: %2dm | Remaining: %2dm" "$current_status" "$minutes_waited" "$remaining_minutes"
    
    sleep 30
    wait_seconds=$((wait_seconds + 30))
  done
  
  echo ""
  echo "⚠️ Timeout waiting for CloudFront distribution $cf_id to reach $target_status"
  return 1
}

echo "🔍 Checking for existing CloudFront distributions..."
echo ""

# Check AWS credentials
if ! aws sts get-caller-identity > /dev/null 2>&1; then
  echo "❌ Error: AWS credentials not configured or invalid"
  echo "Please run 'aws configure' or set AWS environment variables"
  exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Using AWS Account: $ACCOUNT_ID"
echo ""

DISTRIBUTIONS_FOUND=false

# Check for distributions with our CNAMEs
for domain in "ui.sctp-sandbox.com" "short.sctp-sandbox.com"; do
  echo "🔍 Checking for CloudFront distributions with CNAME: $domain"
  
  # Get all distribution IDs that have this domain as an alias
  CF_IDS=$(aws cloudfront list-distributions --query "DistributionList.Items[?Aliases.Items && contains(Aliases.Items, '$domain')].Id" --output text 2>/dev/null || echo "")
  
  if [ -n "$CF_IDS" ] && [ "$CF_IDS" != "None" ]; then
    DISTRIBUTIONS_FOUND=true
    
    for CF_ID in $CF_IDS; do
      echo "📍 Found CloudFront distribution: $CF_ID"
      
      # Get detailed information
      DISTRIBUTION_INFO=$(aws cloudfront get-distribution --id "$CF_ID" 2>/dev/null || echo "{}")
      if [ "$DISTRIBUTION_INFO" != "{}" ]; then
        ENABLED=$(echo "$DISTRIBUTION_INFO" | jq -r '.Distribution.DistributionConfig.Enabled')
        STATUS=$(echo "$DISTRIBUTION_INFO" | jq -r '.Distribution.Status')
        DOMAIN_NAME=$(echo "$DISTRIBUTION_INFO" | jq -r '.Distribution.DomainName')
        ALIASES=$(echo "$DISTRIBUTION_INFO" | jq -r '.Distribution.DistributionConfig.Aliases.Items[]' 2>/dev/null | tr '\n' ' ')
        
        echo "   Domain Name: $DOMAIN_NAME"
        echo "   Status: $STATUS"
        echo "   Enabled: $ENABLED"
        echo "   Aliases: $ALIASES"
        echo ""
      fi
    done
  else
    echo "✅ No CloudFront distributions found for $domain"
    echo ""
  fi
done

if [ "$DISTRIBUTIONS_FOUND" = false ]; then
  echo "🎉 No conflicting CloudFront distributions found!"
  echo "Your daily deployment should work without CNAME conflicts."
  exit 0
fi

echo "🤔 Found CloudFront distributions that may cause conflicts."
echo ""
read -p "Do you want to proceed with cleanup? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Operation cancelled."
  exit 0
fi

echo ""
echo "🚀 Starting CloudFront cleanup process..."
echo ""

# Process each domain again for cleanup
for domain in "ui.sctp-sandbox.com" "short.sctp-sandbox.com"; do
  CF_IDS=$(aws cloudfront list-distributions --query "DistributionList.Items[?Aliases.Items && contains(Aliases.Items, '$domain')].Id" --output text 2>/dev/null || echo "")
  
  if [ -n "$CF_IDS" ] && [ "$CF_IDS" != "None" ]; then
    for CF_ID in $CF_IDS; do
      echo "🔧 Processing CloudFront distribution: $CF_ID (domain: $domain)"
      
      # Get current status
      DISTRIBUTION_INFO=$(aws cloudfront get-distribution --id "$CF_ID" 2>/dev/null || echo "{}")
      if [ "$DISTRIBUTION_INFO" = "{}" ]; then
        echo "✅ Distribution $CF_ID no longer exists"
        continue
      fi
      
      ENABLED=$(echo "$DISTRIBUTION_INFO" | jq -r '.Distribution.DistributionConfig.Enabled')
      STATUS=$(echo "$DISTRIBUTION_INFO" | jq -r '.Distribution.Status')
      
      echo "   Current status: $STATUS, Enabled: $ENABLED"
      
      # Step 1: Disable if needed
      if [ "$ENABLED" = "true" ]; then
        echo "   🔧 Disabling distribution..."
        
        # Get config with ETag
        aws cloudfront get-distribution-config --id "$CF_ID" > /tmp/cf-config-$CF_ID.json 2>/dev/null
        ETAG=$(jq -r '.ETag' /tmp/cf-config-$CF_ID.json)
        
        # Create disabled config (extract only DistributionConfig part)
        jq '.DistributionConfig | .Enabled = false' /tmp/cf-config-$CF_ID.json > /tmp/cf-config-disabled-$CF_ID.json
        
        # Update distribution
        if aws cloudfront update-distribution --id "$CF_ID" --distribution-config file:///tmp/cf-config-disabled-$CF_ID.json --if-match "$ETAG" 2>/dev/null; then
          echo "   ✅ Successfully disabled distribution $CF_ID"
        else
          echo "   ⚠️ Failed to disable distribution $CF_ID"
          continue
        fi
        
        # Clean up temp files
        rm -f /tmp/cf-config-$CF_ID.json /tmp/cf-config-disabled-$CF_ID.json
      fi
      
      # Step 2: Wait for deployment
      echo "   ⏳ Waiting for distribution to be deployed..."
      if wait_for_cloudfront_status "$CF_ID" "Deployed" 20; then
        echo "   🗑️ Attempting to delete distribution..."
        
        # Get fresh ETag for deletion
        FRESH_ETAG=$(aws cloudfront get-distribution --id "$CF_ID" --query 'ETag' --output text 2>/dev/null || echo "")
        
        if [ -n "$FRESH_ETAG" ]; then
          if aws cloudfront delete-distribution --id "$CF_ID" --if-match "$FRESH_ETAG" 2>/dev/null; then
            echo "   ✅ Successfully initiated deletion of distribution $CF_ID"
          else
            echo "   ⚠️ Failed to delete distribution $CF_ID"
            echo "      This may be due to dependencies or the distribution still being in use"
          fi
        else
          echo "   ⚠️ Could not get ETag for deletion"
        fi
      else
        echo "   ⚠️ Distribution did not reach deployed state within timeout"
        echo "      You may need to wait longer and try again later"
      fi
      
      echo ""
    done
  fi
done

echo "🏁 CloudFront cleanup process completed!"
echo ""
echo "💡 Next steps:"
echo "   1. Wait a few minutes for DNS propagation"
echo "   2. Verify no distributions remain: aws cloudfront list-distributions"
echo "   3. Try your daily deployment again"
echo ""
echo "ℹ️  If distributions still exist, they may be in the deletion process."
echo "   CloudFront deletions can take up to 24 hours to complete."
