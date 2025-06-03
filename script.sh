#!/bin/bash

# Exit on error
set -e

# CONFIGURATION
S3_BUCKET="your-s3-bucket-name"     # <-- Replace with your actual S3 bucket name
REGION="ap-southeast-2"             # <-- Replace with your AWS region
TMP_DIR="/tmp/codecommit-backups"
DATE=$(date +%Y-%m-%d)

# Create backup directory (do not delete previous S3 backups)
mkdir -p "$TMP_DIR"

# Get the list of all CodeCommit repositories
echo "🔍 Fetching list of CodeCommit repositories..."
REPOS=$(aws codecommit list-repositories --region "$REGION" --query "repositories[].repositoryName" --output text)

for REPO in $REPOS; do
  echo "📦 Backing up repository: $REPO"

  # Define local and S3 paths
  REPO_DIR="$TMP_DIR/$REPO"
  ZIP_FILE="$TMP_DIR/${REPO}_${DATE}.zip"
  S3_KEY="backups/codecommit/$DATE/${REPO}.zip"

  # Clean previous local clone if exists
  rm -rf "$REPO_DIR"

  # Clone and zip
  git clone "https://git-codecommit.$REGION.amazonaws.com/v1/repos/$REPO" "$REPO_DIR"
  zip -r "$ZIP_FILE" "$REPO_DIR" > /dev/null

  # Upload to S3
  aws s3 cp "$ZIP_FILE" "s3://$S3_BUCKET/$S3_KEY"

  echo "✅ Uploaded to: s3://$S3_BUCKET/$S3_KEY"
done

echo "🎉 All repositories backed up without deleting old S3 backups."
