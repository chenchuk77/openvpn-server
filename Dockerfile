FROM ubuntu:22.04
LABEL maintainer="admin@howtoforge.com"
LABEL version="0.1"
#ARG DEBIAN_FRONTEND=noninteractive
RUN apt update
RUN apt-get -y install \
    openvpn easy-rsa net-tools curl ufw

ENV KEY_COUNTRY="US"
ENV KEY_PROVINCE="CA"
ENV KEY_CITY="SanFrancisco"
ENV KEY_ORG="Fort-Funston"
ENV KEY_EMAIL="me@myhost.mydomain"
ENV KEY_OU="MyOrganizationalUnit"

# override this with public ip
ENV PUBLIC_IP="X.X.X.X"

ENV VPNDEVICE="eth0"

WORKDIR /app

RUN apt-get -y install net-tools vim python3-pip
RUN pip3 install Flask
RUN mkdir -p /app/webserver

#ENV nginx_vhost /etc/nginx/sites-available/default
#ENV php_conf /etc/php/8.1/fpm/php.ini
#ENV nginx_conf /etc/nginx/nginx.conf
COPY entrypoint.sh /app/entrypoint.sh
COPY webserver.py /app/webserver/webserver.py
COPY server.conf /etc/openvpn/server/server.conf
COPY client.conf /root/client-configs/base.conf
#RUN sed -i -e 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g' ${php_conf} && echo "\ndaemon off;" >> ${nginx_conf}
# Volume configuration
#VOLUME ["/etc/nginx/sites-enabled", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx", "/var/www/html"]
#COPY start.sh /start.sh


CMD ["/bin/sleep", "1000h"]
CMD ["./entrypoint.sh"]

# 1194/udp for inbound connection from openvpn client
# 8888 webserver to download openvpn client config
EXPOSE 1194 8888
