FROM ghcr.io/open-webui/open-webui:latest

# Copy our modification script
COPY modify-index.sh /tmp/

# Make it executable just in case
RUN chmod +x /tmp/modify-index.sh

# Run the script to modify index.html
RUN /tmp/modify-index.sh

# Remove the script after execution
RUN rm /tmp/modify-index.sh

# The rest is inherited from the base image 