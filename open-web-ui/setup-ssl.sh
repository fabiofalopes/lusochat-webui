#!/bin/bash

# Description: Script to setup SSL certificates for Lusochat WebUI
# Usage: ./setup-ssl.sh [dev|prod] [domain]

MODE=$1
DOMAIN=${2:-localhost}

setup_dev_cert() {
    echo "Setting up self-signed certificate for development..."
    
    # Generate self-signed certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ssl/privkey.pem \
        -out ssl/fullchain.pem \
        -subj "/CN=localhost" \
        -addext "subjectAltName=DNS:localhost,IP:127.0.0.1"

    # Create symbolic links
    mkdir -p ssl/live/lusochat
    ln -sf ../../privkey.pem ssl/live/lusochat/privkey.pem
    ln -sf ../../fullchain.pem ssl/live/lusochat/fullchain.pem
    
    echo "Development certificates created successfully!"
}

setup_prod_cert() {
    if [ -z "$DOMAIN" ]; then
        echo "Error: Domain name is required for production setup"
        echo "Usage: ./setup-ssl.sh prod your.domain.com"
        exit 1
    fi

    echo "Setting up Let's Encrypt certificate for $DOMAIN..."
    
    # Check if certbot is installed
    if ! command -v certbot &> /dev/null; then
        echo "Certbot not found. Installing..."
        sudo apt-get update
        sudo apt-get install -y certbot
    fi

    # Stop nginx if running to free up port 80
    docker compose -f docker-compose.yaml down nginx

    # Get the certificate
    sudo certbot certonly --standalone \
        -d "$DOMAIN" \
        --agree-tos \
        --non-interactive \
        --preferred-challenges http

    echo "Production certificates obtained successfully!"
}

case "$MODE" in
    "dev")
        setup_dev_cert
        ;;
    "prod")
        setup_prod_cert
        ;;
    *)
        echo "Usage: ./setup-ssl.sh [dev|prod] [domain]"
        echo "Examples:"
        echo "  Development: ./setup-ssl.sh dev"
        echo "  Production:  ./setup-ssl.sh prod your.domain.com"
        exit 1
        ;;
esac

echo "
Next steps:
1. Start the services:
   docker compose -f docker-compose.yaml up -d

2. Access the WebUI:
   Development: https://localhost
   Production:  https://$DOMAIN
" 