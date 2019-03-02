#!/bin/bash

create_cert() {
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt;
    openssl dhparam -out /etc/nginx/dhparam.pem 4096;
}

create_config_files() {
    touch /etc/nginx/snippets/self-signed.conf
    echo 'ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;' >> /etc/nginx/snippets/self-signed.conf;
    echo 'ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;' >> /etc/nginx/snippets/self-signed.conf;
    
    touch /etc/nginx/snippets/ssl-params.conf;
    echo 'ssl_protocols TLSv1.2;' >> /etc/nginx/snippets/ssl-params.conf;
    echo 'ssl_prefer_server_ciphers on;' >> /etc/nginx/snippets/ssl-params.conf;
    echo 'ssl_dhparam /etc/nginx/dhparam.pem;' >> /etc/nginx/snippets/ssl-params.conf;
    echo 'ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;' >> /etc/nginx/snippets/ssl-params.conf;
    echo 'ssl_ecdh_curve secp384r1; # Requires nginx >= 1.1.0' >> /etc/nginx/snippets/ssl-params.conf;
    echo 'ssl_session_timeout  10m;' >> /etc/nginx/snippets/ssl-params.conf;
    echo 'ssl_session_cache shared:SSL:10m;' >> /etc/nginx/snippets/ssl-params.conf;
    echo 'ssl_session_tickets off; # Requires nginx >= 1.5.9' >> /etc/nginx/snippets/ssl-params.conf;
    echo 'ssl_stapling on; # Requires nginx >= 1.3.7' >> /etc/nginx/snippets/ssl-params.conf;
    echo 'ssl_stapling_verify on; # Requires nginx => 1.3.7' >> /etc/nginx/snippets/ssl-params.conf;
    echo 'resolver 8.8.8.8 8.8.4.4 valid=300s;' >> /etc/nginx/snippets/ssl-params.conf;
    echo 'resolver_timeout 5s;' >> /etc/nginx/snippets/ssl-params.conf;
    echo 'add_header X-Frame-Options DENY;' >> /etc/nginx/snippets/ssl-params.conf;
    echo 'add_header X-Content-Type-Options nosniff;' >> /etc/nginx/snippets/ssl-params.conf;
    echo 'add_header X-XSS-Protection "1; mode=block";' >> /etc/nginx/snippets/ssl-params.conf;
}

create_nginx_virtual_host_file() {
    read -p 'Enter the name of the application being deployed: ' app_name;
    read -p 'Enter the path to the application: ' app_path;
    read -p 'Enter the server name(s) or FQDN (space separated): ' server_name;
    tabs 4;
    touch /etc/nginx/sites-available/${app_name};
    echo 'server {' >> /etc/nginx/sites-available/${app_name};
    echo -e "\tserver_name ${server_name};" >> /etc/nginx/sites-available/${app_name};
    echo '' >> /etc/nginx/sites-available/${app_name};
    echo -e '\tlocation / {' >> /etc/nginx/sites-available/${app_name};
    echo -e '\t\tinclude proxy_params;' >> /etc/nginx/sites-available/${app_name};
    echo -e "\t\tproxy_pass http://unix:${app_path}/${app_name}.sock;" >> /etc/nginx/sites-available/${app_name};
    echo -e '\t}' >> /etc/nginx/sites-available/${app_name};
    echo '' >> /etc/nginx/sites-available/${app_name};
    echo -e '\tlisten 443 ssl;' >> /etc/nginx/sites-available/${app_name};
    echo -e '\tlisten [::]:443 ssl;' >> /etc/nginx/sites-available/${app_name};
    echo -e '\tinclude snippets/self-signed.conf;' >> /etc/nginx/sites-available/${app_name};
    echo -e '\tinclude snippets/ssl-params.conf;' >> /etc/nginx/sites-available/${app_name};
    echo '}' >> /etc/nginx/sites-available/${app_name};
    echo '' >> /etc/nginx/sites-available/${app_name};
    echo 'server {' >> /etc/nginx/sites-available/${app_name};
    echo -e "\tserver_name ${server_name}" >> /etc/nginx/sites-available/${app_name};
    echo -e '\tlisten 80;' >> /etc/nginx/sites-available/${app_name};
    echo -e '\tlisten [::]:80;' >> /etc/nginx/sites-available/${app_name};
    echo -e '\treturn 302 https://$host$request_uri;' >> /etc/nginx/sites-available/${app_name};
    echo '}' >> /etc/nginx/sites-available/${app_name};
    ln -s /etc/nginx/sites-available/${app_name} /etc/nginx/sites-enabled;
}

restart_nginx() {
    systemctl restart nginx;
}


create_cert
create_config_files
create_nginx_virtual_host_file
restart_nginx
