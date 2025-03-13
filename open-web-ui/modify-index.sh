#!/bin/bash

# This script modifies the index.html file to customize branding elements
# Set to exit on error
set -e

echo "Starting index.html modification script..."

# Find the index.html file (search in common locations)
INDEX_FILES=$(find /app -name "index.html" 2>/dev/null || find /usr/share/nginx/html -name "index.html" 2>/dev/null || find / -name "index.html" -not -path "*/node_modules/*" -not -path "*/\.*" 2>/dev/null | grep -v ".bak")

if [ -z "$INDEX_FILES" ]; then
  echo "Error: Could not find index.html file"
  exit 1
fi

for INDEX_FILE in $INDEX_FILES; do
  echo "Modifying $INDEX_FILE..."
  
  # Create a backup
  cp "$INDEX_FILE" "${INDEX_FILE}.bak"
  
  # Replace all instances of "Open WebUI" with "Lusochat"
  sed -i 's/Open WebUI/Lusochat/g' "$INDEX_FILE"
  
  # Replace all instances of "OpenWebUI" with "Lusochat"
  sed -i 's/OpenWebUI/Lusochat/g' "$INDEX_FILE"
  
  # Replace the title specifically
  sed -i 's/<title>Lusochat<\/title>/<title>Lusochat<\/title>/g' "$INDEX_FILE"
  
  # Replace meta description
  sed -i 's/content="Lusochat"/content="Lusochat"/g' "$INDEX_FILE"
  
  # Replace opensearch title
  sed -i 's/title="Lusochat"/title="Lusochat"/g' "$INDEX_FILE"
  
  # Replace any remaining instances of "open-webui" in URLs or paths
  sed -i 's/open-webui/lusochat/g' "$INDEX_FILE"
  
  echo "Successfully modified $INDEX_FILE"
done

# Also check for any JavaScript files that might contain branding
JS_FILES=$(find /app -name "*.js" 2>/dev/null | xargs grep -l "Open WebUI" 2>/dev/null || true)

if [ ! -z "$JS_FILES" ]; then
  echo "Found JavaScript files with branding references:"
  
  for JS_FILE in $JS_FILES; do
    echo "Modifying $JS_FILE..."
    
    # Create a backup
    cp "$JS_FILE" "${JS_FILE}.bak"
    
    # Replace all instances of "Open WebUI" with "Lusochat"
    sed -i 's/Open WebUI/Lusochat/g' "$JS_FILE"
    
    # Replace all instances of "OpenWebUI" with "Lusochat"
    sed -i 's/OpenWebUI/Lusochat/g' "$JS_FILE"
    
    echo "Successfully modified $JS_FILE"
  done
fi

echo "Modification complete!" 