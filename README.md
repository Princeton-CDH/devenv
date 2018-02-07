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

Once the prerequisite software is installed, clone this repository using:

`Git clone command goes here`

Then from a terminal, change to the directory where you cloned the repository and run `vagrant up`
If I installed it in my home directory `~` it would be something like:

```
cd ~/devenv
vagrant up
```

Vagrant should then download the trust/xenial64 image, update and configure it, and then
finish. From there, the VM is active on your machine, and has its own virtual memory, OS, etc.

You can access it via SSH (secure shell) by typing `vagrant ssh` from the directory where
the Vagrantfile is located (i.e. from `~/devenv` above).

## Using your new VM

You will be a user called `vagrant` accessing the VM just as if you had logged into your
console on your physical host machine. That use has passwordless super-user status, so you
can do any command that requires elevated privileges using `sudo` and also become root by
typing `sudo su -` (type `exit` to get back to a normal non-elevated command prompt.)

In your home directory you will find a folder called `data` that will sync to a data folder
on your host machine where you initially set up the VM. Doing your coding work there will
let you edit files from your native OS.

To access the MySQL server running on the VM, you can get root access simply by becoming root
or using sudo: `sudo mysql`. The configuration creates a configuration file that provides
the password to the root account. You can use that access to create new MySQL users for your
Django application.

Creating a Django project is as easy as setting up a pipenv in `~vagrant/data` on the VM via
`pipenv install django` (`pipenv install 'django<2'` for 1.11), and then loading that pipenv
using `pipenv shell` from the `data` dir. Then you can use `django-admin startproject` to
begin a project. All of these changes to data should be mirrored to the data directory on
your host system.
