FROM alpine:3.21

RUN apk add --no-cache mariadb mariadb-client && \
	rm /etc/my.cnf.d/mariadb-server.cnf

RUN mkdir -p /var/lib/mysql /run/mysqld && \
    chown -R mysql:mysql /var/lib/mysql /run/mysqld

COPY conf/50-server.cnf /etc/my.cnf.d/50-server.cnf
COPY tools/init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/init.sh"]
