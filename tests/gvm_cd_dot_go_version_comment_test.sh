source $GVM_ROOT/scripts/gvm
## Regression test for issue 10: a .go-version file that holds no usable
## version must not turn cd() into a failure. The empty result of the file
## read used to be passed on as `gvm use ""`, which printed "Unrecognized
## command line argument: ''" and made cd return 1 although the directory
## change had already succeeded. The bare "1.22" form that goenv, asdf and
## Go's own toolchain directive write is accepted as well. Uses fake Go
## versions so that no toolchain is needed.
## Cleanup test objects
rm -rf $GVM_ROOT/gos/go0.0.14 $GVM_ROOT/gos/go0.0.15 $GVM_ROOT/pkgsets/go0.0.14 $GVM_ROOT/pkgsets/go0.0.15 $GVM_ROOT/environments/go0.0.14 $GVM_ROOT/environments/go0.0.14@* $GVM_ROOT/environments/go0.0.15 $GVM_ROOT/tmp-cd-dotver
#######################

mkdir -p $GVM_ROOT/gos/go0.0.14/bin $GVM_ROOT/gos/go0.0.15/bin $GVM_ROOT/pkgsets/go0.0.14/global $GVM_ROOT/pkgsets/go0.0.15/global $GVM_ROOT/tmp-cd-dotver/garbage $GVM_ROOT/tmp-cd-dotver/bare $GVM_ROOT/tmp-cd-dotver/comments # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.14"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.14"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.14/global"\nexport PATH; PATH="$GVM_ROOT/gos/go0.0.14/bin:$GVM_ROOT/bin:$PATH"\n' "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.14 # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.15"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.15"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.15/global"\nexport PATH; PATH="$GVM_ROOT/gos/go0.0.15/bin:$GVM_ROOT/bin:$PATH"\n' "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.15 # status=0
printf 'not a version\n' > $GVM_ROOT/tmp-cd-dotver/garbage/.go-version # status=0
printf 'dotver\n' > $GVM_ROOT/tmp-cd-dotver/garbage/.go-pkgset # status=0
printf '0.0.15\n' > $GVM_ROOT/tmp-cd-dotver/bare/.go-version # status=0
printf '\n' > $GVM_ROOT/tmp-cd-dotver/comments/.go-version # status=0
gvm use go0.0.14 --quiet # status=0
gvm pkgset create dotver # status=0
gvm use go0.0.14 --quiet # status=0

## a .go-version without a usable version is reported and otherwise ignored:
## cd succeeds, the directory changes, and the current version is kept
cd $GVM_ROOT/tmp-cd-dotver/garbage # status=0; match=/Ignoring .*garbage\/\.go-version/; match!=/Unrecognized command line argument/
pwd # match=/tmp-cd-dotver\/garbage$/
echo $gvm_go_name # match=/^go0\.0\.14$/
cd $GVM_ROOT # status=0
cd $GVM_ROOT/tmp-cd-dotver/garbage && echo AND-BRANCH-TAKEN # status=0; match=/AND-BRANCH-TAKEN/

## and the .go-pkgset next to it still applies
echo $gvm_pkgset_name # match=/^dotver$/
cd $GVM_ROOT # status=0
gvm use go0.0.14 --quiet # status=0

## a file with only an empty line is treated the same way
cd $GVM_ROOT/tmp-cd-dotver/comments # status=0; match=/Ignoring/
echo $gvm_go_name # match=/^go0\.0\.14$/
cd $GVM_ROOT # status=0

## the bare form without the "go" prefix selects the matching version
cd $GVM_ROOT/tmp-cd-dotver/bare # status=0; match=/Now using version go0.0.15/
echo $gvm_go_name # match=/^go0\.0\.15$/
cd $GVM_ROOT # status=0

## Cleanup test objects
gvm uninstall go0.0.14 # status=0
gvm uninstall go0.0.15 # status=0
rm -rf $GVM_ROOT/gos/go0.0.14 $GVM_ROOT/gos/go0.0.15 $GVM_ROOT/pkgsets/go0.0.14 $GVM_ROOT/pkgsets/go0.0.15 $GVM_ROOT/environments/go0.0.14 $GVM_ROOT/environments/go0.0.14@* $GVM_ROOT/environments/go0.0.15 $GVM_ROOT/tmp-cd-dotver
