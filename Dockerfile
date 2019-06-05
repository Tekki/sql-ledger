# Dockerfile for test environment
FROM httpd

RUN set -ex \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    libdbd-pg-perl \
  && rm -rf /var/lib/apt/lists/*

RUN echo " <Directory /usr/local/apache2/htdocs/sql-ledger>\n"\
  "  AddHandler cgi-script .pl\n"\
  "  Options +ExecCGI\n"\
  "</Directory>"\
  >> /usr/local/apache2/conf/httpd.conf \
  && sed -i -e 's/#LoadModule cgi/LoadModule cgi/' /usr/local/apache2/conf/httpd.conf

WORKDIR /usr/local/apache2/htdocs/sql-ledger

COPY doc/docker-httpd-foreground /usr/local/bin/httpd-foreground
