source $GVM_ROOT/scripts/gvm
## Regression test for issue 27: a source install needs an existing Go
## toolchain to bootstrap with, and nothing checked for one. compile_go
## exported GOROOT_BOOTSTRAP from `go env GOROOT` unchecked, so with no go on
## PATH the build got "go: command not found", an empty GOROOT_BOOTSTRAP and
## make.bash's "Cannot find $HOME/go1.4/bin/go", after the whole Go source had
## been cloned. And a failed compile was not fatal: its display_fatal ran in a
## subshell, so install_go carried on, wrote an environment file for a version
## that does not exist and reported a second, bogus "Failed to use installed
## version". The install runs against a throwaway copy of the root with a fake
## Go source cache, so there is no network and no real build. Shebangs are
## spelled \043 because a literal # would end the tf command.
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-bootstrap
#######################

mkdir -p $GVM_ROOT/tmp-bootstrap/root/logs $GVM_ROOT/tmp-bootstrap/root/archive $GVM_ROOT/tmp-bootstrap/root/environments $GVM_ROOT/tmp-bootstrap/root/gos $GVM_ROOT/tmp-bootstrap/bin $GVM_ROOT/tmp-bootstrap/fake-goroot/bin # status=0
cp -R $GVM_ROOT/bin $GVM_ROOT/scripts $GVM_ROOT/locales $GVM_ROOT/VERSION $GVM_ROOT/tmp-bootstrap/root/ # status=0

## a PATH that links to everything on the system except go, with stand-ins
## for the C toolchain that gvm-check looks for (nothing here compiles)
ln -s /usr/bin/* /bin/* /usr/local/bin/* $GVM_ROOT/tmp-bootstrap/bin/ 2> /dev/null; true # status=0
rm -f $GVM_ROOT/tmp-bootstrap/bin/go $GVM_ROOT/tmp-bootstrap/bin/bison $GVM_ROOT/tmp-bootstrap/bin/gcc $GVM_ROOT/tmp-bootstrap/bin/make $GVM_ROOT/tmp-bootstrap/bin/ar # status=0
for t in bison gcc make ar; do printf '\043!/bin/sh\nexit 0\n' > $GVM_ROOT/tmp-bootstrap/bin/$t; chmod +x $GVM_ROOT/tmp-bootstrap/bin/$t; done # status=0
PATH=$GVM_ROOT/tmp-bootstrap/bin command -v go # status!=0
PATH=$GVM_ROOT/tmp-bootstrap/bin command -v git # status=0

## with no go on PATH a source install must stop with an actionable message
## before it clones anything, not with "go: command not found" from the build
env PATH=$GVM_ROOT/tmp-bootstrap/bin GVM_ROOT=$GVM_ROOT/tmp-bootstrap/root GVM_NO_GIT_BAK=1 GOROOT_BOOTSTRAP= $GVM_ROOT/tmp-bootstrap/root/bin/gvm install go1.99.98 -s=http://127.0.0.1:1/nope 2>&1 # status!=0; match=/no go on PATH/; match=/gvm install <version> -B/; match!=/command not found/; match!=/Failed to use installed version/
ls -d $GVM_ROOT/tmp-bootstrap/root/archive/go # status!=0

## a GOROOT_BOOTSTRAP that holds no go is refused the same way
env PATH=$GVM_ROOT/tmp-bootstrap/bin GVM_ROOT=$GVM_ROOT/tmp-bootstrap/root GVM_NO_GIT_BAK=1 GOROOT_BOOTSTRAP=$GVM_ROOT/tmp-bootstrap/nowhere $GVM_ROOT/tmp-bootstrap/root/bin/gvm install go1.99.98 -s=http://127.0.0.1:1/nope 2>&1 # status!=0; match=/GOROOT_BOOTSTRAP is set to/; match=/nowhere\/bin\/go/
ls -d $GVM_ROOT/tmp-bootstrap/root/archive/go # status!=0

## a fake Go source cache with one tag, whose make.bash records the bootstrap
## root it was given and then fails, and a fake go that answers `go env GOROOT`
mkdir -p $GVM_ROOT/tmp-bootstrap/root/archive/go/src # status=0
printf '\043!/bin/sh\necho "make.bash saw GOROOT_BOOTSTRAP=$GOROOT_BOOTSTRAP"\nexit 1\n' > $GVM_ROOT/tmp-bootstrap/root/archive/go/src/make.bash # status=0
git -C $GVM_ROOT/tmp-bootstrap/root/archive/go init -q # status=0
git -C $GVM_ROOT/tmp-bootstrap/root/archive/go -c user.name=gvm -c user.email=gvm@example.invalid add . # status=0
git -C $GVM_ROOT/tmp-bootstrap/root/archive/go -c user.name=gvm -c user.email=gvm@example.invalid commit -q -m fake # status=0
git -C $GVM_ROOT/tmp-bootstrap/root/archive/go tag go1.99.98 # status=0
printf '\043!/bin/sh\ncase "$1 $2" in "env GOROOT") echo %s ;; esac\n' "$GVM_ROOT/tmp-bootstrap/fake-goroot" > $GVM_ROOT/tmp-bootstrap/bin/go # status=0
chmod +x $GVM_ROOT/tmp-bootstrap/bin/go # status=0
PATH=$GVM_ROOT/tmp-bootstrap/bin go env GOROOT # status=0; match=/tmp-bootstrap\/fake-goroot$/

## a failed compile must be the one and only error, make.bash must have been
## given the bootstrap root, and nothing may be left behind for the version
env PATH=$GVM_ROOT/tmp-bootstrap/bin GVM_ROOT=$GVM_ROOT/tmp-bootstrap/root GVM_NO_GIT_BAK=1 GOROOT_BOOTSTRAP= $GVM_ROOT/tmp-bootstrap/root/bin/gvm install go1.99.98 2>&1 # status!=0; match=/Failed to compile/; match!=/Failed to use installed version/; match!=/command not found/
grep 'GOROOT_BOOTSTRAP=' $GVM_ROOT/tmp-bootstrap/root/logs/go-go1.99.98-compile.log # status=0; match=/GOROOT_BOOTSTRAP=.*tmp-bootstrap\/fake-goroot$/
[ -e $GVM_ROOT/tmp-bootstrap/root/environments/go1.99.98 ] || echo NO-ENV # match=/^NO-ENV$/
[ -d $GVM_ROOT/tmp-bootstrap/root/gos/go1.99.98 ] || echo NO-GOS # match=/^NO-GOS$/

## Cleanup test objects
rm -rf $GVM_ROOT/tmp-bootstrap
