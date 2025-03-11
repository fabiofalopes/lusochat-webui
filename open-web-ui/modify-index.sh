#!/bin/bash

# This script modifies the index.html file to customize branding elements
# Set to exit on error
set -e

echo "Starting index.html modification script..."

# Find the index.html file (search in common locations)
INDEX_FILES=$(find /app -name "index.html" 2>/dev/null || find /usr/share/nginx/html -name "index.html" 2>/dev/null || find / -name "index.html" -not -path "*/node_modules/*" -not -path "*/\.*" 2>/dev/null | head -n 1)

if [ -z "$INDEX_FILES" ]; then
  echo "Error: Could not find index.html file"
  exit 1
fi

for INDEX_FILE in $INDEX_FILES; do
  echo "Modifying $INDEX_FILE..."
  
  # Create a backup
  cp "$INDEX_FILE" "${INDEX_FILE}.bak"
  
  # Replace the title
  sed -i 's/<title>Open WebUI<\/title>/<title>Lusochat<\/title>/g' "$INDEX_FILE"
  
  # Replace meta description
  sed -i 's/content="Open WebUI"/content="Lusochat"/g' "$INDEX_FILE"
  
  # Replace opensearch title
  sed -i 's/title="Open WebUI"/title="Lusochat"/g' "$INDEX_FILE"
  
  # Replace favicon paths if needed
  # sed -i 's|/static/favicon.png|/static/lusochat-favicon.png|g' "$INDEX_FILE"
  
  # Add any other required replacements here
  
  echo "Successfully modified $INDEX_FILE"
done

echo "Modification complete!" 