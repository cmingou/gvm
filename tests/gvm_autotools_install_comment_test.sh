source $GVM_ROOT/scripts/gvm
## Regression test for issue 39: the autotools build's `make install` was a
## bare `cp -rf .` of the checkout, .git included, and gvm refuses to run from
## a root that has one; it also wrote no scripts/gvm for the install location
## and no environment for a Go already on PATH. Makefile.am now delegates to
## binscripts/gvm-make-install, which is exercised directly against a copy of
## the tree carrying a fake .git and some stale root state, and then through
## the real autogen.sh / make install where autoconf and automake exist (the
## direct run is what the tf suite gates everywhere).
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-autotools
#######################

mkdir -p $GVM_ROOT/tmp-autotools/src/.git/objects $GVM_ROOT/tmp-autotools/src/gos/stale $GVM_ROOT/tmp-autotools/src/environments # status=0
cp -R $GVM_ROOT/bin $GVM_ROOT/binscripts $GVM_ROOT/scripts $GVM_ROOT/locales $GVM_ROOT/VERSION $GVM_ROOT/Makefile.am $GVM_ROOT/configure.ac $GVM_ROOT/autogen.sh $GVM_ROOT/LICENSE $GVM_ROOT/README.md $GVM_ROOT/tmp-autotools/src/ # status=0
echo 'export GVM_ROOT; GVM_ROOT="/stale/root"' > $GVM_ROOT/tmp-autotools/src/environments/default # status=0

## the install script alone: no .git, no stale state, a scripts/gvm for the
## install location, and gvm runs from the result with GVM_NO_GIT_BAK unset
env -u GVM_NO_GIT_BAK $GVM_ROOT/tmp-autotools/src/binscripts/gvm-make-install $GVM_ROOT/tmp-autotools/src $GVM_ROOT/tmp-autotools/direct/gvm 2>&1 # status=0; match=/Installed GVM v/; match=/Add this line to your shell profile/; match=/tmp-autotools\/direct\/gvm\/scripts\/gvm/
ls -d $GVM_ROOT/tmp-autotools/direct/gvm/.git # status!=0
ls -d $GVM_ROOT/tmp-autotools/direct/gvm/gos/stale # status!=0
ls $GVM_ROOT/tmp-autotools/direct/gvm/environments/default # status!=0
cat $GVM_ROOT/tmp-autotools/direct/gvm/scripts/gvm # match=/^export GVM_ROOT=.*\/tmp-autotools\/direct\/gvm$/
env -u GVM_NO_GIT_BAK GVM_ROOT=$GVM_ROOT/tmp-autotools/direct/gvm bash -c '. "$GVM_ROOT/scripts/gvm"; gvm version; gvm list' 2>&1 # status=0; match=/Go Version Manager v.* installed at .*tmp-autotools\/direct\/gvm/; match=/gvm gos \(installed\)/; match!=/\.git directory is present/
## with a Go on PATH the install records it as the system version
if command -v go > /dev/null 2>&1; then grep -c 'gvm_go_name="system"' $GVM_ROOT/tmp-autotools/direct/gvm/environments/system; else echo "no go on PATH: SKIPPED"; fi # status=0; match=/^1$|SKIPPED/
## a DESTDIR-style staging install keeps the runtime root in scripts/gvm
$GVM_ROOT/tmp-autotools/src/binscripts/gvm-make-install $GVM_ROOT/tmp-autotools/src $GVM_ROOT/tmp-autotools/staging/opt/gvm /opt/gvm > /dev/null # status=0
cat $GVM_ROOT/tmp-autotools/staging/opt/gvm/scripts/gvm # match=/^export GVM_ROOT=\/opt\/gvm$/
## the usage error
$GVM_ROOT/tmp-autotools/src/binscripts/gvm-make-install $GVM_ROOT/tmp-autotools/src 2>&1 # status!=0; match=/usage: gvm-make-install/

## the real build, where the autotools are installed
if command -v aclocal > /dev/null 2>&1 && command -v automake > /dev/null 2>&1 && command -v autoconf > /dev/null 2>&1; then (cd $GVM_ROOT/tmp-autotools/src && ./autogen.sh --prefix=$GVM_ROOT/tmp-autotools/prefix > $GVM_ROOT/tmp-autotools/autogen.log 2>&1 && make install > $GVM_ROOT/tmp-autotools/make.log 2>&1 && echo MAKE-INSTALL-OK) || { echo MAKE-INSTALL-FAILED; tail -n 30 $GVM_ROOT/tmp-autotools/autogen.log $GVM_ROOT/tmp-autotools/make.log; }; else echo "autotools not installed: SKIPPED"; fi # status=0; match=/MAKE-INSTALL-OK|SKIPPED/
if [ -d $GVM_ROOT/tmp-autotools/prefix ]; then ls $GVM_ROOT/tmp-autotools/prefix/bin/gvm $GVM_ROOT/tmp-autotools/prefix/gvm/scripts/gvm-default && { ls -d $GVM_ROOT/tmp-autotools/prefix/gvm/.git 2> /dev/null || echo NO-GIT; }; else echo SKIPPED; fi # status=0; match=/NO-GIT|SKIPPED/; match!=/prefix\/gvm\/\.git$/
if [ -d $GVM_ROOT/tmp-autotools/prefix ]; then cat $GVM_ROOT/tmp-autotools/prefix/gvm/scripts/gvm; else echo SKIPPED; fi # match=/^export GVM_ROOT=.*\/tmp-autotools\/prefix\/gvm$|SKIPPED/
if [ -d $GVM_ROOT/tmp-autotools/prefix ]; then env -u GVM_NO_GIT_BAK GVM_ROOT=$GVM_ROOT/tmp-autotools/prefix/gvm bash -c '. "$GVM_ROOT/scripts/gvm"; gvm version' 2>&1; else echo SKIPPED; fi # status=0; match=/installed at .*tmp-autotools\/prefix\/gvm|SKIPPED/; match!=/\.git directory is present/

## Cleanup test objects
rm -rf $GVM_ROOT/tmp-autotools
