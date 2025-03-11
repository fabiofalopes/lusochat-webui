# Lusochat - Custom Open WebUI Deployment

This directory contains files for deploying a customized version of Open WebUI with Lusochat branding. Instead of manually replacing files after deployment, this solution uses a custom Docker build process to modify the necessary files during image creation.

## How It Works

1. **Custom Dockerfile (`Dockerfile.custom`)**: 
   - Extends the official Open WebUI image 
   - Applies our customization script to the index.html file

2. **Modification Script (`modify-index.sh`)**:
   - Automatically finds the index.html file in the container
   - Modifies it to replace "Open WebUI" with "Lusochat" branding
   - Preserves all functionality while updating only branding elements

3. **Custom Docker Compose (`docker-compose.custom.yaml`)**:
   - Uses our custom Dockerfile instead of the official image
   - Still mounts all other custom assets (logos, favicons, etc.)
   - Maintains all the original environment variables and volume mounts

4. **Deployment Script (`deploy-custom.sh`)**:
   - Simplifies the deployment process
   - Ensures the volume exists
   - Builds and runs the custom container

## Benefits of This Approach

- **Maintainable**: When new versions of Open WebUI are released, you can simply update the base image in the Dockerfile
- **Clean**: No need to maintain a full copy of index.html, only the specific changes
- **Reliable**: The script will automatically find and modify the index.html file regardless of its location in the container
- **Transparent**: The modification script clearly shows what changes are being made

## How to Deploy

Simply run:

```bash
./deploy-custom.sh
```

This will build the custom image and start the container. You can access the application at http://localhost:3000.

## How to Customize Further

If you need to make additional modifications to index.html or other files, simply edit the `modify-index.sh` script and add your changes.

## Reverting to Original Deployment

If you want to go back to using the original deployment method, simply use:

```bash
docker compose up -d
```

This will use the original docker-compose.yaml file with direct image references. 