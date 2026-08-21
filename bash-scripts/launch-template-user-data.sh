#!/bin/bash

###############################################################################
# WORDPRESS ASG-LAUNCH-TEMPLATE USER DATA SCRIPT
#
# - RETRIEVES CONFIGURATION FROM PARAMETER STORE
# - MOUNTS EFS UPLOADS STORAGE
# - INJECTS RUNTIME CONFIGURATION INTO WORDPRESS
# - STARTS APACHE
###############################################################################

# EXIT ON ERRORS, UNDEFINED VARIABLES, AND FAILED PIPELINE COMMANDS.

set -euo pipefail

###############################################################################
# DEFINE LOCAL VARIABLES
###############################################################################

REGION="us-east-1"

WEB_ROOT="/var/www/html"
UPLOADS_DIR="/var/www/html/wp-content/uploads"
WP_CONFIG="/var/www/html/wp-config.php"

###############################################################################
# RETRIEVE WORDPRESS CONFIGURATION FROM PARAMETER STORE.
###############################################################################

DB_HOST=$(aws ssm get-parameter --name "/wordpress/db/host" --region "$REGION" --query "Parameter.Value" --output text)

DB_NAME=$(aws ssm get-parameter --name "/wordpress/db/name" --region "$REGION" --query "Parameter.Value" --output text)

DB_USER=$(aws ssm get-parameter --name "/wordpress/db/master_user" --region "$REGION" --query "Parameter.Value" --output text)

DB_PASSWORD=$(aws ssm get-parameter --name "/wordpress/db/master_password" --with-decryption --region "$REGION" --query "Parameter.Value" --output text)

DOMAIN_NAME=$(aws ssm get-parameter --name "/wordpress/prod/domain_name" --region "$REGION" --query "Parameter.Value" --output text)

EFS_ID=$(aws ssm get-parameter --name "/wordpress/efs/id" --region "$REGION" --query "Parameter.Value" --output text)

###############################################################################
# CREATE UPLOADS DIRECTORY IF IT DOES NOT EXIST.
###############################################################################

sudo mkdir -p "$UPLOADS_DIR"

###############################################################################
# MOUNT EFS TO WORDPRESS UPLOADS DIRECTORY.
###############################################################################

if ! mountpoint -q "$UPLOADS_DIR"; then
  sudo mount -t efs "$EFS_ID":/ "$UPLOADS_DIR"
fi

###############################################################################
# PERSIST EFS MOUNT ACROSS REBOOTS.
###############################################################################

if ! grep -q "$UPLOADS_DIR" /etc/fstab; then
  echo "$EFS_ID:/ $UPLOADS_DIR efs defaults,_netdev 0 0" | sudo tee -a /etc/fstab
fi

###############################################################################
# INJECT RUNTIME DATABASE AND DOMAIN VALUES INTO WORDPRESS.
###############################################################################

sudo sed -i "s|__DB_HOST__|$DB_HOST|g" "$WP_CONFIG"
sudo sed -i "s|__DB_NAME__|$DB_NAME|g" "$WP_CONFIG"
sudo sed -i "s|__DB_USER__|$DB_USER|g" "$WP_CONFIG"
sudo sed -i "s|__DB_PASSWORD__|$DB_PASSWORD|g" "$WP_CONFIG"
sudo sed -i "s|__DOMAIN_NAME__|$DOMAIN_NAME|g" "$WP_CONFIG"

###############################################################################
# SET OWNERSHIP AND RESTART APACHE.
###############################################################################

sudo chown -R apache:apache "$WEB_ROOT"

sudo systemctl enable httpd

sudo systemctl restart httpd