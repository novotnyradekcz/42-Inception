FROM alpine:3.21

RUN apk add --no-cache \
    php83 \
    php83-fpm \
    php83-phar \
    php83-mysqli \
    php83-pdo \
    php83-pdo_mysql \
    php83-curl \
    php83-dom \
    php83-exif \
    php83-fileinfo \
    php83-gd \
    php83-iconv \
    php83-intl \
    php83-mbstring \
    php83-opcache \
    php83-openssl \
    php83-session \
    php83-simplexml \
    php83-sodium \
    php83-tokenizer \
    php83-xml \
    php83-xmlreader \
    php83-xmlwriter \
    php83-zip \
    curl \
    netcat-openbsd

# Make 'php' resolve to php83 so wp-cli works
RUN ln -sf /usr/bin/php83 /usr/local/bin/php

# Download wp-cli
RUN curl -fsSL -o /usr/local/bin/wp-cli.phar \
        https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x /usr/local/bin/wp-cli.phar

# Create a thin 'wp' wrapper
RUN printf '#!/bin/sh\nexec php83 /usr/local/bin/wp-cli.phar "$@"\n' \
        > /usr/local/bin/wp && \
    chmod +x /usr/local/bin/wp

RUN mkdir -p /var/www/html && chown -R nobody:nobody /var/www/html

COPY conf/www.conf /etc/php83/php-fpm.d/www.conf
COPY tools/wp-install.sh /usr/local/bin/wp-install.sh
RUN chmod +x /usr/local/bin/wp-install.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/wp-install.sh"]
