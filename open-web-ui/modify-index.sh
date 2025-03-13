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

  # Add disclaimer styles before the closing head tag
  sed -i '/<\/head>/i \
    <style>\
      .disclaimer-container {\
        position: fixed;\
        top: 20px;\
        left: 50%;\
        transform: translateX(-50%);\
        z-index: 1000;\
        width: 100%;\
        max-width: 450px;\
        text-align: center;\
      }\
      .disclaimer-box {\
        background-color: #f8fafc;\
        border: 1px solid #e2e8f0;\
        border-radius: 8px;\
        padding: 16px;\
        margin: 0 16px;\
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);\
      }\
      .warning {\
        color: #dc2626;\
        font-weight: 500;\
        margin: 0 0 8px 0;\
      }\
      .main-text {\
        color: #475569;\
        font-size: 14px;\
        margin: 0 0 8px 0;\
      }\
      .sub-text {\
        color: #64748b;\
        font-size: 13px;\
        margin: 0;\
      }\
      html.dark .disclaimer-box {\
        background-color: #1e293b;\
        border-color: #334155;\
      }\
      html.dark .warning {\
        color: #ef4444;\
      }\
      html.dark .main-text {\
        color: #e2e8f0;\
      }\
      html.dark .sub-text {\
        color: #94a3b8;\
      }\
    </style>' "$INDEX_FILE"

  # Add disclaimer HTML after body tag
  sed -i '/<body data-sveltekit-preload-data="hover">/a \
    <div id="lusochat-disclaimer" class="disclaimer-container">\
      <div class="disclaimer-box">\
        <p class="warning">⚠️ Lusochat encontra-se em fase de testes</p>\
        <p class="main-text">Para aceder utilize o login institucional da Universidade Lusófona.</p>\
        <p class="sub-text">Clique no botão de login com LusofonaIDP e introduza as suas credenciais habituais de email.</p>\
      </div>\
    </div>' "$INDEX_FILE"

  # Add fade effect script before closing body tag
  sed -i '/<\/body>/i \
    <script>\
      setTimeout(function() {\
        const disclaimer = document.getElementById("lusochat-disclaimer");\
        if (disclaimer) {\
          disclaimer.style.opacity = "0.7";\
        }\
      }, 5000);\
    </script>' "$INDEX_FILE"
  
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