source $GVM_ROOT/scripts/gvm
## Regression test for issue 1: the cd() override must stay cheap when no
## .go-version / .go-pkgset file is present, and must still auto-switch when
## one is. Uses a fake Go version so that no toolchain is needed.
## Cleanup test objects
rm -rf $GVM_ROOT/gos/go0.0.3 $GVM_ROOT/pkgsets/go0.0.3 $GVM_ROOT/environments/go0.0.3 $GVM_ROOT/environments/go0.0.3@cdtest $GVM_ROOT/tmp-cdtest
#######################

mkdir -p $GVM_ROOT/gos/go0.0.3/bin $GVM_ROOT/pkgsets/go0.0.3/global $GVM_ROOT/tmp-cdtest/plain $GVM_ROOT/tmp-cdtest/versioned # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.3"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.3"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.3/global"\nexport PATH; PATH="$GVM_ROOT/gos/go0.0.3/bin:$GVM_ROOT/bin:$PATH"\n' "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.3 # status=0
printf 'go0.0.3\n' > $GVM_ROOT/tmp-cdtest/versioned/.go-version # status=0
printf 'cdtest\n' > $GVM_ROOT/tmp-cdtest/versioned/.go-pkgset # status=0
gvm use go0.0.3 --quiet # status=0
gvm pkgset create cdtest # status=0

## a directory without dot files must not switch anything
gvm use go0.0.3 --quiet # status=0
cd $GVM_ROOT/tmp-cdtest/plain # status=0
echo $gvm_go_name # match=/^go0\.0\.3$/
pwd # match=/tmp-cdtest\/plain$/

## a directory with .go-version and .go-pkgset must switch to them
cd $GVM_ROOT/tmp-cdtest/versioned # status=0; match=/Now using version go0.0.3/; match=/Now using pkgset go0.0.3@cdtest/
echo $gvm_go_name $gvm_pkgset_name # match=/^go0\.0\.3 cdtest$/
pwd # match=/tmp-cdtest\/versioned$/

## 400 cd calls without dot files must take well under 3 seconds (issue 1: master needs ~28s)
GVM_TEST_T0=$SECONDS
for i in $(seq 200); do cd $GVM_ROOT/tmp-cdtest/plain; cd $GVM_ROOT; done # status=0
echo $((SECONDS - GVM_TEST_T0)) # match=/^[0-2]$/
cd $GVM_ROOT # status=0

## Cleanup test objects
gvm uninstall go0.0.3 # status=0
rm -rf $GVM_ROOT/gos/go0.0.3 $GVM_ROOT/pkgsets/go0.0.3 $GVM_ROOT/environments/go0.0.3 $GVM_ROOT/environments/go0.0.3@cdtest $GVM_ROOT/tmp-cdtest
unset GVM_TEST_T0
