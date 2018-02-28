# Getting Started with Django database models and Django admin

The following steps are intended to take you from having a custom
MySQL database schema to having a preliminary Django application
with a lightly customized admin interface that you can use to manage your
data.

The following conventions are used to indicate the context where you
should run a command:
    * `>` - shell on your local machine
    * `vagrant:>` - shell on your vagrant vm
    * `mysql>` - run in mysql shell (after running `sudo mysql` from the terminal)
    * `(pipenv) vagrant:>` - pipenv shell on your vagrant vm


## Prep

1. Make sure you have a mysqldump of your current database with any content.
  (You should already have one if you haven't made any schema changes or
  added any data.)

    `> mysqldump -u root -p dbname > yyyy-mmm-dd_dbname.sql`

2. Copy your sqldump into your shared data folder so it will be available
   to you within the virtual environment.  You can either use the finder
   to drap or copy into `devenv/data` or copy from the command line. The command
   below assumes that you have your SQL dump in the same folder as your devenv,
   e.g. HOME (`~`):

   `> cp yyyy-mmm-dd_dbname.sql devenv/data/`

3. Change your working directory into your check out of this project,
   where your virtual machine is.  From your home directory,

    `> cd devenv`

4. Start up your vagrant virtual machine:

    `> vagrant up`

5. Shell into the virtual machine:

    `> vagrant ssh`

## Development database setup

1. Create a database and user for the project database to use with Django.
   First enter the MySQL console:

   `vagrant:> sudo mysql`

   Then enter the SQL commands to create the user, database, and give
   the user permissions on the database.

    ```
    mysql> CREATE USER 'myproj'@'localhost' IDENTIFIED BY 'mypassword';
    mysql> CREATE DATABASE myproj CHARSET utf8mb4;
    mysql> GRANT ALL ON myproj.* TO 'myproj'@'localhost';
    ```

2. Load your mysqldump file into the database you just created.  This will
   create all of your tables and foreign key relationships, and load any
   data included in your export:

    `vagrant:> sudo mysql myproj < data/yyyy-mmm-dd_dbname.sql`

## Django project setup

1. Change directory into the shared data folder:

    `vagrant:> cd data`

2. Install Django and the Python MySQL client if you have not already done so:

    `vagrant:> pipenv install 'django<2' mysqlclient`

2. Activate your python environment:

    `vagrant:> pipenv shell`

4. Create a new django project.  Recommended: name the django project based
   on a short or abbreviated version of your research project name.
   Use lower case without spaces; if you must delimit words, use an underscore.

    `(pipenv) vagrant:>django-admin startproject myproj`

5. In the editor of your choice, edit the settings for your new django
    project at `data/myproj/myproj/settings.py`.

    Replace the default `DATABASES` configuration:

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

    For development, configure allowed hosts so you can access
    the development server from outside the virtual machine:

    ```python
    ALLOWED_HOSTS = ["*"]
    ```

6. Change directory into the newly created django project so that you
    can run django manage commands:

    `(pipenv) vagrant:> cd myproj`

7. Create a new django "app" that will contain your models and
    customizations.  Recommended: name the app based on a central entity
    from your database schema.  Use lower case without spaces;
    if you must delimit words, use an underscore.

    ```
    (pipenv) vagrant:> mkdir myproj/myentity
    (pipenv) vagrant:> python manage.py startapp myentity myproj/myentity
    ```

8. Generate django models from your existing database structure:

    `(pipenv) vagrant:> python manage.py inspectdb > myproj/myentity/models.py`

9. Run database migrations to create other database tables that django
    needs to run:

    `(pipenv) vagrant:> python manage.py migrate`

10. Create a user account for yourself so you'll be able to login
    to your new site.

    `(pipenv) vagrant:> python manage.py createsuperuser`

11. To check that everything is working properly, start your django
    development server and log in to your admin site.

    `(pipenv) vagrant:> python manage.py runserver 0.0.0.0:8000`

    You should be able to access and log into your admin site in a
    browser at http://localhost:8000/admin/

    To stop the runserver, use `ctrl-c` in the terminal where it is
    running.

## Django Admin

1. Add your newly created Django app to your project applications.
   Update `settings.py` and add it to the end of **INSTALLED_APPS**:

   ```python
    INSTALLED_APPS = [
        ...
        'myproj.myentity',
    ]
    ```


2. Register your models to make them available in Django admin.  Create
    a file named `admin.py` in your app directory (`devenv/data/myproj/myentity`)
    with contents like this:

    ```python
    from django.contrib import admin
    from myproject.myentity.models import MyModel

    class MyModelAdmin(admin.ModelAdmin):
        pass

    admin.site.register(MyModel, MyModelAdmin)
    ```

3. Start your django development server and log in to your admin site.

    `(pipenv) vagrant:> python manage.py runserver 0.0.0.0:8000`

    You should be able to access it in a browser at http://localhost:8000/admin/

4. Refine your admin configuration, customizing `list_display`,
    `search_fields`, etc.  Register and configure other models.

5. Turn on django debug logging so that you can see the SQL queries
    that django generates and run as you use the site.  Edit your
    project `settings.py` and add the following:

    ```python
    LOGGING = {
        'version': 1,
        'disable_existing_loggers': False,
        'handlers': {
            'console': {
                'class': 'logging.StreamHandler',
            },
        },
        'loggers': {
            'django.db': {
                'handlers': ['console'],
                'level': 'DEBUG',
            },
        },
    }```

    To turn this off later, you can switch `'DEBUG'` to `'INFO'`.


*Still to be done: customizing the auto-generated models, configuring
them to be managed by Django, etc.*


## End your work session

When you end your session, you should exit everything and shut down your
virtual machine.  Use `ctrl+c` to stop Django runserver if it is still
running.

    ```
    (pipenv) vagrant:> exit
    vagrant:> exit
    > vagrant halt
    ```
