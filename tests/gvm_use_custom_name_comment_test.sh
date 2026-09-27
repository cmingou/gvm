source $GVM_ROOT/scripts/gvm
## Regression test for issue 38: `gvm use` must accept a custom version name
## that contains a digit, dot or hyphen, such as one created with
## `gvm install --name=test-go1.20`. The alias pattern only accepted letters,
## so any other custom name fell through to the pkgset pattern, was stored as
## --pkgset, and `gvm use` gave up with "Please specify the version". Uses
## fake Go versions so that no toolchain is needed.
## Cleanup test objects
rm -rf $GVM_ROOT/gos/test-go0.0.9 $GVM_ROOT/pkgsets/test-go0.0.9 $GVM_ROOT/environments/test-go0.0.9 $GVM_ROOT/environments/test-go0.0.9@* $GVM_ROOT/gos/go0.0.9 $GVM_ROOT/pkgsets/go0.0.9 $GVM_ROOT/environments/go0.0.9 $GVM_ROOT/environments/go0.0.9@*
#######################

mkdir -p $GVM_ROOT/gos/test-go0.0.9/bin $GVM_ROOT/pkgsets/test-go0.0.9/global $GVM_ROOT/gos/go0.0.9/bin $GVM_ROOT/pkgsets/go0.0.9/global # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="test-go0.0.9"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/test-go0.0.9"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/test-go0.0.9/global"\nexport PATH; PATH="$GVM_ROOT/gos/test-go0.0.9/bin:$GVM_ROOT/bin:$PATH"\n' "$GVM_ROOT" > $GVM_ROOT/environments/test-go0.0.9 # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.9"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.9"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.9/global"\nexport PATH; PATH="$GVM_ROOT/gos/go0.0.9/bin:$GVM_ROOT/bin:$PATH"\n' "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.9 # status=0
cd $GVM_ROOT # status=0

## a custom name with a hyphen, digits and dots is a version, not a pkgset
gvm use test-go0.0.9 # status=0; match=/Now using version test-go0\.0\.9/; match!=/Please specify the version/
echo $gvm_go_name # match=/^test-go0\.0\.9$/
echo $GOROOT # match=/\/gos\/test-go0\.0\.9$/
gvm use go0.0.9 --quiet # status=0
gvm use --version test-go0.0.9 --quiet # status=0
echo $gvm_go_name # match=/^test-go0\.0\.9$/

## the custom name combines with a pkgset in both forms
gvm pkgset create set-1 # status=0
gvm use go0.0.9 --quiet # status=0
gvm use test-go0.0.9@set-1 --quiet # status=0
echo $gvm_go_name # match=/^test-go0\.0\.9$/
echo $gvm_pkgset_name # match=/^set-1$/
gvm use go0.0.9 --quiet # status=0
gvm use test-go0.0.9 --pkgset set-1 --quiet # status=0
echo $gvm_go_name # match=/^test-go0\.0\.9$/
echo $gvm_pkgset_name # match=/^set-1$/

## a bare pkgset name after the version is still taken as the pkgset
gvm use go0.0.9 --quiet # status=0
gvm pkgset create set-2 # status=0
gvm use go0.0.9 set-2 --quiet # status=0
echo $gvm_go_name # match=/^go0\.0\.9$/
echo $gvm_pkgset_name # match=/^set-2$/
gvm use go0.0.9 --quiet # status=0
gvm use --pkgset set-2 go0.0.9 --quiet # status=0
echo $gvm_pkgset_name # match=/^set-2$/

## a plain go version is still matched exactly, not by its custom-named twin
gvm use go0.0.9 --quiet # status=0
echo $gvm_go_name # match=/^go0\.0\.9$/
echo $GOROOT # match=/\/gos\/go0\.0\.9$/

## an option flag is still not a version name
gvm use --bogus # status!=0; match=/Unrecognized command line argument/

## Cleanup test objects
cd $GVM_ROOT # status=0
gvm uninstall test-go0.0.9 # status=0
gvm uninstall go0.0.9 # status=0
rm -rf $GVM_ROOT/gos/test-go0.0.9 $GVM_ROOT/pkgsets/test-go0.0.9 $GVM_ROOT/environments/test-go0.0.9 $GVM_ROOT/environments/test-go0.0.9@* $GVM_ROOT/gos/go0.0.9 $GVM_ROOT/pkgsets/go0.0.9 $GVM_ROOT/environments/go0.0.9 $GVM_ROOT/environments/go0.0.9@*
