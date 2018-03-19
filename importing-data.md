# Importing data into Django

## First, backing up and dropping databases

In working on importing data from a CSV you are going to hit snags, and probably
manage to import junk data a few times. That's OK and normal, provided that
you make frequent backups of your Django database.

Backing up data from the Vagrant box you're working in follows the same steps
as before:

```shell
vagrant:$ sudo mysqldump mydb > ~/data/YYYY-MM-DD-mydb.sql  
```

(Where YYYY-MM-DD is today's date and the and mydb is your database name.)

This will dump the MySQL database and its structure as it exists currently to
the shared `data` folder that you can access from your host machine and from
the VM.

This dump will now include the tables Django uses to manage its own features
(like users accounts in the `auth` tables), as well as the tables that back
your managed models.

These dumps also pull the data with them, which means you can use them to make
quick recoveries. Here's how you will do that, **when the time comes**.

To that end, you'll need to engage in a two step process:

1) Drop the previous database *once you have it backed up to an SQL dump*. The DROP
command is not to be taken lightly, but it is a tool to be used. In your Vagrant VM
as root (you can do this handily by just typing `sudo mysql`), issue the following
two commands in the MySQL console.

```sql
DROP DATABASE mydb;
CREATE DATABASE mydb CHARSET utf8mb4;
```

(where `mydb` is the name of your Django database)

Then from the Vagrant command line issue the following command

```shell
vagrant:$ sudo mysql mydb < ~/data/YYYY-MM-DD-mydb.sql
```
(where `YYY-MM-DD` is replaced by the name you used for your db backup)

This should fully restore your database to the state it was in before any changes
you may have made subsequently. The syntax we've seen before and pipes the
contents of `YYYY-MM-DD-mydb.sql` to the `mysql` client, with one parameter
(the name of the database that the dumps statements should apply to)

## Importing data -- first steps

First, take a look at [this linked Gist](https://gist.github.com/bwhicks/137268ca8e7ea39ae5ee40fff7c0e8ce).
It is a long read, but there are many comments to try to guide you through it.
This script, with modification, can be put in your Django app (the module named
folder), to import data into a model (and its associated MySQL table) via Django's
command functionality. Basically, this is your own custom `python manage.py` command.

As an example, to create the file to house the import command code, issue the following
statements from the VM:

```shell
vagrant:$ mkdir -p ~/data/projectfolder/myproject/myapp/management/commands
```

Adjust as needed to land this in the 'module' portion of your Django project,
with `management` being a folder at the same level as `models.py`.

Then create a file named `import_mymodel.py` in `management/commands` and copy
the contents of the Gist above.

## Editing the script

The script needs significant edits to make it work. It is hard to give a play
by play because your models are all different, but these are the general steps
(with some likely 'gotchas' explained):

1) Decide what model you're importing

For this first import script, you should pick a model that it relatively simple
(i.e. no foreign keys) and prepare a CSV with headers ('name', 'location', etc.)
in the first row. The script assumes that's what you have.

Once you know that model, edit the script to do the following:
  * Change the import script to import your model, using the syntax:
  ```python
  from myproject.mymodule.models import MyModel
  ```
  (N.B. Delete the second model unless you absolute must import a ForeignKey
  relationship.)

  * Look at the `map_csv` method the `Command` class. This is called in the main
    portion of the script and is the part you'll have to do the most tweaking to
    get right.

    1. Since you're just importing a single model, you should delete the rows that
    have `address` on them in the example. Instead, just edit the following lines:

      ```python
      person = Person()
      ```

      Change this to the model you just imported. This creates an instance of
      whatever model you just chose. It has all the fields and properties you
      specified in `models.py`.

      The code reads each row of the CSV into `row` and you can access each
      column by its name.
    2. Change the lines that assign columns to properties on the model:

        ```python
        person.last_name = row['last_name']
        person.first_name = row['first_name']
        ```

        Properties in Python are set using dot notation. So, change `.last_name`
        to the property you intend to set (i.e. `full_name`). Then edit the string
        in brackets on row to match the column in your CSV that provides that info.

        (In Python, we're reading the value of each CSV row into a dictionary,
        which uses a 'key' (`[last_name]`) to look up a 'value' within it.)

        Then edit the `save` statement to use the instance you just edited in.

    3. Run the import and see if your Python was accurate.

      Assuming you created a file named something like this:

      ```shell
      ~/data/myproject/mydjangoproject/mymodule/management/commands/import_mymodel.py
      ```

      Django's `manage.py` now knows about a command called `import_mymodel`
      that takes the following syntax (which is set up in the `handle` method
      of the python file):

      ```shell
      python manage.py import_mymodel ~/data/name_of_csv.csv
      ```

      It takes one argument, which is the path to your CSV. If the import runs
      correctly, the command will run without comment and then if you load up
      the admin site, your model will now be populated with rows taken from the
      CSV you imported.


## A more complicated import: A Model with a Foreign Key

If all your models were separate tables with no links, this would be done and
over, just recycle as necessary. Unfortunately, you are going to be dealing
with linked models. MySQL expresses this as a table with a link by foreign key
from one row to another. Django expresses this as a ForeignKey field from one
object to another (that it then reflects as a foreign key in SQL).

One way to do this is to set up your CSV with two models that are linked on the
same row. For this exercise, I'm going to use person and address as in the sample
[Gist](https://gist.github.com/bwhicks/137268ca8e7ea39ae5ee40fff7c0e8ce).

1) Setting up the CSV

The first step is a CSV with an eye towards how to handle the data in a useful way. Let's assume models that look something like this:


```python

class Address(models.Model):
    street_address = models.TextField()
    zip_code = models.CharField(max_length=50)


class Person(models.Model):
    last_name = models.CharField(max_length=255)
    first_name = models.CharField(max_length=255)
    address = models.ForeignKey(Address)
```     

You might set up a CSV that looks something like:

```csv
last_name,first_name,street_address,zip_code
Doe,Jane,'123 Wilfred',99999
Doe,John,'123 Wilfred',99999
Person,Other,'456 Elsewhwere',123456
```

This duplicates data, of course. A third normalized form database scheme would
do just as the models above do and pull out address to its own table. But it
works well for data entry.

To import this, you need to do a few things:

  1. Split the data that goes into the model with the ForeignKey field and set those fields.
  2. Create a model instance of the foreign key object
  and then set its fields. You also need to **save it**. This lets you use it
  to create relationships. An `Address` instance needs to exist in the database
  before
  you can set it on the `Person` model.

  We use a special method that Django has on the manager for each object in
  the database to do that for `Address` called `get_or_create`. This looks for
  an item that matches the parameters given and return it if it already exists
  in the database, or it creates a new one if it does not exist. This helps
  remove duplicates as above with Jane and John Doe sharing the same address.

  3. Set that model instance as the ForeignKey for the
  model that holds the ForeignKey field. This is handled by the line:

  ```python
   person.address = address
  ```

  In Django you don't need to worry about the hidden `id` primary key fields.
  Just set the model instance that you created above and Django will handle
  the rest for you.


This all may not be obvious. That is okay and something to be expected.
Members of the database cohort should feel free and encouraged to reach out for
help from the CDH dev team in planning your CSV arrangements and how to make
the script work.  

## Gotchas

Some errors you may expect to hit in no particular order:

* My script doesn't run or `python manage.py command_name` doesn't work.
This is likely caused by your directory structure being off (Django looks in a
very rigidly set path for commands), or some similar problem. Remember that
`management/commands` needs to be in the set of directories that are parallel
with your `models.py`.

* Your has Python syntax errors. These may pose a challenge in troubleshooting
but are the easiest to fix. If you get complaints about indents, this is because
python expects indentations to be multiples of four spaces (with no mixed-in tabs).
If your syntax editor is Sublime or Atom, it may even do you the courtesy of
marking which indent is off. The error message will also specify a line number
where things went wrong.

* Your CSV and model mapping are off--or data isn't parsing as the right type.
Make sure that you're mapping `row['column_name']` to the right property and that
it doesn't have any unexpected charactes or cruft. If you're parsing year dates as
integers (for example), Django needs to be able to make a clean conversion to the
right data type, so '1968' would work, but 'Dec. 1968' would make the script
die.

* You get complains about duplicates on unique fields. If you've marked any fields
as unique, you may be flagged that you have a duplicate during the import. The
easiest way to fix it is probably to check your data and figure out why you
have a duplicate in a field you thought was unique!

* You have junk data from multiple import runs. Follow the instructions to
`DROP` a database and restore from the clean backups that you made before
experimenting with import scripts. This might be a good idea before running the
final pass of your import scripts when you're happy with them in any case, just to
be sure.
