# Setup Custom Open Web UI Docker 
- Carrega os logos da empresa;
- Setup [Web Search](https://docs.openwebui.com/tutorial/web_search/)

```shell
docker compose -f docker-compose.yaml -f docker-compose.searxng.yaml up -d
```

# Lusochat WebUI

## Lusofona Identity Provider Integration

### Overview
The application integrates with Lusofona's Identity Provider (IDP) for user authentication and authorization. This integration allows users to log in using their Lusofona credentials.

### Required Information for IDP Team
When setting up the integration, the following details need to be provided to/configured with the Lusofona IDP team:

1. **Application Details**
   - Application Name: Lusochat WebUI
   - Environment: Development/Production
   - Redirect URI: `http://localhost:3000/api/auth/callback/openid`
   - Application Type: Web Application

2. **Required Scopes**
   - openid
   - email
   - profile

3. **Authentication Settings**
   - Grant Type: Authorization Code Flow
   - Token Endpoint Auth Method: client_secret_basic
   - Response Type: code

### Integration Checklist
- [ ] Provide application details to IDP team
- [ ] Receive Client ID and Client Secret
- [ ] Update docker-compose.yaml with provided credentials
- [ ] Test authentication flow in development environment
- [ ] Verify user information retrieval
- [ ] Confirm email-based account linking functionality

### Configuration
The OIDC configuration is managed through environment variables in `docker-compose.yaml`. After receiving the credentials from the IDP team:

1. Update the following variables:
   ```yaml
   - OAUTH_CLIENT_ID=<provided_client_id>
   - OAUTH_CLIENT_SECRET=<provided_client_secret>
   ```

2. Verify the following settings match IDP requirements:
   ```yaml
   - OAUTH_SCOPES=openid email profile
   - OAUTH_RESPONSE_TYPE=code
   - OAUTH_TOKEN_ENDPOINT_AUTH_METHOD=client_secret_basic
   ```

### Testing the Integration
1. Start the application with updated credentials
2. Navigate to the login page
3. Click on "Login with LusofonaIDP"
4. Verify successful authentication
5. Confirm user information is correctly retrieved

### Support
For integration support, contact:
- Lusofona IDP Team: [Contact Information]
- Application Development Team: [Contact Information]

```
https://idp-dev.ulusofona.pt/idp/profile/oidc/configuration
```