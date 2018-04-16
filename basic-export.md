## Basic Django export using django-import-export

## Install django-import-export

From your VM's prompt, but before you activate your pipenv:

```shell
vagrant:$ pipenv install django-import-export
```

Edit the installed apps in your project's `settings.py` to include the new
package and load into your pipenv.

```python
INSTALLED_APPS = [
  ...
  'import_export'
]
```

## Add import-export functionality to an admin

In `admin.py` for your module's app:

```
from import_export.admin import ImportExportModelAdmin

class MyModelAdmin(ImportExportModelAdmin):
    pass

```

If you change `admin.ModelAdmin` to the newly imported `ImportExportModelAdmin`,
that model will now be able to export its data in a variety of format, some of
which (like JSON) can be read into OpenRefine and follow many to many links.
