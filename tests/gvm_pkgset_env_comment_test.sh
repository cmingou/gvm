source $GVM_ROOT/scripts/gvm
## Regression test for issue 36: a pkgset environment must follow the version
## environment it was created from. `gvm pkgset create` used to copy the
## version environment into the pkgset file, so an edit made later through a
## bare `gvm pkgenv` (which opens the version environment) was honoured by
## `gvm use` and silently discarded by `gvm pkgset use`. Uses a fake Go version
## so that no toolchain is needed.
## Cleanup test objects
rm -rf $GVM_ROOT/gos/go0.0.8 $GVM_ROOT/pkgsets/go0.0.8 $GVM_ROOT/environments/go0.0.8 $GVM_ROOT/environments/go0.0.8@* $GVM_ROOT/tmp-pkgset-env
#######################

mkdir -p $GVM_ROOT/gos/go0.0.8/bin $GVM_ROOT/pkgsets/go0.0.8/global $GVM_ROOT/tmp-pkgset-env # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.8"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.8"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.8/global"\nexport PATH; PATH="$GVM_ROOT/gos/go0.0.8/bin:$GVM_ROOT/bin:$PATH"\n' "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.8 # status=0
## a stand-in for the user's editor: it appends a GOPATH override to whatever
## file `gvm pkgenv` hands it
echo 'echo "export GOPATH; GOPATH=\"$GVM_ROOT/tmp-pkgset-env/edited-gopath\"" >> "$1"' > $GVM_ROOT/tmp-pkgset-env/editor.sh # status=0
gvm use go0.0.8 --quiet # status=0
gvm pkgset create envtest # status=0

## editing the version environment through a bare `gvm pkgenv`
EDITOR="sh $GVM_ROOT/tmp-pkgset-env/editor.sh" gvm pkgenv # status=0
grep -c 'edited-gopath' $GVM_ROOT/environments/go0.0.8 # match=/^1$/

## must be honoured by `gvm use`
gvm use go0.0.8 --quiet # status=0
echo $GOPATH # match=/tmp-pkgset-env\/edited-gopath$/

## and equally by `gvm pkgset use` of a pkgset created before the edit
gvm pkgset use envtest --quiet # status=0
echo $gvm_go_name $gvm_pkgset_name # match=/^go0\.0\.8 envtest$/
echo $GOPATH # match=/^.*\/pkgsets\/go0\.0\.8\/envtest:.*tmp-pkgset-env\/edited-gopath$/
echo $GOROOT # match=/\/gos\/go0\.0\.8$/

## and by the combined form
gvm use go0.0.8 --quiet # status=0
gvm use go0.0.8@envtest --quiet # status=0
echo $GOPATH # match=/tmp-pkgset-env\/edited-gopath$/

## the pkgset can still be made the default and loaded by a fresh shell
## (an existing default is moved aside for this part and restored below)
mv $GVM_ROOT/environments/default $GVM_ROOT/environments/default.envtestbak 2> /dev/null; true # status=0
gvm pkgset use envtest --default --quiet # status=0
bash --norc --noprofile -c 'export GVM_NO_GIT_BAK=1; source "$GVM_ROOT/scripts/gvm" > /dev/null 2>&1; echo "$gvm_go_name $gvm_pkgset_name $GOPATH"' # status=0; match=/^go0\.0\.8 envtest .*\/pkgsets\/go0\.0\.8\/envtest:.*tmp-pkgset-env\/edited-gopath$/

## and cd() still reads the version and pkgset name from the default
gvm use go0.0.8 --quiet # status=0
GVM_DEBUG=1 cd $GVM_ROOT/tmp-pkgset-env # status=0; match=/Resolved default go: go0\.0\.8/; match=/Resolved default pkgset: envtest/
cd $GVM_ROOT # status=0

## Cleanup test objects
rm -f $GVM_ROOT/environments/default # status=0
mv $GVM_ROOT/environments/default.envtestbak $GVM_ROOT/environments/default 2> /dev/null; true # status=0
gvm uninstall go0.0.8 # status=0
rm -rf $GVM_ROOT/gos/go0.0.8 $GVM_ROOT/pkgsets/go0.0.8 $GVM_ROOT/environments/go0.0.8 $GVM_ROOT/environments/go0.0.8@* $GVM_ROOT/tmp-pkgset-env
