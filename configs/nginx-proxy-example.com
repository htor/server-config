server_tokens off;

server {
  listen [::]:80;
  listen 80;
  server_name www.example.com example.com;
  return 301 https://example.no$request_uri;
}

server {
  listen [::]:443 ssl http2;
  listen 443 ssl http2;
  ssl_certificate /etc/letsencrypt/live/www.example.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/www.example.com/privkey.pem;
  server_name www.example.com example.com;
  return 301 https://example.no$request_uri;
}

server {
  listen [::]:443 ssl http2;
  listen 443 ssl http2;
  ssl_certificate /etc/letsencrypt/live/www.example.no/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/www.example.no/privkey.pem;
  server_name www.example.no;
  return 301 https://example.no$request_uri;
}

server {
    listen [::]:443 ssl http2;
    listen 443 ssl http2;
    ssl_certificate /etc/letsencrypt/live/example.no/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.no/privkey.pem;
    server_name example.no;
    access_log /var/log/example-website/access.log;
    error_log /var/log/example-website/error.log;
    charset utf-8;
    add_header "X-UA-Compatible" "IE=Edge";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header X-XSS-Protection "1; mode=block";

    location /foo {
        alias /var/www/foo/dist;
    }

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
    }
}

