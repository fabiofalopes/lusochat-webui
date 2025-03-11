# Setup Custom Open Web UI Docker 
- Carrega os logos da empresa;
- Setup [Web Search](https://docs.openwebui.com/tutorial/web_search/)

```shell
docker compose -f docker-compose.yaml -f docker-compose.searxng.yaml up -d
```

# Lusochat WebUI

A customized version of Open WebUI integrated with Lusofona's Identity Provider for authentication.

## Quick Start

1. Start the application with web search capability:
```shell
docker compose -f docker-compose.yaml -f docker-compose.searxng.yaml up -d
```

## Authentication Setup

### Overview
The application uses Lusofona's Identity Provider (IDP) for authentication. The development environment (`idp-dev.ulusofona.pt`) is already configured in the `.env` file.

### Current Status
- ✅ IDP Development environment is configured
- ✅ All required OIDC settings are defined
- ❌ Need client credentials (ID and Secret) from IDP team

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

# Credentials (Need to be provided)
OAUTH_CLIENT_ID=YOUR_OIDC_CLIENT_ID
OAUTH_CLIENT_SECRET=YOUR_OIDC_CLIENT_SECRET
```

### Application Details for IDP Team
When requesting credentials, provide these details to the IDP team:
- Application Name: Lusochat WebUI
- Environment: Development
- Redirect URI: `http://localhost:3000/api/auth/callback/openid`
    - `http://192.168.108.80:3000/api/auth/callback/openid`
- Required Scopes: `openid email profile`
- Grant Type: Authorization Code Flow
- Token Endpoint Auth Method: `client_secret_basic`

### Next Steps
1. Request client credentials from the IDP team
2. Update `.env` file with provided credentials
3. Test the authentication flow


.well-known