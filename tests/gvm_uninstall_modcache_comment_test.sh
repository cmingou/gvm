source $GVM_ROOT/scripts/gvm
## Regression test for issue 29: `gvm uninstall` must remove a version whose
## pkgsets contain a Go module cache. Go writes GOPATH/pkg/mod read-only
## (0555 directories, 0444 files), which `rm -rf` cannot remove as a normal
## user, so uninstall aborted with "Couldn't remove pkgsets", left the version
## installed and its pkgset half-deleted. Uses a fake Go version so that no
## toolchain is needed. Note that root ignores file permissions, so the
## uninstall never failed for root and this test only proves something when
## it runs as an unprivileged user, which is what CI does.
## Cleanup test objects
chmod -R u+w $GVM_ROOT/pkgsets/go0.0.8 2> /dev/null; rm -rf $GVM_ROOT/gos/go0.0.8 $GVM_ROOT/pkgsets/go0.0.8 $GVM_ROOT/environments/go0.0.8 $GVM_ROOT/environments/go0.0.8@*
#######################

mkdir -p $GVM_ROOT/gos/go0.0.8/bin $GVM_ROOT/pkgsets/go0.0.8/global/pkg/mod/example.com/dep@v1.0.0 $GVM_ROOT/pkgsets/go0.0.8/global/pkg/mod/cache/download # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.8"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.8"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.8/global"\nexport PATH; PATH="$GVM_ROOT/gos/go0.0.8/bin:$GVM_ROOT/bin:$PATH"\n' "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.8 # status=0
cp $GVM_ROOT/environments/go0.0.8 $GVM_ROOT/environments/go0.0.8@global # status=0
touch $GVM_ROOT/pkgsets/go0.0.8/global/pkg/mod/example.com/dep@v1.0.0/go.mod $GVM_ROOT/pkgsets/go0.0.8/global/pkg/mod/cache/download/list # status=0

## make the module cache read-only, the way `go mod download` leaves it
chmod -R a-w $GVM_ROOT/pkgsets/go0.0.8/global/pkg # status=0
gvm list # match=/go0\.0\.8/

## uninstalling must succeed and leave nothing of the version behind
cd $GVM_ROOT # status=0
gvm uninstall go0.0.8 # status=0; match=/Uninstalled version go0\.0\.8/
ls -d $GVM_ROOT/pkgsets/go0.0.8 # status!=0
ls -d $GVM_ROOT/gos/go0.0.8 # status!=0
ls $GVM_ROOT/environments # match!=/go0\.0\.8/
gvm list # match!=/go0\.0\.8/

## Cleanup test objects
chmod -R u+w $GVM_ROOT/pkgsets/go0.0.8 2> /dev/null; rm -rf $GVM_ROOT/gos/go0.0.8 $GVM_ROOT/pkgsets/go0.0.8 $GVM_ROOT/environments/go0.0.8 $GVM_ROOT/environments/go0.0.8@*
