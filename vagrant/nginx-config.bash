#!/bin/bash

set -euo pipefail

echo " 
stream{
  upstream kubernetes {
      server 192.168.77.10:6443;
      server 192.168.77.11:6443;
      server 192.168.77.12:6443;
  }
  server {
      listen 6443;
      proxy_pass kubernetes;
  }
}
" >> /etc/nginx/nginx.conf

systemctl enable nginx
systemctl restart nginx

