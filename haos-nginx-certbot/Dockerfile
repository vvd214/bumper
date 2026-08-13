FROM jonasal/nginx-certbot:latest

LABEL org.opencontainers.image.source=https://github.com/vvd214/bumper
LABEL org.opencontainers.image.description="Nginx Certbot HAOS add-on"
LABEL org.opencontainers.image.licenses=GPLv3

COPY haos-nginx-certbot/run.sh /run.sh
RUN chmod a+x /run.sh

ENTRYPOINT ["/run.sh"]
