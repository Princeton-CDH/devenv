# Admin niceties and string methods

Django has many options for formatting your admin views beyond simply adding
models. It also has ways of letting you set intelligent text options to identify
objects. A few are below.

## The `__str__` method

Python objects by default have some methods (functions that 'do things' in relationship
to an object, think `wrench.turn()` to get the idea). One of them that Django
uses frequently in the admin is the `__str__` method. The double underscores
mean that it is a special method that Python object simply 'have'. (Though it
*is* actually just a convention.)

Say you have this model in `models.py`:

```python
class Person(models.Model):
    name = models.CharField(max_length=191)
    occupation = models.ForeignKey(Occupation, blank=True, null=True)
```

Django will merrily display all of the instances of this in your admin, if you
add it using directions found [here](getting-started-django-models.md#Django Admin) under step 1 of the tutorial.

However, you will see many confusing 'Person objects' scattered throughout. One
way to make this more useful (and crucially make objects selectable by a human
being in the admin), is the `__str__` method.

This snippet would cause all of those objects to be labeled with the name of
the person as taken from the dictionary:

```python
class Person(models.Model):
    name = models.CharField(max_length=191)
    age = models.PositiveSmallIntegerField()
    occupation = models.ForeignKey(Occupation, blank=True, null=True)

    def __str__(self):
      return self.name
```

The method takes one parameter (`self`), i.e. the person object itself and has
access to all the fields that we've defined for `Person`. Now the admin will
display a `Person` object as their name. Not all fields can be used directly to
`return` in a `__str__` method, i.e. `ForeignKey` fields.

## Admin 'List View' enhancements

When you click on a Model in the Django admin, the list of objects of that model
is sometimes called the 'list view' in the Django documentation. You earlier
created subclasses of `ModelAdmin` in `myentity/admin.py` like so:

```python
from django.contrib import admin
from myproject.myentity.models import MyModel

class MyModelAdmin(admin.ModelAdmin):
    pass

admin.site.register(MyModel, MyModelAdmin)
```

Now let's set two features on them. Any property that isn't a `ForeignKey` can
usually be displayed with a minimum of effort in the list view using a setting
on `ModelAdmin` called `list_display` ([documentation here](https://docs.djangoproject.com/en/2.0/ref/contrib/admin/#django.contrib.admin.ModelAdmin.list_display)).

You set it like so, using the `Person` model from earlier:

```python
from django.contrib import admin
from myproject.myentity.models import Person

class PersonAdmin(admin.ModelAdmin):
    list_display = ('name', 'age',)

admin.site.register(Person, PersonAdmin)
```

The list view will now display the person with columns for their name and age.

You can also add fields to be made searcheable (here only `name` probably
makes sense) using a similar setting called [`search_fields`](https://docs.djangoproject.com/en/2.0/ref/contrib/admin/#django.contrib.admin.ModelAdmin.search_fields):

```python
from django.contrib import admin
from myproject.myentity.models import Person

class PersonAdmin(admin.ModelAdmin):
    list_display = ('name', 'age',)
    search_fields = ['name']

admin.site.register(Person, PersonAdmin)
```

Now a search bar will appear on the right of the list view, which can be used
to search by person name!
