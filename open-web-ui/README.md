# Lusochat WebUI

A customized version of Open WebUI integrated with Lusofona's Identity Provider for authentication, featuring HTTPS support for secure communication.

## Features

- **Custom Branding**: Customized with Lusofona logos and styling
- **HTTPS Support**: Secure communication with SSL/TLS encryption
- **OIDC Authentication**: Integration with Lusofona's Identity Provider

## Deployment

For secure deployment with HTTPS:

```shell
./deploy-https.sh
```

The deployment script will:
1. Generate self-signed SSL certificates if they don't exist
2. Configure Nginx with HTTPS support
3. Start the application with secure cookie settings

## How It Works

### Customization Approach

1. **Custom Dockerfile**: 
   - Extends the official Open WebUI image 
   - Applies our customization script to the index.html file

2. **Modification Script (`modify-index.sh`)**:
   - Automatically finds and modifies branding elements
   - Replaces "Open WebUI" with "Lusochat" throughout the application
   - Preserves all functionality while updating only branding elements

3. **Docker Compose Configuration**:
   - Uses our custom Dockerfile
   - Mounts custom assets (logos, favicons, etc.)
   - Configures HTTPS with Nginx as a reverse proxy

## Authentication Setup

### Overview
The application uses Lusofona's Identity Provider (IDP) for authentication. The development environment (`idp-dev.ulusofona.pt`) is already configured in the `.env` file.

### Current Status
- ✅ IDP Development environment is configured
- ✅ All required OIDC settings are defined
- ✅ HTTPS support for secure authentication
- ✅ Secure cookie settings enabled
- ✅ Need client credentials (ID and Secret) from IDP

### Required Configuration
The following settings are already configured in the `.env` file:

```yaml
# OIDC Base Configuration (Already Set)
ENABLE_OAUTH_SIGNUP=true
OAUTH_MERGE_ACCOUNTS_BY_EMAIL=true
OAUTH_PROVIDER_NAME=LusofonaIDP
OPENID_PROVIDER_URL=https://idp-dev.ulusofona.pt/.well-known/openid-configuration
OAUTH_SCOPES=openid email profile
OAUTH_RESPONSE_TYPE=code
OAUTH_TOKEN_ENDPOINT_AUTH_METHOD=client_secret_basic

# Security Settings
WEBUI_SESSION_COOKIE_SAME_SITE=lax
WEBUI_AUTH_COOKIE_SAME_SITE=lax
WEBUI_SESSION_COOKIE_SECURE=true
WEBUI_AUTH_COOKIE_SECURE=true

# Credentials (Need to be provided)
OAUTH_CLIENT_ID=YOUR_OIDC_CLIENT_ID
OAUTH_CLIENT_SECRET=YOUR_OIDC_CLIENT_SECRET
```

### Application Details for IDP
When requesting credentials, provide these details to the IDP:
- Application Name: Lusochat WebUI
- Environment: Development/Production
- Redirect URI: `https://your-domain/oauth/oidc/callback`
  - For local testing: `https://<ip>:<port>/oauth/oidc/callback`
  - Nginx: 
   - `https://192.168.x.x:443/oauth/oidc/callback` ???
   - `https://localhost/oauth/LusofonaIDP/callback` ???
- Required Scopes: `openid email profile`
- Grant Type: Authorization Code Flow
- Token Endpoint Auth Method: `client_secret_basic`

### Next Steps
1. Request client credentials from the IDP
2. Update `.env` file with provided credentials
3. Deploy with HTTPS using `./deploy-https.sh`
4. Test the authentication flow

## Troubleshooting

If you encounter issues with the OIDC authentication:

1. **Check the logs**:
   ```bash
   docker logs open-webui-lusofona
   ```

2. **Verify your IDP configuration**:
   - Make sure the redirect URI is correctly registered with your IDP
   - Confirm that your IDP is configured to release the email attribute
   - Check that the scopes are correctly configured

3. **Browser issues**:
   - Clear your browser cookies and cache
   - Try using incognito/private browsing mode

4. **Certificate issues**:
   - For production, use a trusted certificate from Let's Encrypt
   - For development, you may need to accept the self-signed certificate in your browser

## Maintenance

### Updating the Application

When new versions of Open WebUI are released:

1. Update the base image in `Dockerfile`:
   ```dockerfile
   FROM ghcr.io/open-webui/open-webui:latest
   ```

2. Rebuild and restart:
   ```bash
   ./deploy-https.sh
   ```

### Customizing Further

If you need to make additional modifications:

1. Edit the `modify-index.sh` script to add your changes
2. Rebuild the container using `./deploy-https.sh`
