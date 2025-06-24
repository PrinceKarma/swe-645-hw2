FROM nginx:alpine

# Copy the HTML files to the Nginx web root directory
COPY webapp/ /usr/share/nginx/html

# Expose port 80 to allow traffic to the web server
EXPOSE 80