# Getting Started with Django database models and Django admin

The following steps are intended to take you from having a custom
MySQL database schema to having a preliminary Django application
with a lightly customized admin interface that you can use to manage your
data.

1. Make sure you have a mysqldump of your current database with any content.
  (You should already have one if you haven't made any schema changes or
  added any data.)

    `mysqldump -u root -p dbname > yyyy-mmm-dd_dbname.sql`

2. Copy your sqldump into your shared data folder so it will be available
   to you within the virtual environment.  You can either use the finder
   to drap or copy into `devenv/data` or copy from the command line. The command
   below assumes that you have your SQL dump in the same folder as your devenv,
   e.g. HOME (`~`):

   `cp yyyy-mmm-dd_dbname.sql devenv/data/`

3. Change your working directory into your check out of this project,
   where your virtual machine is.  From your home directory,

    `cd devenv`

4. Start up your vagrant virtual machine:

    `vagrant up`

5. Shell into the virtual machine:

    `vagrant ssh`

6. Create a database and user for the project database to use with Django.
   First enter the MySQL console:

   `sudo mysql`

   Then enter the SQL commands to create the user, database, and give
   the user permissions on the database.

    ```
    CREATE USER 'myproj'@'localhost' IDENTIFIED BY 'mypassword';
    CREATE DATABASE myproj CHARSET UTF8;
    GRANT ALL ON myproj.* TO 'myproj'@'localhost';
    ```

7. Load your mysqldump file into the database you just created.  This will
   create all of your tables and foreign key relationships, and load any
   data included in your export:

    `sudo mysql myproj < data/yyyy-mmm-dd_dbname.sql`

8. Activate your python environment:

    `pipenv shell`

9. Change directory into the shared data folder:

    `cd data`

10. Install Django and the Python MySQL client if you have not already done so:

    `pipenv install 'django<2' mysqlclient`

11. Create a new django project.  Recommended: name the django project based
   on a short or abbreviated version of your research project name.
   Use lower case without spaces; if you must delimit words, use an underscore.

    `django-admin startproject myproj`

12. In the editor of your choice, edit the settings for your new django
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

13. Change directory into the newly created django project so that you
    can run django manage commands:

    `cd myproj`

14. Create a new django "app" that will contain your models and
    customizations.  Recommended: name the app based on a central entity
    from your database schema.  Use lower case without spaces;
    if you must delimit words, use an underscore.

    ```
    mkdir myproj/myentity
    python manage.py startapp myentity myproj/myentity
    ```

15. Generate django models from your existing database structure:

    `python manage.py inspectdb > myproj/myentity/models.py`

16. Run database migrations to create other database tables that django
    needs to run:

    `python manage.py migrate`

17. Create a user account for yourself so you'll be able to login
    to your new site.

    `python manage.py createuser`

18. Register your models to make them available in Django admin.  Create
    a file named `admin.py` in your app directory (`devenv/data/myproj/myentity`)
    with contents like this:

    ```python
    from django.contrib import admin
    from myproject.myentity.models import MyModel

    class MyModelAdmin(admin.ModelAdmin):
        pass

    admin.site.register(MyModel, MyModelAdmin)
    ```

19. Start your django development server and log in to your admin site.

    `python manage.py runserver 0.0.0.0:8000`

    You should be able to access it in a browser at http://localhost:8000/admin/

20. Refine your admin configuration, customizing `list_display`,
    `search_fields`, etc.  Register and configure other models.

21. Turn on django debug logging so that you can see the SQL queries
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



When you end your session, you should `exit` your pipenv shell, `exit` your
shell session on your virtual machine, and then use `vagrant halt` to
shutdown the VM.
