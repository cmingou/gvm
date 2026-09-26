source $GVM_ROOT/scripts/gvm
## Regression test for issue 5: the fallback resolvers must not run `gvm list`
## or `gvm pkgset list` in a command substitution. Each of those forks a shell
## that reloads every function file, then a pipeline of ls and sed, which cost
## ~250ms and ~950ms per call on a macOS runner. The resolvers are called on
## the first cd of every shell whose root has no default or system environment,
## so that cost was paid at every login on a machine with no default set.
## The property tested is the call count, not the clock: a gvm() shadow counts
## into a file, because the resolvers run inside a command substitution and a
## variable incremented there would not survive the subshell.
## Cleanup test objects
rm -rf $GVM_ROOT/gos/go0.0.1 $GVM_ROOT/gos/go0.0.9 $GVM_ROOT/gos/go0.0.10 $GVM_ROOT/gos/mygo $GVM_ROOT/gos/go1.2.3-rc $GVM_ROOT/pkgsets/go0.0.10 $GVM_ROOT/pkgsets/go0.0.9 $GVM_ROOT/tmp-fallback
#######################

mkdir -p $GVM_ROOT/gos/go0.0.1/bin $GVM_ROOT/gos/go0.0.9/bin $GVM_ROOT/gos/go0.0.10/bin $GVM_ROOT/gos/mygo/bin $GVM_ROOT/gos/go1.2.3-rc/bin $GVM_ROOT/pkgsets/go0.0.10/global $GVM_ROOT/pkgsets/go0.0.10/other $GVM_ROOT/tmp-fallback/local/.gvm_local $GVM_ROOT/tmp-fallback/plain # status=0
rm -f $GVM_ROOT/tmp-fallback/calls # status=0
gvm() { echo "gvm $*" >> "$GVM_ROOT/tmp-fallback/calls"; command "$GVM_ROOT/bin/gvm" "$@"; }

## the fallback version is the highest goM.m[.p] name in gos: compared
## numerically, so go0.0.10 beats go0.0.9, and names that are not plain go
## versions (mygo, go1.2.3-rc, system) never qualify
__gvm_resolve_fallback_version # status=0; match=/^go0\.0\.10$/
[ -f $GVM_ROOT/tmp-fallback/calls ] && cat $GVM_ROOT/tmp-fallback/calls; echo "calls=$(cat $GVM_ROOT/tmp-fallback/calls 2> /dev/null | wc -l | tr -d ' ')" # match=/^calls=0$/

## the fallback pkgset is "global" when the version has one
__gvm_resolve_fallback_pkgset go0.0.10 # status=0; match=/^global$/
## the version's own global pkgset, not another version's
__gvm_resolve_fallback_pkgset go0.0.9 # status!=0; match!=/global/
## an empty version resolves nothing
__gvm_resolve_fallback_pkgset "" # status!=0

## a local pkgset in the current directory wins over global
cd $GVM_ROOT/tmp-fallback/local # status=0
__gvm_resolve_fallback_pkgset go0.0.10 # status=0; match=/tmp-fallback\/local$/
## but only in that directory itself, as before
cd $GVM_ROOT/tmp-fallback/plain # status=0
__gvm_resolve_fallback_pkgset go0.0.10 # status=0; match=/^global$/
cd $GVM_ROOT # status=0

## none of the above may have run a gvm command
echo "calls=$(cat $GVM_ROOT/tmp-fallback/calls 2> /dev/null | wc -l | tr -d ' ')" # match=/^calls=0$/
unset -f gvm

## the first cd in a root without default and system environments resolves
## the fallback through the same resolver, so it must not run gvm either
mv $GVM_ROOT/environments/default $GVM_ROOT/environments/default.fbtestbak 2> /dev/null; true # status=0
mv $GVM_ROOT/environments/system $GVM_ROOT/environments/system.fbtestbak 2> /dev/null; true # status=0
rm -f $GVM_ROOT/tmp-fallback/calls # status=0
gvm() { echo "gvm $*" >> "$GVM_ROOT/tmp-fallback/calls"; command "$GVM_ROOT/bin/gvm" "$@"; }
__gvmp_fallback_cached=""
cd $GVM_ROOT/tmp-fallback/plain # status=0
cd $GVM_ROOT # status=0
echo "calls=$(cat $GVM_ROOT/tmp-fallback/calls 2> /dev/null | wc -l | tr -d ' ')" # match=/^calls=0$/
unset -f gvm
mv $GVM_ROOT/environments/default.fbtestbak $GVM_ROOT/environments/default 2> /dev/null; true # status=0
mv $GVM_ROOT/environments/system.fbtestbak $GVM_ROOT/environments/system 2> /dev/null; true # status=0

## Cleanup test objects
rm -rf $GVM_ROOT/gos/go0.0.1 $GVM_ROOT/gos/go0.0.9 $GVM_ROOT/gos/go0.0.10 $GVM_ROOT/gos/mygo $GVM_ROOT/gos/go1.2.3-rc $GVM_ROOT/pkgsets/go0.0.10 $GVM_ROOT/pkgsets/go0.0.9 $GVM_ROOT/tmp-fallback
