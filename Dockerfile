FROM centos:7
USER 0

RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && \
 yum install -y \
 nginx gettext nmap-ncat wget \
 openssh-clients \
 iputils \
 bind-utils \
 tar \
 less \
 rsync \
 iftop \
 fio \
 sysbench \
 ioping \
 iperf3 \
 stress-ng \
 && yum clean all

RUN mkdir -p /app/web/mnt /usr/share/nginx/perl/lib \
 && chgrp -R 0 /app/web/ /var/log/nginx /var/lib/nginx && chmod -R g=u /app/web/ \
 && chmod g=u /etc/passwd \
 && chmod -R 775 /var/log/nginx /etc/nginx/conf.d /var/lib/nginx /run /app/web/ \
 && ln -sf /dev/stdout /var/log/nginx/access.log \
 && ln -sf /dev/stderr /var/log/nginx/error.log


COPY docker/run.sh /run.sh
COPY docker/perftest.sh /perftest.sh
COPY docker/perftest1.pm /usr/share/nginx/perl/lib
COPY docker/perftest2.pm /usr/share/nginx/perl/lib
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY app/web/ /app/web/

RUN chmod 755 /run.sh /perftest.sh

USER 1001
EXPOSE 8080
ENTRYPOINT ["/run.sh"]
