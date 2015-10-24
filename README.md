mconf-lb Cookbook
=================

This Chef cookbook installs an instance of [Mconf-LB](https://github.com/mconf/mconf-lb).

It installs and configures all the system dependencies needed to run Mconf-LB, except:

* The database. For that we use the cookbook [mconf-db](https://github.com/mconf-cookbooks/mconf-db).
* The source code and application configurations (the actual "deploy" of the application). For that we use Capistrano.


Requirements
------------

This cookbook is tested with Chef 11 (latest version). It may work with or without modification on newer versions of Chef, but Chef 11 is recommended.

Platform
--------

This cookbook currently supports Ubuntu 14.04. It will always be updated to support the OS version supported by Mconf-LB, which is usually the latest LTS version of Ubuntu.

Recipes
-------

#### default

Installs everything needed for Mconf-LB.


Usage
-----

#### mconf-lb::default

Include `mconf-lb` in your node's `run_list` along with the required attributes:

```json
{
  "name":"my_node",
  "mconf-lb": {
    "user": "mconf",
    "app_group": "www-data",
    "domain": "192.168.0.100"
  },
  "run_list": [
    "recipe[mconf-lb]"
  ]
}
```
