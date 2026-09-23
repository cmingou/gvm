source $GVM_ROOT/scripts/gvm
## Regression test for issue 18: bin/gvm ran scripts/gvm-check, which looks
## for bison, gcc, make and binutils, ahead of every command. Those are needed
## only to compile Go from source, yet `gvm list`, `gvm version` and a binary
## install were all refused without them. The toolchain is hidden behind a PATH
## that links to everything else on the system; a fake Go version stands in for
## an installed one so that no toolchain is needed.
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-check-gate $GVM_ROOT/gos/go0.0.10 $GVM_ROOT/pkgsets/go0.0.10 $GVM_ROOT/environments/go0.0.10 $GVM_ROOT/gos/go0.0.11
#######################

mkdir -p $GVM_ROOT/tmp-check-gate/bin $GVM_ROOT/gos/go0.0.10/bin $GVM_ROOT/pkgsets/go0.0.10/global # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.10"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.10"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.10/global"\nexport PATH; PATH="$GVM_ROOT/gos/go0.0.10/bin:$GVM_ROOT/bin:$PATH"\n' "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.10 # status=0
ln -s /usr/bin/* /bin/* /usr/local/bin/* $GVM_ROOT/tmp-check-gate/bin/ 2> /dev/null; true # status=0
rm -f $GVM_ROOT/tmp-check-gate/bin/bison $GVM_ROOT/tmp-check-gate/bin/gcc $GVM_ROOT/tmp-check-gate/bin/cc $GVM_ROOT/tmp-check-gate/bin/make $GVM_ROOT/tmp-check-gate/bin/gmake $GVM_ROOT/tmp-check-gate/bin/ar # status=0
PATH=$GVM_ROOT/tmp-check-gate/bin command -v bison # status!=0
PATH=$GVM_ROOT/tmp-check-gate/bin command -v ls # status=0
gvm use go0.0.10 --quiet # status=0

## read-only commands must run without the C toolchain
PATH=$GVM_ROOT/tmp-check-gate/bin gvm version # status=0; match=/Go Version Manager/; match!=/Missing requirements/
PATH=$GVM_ROOT/tmp-check-gate/bin gvm list # status=0; match=/go0\.0\.10/; match!=/Could not find/
PATH=$GVM_ROOT/tmp-check-gate/bin gvm pkgset list # status=0; match=/global/; match!=/Missing requirements/

## a binary install must not be refused for a missing compiler either: with a
## dead download URL it fails on the download, off the network, and not before
PATH=$GVM_ROOT/tmp-check-gate/bin GO_BINARY_BASE_URL=http://127.0.0.1:1 gvm install go0.0.11 -B # status!=0; match=/Failed to download binary/; match!=/Missing requirements/

## while a build from source must still be refused, before anything is cloned
PATH=$GVM_ROOT/tmp-check-gate/bin gvm install go0.0.11 # status!=0; match=/Could not find bison/; match=/Missing requirements/
ls -d $GVM_ROOT/gos/go0.0.11 # status!=0

## Cleanup test objects
cd $GVM_ROOT # status=0
gvm uninstall go0.0.10 # status=0
rm -rf $GVM_ROOT/tmp-check-gate $GVM_ROOT/gos/go0.0.10 $GVM_ROOT/pkgsets/go0.0.10 $GVM_ROOT/environments/go0.0.10 $GVM_ROOT/gos/go0.0.11
