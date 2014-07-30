# eccube_devel_utils

----

- to make module dist file:

```
carton exec -- perl make_mdldist.pl path/to/mdl_foobar
```
mdl_foobar.tar.gz will appear on current directory


- to run ostore test server:

```
ECCUBE_DIST_FILE=./mdl_foobar.tar.gz \
carton exec -- plackup ostore.psgi
```
