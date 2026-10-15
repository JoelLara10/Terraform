#!/usr/bin/env python3
"""Diagnóstico desde la VM; no imprime tokens y no modifica datos."""
import argparse
import json
import os
import socket
import subprocess
import urllib.parse
import urllib.request
from datetime import datetime, timezone


def token(resource):
    query = urllib.parse.urlencode({'api-version': '2018-02-01', 'resource': resource})
    req = urllib.request.Request('http://169.254.169.254/metadata/identity/oauth2/token?' + query, headers={'Metadata': 'true'})
    # IMDS no debe pasar por un proxy HTTP.
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
    with opener.open(req, timeout=15) as res:
        return json.load(res)['access_token']


def private_dns(host, expected):
    ips = {a[4][0] for a in socket.getaddrinfo(host, None, socket.AF_INET)}
    if ips != {expected}:
        raise RuntimeError(f'DNS inesperado para {host}: {ips}; se esperaba {expected}')
    print(f'DNS OK {host} -> {expected}')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--postgres', required=True)
    ap.add_argument('--storage', required=True)
    args = ap.parse_args()
    private_dns(args.postgres, '10.0.2.4')
    blobhost = args.storage + '.blob.core.windows.net'
    private_dns(blobhost, '10.0.4.4')
    req = urllib.request.Request('https://' + blobhost + '/jobs?restype=container&comp=list', headers={
        'Authorization': 'Bearer ' + token('https://storage.azure.com/'),
        'x-ms-version': '2023-11-03',
        'x-ms-date': datetime.now(timezone.utc).strftime('%a, %d %b %Y %H:%M:%S GMT')})
    with urllib.request.urlopen(req, timeout=30) as res:
        print('Blob HTTPS con MI:', res.status)
    env = os.environ.copy()
    env.update(PGHOST=args.postgres, PGPORT='5432', PGUSER='ineo_worker', PGDATABASE='ineo',
               PGSSLMODE='verify-full', PGSSLROOTCERT='/etc/ssl/certs/ca-certificates.crt',
               PGPASSWORD=token('https://ossrdbms-aad.database.windows.net'))
    subprocess.run(['psql', '-v', 'ON_ERROR_STOP=1', '-c', 'SELECT current_user, count(*) FROM ineo.jobs;'], env=env, check=True)
    print('Pruebas completadas. No se modificaron jobs.')


if __name__ == '__main__':
    main()
