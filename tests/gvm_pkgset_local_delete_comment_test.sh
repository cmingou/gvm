source $GVM_ROOT/scripts/gvm
## Regression test for issue 34: `gvm pkgset delete --local` must leave no
## trace of the deleted pkgset. It removed only the pkgset directory and the
## environment file and left the <project>/.gvm_local skeleton behind, so
## `gvm pkgset list` still listed the project as a local pkgset, marked
## current, and its output was byte-identical before and after the delete.
## Uses fake Go versions so that no toolchain is needed.
## Cleanup test objects
rm -rf $GVM_ROOT/gos/go0.0.6 $GVM_ROOT/pkgsets/go0.0.6 $GVM_ROOT/environments/go0.0.6 $GVM_ROOT/environments/go0.0.6@* $GVM_ROOT/gos/go0.0.7 $GVM_ROOT/pkgsets/go0.0.7 $GVM_ROOT/environments/go0.0.7 $GVM_ROOT/environments/go0.0.7@* $GVM_ROOT/tmp-pkgset-delete
#######################

mkdir -p $GVM_ROOT/gos/go0.0.6/bin $GVM_ROOT/pkgsets/go0.0.6/global $GVM_ROOT/gos/go0.0.7/bin $GVM_ROOT/pkgsets/go0.0.7/global $GVM_ROOT/tmp-pkgset-delete/proj # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.6"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.6"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.6/global"\nexport PATH; PATH="$GVM_ROOT/gos/go0.0.6/bin:$GVM_ROOT/bin:$PATH"\n' "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.6 # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.7"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.7"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.7/global"\nexport PATH; PATH="$GVM_ROOT/gos/go0.0.7/bin:$GVM_ROOT/bin:$PATH"\n' "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.7 # status=0
cd $GVM_ROOT/tmp-pkgset-delete/proj # status=0
gvm use go0.0.6 --quiet # status=0
gvm pkgset create --local # status=0
gvm pkgset list # status=0; match=/L .*tmp-pkgset-delete\/proj$/

## deleting the only local pkgset must remove the .gvm_local skeleton with it
gvm pkgset delete --local # status=0
ls -d $GVM_ROOT/tmp-pkgset-delete/proj/.gvm_local # status!=0
gvm pkgset list # status=0; match!=/L .*tmp-pkgset-delete/
ls $GVM_ROOT/tmp-pkgset-delete/proj # match!=/gvm_local/

## deleting it again must fail, as for any pkgset that does not exist
gvm pkgset delete --local # status!=0; match=/doesn't exist/

## a local pkgset of another Go version in the same project must survive the delete
gvm use go0.0.6 --quiet # status=0
gvm pkgset create --local # status=0
gvm use go0.0.7 --quiet # status=0
gvm pkgset create --local # status=0
gvm pkgset delete --local # status=0
ls $GVM_ROOT/tmp-pkgset-delete/proj/.gvm_local/environments # match=/^go0\.0\.6@local$/; match!=/go0\.0\.7/
ls $GVM_ROOT/tmp-pkgset-delete/proj/.gvm_local/pkgsets # match=/^go0\.0\.6$/; match!=/go0\.0\.7/
gvm use go0.0.6 --quiet # status=0
gvm pkgset list # status=0; match=/L .*tmp-pkgset-delete\/proj$/
gvm pkgset use --local --quiet # status=0
echo $gvm_pkgset_name # match=/^__local__$/

## and once the last one goes, so does the skeleton
gvm pkgset delete --local # status=0
ls -d $GVM_ROOT/tmp-pkgset-delete/proj/.gvm_local # status!=0

## a standard pkgset delete must be unaffected
gvm use go0.0.6 --quiet # status=0
gvm pkgset create deltest # status=0
gvm pkgset delete deltest # status=0
ls $GVM_ROOT/pkgsets/go0.0.6 # match!=/deltest/
ls -d $GVM_ROOT/pkgsets/go0.0.6/global # status=0

## Cleanup test objects
cd $GVM_ROOT # status=0
gvm uninstall go0.0.6 # status=0
gvm uninstall go0.0.7 # status=0
rm -rf $GVM_ROOT/gos/go0.0.6 $GVM_ROOT/pkgsets/go0.0.6 $GVM_ROOT/environments/go0.0.6 $GVM_ROOT/environments/go0.0.6@* $GVM_ROOT/gos/go0.0.7 $GVM_ROOT/pkgsets/go0.0.7 $GVM_ROOT/environments/go0.0.7 $GVM_ROOT/environments/go0.0.7@* $GVM_ROOT/tmp-pkgset-delete
