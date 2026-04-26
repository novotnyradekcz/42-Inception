FROM alpine:3.21

RUN apk add --no-cache nginx openssl

RUN mkdir -p /etc/nginx/ssl /var/www/html && \
    openssl req -x509 -nodes -newkey rsa:4096 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=rnovotny/CN=rnovotny.42.fr" \
        -days 365

COPY conf/nginx.conf /etc/nginx/nginx.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
