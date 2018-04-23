# Django Views

Django also has ways to display data and get it out of the database, just like
the admin interface lets you put data in and modify the database.

These also let you create more complicated CSV or JSON output that uses SQL
in the background to do more complex things like following foreign key
relationships to get information.

## The Parts

Views have two "parts" in Django. One is modifying `views.py` to create a simple
code snippet that outputs a CSV. The second is to import that view into
`urls.py` so that Django knows what url to serve it on (i.e., just like
`localhost:8000/admin` is where Django lists the admin url).

Here is a sample CSV export view with some explanation. `MyModel` is just a
stand-in for your model's actual name. This goes in your application's `views.py`

```python
import csv

from django.http import HttpResponse
from django.views.generic import ListView,


class MyObjectListView(ListView):
    model = MyModel

    def get_data(self):
      """
      Get data for MyModel as we see fit and pass it to a list of dictionaries
      for CSV Writer
      """
      # By default every instance of MyModel
      mymodels = self.get_queryset()
      # but we'll look at ways to filter it down later
      dictionary_list = []
      for model in mymodels:
          model_dict = {}
          model_dict['field1'] = model.field1
          model_dict['field2'] = model.field2
          # Here we're referencing a foreign key object and then its name
          model_dict['fk_obj'] = model.fk_obj.name
          # Here we're grabbing a Django managed m2m and th
          model_dict['topics'] = [topic.name for topic
                                in ';'.join(model.topics.all())
                                # the syntax looks hairy but it isn't -- we're just telling python
                                # to get all the related topics, and then make a list of their name
                                # properties and join them with a semi-colon

        # now we append it to the list
          dictionary_list.append(model_dict)

      return dictionary_list

    def render_to_response(self, context, **kwargs):

        # This boiler plate sets up the response and sets fields that tell
        # your browser this is a file, not a webpage.
        response = HttpResponse(context_type='text/csv')
        response['Content-Disposition'] = 'attachment; filename="mymodel.csv"'

        # these need to match your dictionary above
        # if they don't python will complain
        headers = ['field1', 'field2', 'fk_obj', 'topics']

        writer = csv.DictWriter(response, headers)
        writer.writeheader()
        rows = self.get_data()
        for row in rows:
            writer.writerow(row)

        return response  
```

Now that we've written the code for producing the output, we need to
hook it up in `urls.py`. Your application will have one of these, but since
we're keepign this simple, it will be easier to use your project level `urls.py`

It will need to look something like this:
```python
from django.conf.urls import url, include
from django.contrib import admin

from myapp.views import MyObjectListView

urlpatterns = [
   url(r'^admin/', admin.site.urls),
   url(r'^csv/mymodel', MyObjectListView.as_view(), name='mymodel_csv'),
]

```

If all goes well, once you've added this to your list, if you go to the url you
substituted (for above it would be `localhost:8000/csv/mymodel`) you'll get a CSV
file with the search you just performed above.

## Filters

Of course, returning all objects isn't very useful. `self.get_queryset()` returns
a Django `QuerySet`, which is a potential search that leverages all the power that
SQL offers, with convenience wrappers so that you don't have to remember SQL
syntax.

They also merrily chain and let you do many common subsetting tasks. Say you wanted
above to only have those objects that had 'Foobar' among their topic names:

```python
mymodels = self.get_queryset().filter(topics__name='Foobar')
```

Now `mymodels` would only contain those that have 'Foobar' among the topics.

Filtering is incredibly powerful and it really does duplicate most common SQL
queries in a streamlined wrapper. See [Making queries](https://docs.djangoproject.com/en/2.0/topics/db/queries/)
for more instructions and detail about all the different filters at your disposal.
