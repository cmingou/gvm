source $GVM_ROOT/scripts/gvm
## Regression test for issue 20: gvm was unusable in a shell running under
## `set -u`. Sourcing the integration died on the first unguarded expansion
## of GVM_DEBUG or ZSH_VERSION (scripts/gvm-default runs `cd .` at load, which
## enters env/cd), and a shell that enabled the option after a clean load lost
## `gvm use` the same way. The environment files themselves were a second
## source: the PKG_CONFIG_PATH line that scripts/install wrote expands a bare
## ${PKG_CONFIG_PATH}, which is unset on most machines, so gvm_source_environment
## now lifts nounset around its eval. Under bash 3.2 an empty array counts as
## unset too, which munge_path's rvm list usually is; the macOS leg of CI is
## what covers that. The version environment below is written the way
## scripts/install wrote it before this fix, and PKG_CONFIG_PATH is removed
## from the environment so that its bare expansion is really exercised.
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-set-u $GVM_ROOT/gos/go0.0.13 $GVM_ROOT/pkgsets/go0.0.13 $GVM_ROOT/environments/go0.0.13 $GVM_ROOT/environments/go0.0.13@global $GVM_ROOT/environments/go0.0.13@strict
#######################

mkdir -p $GVM_ROOT/tmp-set-u/project/sub $GVM_ROOT/gos/go0.0.13/bin $GVM_ROOT/pkgsets/go0.0.13/global/overlay/lib/pkgconfig # status=0
[ -f $GVM_ROOT/environments/default ] && cp $GVM_ROOT/environments/default $GVM_ROOT/tmp-set-u/default.bak; true # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.13"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.13"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.13/global"\nexport GVM_OVERLAY_PREFIX; GVM_OVERLAY_PREFIX="${GVM_ROOT}/pkgsets/go0.0.13/global/overlay"\nexport PATH; PATH="${GVM_ROOT}/pkgsets/go0.0.13/global/bin:${GVM_ROOT}/gos/go0.0.13/bin:${GVM_OVERLAY_PREFIX}/bin:${GVM_ROOT}/bin:${PATH}"\nexport LD_LIBRARY_PATH; LD_LIBRARY_PATH="${GVM_OVERLAY_PREFIX}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"\nexport DYLD_LIBRARY_PATH; DYLD_LIBRARY_PATH="${GVM_OVERLAY_PREFIX}/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"\nexport PKG_CONFIG_PATH; PKG_CONFIG_PATH="${GVM_OVERLAY_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}"\n' "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.13 # status=0
grep -c 'pkgconfig:${PKG_CONFIG_PATH}"' $GVM_ROOT/environments/go0.0.13 # match=/^1$/
gvm use go0.0.13 --quiet # status=0
gvm pkgset create strict # status=0
echo go0.0.13 > $GVM_ROOT/tmp-set-u/project/.go-version # status=0
echo strict > $GVM_ROOT/tmp-set-u/project/.go-pkgset # status=0

## a shell that had set -u before sourcing the integration: it must load,
## and every command sourced into the shell must work, with the version and
## pkgset unset first so that cd resolves them from the dot files
env -u PKG_CONFIG_PATH bash -c 'set -u; source "$GVM_ROOT/scripts/gvm" || exit 1; echo loaded; gvm > /dev/null; echo "noargs=$?"; gvm pkgset > /dev/null 2>&1; echo "pkgset-noargs=$?"; gvm version > /dev/null; echo "version=$?"; unset gvm_go_name gvm_pkgset_name; cd "$GVM_ROOT/tmp-set-u/project"; echo "cd=$? name=$gvm_go_name pkgset=$gvm_pkgset_name"; cd sub; echo "cdsub=$?"; cd "$GVM_ROOT/tmp-set-u"; echo "cdup=$?"; gvm use go0.0.13 --quiet; echo "use=$? $gvm_go_name"; gvm use go0.0.13@strict --quiet; echo "useat=$? $gvm_pkgset_name"; gvm use --version go0.0.13 --pkgset global --default --quiet; echo "usedefault=$? $gvm_pkgset_name"; gvm pkgset use strict --quiet; echo "pkgsetuse=$? $gvm_pkgset_name"; gvm pkgset use --pkgset global --quiet; echo "pkgsetuse2=$? $gvm_pkgset_name"; gvm list > /dev/null; echo "list=$?"; gvm pkgset list > /dev/null; echo "pkgsetlist=$?"; gvm use > /dev/null 2>&1; echo "usenoarg=$?"; gvm use --version > /dev/null 2>&1; echo "usemissing=$?"; yes n | gvm implode > /dev/null; echo "implode=$?"; source "$GVM_ROOT/scripts/gvm"; echo "reload=$?"; GVM_DEBUG=1 gvm use go0.0.13 --quiet > /dev/null 2>&1; echo "debug=$?"; GVM_DEBUG=1 cd "$GVM_ROOT/tmp-set-u/project" > /dev/null 2>&1; echo "debugcd=$?"; echo END' 2>&1 # status=0; match=/^loaded$/; match=/^noargs=0$/; match=/^version=0$/; match=/^cd=0 name=go0.0.13 pkgset=strict$/; match=/^cdsub=0$/; match=/^cdup=0$/; match=/^use=0 go0.0.13$/; match=/^useat=0 strict$/; match=/^usedefault=0 global$/; match=/^pkgsetuse=0 strict$/; match=/^pkgsetuse2=0 global$/; match=/^list=0$/; match=/^pkgsetlist=0$/; match=/^usenoarg=1$/; match=/^usemissing=1$/; match=/^implode=0$/; match=/^reload=0$/; match=/^debug=0$/; match=/^debugcd=0$/; match=/^END$/; match!=/unbound variable/; match!=/parameter not set/

## set -u enabled after a clean load must not take gvm use or cd away either
env -u PKG_CONFIG_PATH bash -c 'source "$GVM_ROOT/scripts/gvm" > /dev/null 2>&1; set -u; gvm use go0.0.13 --quiet; echo "use=$? $gvm_go_name"; cd "$GVM_ROOT/tmp-set-u/project"; echo "cd=$? $gvm_pkgset_name"; gvm pkgset use global --quiet; echo "pkgsetuse=$? $gvm_pkgset_name"; echo END' 2>&1 # status=0; match=/^use=0 go0.0.13$/; match=/^cd=0 strict$/; match=/^pkgsetuse=0 global$/; match=/^END$/; match!=/unbound variable/; match!=/parameter not set/

## the same under zsh where it is installed (the tf suite itself runs under
## bash); zsh reports the failure as "parameter not set"
if command -v zsh > /dev/null 2>&1; then env -u PKG_CONFIG_PATH zsh -f -c 'set -u; source "$GVM_ROOT/scripts/gvm" || exit 1; echo loaded; unset gvm_go_name gvm_pkgset_name; cd "$GVM_ROOT/tmp-set-u/project"; echo "cd=$? name=$gvm_go_name pkgset=$gvm_pkgset_name"; cd "$GVM_ROOT/tmp-set-u"; gvm use go0.0.13 --quiet; echo "use=$? $gvm_go_name"; gvm pkgset use strict --quiet; echo "pkgsetuse=$? $gvm_pkgset_name"; gvm pkgset use global --quiet; gvm list > /dev/null; echo "list=$?"; gvm use > /dev/null 2>&1; echo "usenoarg=$?"; yes n | gvm implode > /dev/null; echo "implode=$?"; GVM_DEBUG=1 gvm use go0.0.13 --quiet > /dev/null 2>&1; echo "debug=$?"; echo END' 2>&1; else echo "zsh not installed: SKIPPED"; fi # status=0; match=/^debug=0$|SKIPPED/; match=/^loaded$|SKIPPED/; match=/^cd=0 name=go0.0.13 pkgset=strict$|SKIPPED/; match=/^use=0 go0.0.13$|SKIPPED/; match=/^pkgsetuse=0 strict$|SKIPPED/; match=/^list=0$|SKIPPED/; match=/^usenoarg=1$|SKIPPED/; match=/^implode=0$|SKIPPED/; match=/^END$|SKIPPED/; match!=/unbound variable/; match!=/parameter not set/

## Cleanup test objects
cd $GVM_ROOT # status=0
[ -f $GVM_ROOT/tmp-set-u/default.bak ] && cp $GVM_ROOT/tmp-set-u/default.bak $GVM_ROOT/environments/default || rm -f $GVM_ROOT/environments/default; true # status=0
gvm uninstall go0.0.13 # status=0
rm -rf $GVM_ROOT/tmp-set-u $GVM_ROOT/gos/go0.0.13 $GVM_ROOT/pkgsets/go0.0.13 $GVM_ROOT/environments/go0.0.13 $GVM_ROOT/environments/go0.0.13@global $GVM_ROOT/environments/go0.0.13@strict
