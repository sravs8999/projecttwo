#!/bin/bash
curl -sL https://rpm.nodesource.com/setup_12.x | sudo -E bash - ## Installing node repo
yum update -y
yum install git nodejs -y
amazon-linux-extras install nginx1 -y
###Cloning the GIT REPO
mkdir -p /home/ec2-user/sample-website
git clone https://github.com/Challa-shekhar/sample-website-1.git /home/ec2-user/sample-website
#cd /home/ec2-user/sample-website
npm install --prefix /home/ec2-user/sample-website
npm install pm2 -g
env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u ec2-user --hp /home/ec2-user
#pm2 start /home/ec2-user/sample-website/server.js
nohup node /home/ec2-user/sample-website/server.js &
###################
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bkp
cat <<"EOF" > /etc/nginx/nginx.conf
# For more information on configuration, see:
#   * Official English Documentation: http://nginx.org/en/docs/
#   * Official Russian Documentation: http://nginx.org/ru/docs/

user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    include             /etc/nginx/sites-enabled/*.conf;
    default_type        application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;

    server {
        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  _;
        root         /usr/share/nginx/html;

        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;

        location / {
        }

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }
    server {
        listen 80;
        listen [::]:80;

        #root /var/www/example.com/html;
        #index index.html index.htm index.nginx-debian.html;

        server_name tekleaders-training.net  www.tekleaders-training.net;

        location / {
		proxy_pass http://localhost:3000;
        	proxy_http_version 1.1;
        	proxy_set_header Upgrade $http_upgrade;
        	proxy_set_header Connection 'upgrade';
        	proxy_set_header Host $host;
        	proxy_cache_bypass $http_upgrade;
        }
    }
}
EOF
nginx -t
systemctl start nginx