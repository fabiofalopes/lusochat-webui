# Open WebUI OIDC Authentication Guide

This document provides a focused guide to understanding and troubleshooting OIDC authentication within Open WebUI, specifically tailored for deployments integrating with an internal Identity Provider (IDP).

## 1. Authentication Flow Overview

The OIDC authentication process in Open WebUI follows these key steps:

1.  **User Initiates Login:** The user clicks the login button (or is redirected if unauthenticated).  The button's label will likely say "SSO" or the value of `OAUTH_PROVIDER_NAME`.

2.  **Redirection to IDP:** Open WebUI redirects the user's browser to your configured IDP's authorization endpoint. This URL is constructed using the `OPENID_PROVIDER_URL` (which should point to the `.well-known/openid-configuration` endpoint) and includes parameters like:
    *   `client_id`: Your application's `OAUTH_CLIENT_ID`.
    *   `redirect_uri`:  The callback URL where the IDP will send the response (e.g., `https://your-domain/oauth/LusofonaIDP/callback`).  **This MUST match exactly what's registered with your IDP.**
    *   `scope`:  The requested scopes (e.g., `openid email profile`).  Open WebUI requires at least `openid` and `email`.
    *   `response_type`: Usually `code` for the Authorization Code Flow.
    *   `state`: A randomly generated value used by Open WebUI to prevent CSRF attacks.

3.  **IDP Authentication:** The user authenticates with your IDP (e.g., enters credentials).

4.  **IDP Redirects Back:**  After successful authentication, the IDP redirects the user's browser back to the `redirect_uri` specified in step 2.  This redirect includes:
    *   `code`: An authorization code.
    *   `state`: The same `state` value sent in step 2.  Open WebUI verifies this.

5.  **Token Exchange (Backend):**  This is the **critical step** where your issue likely lies.  Open WebUI's *backend* (not the user's browser) makes a direct request to your IDP's token endpoint.  It sends:
    *   `grant_type`:  `authorization_code`.
    *   `code`: The authorization code received in step 4.
    *   `client_id`: Your `OAUTH_CLIENT_ID`.
    *   `client_secret`: Your `OAUTH_CLIENT_SECRET`.
    *   `redirect_uri`: The same `redirect_uri` used earlier.
    *  `OAUTH_TOKEN_ENDPOINT_AUTH_METHOD`: how to authenticate to the token endpoint, usually `client_secret_basic`

6.  **IDP Token Response:** The IDP responds (to the backend) with a JSON payload containing:
    *   `access_token`:  Used for accessing protected resources (not directly used by Open WebUI in this flow).
    *   `id_token`:  A JWT (JSON Web Token) containing user information (claims).  **This is what Open WebUI uses.**
    *   `expires_in`:  Token lifetime.
    *   `token_type`: Usually `Bearer`.
    *   `refresh_token` (optional): Used to obtain new tokens without re-authentication.

7.  **Token Validation and User Creation/Login (Backend):** Open WebUI's backend:
    *   Validates the `id_token` signature (using the IDP's public keys, obtained from the `jwks_uri` in the `.well-known/openid-configuration`).
    *   Verifies the `iss` (issuer), `aud` (audience), and `exp` (expiration) claims.
    *   Extracts the user's email from the `email` claim.
    *   Checks if a user with that email already exists.
        *   If `OAUTH_MERGE_ACCOUNTS_BY_EMAIL` is true, it logs in the existing user.
        *   If `ENABLE_OAUTH_SIGNUP` is true and the user doesn't exist, it creates a new user.
    *   Creates a session cookie for the user.

8.  **Redirection to Frontend:** The backend redirects the user's browser to the main Open WebUI interface. The user is now logged in.

## 2. Troubleshooting Checklist

Given your description, the problem is most likely in steps 5, 6, or 7. Here's how to investigate:

*   **Backend Logs:**  Enable `GLOBAL_LOG_LEVEL=DEBUG` in your `.env` file.  Restart Open WebUI and examine the Docker logs (`docker logs open-webui-lusofona -f`). Look for:
    *   Errors related to the token exchange (e.g., network errors, invalid client credentials, invalid grant).
    *   Errors related to token validation (e.g., invalid signature, missing claims).
    *   Any exceptions or stack traces.

*   **IDP Logs:** Check your IDP's logs to see if it received the token request from Open WebUI's backend and how it responded.  This will confirm whether the issue is on the Open WebUI side or the IDP side.

*   **Network Connectivity:** Ensure that your Open WebUI backend container can reach your IDP's token endpoint.  Network issues (firewalls, DNS problems) can prevent the token exchange.  You can test this from within the container:
    ```bash
    docker exec -it open-webui-lusofona sh
    # Inside the container:
    apk add curl  # Install curl (if not already present)
    curl -v <your_IDP_token_endpoint>
    ```

*   **`.env` Configuration:** Double-check *all* OIDC-related environment variables:
    *   `OPENID_PROVIDER_URL`:  Must point to the `.well-known/openid-configuration` endpoint.
    *   `OAUTH_CLIENT_ID`:  Must match the client ID registered with your IDP.
    *   `OAUTH_CLIENT_SECRET`: Must match the client secret.
    *   `OAUTH_SCOPES`:  Must include `openid` and `email`.
    *   `OPENID_REDIRECT_URI`: Must *exactly* match the registered redirect URI.  Include the correct protocol (HTTPS), domain, port, and path.
    * `OAUTH_TOKEN_ENDPOINT_AUTH_METHOD`: Must match what your IDP expects.

*   **IDP Configuration:**
    *   **Redirect URI:**  Ensure the redirect URI registered with your IDP is *exactly* correct.  Even a trailing slash difference can cause problems.
    *   **Client Authentication Method:** Verify that the client authentication method configured in your IDP matches `OAUTH_TOKEN_ENDPOINT_AUTH_METHOD`.
    *   **Allowed Scopes:**  Make sure your IDP is configured to release the `email` claim.  If you want to use `name` and `picture`, ensure those are released as well.
    *   **Token Endpoint URL:** Double-check the token endpoint URL provided by your IDP.

* **Inspect the ID Token (If You Can Get It):** If you can capture the `id_token` (e.g., from the IDP logs or by temporarily modifying Open WebUI code to log it), use a tool like [jwt.io](https://jwt.io/) to decode it.  Verify:
        *   The `iss` claim matches your IDP's issuer URL.
        *   The `aud` claim contains your `OAUTH_CLIENT_ID`.
        *   The `exp` claim is in the future.
        *   The `email` claim is present and contains the expected email address.

* **HTTPS and Cookies:**
    * Ensure that `WEBUI_SESSION_COOKIE_SECURE` and `WEBUI_AUTH_COOKIE_SECURE` are set to `true` since you're using HTTPS.
    * Ensure that `WEBUI_SESSION_COOKIE_SAME_SITE` and `WEBUI_AUTH_COOKIE_SAME_SITE` are appropriately set (lax is a reasonable default).

## 3. Key Files and Code Locations

*   **`.env`:**  Contains all the crucial OIDC configuration.
*   **`docker-compose.yaml`:** Defines the services, including environment variables.
*   **Backend Code:** The core authentication logic is within the Open WebUI backend. While you don't need to modify it, understanding the flow is helpful. The relevant files are likely in the `backend/app/auth` and `backend/app/oauth` directories (you can browse the GitHub repository to get a better sense).
* **`deploy-https.sh`**: Your deployment script.

## 4.  Debugging Tips

*   **Simplify:** Temporarily disable any custom themes or modifications to rule out interference.
*   **Start Small:** If possible, test with a simpler OIDC client (e.g., a publicly available OIDC test server) to isolate the problem.
*   **Use a Proxy:**  A tool like Charles Proxy or Burp Suite can intercept and inspect the HTTP requests between Open WebUI and your IDP, helping you pinpoint the exact point of failure.

## 5. Example .env Snippet (Corrected and Annotated)

```env
# --- OIDC Configuration ---
ENABLE_OAUTH_SIGNUP=true          # Allow new user registration via OIDC
OAUTH_MERGE_ACCOUNTS_BY_EMAIL=true # Merge with existing accounts if emails match
OAUTH_PROVIDER_NAME=LusofonaIDP   # Display name for the login button
OPENID_PROVIDER_URL=https://idp-dev.ulusofona.pt/.well-known/openid-configuration  # Correct URL to the discovery document
OAUTH_CLIENT_ID=your-oidc-client-id-here     # Your actual client ID
OAUTH_CLIENT_SECRET=your-oidc-client-secret-here # Your actual client secret
OAUTH_SCOPES=openid email profile  # Request these scopes

# --- Authentication Flow ---
OAUTH_RESPONSE_TYPE=code             # Use Authorization Code Flow
OAUTH_TOKEN_ENDPOINT_AUTH_METHOD=client_secret_basic  # How to authenticate to the token endpoint

# --- Cookie Security (Important for HTTPS) ---
WEBUI_SESSION_COOKIE_SAME_SITE=lax
WEBUI_AUTH_COOKIE_SAME_SITE=lax
WEBUI_SESSION_COOKIE_SECURE=true
WEBUI_AUTH_COOKIE_SECURE=true

# --- Redirect URI (CRITICAL) ---
OPENID_REDIRECT_URI=https://your-domain/oauth/LusofonaIDP/callback  # Replace with your ACTUAL domain and path
```

This guide should provide a solid foundation for understanding and troubleshooting your OIDC integration. Remember to replace placeholders with your actual values and consult your IDP's documentation for specific configuration details. Good luck! 