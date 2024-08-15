# Dockerfile for test environment
FROM httpd:bookworm

RUN set -ex \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    gpg \
    gpg-agent \
    libarchive-extract-perl \
    libarchive-zip-perl \
    libdbd-pg-perl \
    libexcel-writer-xlsx-perl \
    libio-socket-ssl-perl \
    libmojolicious-perl \
    libspreadsheet-parsexlsx-perl \
    postgresql-client \
  && rm -rf /var/lib/apt/lists/*

RUN echo " <Directory /usr/local/apache2/htdocs/sql-ledger>\n"\
  "  AddHandler cgi-script .pl\n"\
  "  Options +ExecCGI\n"\
  "</Directory>"\
  >> /usr/local/apache2/conf/httpd.conf \
  && sed -i -e 's/#LoadModule cgi/LoadModule cgi/' /usr/local/apache2/conf/httpd.conf

RUN set -ex \
    && mkdir -p /usr/local/apache2/gnupg \
    && chown -R www-data:www-data /usr/local/apache2/gnupg \
    && chmod 0700 /usr/local/apache2/gnupg

WORKDIR /usr/local/apache2/htdocs/sql-ledger

COPY docker-httpd-foreground /usr/local/bin/httpd-foreground
