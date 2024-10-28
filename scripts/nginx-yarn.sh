MAIN_USER="team"

NGINX_YARN_AVAILABLE_CONF_PATH="/etc/nginx/sites-available/yarn"
NGINX_YARN_ENABLED_CONF_PATH="/etc/nginx/sites-enabled/yarn"
NGINX_HSERVER_AVAILABLE_CONF_PATH="/etc/nginx/sites-available/hserver"
NGINX_HSERVER_ENABLED_CONF_PATH="/etc/nginx/sites-enabled/hserver"

# Setup nginx

echo "Setting up nginx for yarn and historyserver"
read -p "Enter namenode host: " NAMENODE_HOST
read -sp "Enter password for sudo: " main_password

if [ -f "$NGINX_YARN_AVAILABLE_CONF_PATH" ]; then
  echo "File $NGINX_YARN_AVAILABLE_CONF_PATH already exists"
  exit 1
fi

if [ -f "$NGINX_HSERVER_AVAILABLE_CONF_PATH" ]; then
  echo "File $NGINX_HSERVER_AVAILABLE_CONF_PATH already exists"
  exit 1
fi

if [ ! $(whoami) eq "$MAIN_USER" ]; then
  echo "Wrong user to setup ngnix: $(whoami). Switch to $MAIN_USER"
  exit 1 
fi

# yarn
echo '$main_password' | sudo -S cp /etc/nginx/sites-available/default $NGINX_YARN_AVAILABLE_CONF_PATH
echo '$main_password' | sudo -S sed -i -e 's/80/8088/g' -e '/\[::\]/d' -e "0,/try_files/s/.*try_files.*/\t\tproxy_pass http:\/\/$NAMENODE_HOST:8088;/" $NGINX_YARN_AVAILABLE_CONF_PATH
echo '$main_password' | sudo -S ln -s $NGINX_YARN_AVAILABLE_CONF_PATH $NGINX_YARN_ENABLED_CONF_PATH

# history server
echo '$main_password' | sudo -S cp /etc/nginx/sites-available/default $NGINX_HSERVER_AVAILABLE_CONF_PATH
echo '$main_password' | sudo -S sed -i -e 's/80/19888/g' -e '/\[::\]/d' -e "0,/try_files/s/.*try_files.*/\t\tproxy_pass http:\/\/$NAMENODE_HOST:19888;/" $NGINX_HSERVER_AVAILABLE_CONF_PATH
echo '$main_password' | sudo -S ln -s $NGINX_HSERVER_AVAILABLE_CONF_PATH $NGINX_HSERVER_ENABLED_CONF_PATH

echo "Nginx setup is succesful, reload nginx with `sudo systemctl reload nginx`"

exit 0
