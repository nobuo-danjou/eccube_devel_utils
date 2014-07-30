# eccube_devel_utils

----

to run ostore test server:

```
ECCUBE_DIST_FILE=../mdl_foobar.tar.gz \
carton exec -- plackup ostore.psgi
```

to make module dist file:
```
carton exec -- perl make_mdldist.pl path/to/mdl_dist
```
dist.tar.gz will appear on current directory
