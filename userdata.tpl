#!/bin/bash

#Run update & setup passenger,nginx
yum update -y
curl --fail -sSLo /etc/yum.repos.d/passenger.repo https://oss-binaries.phusionpassenger.com/yum/definitions/el-passenger.repo
yum install -y nginx passenger || sudo yum-config-manager --enable cr
sed -i 's/#passenger/passenger/g' /etc/nginx/conf.d/passenger.conf
systemctl restart nginx

#Install bundler to fulfill app dependencies
gem install bundler

#Install git to clone code repo
yum install git -y

#Prepare root directory. Permissions & bundle install performed as non-root user for better security.
mkdir -p /var/www/sinatra
chown pravin: /var/www/sinatra
sudo -u pravin -H sh -c "cd /var/www/sinatra && git clone https://github.com/iproperty/simple-sinatra-app.git code"
sudo -u pravin -H sh -c "mkdir /var/www/sinatra/code/public"
sudo -u pravin -H sh -c "cd /var/www/sinatra/code && cp config.ru helloworld.rb public/"
sudo -u pravin -H sh -c "cd /var/www/sinatra/code && /usr/local/bin/bundle install"

#Write nginx config file. Grab the assigned public ip and configure Nginx with it.
PUBIP=`curl http://169.254.169.254/latest/meta-data/public-ipv4`

cat <<EOT >> /etc/nginx/conf.d/sinatra.conf
server {
    listen 80;
    server_name $PUBIP;

    location / {
      root /var/www/sinatra/code/public;
    }

    # Turn on Passenger
    passenger_enabled on;
    passenger_ruby /usr/bin/ruby;
}
EOT

#Restart nginx
systemctl restart nginx
