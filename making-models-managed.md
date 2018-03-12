## Making Models Managed

All of your models that you have created using `inspectdb` include a line
something like this in `yourmodule/models.py`:

```python
class Meta:
    managed = False
```

This tells Django not to create migrations for those models. Migrations are how
Django handles different database 'versions'. They function like a log to
recreate the current state of your databases structure. (NOT any data you may
have in your database. While migrations should be safe and not mangle data, they
do not back it up in any way. Regular SQL dumps will do that for you.)

Migrations provides several advantages, but the greatest is that they will let
you make changes to models (and especially `ForeignKey` relationships) using
Django's syntax.

## Clean up beforehand

You'll want to make sure that you've done a few things before creating your
managed models.

1. Make sure that you can add your models to the Django admin without issue
and you can run the Django application without errors.
2. This includes especially issues where Django complains of a clashing reverse
accessor.
3. Make sure that you have some useful `__str__` and admin customizations per
instructions [here](admin-customizations-str-methods.md). They can help you
spot problems.

## Making your models managed

Before you do anything in this section, you should make a backup dump of your
database, just in case.

From your Vagrant machine(i.e., after you type `vagrant up` and `vagrant ssh`):

(The `vagrant:$` is just a reminder that you should be at the prompt indicating
you are in the Vagrant VM. You don't need to type it.)

```shell
vagrant:$ sudo mysqldump mydb > ~/data/YYYY-MM-DD-mydb.sql  
```

(Where YYYY-MM-DD is today's date and the and mydb is your database name.)

This will dump the MySQL database and its structure as it exists currently to
the shared `data` folder that you can access from your host machine and from
the VM.

As a suggestion, back up your `models.py`!

Now go through your models and remove the line `managed = False` from the
`class Meta` of all your models. You can probably do this using the find and
replace feature of your text editor (just replace the exact phrase as a blank.)

Now from the Vagrant command prompt, issue the following command, substituting
your actual project names:

```shell
vagrant:$ cd ~
vagrant:$ pipenv shell
(pipenv-shell) vagrant:$ cd ~/data/myproject/
(pipenv-shell) vagrant:$ python manage.py makemigrations
```

This, assuming it works, will produce an `initial` migration in
`yourproject/yourmodule/migrations` that, if necessary, could recreate the
current structure of your database from scratch.

## Making changes

Let's use Person as an example again.

```python
class Person(models.Model):
    name = models.CharField(max_length=191)
    occupation = models.ForeignKey(Occupation, blank=True, null=True)
```

Now that it is managed, if you wanted to add an integer field for `age`, this
is straightforward in Django.

Just add a line as follows:

```python
class Person(models.Model):
    name = models.CharField(max_length=191)
    age = models.PositiveSmallIntegerField(blank=True, null=True)
    occupation = models.ForeignKey(Occupation, blank=True, null=True)
```

Then from as above from the pipenv shell, run `makemigrations`:

```shell
(pipenv-shell) vagrant:$ python manage.py makemigrations -n add_age_person
```

This will create a migration file named something like `0002_add_age_person.py`
that contains the record of this change to the database. If you apply it:

```shell
(pipenv-shell) vagrant:$ python manage.py migrate
```

Django will issue the necessary `ALTER TABLE` statements to create this field.
If you made it required, when you make the migration, Django will ask if you want
to set a default since previously existing `Person` records would not have it.

To learn a bit about the different field types Django offers, which map to
MySQL's column types, see [Model field reference](https://docs.djangoproject.com/en/2.0/ref/models/fields/).
