#!/bin/bash

# Deploy script for custom Open WebUI with Lusochat branding
set -e

echo "Building and deploying custom Open WebUI with Lusochat branding..."

# Ensure the volume exists
docker volume inspect open-webui >/dev/null 2>&1 || docker volume create open-webui

# Build and start the services
docker compose -f docker-compose.custom.yaml build --no-cache
docker compose -f docker-compose.custom.yaml up -d

echo "Deployment complete! Your customized Open WebUI is now running with Lusochat branding."
echo "You can access it at: http://localhost:3000" 