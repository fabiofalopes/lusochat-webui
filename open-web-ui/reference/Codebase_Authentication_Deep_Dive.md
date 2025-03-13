# Open WebUI Codebase: Authentication Deep Dive (OIDC Focus)

This document provides a detailed examination of the Open WebUI authentication system, with a particular focus on OIDC implementation. The document references actual files and code patterns based on the repository structure.

## 1. Authentication File Structure

Open WebUI's authentication system is distributed across several key directories and files within both the backend and frontend codebases.

### Backend Authentication Files

The backend is built with FastAPI and contains the core authentication logic:

* **Authentication Utilities**: [`backend/open_webui/utils/auth.py`](https://github.com/open-webui/open-webui/blob/main/backend/open_webui/utils/auth.py)
  * Contains functions for user authentication, token validation, and session management
  * Likely implements password hashing and verification

* **OAuth Implementation**: [`backend/open_webui/utils/oauth.py`](https://github.com/open-webui/open-webui/blob/main/backend/open_webui/utils/oauth.py)
  * Implements OIDC and OAuth flows
  * Contains functions for token exchange and validation
  * Handles user creation/validation based on OAuth claims

* **Authentication Routers**: [`backend/open_webui/routers/auths.py`](https://github.com/open-webui/open-webui/blob/main/backend/open_webui/routers/auths.py)
  * Defines API endpoints for login, logout, registration
  * Implements OAuth callback endpoints
  * Manages session cookies and tokens

* **Authentication Models**: [`backend/open_webui/models/auths.py`](https://github.com/open-webui/open-webui/blob/main/backend/open_webui/models/auths.py)
  * Defines authentication-related data structures
  * Could include token models, request/response schemas, etc.

* **User Models**: [`backend/open_webui/models/users.py`](https://github.com/open-webui/open-webui/blob/main/backend/open_webui/models/users.py)
  * Defines user data models 
  * Includes fields populated from OIDC claims (email, name, etc.)
  * Contains methods for user creation and retrieval

* **Access Control**: [`backend/open_webui/utils/access_control.py`](https://github.com/open-webui/open-webui/blob/main/backend/open_webui/utils/access_control.py)
  * Implements role-based access control
  * Contains functions for permission checks

### Frontend Authentication Files

The frontend is built with SvelteKit and handles the user interface for authentication:

* **Authentication API Client**: [`src/lib/apis/auths/index.ts`](https://github.com/open-webui/open-webui/blob/main/src/lib/apis/auths/index.ts)
  * Implements API calls to the backend authentication endpoints
  * Handles login, logout, and registration requests
  * Likely manages OAuth redirect flows from the frontend

* **Authentication Page**: [`src/routes/auth/+page.svelte`](https://github.com/open-webui/open-webui/blob/main/src/routes/auth/+page.svelte)
  * Implements the login and registration UI
  * Contains forms for username/password authentication
  * Includes OAuth provider buttons (including OIDC)

* **Authentication State Management**: [`src/lib/stores/index.ts`](https://github.com/open-webui/open-webui/blob/main/src/lib/stores/index.ts)
  * Contains Svelte stores for authentication state
  * Manages user session information
  * Tracks login status across the application

* **Protected Route Logic**: [`src/routes/(app)/+layout.svelte`](https://github.com/open-webui/open-webui/blob/main/src/routes/(app)/+layout.svelte)
  * Likely contains logic to protect routes requiring authentication
  * Redirects unauthenticated users to the login page

## 2. OIDC Authentication Flow

Based on the codebase structure, here's how the OIDC flow is implemented:

### 2.1 Backend Configuration Loading

The application reads configuration from environment variables, defined in files like:

* [`backend/open_webui/config.py`](https://github.com/open-webui/open-webui/blob/main/backend/open_webui/config.py) - Loads all configuration variables

Relevant OIDC configuration parameters include:
```python
# Likely content pattern in config.py
OAUTH_CLIENT_ID = os.getenv("OAUTH_CLIENT_ID", "")
OAUTH_CLIENT_SECRET = os.getenv("OAUTH_CLIENT_SECRET", "")
OPENID_PROVIDER_URL = os.getenv("OPENID_PROVIDER_URL", "")
OAUTH_SCOPES = os.getenv("OAUTH_SCOPES", "openid email profile")
ENABLE_OAUTH_SIGNUP = os.getenv("ENABLE_OAUTH_SIGNUP", "false").lower() == "true"
OAUTH_MERGE_ACCOUNTS_BY_EMAIL = os.getenv("OAUTH_MERGE_ACCOUNTS_BY_EMAIL", "false").lower() == "true"
# etc.
```

### 2.2 Login Endpoint Implementation

The OIDC login flow begins in the authentication router:

* [`backend/open_webui/routers/auths.py`](https://github.com/open-webui/open-webui/blob/main/backend/open_webui/routers/auths.py)

Typical implementation pattern:
```python
# Example pattern (not exact code)
@router.get("/login/oidc")
async def login_oidc(request: Request):
    # Generate state parameter for CSRF protection
    state = secrets.token_urlsafe(16)
    request.session["oauth_state"] = state
    
    # Construct authorization URL
    auth_url = construct_oauth_authorization_url(
        provider_url=OPENID_PROVIDER_URL,
        client_id=OAUTH_CLIENT_ID,
        redirect_uri=f"{request.base_url}oauth/oidc/callback",
        scope=OAUTH_SCOPES,
        state=state,
        response_type="code"
    )
    
    # Redirect to Identity Provider
    return RedirectResponse(auth_url)
```

### 2.3 OAuth Callback Implementation

After authentication with the IDP, the user is redirected to the callback endpoint:

* [`backend/open_webui/routers/auths.py`](https://github.com/open-webui/open-webui/blob/main/backend/open_webui/routers/auths.py) - Contains the callback endpoint
* [`backend/open_webui/utils/oauth.py`](https://github.com/open-webui/open-webui/blob/main/backend/open_webui/utils/oauth.py) - Contains helper functions for token exchange

Typical implementation pattern:
```python
# Example pattern (not exact code)
@router.get("/oauth/oidc/callback")
async def oauth_callback(request: Request, code: str, state: str):
    # Verify state to prevent CSRF
    stored_state = request.session.pop("oauth_state", None)
    if not stored_state or stored_state != state:
        raise HTTPException(status_code=400, detail="Invalid state parameter")
    
    # Exchange authorization code for tokens
    tokens = await exchange_code_for_tokens(
        token_endpoint=get_token_endpoint(OPENID_PROVIDER_URL),
        code=code,
        client_id=OAUTH_CLIENT_ID,
        client_secret=OAUTH_CLIENT_SECRET,
        redirect_uri=f"{request.base_url}oauth/oidc/callback",
    )
    
    # Validate ID token and extract user information
    id_token = tokens.get("id_token")
    user_info = validate_and_decode_id_token(id_token, OPENID_PROVIDER_URL)
    
    # Get or create user based on email
    email = user_info.get("email")
    user = await get_or_create_user(email, user_info)
    
    # Create session for the user
    request.session["user_id"] = str(user.id)
    
    # Redirect to the main application
    return RedirectResponse(url="/")
```

### 2.4 Token Validation and User Creation

The OAuth utility module handles token validation and user management:

* [`backend/open_webui/utils/oauth.py`](https://github.com/open-webui/open-webui/blob/main/backend/open_webui/utils/oauth.py) - Token validation
* [`backend/open_webui/models/users.py`](https://github.com/open-webui/open-webui/blob/main/backend/open_webui/models/users.py) - User data models

Typical implementation pattern:
```python
# Example pattern (not exact code)
async def validate_and_decode_id_token(id_token, provider_url):
    # Get JWKS from the provider
    jwks_uri = get_jwks_uri(provider_url)
    jwks_client = get_jwks_client(jwks_uri)
    
    # Decode and validate the token
    decoded_token = jwt.decode(
        id_token,
        jwks_client,
        algorithms=["RS256"],
        audience=OAUTH_CLIENT_ID,
        # Additional validation parameters
    )
    
    return decoded_token

async def get_or_create_user(email, user_info):
    # Check if user exists
    user = await User.get_by_email(email)
    
    if user:
        # Update existing user if needed
        if OAUTH_MERGE_ACCOUNTS_BY_EMAIL:
            user = await update_user_from_oauth(user, user_info)
            return user
    elif ENABLE_OAUTH_SIGNUP:
        # Create new user
        user = await User.create(
            email=email,
            name=user_info.get("name", email),
            picture=user_info.get("picture"),
            oauth_provider="oidc",
            oauth_sub=user_info.get("sub"),
        )
        return user
    else:
        # Signup not allowed
        raise HTTPException(status_code=403, detail="Signup not allowed")
```

## 3. Frontend Authentication Implementation

### 3.1 Login Page

The login UI is implemented in:

* [`src/routes/auth/+page.svelte`](https://github.com/open-webui/open-webui/blob/main/src/routes/auth/+page.svelte)

Typical pattern for the OIDC button:
```svelte
<!-- Example pattern (not exact code) -->
<script>
  import { t } from '$lib/i18n';
  
  // Component logic
</script>

<div class="login-container">
  <!-- Other login methods -->
  
  <!-- OIDC login button -->
  {#if showOIDCButton}
    <a href="/api/auth/login/oidc" class="oidc-button">
      {t('login.signInWith', { provider: oauthProviderName })}
    </a>
  {/if}
</div>
```

### 3.2 Authentication API Client

The frontend API client for authentication:

* [`src/lib/apis/auths/index.ts`](https://github.com/open-webui/open-webui/blob/main/src/lib/apis/auths/index.ts)

Typical implementation pattern:
```typescript
// Example pattern (not exact code)
export async function login(username: string, password: string) {
  const response = await fetch('/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username, password }),
  });
  return handleResponse(response);
}

export async function logout() {
  const response = await fetch('/api/auth/logout', { method: 'POST' });
  return handleResponse(response);
}

export async function getUser() {
  const response = await fetch('/api/auth/me');
  return handleResponse(response);
}
```

### 3.3 Session Management

User session state is managed in store files:

* [`src/lib/stores/index.ts`](https://github.com/open-webui/open-webui/blob/main/src/lib/stores/index.ts)

Typical implementation pattern:
```typescript
// Example pattern (not exact code)
import { writable } from 'svelte/store';

// User authentication store
export const user = writable(null);
export const isAuthenticated = writable(false);

// Initialize authentication state
export async function initAuth() {
  try {
    const userData = await getUser();
    user.set(userData);
    isAuthenticated.set(true);
  } catch (error) {
    user.set(null);
    isAuthenticated.set(false);
  }
}
```

## 4. Authentication Protection for Routes

### 4.1 Backend API Protection

API endpoints are protected with a dependency:

* [`backend/open_webui/utils/auth.py`](https://github.com/open-webui/open-webui/blob/main/backend/open_webui/utils/auth.py)

Typical implementation pattern:
```python
# Example pattern (not exact code)
async def get_current_user(request: Request) -> User:
    user_id = request.session.get("user_id")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated"
        )
    
    user = await User.get(id=user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    
    return user
```

This dependency is used in protected routes:
```python
# Example pattern (not exact code)
@router.get("/api/protected-resource")
async def get_protected_resource(current_user: User = Depends(get_current_user)):
    # Only authenticated users reach this point
    return {"message": "This is protected", "user": current_user.email}
```

### 4.2 Frontend Route Protection

Protected routes in the frontend:

* [`src/routes/(app)/+layout.svelte`](https://github.com/open-webui/open-webui/blob/main/src/routes/(app)/+layout.svelte) - App layout that requires authentication

Typical implementation pattern:
```svelte
<!-- Example pattern (not exact code) -->
<script>
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { isAuthenticated, initAuth } from '$lib/stores';
  
  onMount(async () => {
    await initAuth();
    
    // Redirect to login if not authenticated
    if (!$isAuthenticated) {
      goto('/auth');
    }
  });
</script>

{#if $isAuthenticated}
  <slot />
{:else}
  <!-- Loading indicator -->
{/if}
```

## 5. Key Configuration Parameters

The following environment variables control OIDC configuration:

```env
# --- OIDC Core Configuration ---
ENABLE_OAUTH_SIGNUP=true          # Allow new user registration via OIDC
OAUTH_MERGE_ACCOUNTS_BY_EMAIL=true # Merge with existing accounts if emails match
OAUTH_PROVIDER_NAME=MyIDP         # Display name for the login button
OPENID_PROVIDER_URL=https://my-idp.example.com/.well-known/openid-configuration 
OAUTH_CLIENT_ID=client-id-here     
OAUTH_CLIENT_SECRET=client-secret-here 
OAUTH_SCOPES=openid email profile  # Request these scopes

# --- Authentication Flow ---
OAUTH_RESPONSE_TYPE=code             # Use Authorization Code Flow
OAUTH_TOKEN_ENDPOINT_AUTH_METHOD=client_secret_basic  # Authentication method

# --- Cookie Security ---
WEBUI_SESSION_COOKIE_SAME_SITE=lax
WEBUI_AUTH_COOKIE_SAME_SITE=lax
WEBUI_SESSION_COOKIE_SECURE=true
WEBUI_AUTH_COOKIE_SECURE=true

# --- Redirect URI ---
OPENID_REDIRECT_URI=https://my-openwebui.example.com/oauth/oidc/callback
```

## 6. Libraries and Dependencies

Based on the repository structure, Open WebUI likely uses these libraries for OIDC:

* **Backend**:
  * **FastAPI** - Web framework 
  * **PyJWT** - For JWT validation and handling
  * **httpx** or **aiohttp** - For asynchronous HTTP requests to the IDP
  * **SQLAlchemy** or similar - For database operations
  * **python-multipart** - For form handling

* **Frontend**:
  * **SvelteKit** - Frontend framework
  * **fetch API** - For HTTP requests
  * **svelte/store** - For state management

## 7. Debugging Authentication Issues

When troubleshooting OIDC authentication issues:

1. **Enable Debug Logging**:
   * Set `GLOBAL_LOG_LEVEL=DEBUG` in your `.env` file
   * Check the logs with `docker logs open-webui-container -f`
   * Look for OAuth-related log messages

2. **Examine Network Requests**:
   * Use browser developer tools to inspect:
     * The redirect to the IDP
     * The callback request
     * Any token exchange requests

3. **Check for Common Issues**:
   * **Redirect URI Mismatch**: Most common issue - ensure exact match
   * **Invalid Client Credentials**: Check ID and secret
   * **Network Connectivity**: Ensure backend can reach the IDP
   * **Cookie Settings**: Check if secure cookies are causing issues in non-HTTPS environments

4. **Test OAuth Endpoints Directly**:
   * Test authorization endpoint with a direct browser request
   * Test token endpoint with a tool like Postman or curl

This deep dive provides concrete references to the authentication implementation in Open WebUI. For the most accurate and up-to-date information, examining the actual code in these files is recommended. 