# Update the OS
apt-get update && apt-get upgrade -y

if [ ! -f /etc/init.d/mysql* ]; then

  echo "Preparing to install MySQL..."
  export DEBIAN_FRONTEND="noninteractive"
  password=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c6`
  debconf-set-selections <<< "mysql-server mysql-server/root_password password "
  debconf-set-selections <<< "mysql-server mysql-server/root_password_again password "

  # add the password to root user
  echo "
  [client]
  user=root
  password=$password" > /root/.my.cnf
  chmod 600 /root/.my.cnf


  # install mysql-server and common files
  echo "Installing MySQL..."
  apt-get install -y mysql-server mysql-common

  # Mime the functionality of mysql_secure_installation
  # except root password, because we already randomized it.
  # https://gist.github.com/Mins/4602864 for other solutions and @jportoles
  # for this one.
  echo "Configuring MySQL installation..."
  mysql -u root <<-EOF
  DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
  DELETE FROM mysql.user WHERE User='';
  DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';
  FLUSH PRIVILEGES;
EOF

else
  echo "MySQL installed, skipping installation"
fi

# Install other utilities, including python3 and pipenv
apt-get install -y python3-pip tree nano vim
pip3 install --upgrade pipenv
