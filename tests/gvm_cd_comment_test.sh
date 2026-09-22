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

## A cd without dot files must not re-resolve the fallback (issue 49).
## Deterministic rather than timed: the old assertion hard-coded "400 cd calls
## in under 3 seconds", which held on the machine that wrote it and failed on a
## macOS runner, where the fallback costs ~325ms per cd because a fork is ~90ms.
## Counting the calls tests the property itself and does not depend on how fast
## the machine is. The fallback branch only runs when neither a default nor a
## system environment file exists, so both are moved aside for this part.
mv $GVM_ROOT/environments/default $GVM_ROOT/environments/default.cdtestbak 2> /dev/null; true # status=0
mv $GVM_ROOT/environments/system $GVM_ROOT/environments/system.cdtestbak 2> /dev/null; true # status=0
## The counter is a file: cd() calls the resolver inside a command
## substitution, so a variable incremented there would not survive the subshell.
rm -f $GVM_ROOT/tmp-cdtest/calls # status=0
__gvm_resolve_fallback_version() { echo call >> "$GVM_ROOT/tmp-cdtest/calls"; echo "go0.0.3"; }
cd $GVM_ROOT/tmp-cdtest/plain # status=0
cd $GVM_ROOT # status=0
cd $GVM_ROOT/tmp-cdtest/plain # status=0
cd $GVM_ROOT # status=0
echo $(wc -l < $GVM_ROOT/tmp-cdtest/calls) # match=/^1$/
unset -f __gvm_resolve_fallback_version
rm -f $GVM_ROOT/tmp-cdtest/calls # status=0
mv $GVM_ROOT/environments/default.cdtestbak $GVM_ROOT/environments/default 2> /dev/null; true # status=0
mv $GVM_ROOT/environments/system.cdtestbak $GVM_ROOT/environments/system 2> /dev/null; true # status=0

## and 400 cd calls must still finish in single-digit seconds on any machine,
## which a fork-per-cd regression (~1400 forks) does not.
GVM_TEST_T0=$SECONDS
for i in $(seq 200); do cd $GVM_ROOT/tmp-cdtest/plain; cd $GVM_ROOT; done # status=0
echo $((SECONDS - GVM_TEST_T0)) # match=/^[0-9]$/
cd $GVM_ROOT # status=0

## Cleanup test objects
gvm uninstall go0.0.3 # status=0
rm -rf $GVM_ROOT/gos/go0.0.3 $GVM_ROOT/pkgsets/go0.0.3 $GVM_ROOT/environments/go0.0.3 $GVM_ROOT/environments/go0.0.3@cdtest $GVM_ROOT/tmp-cdtest
unset GVM_TEST_T0
