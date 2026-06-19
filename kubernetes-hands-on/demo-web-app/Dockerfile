FROM nginx:alpine

COPY index.html /usr/share/nginx/html/index.html
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]


# docker buildx build --platform linux/amd64,linux/arm64 -t iaminnocent/demo-web-app:v1.0.1 --push .