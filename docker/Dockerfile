# Dockerfile for test environment
FROM httpd:trixie

RUN set -ex \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    cpanminus \
    gpg \
    gpg-agent \
    libarchive-extract-perl \
    libarchive-zip-perl \
    libdbd-mock-perl \
    libdbd-pg-perl \
    libexcel-writer-xlsx-perl \
    libhtml-form-perl \
    libio-socket-ssl-perl \
    libmojolicious-perl \
    libspreadsheet-parsexlsx-perl \
    libtext-qrcode-perl \
    libtemplate-perl \
    libtie-ixhash-perl \
    libyaml-pp-perl \
    postgresql-client \
    vim \
  && rm -rf /var/lib/apt/lists/*

RUN set -ex \
  && cpanm \
    Print::Colored \
  && rm -rf ~/.cpanm/*

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
