# Use Nginx as the base image
FROM nginx:alpine

# Copy your HTML files to the default Nginx public directory
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
