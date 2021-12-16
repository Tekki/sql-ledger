# Dockerfile for test environment
FROM httpd

RUN set -ex \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    libarchive-extract-perl \
    libarchive-zip-perl \
    libdbd-pg-perl \
    libexcel-writer-xlsx-perl \
    libio-socket-ssl-perl \
    libmojolicious-perl \
  && rm -rf /var/lib/apt/lists/*

RUN echo " <Directory /usr/local/apache2/htdocs/sql-ledger>\n"\
  "  AddHandler cgi-script .pl\n"\
  "  Options +ExecCGI\n"\
  "</Directory>"\
  >> /usr/local/apache2/conf/httpd.conf \
  && sed -i -e 's/#LoadModule cgi/LoadModule cgi/' /usr/local/apache2/conf/httpd.conf

WORKDIR /usr/local/apache2/htdocs/sql-ledger

COPY docker-httpd-foreground /usr/local/bin/httpd-foreground
