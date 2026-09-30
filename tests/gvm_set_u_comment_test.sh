source $GVM_ROOT/scripts/gvm
## Regression test for issue 20: gvm was unusable in a shell running under
## `set -u`. Sourcing the integration died on the first unguarded expansion
## of GVM_DEBUG or ZSH_VERSION (scripts/gvm-default runs `cd .` at load, which
## enters env/cd), and a shell that enabled the option after a clean load lost
## `gvm use` the same way. The environment files themselves were a second
## source: the PKG_CONFIG_PATH line that scripts/install wrote expands a bare
## ${PKG_CONFIG_PATH}, which is unset on most machines, so gvm_source_environment
## now lifts nounset around its eval. Under bash 3.2 an empty array counts as
## unset too, which munge_path's rvm list usually is, and so does an empty
## "$@"; the macOS leg of CI is what covers that shell.
##
## The integration runs from a throwaway copy of the root that has no .git,
## so that GVM_NO_GIT_BAK can be left unset the way it is for every real
## user (gvm() reads it before anything else), and TERM, GVM_NO_UPDATE_PROFILE
## and PKG_CONFIG_PATH are removed from the environment as well: bash sets
## its own TERM, zsh does not, and the display helpers read it. The version
## environment is written the way scripts/install wrote it before this fix.
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-set-u
#######################

mkdir -p $GVM_ROOT/tmp-set-u/root/logs $GVM_ROOT/tmp-set-u/root/archive $GVM_ROOT/tmp-set-u/root/environments $GVM_ROOT/tmp-set-u/root/gos/go0.0.13/bin $GVM_ROOT/tmp-set-u/root/pkgsets/go0.0.13/global/overlay/lib/pkgconfig $GVM_ROOT/tmp-set-u/root/pkgsets/go0.0.13/strict/bin $GVM_ROOT/tmp-set-u/project/sub # status=0
cp -R $GVM_ROOT/bin $GVM_ROOT/scripts $GVM_ROOT/locales $GVM_ROOT/VERSION $GVM_ROOT/tmp-set-u/root/ # status=0
ls -d $GVM_ROOT/tmp-set-u/root/.git # status!=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.13"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.13"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.13/global"\nexport GVM_OVERLAY_PREFIX; GVM_OVERLAY_PREFIX="${GVM_ROOT}/pkgsets/go0.0.13/global/overlay"\nexport PATH; PATH="${GVM_ROOT}/pkgsets/go0.0.13/global/bin:${GVM_ROOT}/gos/go0.0.13/bin:${GVM_OVERLAY_PREFIX}/bin:${GVM_ROOT}/bin:${PATH}"\nexport LD_LIBRARY_PATH; LD_LIBRARY_PATH="${GVM_OVERLAY_PREFIX}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"\nexport DYLD_LIBRARY_PATH; DYLD_LIBRARY_PATH="${GVM_OVERLAY_PREFIX}/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"\nexport PKG_CONFIG_PATH; PKG_CONFIG_PATH="${GVM_OVERLAY_PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH}"\n' "$GVM_ROOT/tmp-set-u/root" > $GVM_ROOT/tmp-set-u/root/environments/go0.0.13 # status=0
grep -c 'pkgconfig:${PKG_CONFIG_PATH}"' $GVM_ROOT/tmp-set-u/root/environments/go0.0.13 # match=/^1$/
cp $GVM_ROOT/tmp-set-u/root/environments/go0.0.13 $GVM_ROOT/tmp-set-u/root/environments/go0.0.13@global # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\n. "${GVM_ROOT}/environments/go0.0.13"\nexport gvm_go_name; gvm_go_name="go0.0.13"\nexport gvm_pkgset_name; gvm_pkgset_name="strict"\nexport GOPATH; GOPATH="${GVM_ROOT}/pkgsets/go0.0.13/strict:$GOPATH"\nexport PATH; PATH="${GVM_ROOT}/pkgsets/go0.0.13/strict/bin:$PATH"\n' "$GVM_ROOT/tmp-set-u/root" > $GVM_ROOT/tmp-set-u/root/environments/go0.0.13@strict # status=0
echo go0.0.13 > $GVM_ROOT/tmp-set-u/project/.go-version # status=0
echo strict > $GVM_ROOT/tmp-set-u/project/.go-pkgset # status=0

## a shell that had set -u before sourcing the integration: it must load,
## and every command sourced into the shell must work, with the version and
## pkgset unset first so that cd resolves them from the dot files
env -u GVM_NO_GIT_BAK -u GVM_NO_UPDATE_PROFILE -u TERM -u PKG_CONFIG_PATH GVM_ROOT=$GVM_ROOT/tmp-set-u/root bash -c 'set -u; . "$GVM_ROOT/scripts/gvm-default" || exit 1; echo loaded; gvm > /dev/null; echo "noargs=$?"; gvm pkgset > /dev/null 2>&1; echo "pkgset-noargs=$?"; gvm version > /dev/null; echo "version=$?"; unset gvm_go_name gvm_pkgset_name; cd "$GVM_ROOT/../project"; echo "cd=$? name=$gvm_go_name pkgset=$gvm_pkgset_name"; cd sub; echo "cdsub=$?"; cd; echo "cdbare=$?"; cd "$GVM_ROOT/.."; echo "cdup=$?"; gvm use go0.0.13 --quiet; echo "use=$? $gvm_go_name"; gvm use go0.0.13@strict --quiet; echo "useat=$? $gvm_pkgset_name"; gvm use --version go0.0.13 --pkgset global --default --quiet; echo "usedefault=$? $gvm_pkgset_name"; gvm pkgset use strict --quiet; echo "pkgsetuse=$? $gvm_pkgset_name"; gvm pkgset use --pkgset global --quiet; echo "pkgsetuse2=$? $gvm_pkgset_name"; gvm list > /dev/null; echo "list=$?"; gvm pkgset list > /dev/null; echo "pkgsetlist=$?"; gvm use > /dev/null 2>&1; echo "usenoarg=$?"; gvm use --version > /dev/null 2>&1; echo "usemissing=$?"; gvm use --bogus > /dev/null 2>&1; echo "usebogus=$?"; gvm pkgset use > /dev/null 2>&1; echo "pkgsetusenoarg=$?"; yes n | gvm implode > /dev/null; echo "implode=$?"; . "$GVM_ROOT/scripts/gvm-default"; echo "reload=$?"; GVM_DEBUG=1 gvm use go0.0.13 --quiet > /dev/null 2>&1; echo "debug=$?"; GVM_DEBUG=1 gvm pkgset use strict --quiet > /dev/null 2>&1; echo "debugpkgset=$?"; GVM_DEBUG=1 cd "$GVM_ROOT/../project" > /dev/null 2>&1; echo "debugcd=$?"; echo END' 2>&1 # status=0; match=/^loaded$/; match=/^noargs=0$/; match=/^version=0$/; match=/^cd=0 name=go0.0.13 pkgset=strict$/; match=/^cdsub=0$/; match=/^cdbare=0$/; match=/^cdup=0$/; match=/^use=0 go0.0.13$/; match=/^useat=0 strict$/; match=/^usedefault=0 global$/; match=/^pkgsetuse=0 strict$/; match=/^pkgsetuse2=0 global$/; match=/^list=0$/; match=/^pkgsetlist=0$/; match=/^usenoarg=1$/; match=/^usemissing=1$/; match=/^usebogus=1$/; match=/^pkgsetusenoarg=1$/; match=/^implode=0$/; match=/^reload=0$/; match=/^debug=0$/; match=/^debugpkgset=0$/; match=/^debugcd=0$/; match=/^END$/; match!=/unbound variable/; match!=/parameter not set/; match!=/\.git directory is present/

## set -u enabled after a clean load must not take gvm use or cd away either
env -u GVM_NO_GIT_BAK -u GVM_NO_UPDATE_PROFILE -u TERM -u PKG_CONFIG_PATH GVM_ROOT=$GVM_ROOT/tmp-set-u/root bash -c '. "$GVM_ROOT/scripts/gvm-default" > /dev/null 2>&1; set -u; gvm use go0.0.13 --quiet; echo "use=$? $gvm_go_name"; cd "$GVM_ROOT/../project"; echo "cd=$? $gvm_pkgset_name"; gvm pkgset use global --quiet; echo "pkgsetuse=$? $gvm_pkgset_name"; echo END' 2>&1 # status=0; match=/^use=0 go0.0.13$/; match=/^cd=0 strict$/; match=/^pkgsetuse=0 global$/; match=/^END$/; match!=/unbound variable/; match!=/parameter not set/

## the same under zsh where it is installed (the tf suite itself runs under
## bash); zsh reports the failure as "parameter not set"
if command -v zsh > /dev/null 2>&1; then env -u GVM_NO_GIT_BAK -u GVM_NO_UPDATE_PROFILE -u TERM -u PKG_CONFIG_PATH GVM_ROOT=$GVM_ROOT/tmp-set-u/root zsh -f -c 'set -u; . "$GVM_ROOT/scripts/gvm-default" || exit 1; echo loaded; unset gvm_go_name gvm_pkgset_name; cd "$GVM_ROOT/../project"; echo "cd=$? name=$gvm_go_name pkgset=$gvm_pkgset_name"; cd; echo "cdbare=$?"; cd "$GVM_ROOT/.."; gvm use go0.0.13 --quiet; echo "use=$? $gvm_go_name"; gvm use go0.0.13; echo "useloud=$?"; gvm pkgset use strict --quiet; echo "pkgsetuse=$? $gvm_pkgset_name"; gvm pkgset use global --quiet; gvm list > /dev/null; echo "list=$?"; gvm use > /dev/null 2>&1; echo "usenoarg=$?"; yes n | gvm implode > /dev/null; echo "implode=$?"; GVM_DEBUG=1 gvm use go0.0.13 --quiet > /dev/null 2>&1; echo "debug=$?"; echo END' 2>&1; else echo "zsh not installed: SKIPPED"; fi # status=0; match=/^loaded$|SKIPPED/; match=/^cd=0 name=go0.0.13 pkgset=strict$|SKIPPED/; match=/^cdbare=0$|SKIPPED/; match=/^use=0 go0.0.13$|SKIPPED/; match=/^Now using version go0.0.13$|SKIPPED/; match=/^useloud=0$|SKIPPED/; match=/^pkgsetuse=0 strict$|SKIPPED/; match=/^list=0$|SKIPPED/; match=/^usenoarg=1$|SKIPPED/; match=/^implode=0$|SKIPPED/; match=/^debug=0$|SKIPPED/; match=/^END$|SKIPPED/; match!=/unbound variable/; match!=/parameter not set/

## Cleanup test objects
cd $GVM_ROOT # status=0
rm -rf $GVM_ROOT/tmp-set-u
