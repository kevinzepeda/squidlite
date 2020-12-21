#!/bin/bash
set -e

echo "Create log_dir"
mkdir -p /var/log/squid
chmod 777 -R /var/log/squid
chown squid:squid /var/log/squid

echo "Create cache_dir"
mkdir -p /var/spool/squid
chmod 777 -R /var/spool/squid
chown squid:squid /var/spool/squid

echo "Add program block_files"
cp /etc/block/* /var/spool/squid

echo "Add default config"
cp /etc/squid_default/squid.conf /etc/squid/squid.conf

# allow arguments to be passed to squid
if [[ ${1:0:1} = '-' ]]; then
  EXTRA_ARGS="$@"
  set --
elif [[ ${1} == squid || ${1} == $(which squid) ]]; then
  EXTRA_ARGS="${@:2}"
  set --
fi

# default behaviour is to launch squid
if [[ -z ${1} ]]; then
  if [[ ! -d ${SQUID_CACHE_DIR}/00 ]]; then
    echo "Generate Cert and Key"
    openssl req -newkey rsa:4096 -x509 -keyout /etc/squid/key.pem -out /etc/squid/cert.pem -nodes -subj "/C=MX"
    echo "Starting Cert DB"
    /usr/lib/squid/security_file_certgen -c -s /var/cache/squid/ssl_db -M 20MB
    echo "Initializing cache..."
    $(which squid) -N -f /etc/squid/squid.conf -z
  fi
  echo "Starting squid..."
  exec $(which squid) -f /etc/squid/squid.conf -NYCd 1 ${EXTRA_ARGS}
else
  exec "$@"
fi