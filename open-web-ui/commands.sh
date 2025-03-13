#!/bin/bash
# Useful commands for managing Lusochat WebUI

# Deploy with HTTPS
echo "Run ./deploy-https.sh to deploy with HTTPS"

# View logs
echo "Run docker logs open-webui-lusofona -f to view logs"

# Restart the application
echo "Run docker compose -f docker-compose.yaml down && docker compose -f docker-compose.yaml up -d to restart"
