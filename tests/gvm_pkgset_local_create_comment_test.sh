source $GVM_ROOT/scripts/gvm
## Regression test for issue 33: `gvm pkgset create --local` must write the
## whole local pkgset, overlay block included, under <project>/.gvm_local and
## nothing into $GVM_ROOT. It used to write the overlay block into $GVM_ROOT,
## which created a phantom global pkgset named "local" and left the real local
## environment without its overlay. It also tested `-d LOCAL_TOP` (a literal,
## missing its $), so an existing .gvm_local above the current directory was
## never found. Uses a fake Go version so that no toolchain is needed.
## Cleanup test objects
rm -rf $GVM_ROOT/gos/go0.0.5 $GVM_ROOT/pkgsets/go0.0.5 $GVM_ROOT/environments/go0.0.5 $GVM_ROOT/environments/go0.0.5@* $GVM_ROOT/tmp-pkgset-local
#######################

mkdir -p $GVM_ROOT/gos/go0.0.5/bin $GVM_ROOT/pkgsets/go0.0.5/global $GVM_ROOT/tmp-pkgset-local/proj/sub # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.5"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.5"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.5/global"\nexport PATH; PATH="$GVM_ROOT/gos/go0.0.5/bin:$GVM_ROOT/bin:$PATH"\n' "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.5 # status=0
gvm use go0.0.5 --quiet # status=0
cd $GVM_ROOT/tmp-pkgset-local/proj # status=0
gvm pkgset create --local # status=0

## the local pkgset, with its overlay, must live under the project's .gvm_local
ls $GVM_ROOT/tmp-pkgset-local/proj/.gvm_local/environments # match=/^go0\.0\.5@local$/
grep -c 'GVM_OVERLAY_PREFIX' $GVM_ROOT/tmp-pkgset-local/proj/.gvm_local/environments/go0.0.5@local # status=0; match=/^[1-9]/
grep 'GVM_OVERLAY_PREFIX=' $GVM_ROOT/tmp-pkgset-local/proj/.gvm_local/environments/go0.0.5@local # match=/tmp-pkgset-local\/proj\/\.gvm_local\/pkgsets\/go0\.0\.5\/local\/overlay/
ls -d $GVM_ROOT/tmp-pkgset-local/proj/.gvm_local/pkgsets/go0.0.5/local/overlay/bin # status=0
ls -d $GVM_ROOT/tmp-pkgset-local/proj/.gvm_local/pkgsets/go0.0.5/local/overlay/lib/pkgconfig # status=0

## and nothing may have been written into $GVM_ROOT
ls $GVM_ROOT/environments # match!=/go0\.0\.5@local/
ls $GVM_ROOT/pkgsets/go0.0.5 # match!=/^local$/
gvm pkgset list # status=0; match=/L .*tmp-pkgset-local\/proj$/; match!=/^ +local$/

## the local pkgset must still be usable
gvm pkgset use --local --quiet # status=0
echo $gvm_pkgset_name # match=/^__local__$/
echo $GVM_OVERLAY_PREFIX # match=/tmp-pkgset-local\/proj\/\.gvm_local\/pkgsets\/go0\.0\.5\/local\/overlay$/

## from a subdirectory the existing .gvm_local above must be found, not a new one created
gvm use go0.0.5 --quiet # status=0
cd $GVM_ROOT/tmp-pkgset-local/proj/sub # status=0
gvm pkgset create --local # status!=0; match=/already exists/
ls -d $GVM_ROOT/tmp-pkgset-local/proj/sub/.gvm_local # status!=0

## a standard pkgset must be unaffected and keep its overlay under $GVM_ROOT
gvm pkgset create localtest # status=0
grep 'GVM_OVERLAY_PREFIX=' $GVM_ROOT/environments/go0.0.5@localtest # match=/\$\{GVM_ROOT\}\/pkgsets\/go0\.0\.5\/localtest\/overlay/
ls -d $GVM_ROOT/pkgsets/go0.0.5/localtest/overlay/bin # status=0

## Cleanup test objects
cd $GVM_ROOT # status=0
gvm uninstall go0.0.5 # status=0
rm -rf $GVM_ROOT/gos/go0.0.5 $GVM_ROOT/pkgsets/go0.0.5 $GVM_ROOT/environments/go0.0.5 $GVM_ROOT/environments/go0.0.5@* $GVM_ROOT/tmp-pkgset-local
