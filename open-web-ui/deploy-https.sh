#!/bin/bash

# Deploy script for Lusochat WebUI with HTTPS and OIDC authentication
set -e

echo "Deploying Lusochat WebUI with HTTPS and OIDC authentication..."

# Check if SSL certificates exist
if [ ! -f "ssl/fullchain.pem" ] || [ ! -f "ssl/privkey.pem" ]; then
    echo "SSL certificates not found. Generating self-signed certificates..."
    ./setup-ssl.sh dev
fi

# Ensure the volume exists
docker volume inspect open-webui >/dev/null 2>&1 || docker volume create open-webui

# Ensure the network exists
docker network inspect ulht-web-ui_default >/dev/null 2>&1 || docker network create ulht-web-ui_default

# Stop any running containers
docker compose -f docker-compose.yaml down

# Build and start the services
echo "Building custom Docker image with Lusochat branding..."
docker compose -f docker-compose.yaml build --no-cache

echo "Starting services..."
docker compose -f docker-compose.yaml up -d

echo "Deployment complete! Your Lusochat WebUI is now running with HTTPS and OIDC authentication."
echo "You can access it at: https://localhost"
echo ""
echo "Important OIDC Information for IDP Team:"
echo "----------------------------------------"
echo "Application Name: Lusochat WebUI"
echo "Redirect URI: https://localhost/oauth/LusofonaIDP/callback"
echo "Required Scopes: openid email profile"
echo "Grant Type: Authorization Code Flow"
echo "Token Endpoint Auth Method: client_secret_basic"
echo ""
echo "If you're using a different domain, replace 'localhost' with your domain name." 