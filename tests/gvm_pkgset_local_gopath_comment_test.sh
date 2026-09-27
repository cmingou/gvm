source $GVM_ROOT/scripts/gvm
## Regression test for issue 35: a local pkgset must not put the project root
## itself into GOPATH. `gvm pkgset create --local` wrote the project directory
## as the first GOPATH entry, ahead of <project>/.gvm_local/pkgsets/<version>/local,
## so with a go.mod in the project every go command warned
## "ignoring go.mod in $GOPATH" (a hard error on go1.13 to go1.16). Uses a
## fake Go version so that no toolchain is needed.
## Cleanup test objects
rm -rf $GVM_ROOT/gos/go0.0.10 $GVM_ROOT/pkgsets/go0.0.10 $GVM_ROOT/environments/go0.0.10 $GVM_ROOT/environments/go0.0.10@* $GVM_ROOT/tmp-pkgset-gopath
#######################

mkdir -p $GVM_ROOT/gos/go0.0.10/bin $GVM_ROOT/pkgsets/go0.0.10/global $GVM_ROOT/tmp-pkgset-gopath/proj # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.10"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.10"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.10/global"\nexport PATH; PATH="$GVM_ROOT/gos/go0.0.10/bin:$GVM_ROOT/bin:$PATH"\n' "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.10 # status=0
printf 'module example.com/proj\n' > $GVM_ROOT/tmp-pkgset-gopath/proj/go.mod # status=0
gvm use go0.0.10 --quiet # status=0
cd $GVM_ROOT/tmp-pkgset-gopath/proj # status=0
gvm pkgset create --local # status=0

## the environment file must start GOPATH with the local pkgset, not the project
grep 'GOPATH=' $GVM_ROOT/tmp-pkgset-gopath/proj/.gvm_local/environments/go0.0.10@local # status=0; match=/GOPATH="[^":]*\/tmp-pkgset-gopath\/proj\/\.gvm_local\/pkgsets\/go0\.0\.10\/local:/; match!=/GOPATH="[^"]*\/tmp-pkgset-gopath\/proj:/

## and the GOPATH in effect after `gvm pkgset use --local` must not contain the project root
gvm pkgset use --local --quiet # status=0
echo $gvm_pkgset_name # match=/^__local__$/
echo "${GOPATH%%:*}" # match=/\/tmp-pkgset-gopath\/proj\/\.gvm_local\/pkgsets\/go0\.0\.10\/local$/
echo ":$GOPATH:" # match!=/:[^:]*\/tmp-pkgset-gopath\/proj:/

## the project's own bin directory stays on PATH, as before
echo ":$PATH:" # match=/:[^:]*\/tmp-pkgset-gopath\/proj\/bin:/

## Cleanup test objects
cd $GVM_ROOT # status=0
gvm uninstall go0.0.10 # status=0
rm -rf $GVM_ROOT/gos/go0.0.10 $GVM_ROOT/pkgsets/go0.0.10 $GVM_ROOT/environments/go0.0.10 $GVM_ROOT/environments/go0.0.10@* $GVM_ROOT/tmp-pkgset-gopath
