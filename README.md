# CDH Dev Env

## Introduction

This Vagrantfile deploys and provisions a VM with Ubuntu Xenial, updates it,
configures MySQL and installs packages needed for using Python3 with [pipenv](https://github.com/pypa/pipenv). It is written with the CDH Database cohort in mind
but anyone is welcome to use it.

## Installation

To use this Vagrant file you will need up to date copies of [Vagrant](https://www.vagrantup.com/downloads.html) and some virtualizer. Oracle
[VirtualBox](https://www.virtualbox.org/wiki/Downloads). The latest versions of these
(at least Vagrant 2.0.2 and VirtualBox 5.2.6) are strongly recommended.

**Note: If you have trouble installing VirtualBox on MacOS High Sierra, after the
installation fails, go to System Preferences -> Security and Privacy -> General and allow
software written by Oracle to be installed.**


The easiest way to acquire this Vagrantfile and associated setup is to clone is using git.
If it is not already installed on your system, you should do so. On MacOS, you can do so by
installing XCode or get a more up to date version using [Homebrew](https://brew.sh/)
(`brew install git`) or even the [Github for Mac](https://desktop.github.com/) install
(the desktop tools have an option to install commmand line tools).

Once the prerequisite software is installed, clone this repository using:

`git clone https://github.com/Princeton-CDH/devenv.git`

Then from a terminal, change to the directory where you cloned the repository and run `vagrant up`
If I cloned the repo from my home directory `~` it would be something like:

```
cd ~/devenv
vagrant up
```

Vagrant should then download the trusty/xenial64 image, update and configure it, and then
finish. From there, the VM is active on your machine, and has its own virtual memory, OS, etc.

You can access it via SSH (secure shell) by typing `vagrant ssh` from the directory where
the Vagrantfile is located (i.e. from `~/devenv` above).

To turn off your VM, from the same directory run `vagrant halt`. To remove it completely
(warning: this **will** delete the virtual drive that holds your VM files), use `vagrant destroy`.


## Using your new VM

Whenever you SSH in by running `vagrant ssh`, you will be a user called `vagrant` accessing the VM just as if you had logged into your console on your physical host machine.
That user has passwordless super-user status, so you can do any command that requires
elevated privileges using `sudo` and also become root by typing `sudo su -`
(type `exit` to get back to a normal non-elevated command prompt.)

In your home directory you will find a folder called `data` that will sync to a data folder
on your host machine where you initially set up the VM. Doing your coding work there will
let you edit files from your native OS.

To access the MySQL server running on the VM, you can get root access simply by becoming root
or using sudo: `sudo mysql`. The configuration creates a configuration file that provides
the password to the root account. You can use that access to create new MySQL users for your
Django application.

Creating a Django project is as easy as setting up a pipenv in `~vagrant/data` on the VM via
`pipenv install django` (`pipenv install 'django<2'` for 1.11), and then loading that pipenv
using `pipenv shell` from the `data` dir. Then you can use `django-admin startproject myproj` to
begin a project. All of these changes to `data` should be mirrored to the `data` directory on
your host system.

## A note about running Django

When you run the development server for Django, you will need to add one extra instruction.
Django's usual `python manage.py runserver` will need to be run as follows to ensure that you
can access it at the usual `localhost:8000` from your web browser. Instead type:

`python manage.py runserver 0.0.0.0:8000`

You may also need to edit the `ALLOWED_HOSTS` setting in `data/myproj/myproj/settings.py` if
Django complains of connections not coming from an allowed host. Simply changing it to:
`ALLOWED_HOSTS = ["*"]` should do the trick. (Note: This would be a bad idea in production
as it allows connections to your IP with any declared HTTP header. Normally you'd limit to the
site name that you want to serve your app on!) You should be able to open up `settings.py` in
your text editor of choice on your host system from the shared `data` directory.


## Connecting VM Django Instance to your VM's MySQL server
Typically Django instances have their own user and database. The first step in this configuration
is making the database user and a database on which it has all access privileges (i.e., it can
create tables, drop them, add/edit/insert).

Your VM's MySQL is set up to be fully accessible as root (with the root system account mapping
to the root MySQL account). In Vagrant ssh session, just `sudo mysql`.

Then from the MySQL client issue a command like:

`CREATE USER 'myproj'@'localhost' IDENTIFIED BY 'secretpasswordhere';`

where 'myproj' is your project name and you use some sort of password in the `IDENTIFIED BY` clause.

After that command succeeds, you'll also need a database. A common convention is to name the
database using the same name as the user that will use it:

`CREATE DATABASE myproj CHARSET utf8mb4;`

This creates `myproj` and makes its default character set UTF-8 (which is a modern multipurpose text encoding).

Finally, grant the 'myproj' user access to the 'myproj' database:

`GRANT ALL ON myproj.* TO 'myproj'@'localhost';`

(If you're wondering about the localhost bit, you're saying that this user cannot use remote
connections, which are a security risk.)

Then in your Django `settings.py`, you'll want to remove the following stanza:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': os.path.join(BASE_DIR, 'db.sqlite3'),
    }
}
```

Replace it with:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'myproj',
        'USER': 'myproj',
        'PASSWORD': 'secretpasswordhere',
        'HOST': 'localhost',
        'OPTIONS': {
            'init_command': "SET sql_mode='STRICT_TRANS_TABLES'",
            'charset': 'utf8mb4',
        },
        'PORT': '',
    },

}
```
This looks hairy but it only does a few things: Uses the MySQL database backend for Django,
sets the username and password to login, points at localhost for the server location, and
requires MySQL to warn aggressively if data that would be truncated by a column is entered.

You'll also need to `pipenv install mysqlclient` from outside your virtualenvironment
but within Vagrant (i.e., `~` as `vagrant@xenial`)!

At this point, from within your pipenv created virtualenvironment (`pipenv shell`), you should
now be able to run `python manage.py migrate` to create database migrations.
