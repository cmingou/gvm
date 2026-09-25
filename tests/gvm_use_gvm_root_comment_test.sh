source $GVM_ROOT/scripts/gvm
## Regression test for issue 28: an environment file carries the GVM_ROOT
## that was current when it was written, and `gvm use`, `gvm pkgset use` and
## the login-time load of environments/default sourced it as is. A user who
## set GVM_ROOT to a relocated or custom root had it silently reverted to the
## install-time path, with GOROOT, GOPATH and PATH following. The file's own
## GVM_ROOT line is now left out when gvm sources one, so every path in the
## file expands against the caller's root. Uses fake Go versions and an
## environment written for a root that does not exist.
## Cleanup test objects
rm -rf $GVM_ROOT/gos/go0.0.18 $GVM_ROOT/pkgsets/go0.0.18 $GVM_ROOT/environments/go0.0.18 $GVM_ROOT/environments/go0.0.18@* $GVM_ROOT/tmp-gvmroot
#######################

mkdir -p $GVM_ROOT/gos/go0.0.18/bin $GVM_ROOT/pkgsets/go0.0.18/global $GVM_ROOT/tmp-gvmroot # status=0
## the version environment as `gvm install` writes it, but for another root
printf 'export GVM_ROOT; GVM_ROOT="/nonexistent/install-time-root"\nexport gvm_go_name; gvm_go_name="go0.0.18"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.18"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.18/global"\nexport PATH; PATH="${GVM_ROOT}/pkgsets/go0.0.18/global/bin:${GVM_ROOT}/gos/go0.0.18/bin:${GVM_ROOT}/bin:${PATH}"\n' > $GVM_ROOT/environments/go0.0.18 # status=0

## gvm use keeps the caller's GVM_ROOT and resolves GOROOT, GOPATH and PATH against it
gvm use go0.0.18 --quiet # status=0
echo $GVM_ROOT # match!=/install-time-root/
echo $GOROOT # match!=/install-time-root/
echo $GOROOT # match=/\/gos\/go0\.0\.18$/
echo $GOPATH # match=/\/pkgsets\/go0\.0\.18\/global$/
echo $PATH # match!=/install-time-root/
echo $PATH # match=/\/gos\/go0\.0\.18\/bin/
gvm list # match=/go0\.0\.18/

## the same for a pkgset environment, which carries the root and sources the version environment
gvm pkgset create rootpkg # status=0
printf 'export GVM_ROOT; GVM_ROOT="/nonexistent/install-time-root"\n. "${GVM_ROOT}/environments/go0.0.18" || return 1\nexport gvm_go_name; gvm_go_name="go0.0.18"\nexport gvm_pkgset_name; gvm_pkgset_name="rootpkg"\nexport GOPATH; GOPATH="${GVM_ROOT}/pkgsets/go0.0.18/rootpkg:$GOPATH"\nexport PATH; PATH="${GVM_ROOT}/pkgsets/go0.0.18/rootpkg/bin:$PATH"\n' > $GVM_ROOT/environments/go0.0.18@rootpkg # status=0
gvm pkgset use rootpkg --quiet # status=0
echo $GVM_ROOT # match!=/install-time-root/
echo $gvm_go_name $gvm_pkgset_name # match=/^go0\.0\.18 rootpkg$/
echo $GOPATH # match!=/install-time-root/
echo $GOPATH # match=/\/pkgsets\/go0\.0\.18\/rootpkg:.*\/pkgsets\/go0\.0\.18\/global$/
echo $PATH # match!=/install-time-root/
gvm use go0.0.18@rootpkg --quiet # status=0
echo $GVM_ROOT $GOROOT $GOPATH $PATH # match!=/install-time-root/
echo $gvm_go_name $gvm_pkgset_name # match=/^go0\.0\.18 rootpkg$/

## and for environments/default, which a new shell loads at login
## (an existing default is moved aside for this part and restored below)
mv $GVM_ROOT/environments/default $GVM_ROOT/environments/default.gvmrootbak 2> /dev/null; true # status=0
cp $GVM_ROOT/environments/go0.0.18@rootpkg $GVM_ROOT/environments/default # status=0
bash -c 'export GVM_NO_GIT_BAK=1; . "$GVM_ROOT/scripts/gvm-default"; echo "root=$GVM_ROOT goroot=$GOROOT gopath=$GOPATH name=$gvm_go_name@$gvm_pkgset_name"' # status=0; match!=/install-time-root/; match=/goroot=.*\/gos\/go0\.0\.18 gopath=.*\/rootpkg:.* name=go0\.0\.18@rootpkg$/
rm -f $GVM_ROOT/environments/default # status=0
mv $GVM_ROOT/environments/default.gvmrootbak $GVM_ROOT/environments/default 2> /dev/null; true # status=0

## an environment file can still be sourced on its own, outside gvm, where its GVM_ROOT line is what sets the root
bash -c 'unset GVM_ROOT; . "'$GVM_ROOT'/environments/go0.0.18"; echo "$GVM_ROOT"' # status=0; match=/^\/nonexistent\/install-time-root$/

## Cleanup test objects
gvm uninstall go0.0.18 # status=0
rm -rf $GVM_ROOT/gos/go0.0.18 $GVM_ROOT/pkgsets/go0.0.18 $GVM_ROOT/environments/go0.0.18 $GVM_ROOT/environments/go0.0.18@* $GVM_ROOT/tmp-gvmroot
