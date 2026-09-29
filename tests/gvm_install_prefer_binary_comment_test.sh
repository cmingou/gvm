source $GVM_ROOT/scripts/gvm
## Regression test for issue 25: `gvm install --prefer-binary` must fall back
## to a source install when the binary cannot be downloaded or unpacked.
## download_binary answered every failure with `exit 1`, which ends the whole
## scripts/install process, so the `install_go_binary || install_from_source`
## fallback was unreachable and --prefer-binary behaved exactly like -B. The
## install runs against a throwaway copy of the root, with a dead binary base
## URL and a dead source URL (so a real fallback cannot start a clone), and
## against a corrupt archive so that the extraction failure is covered too.
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-prefer-binary
#######################

mkdir -p $GVM_ROOT/tmp-prefer-binary/root/logs $GVM_ROOT/tmp-prefer-binary/root/archive $GVM_ROOT/tmp-prefer-binary/root/environments $GVM_ROOT/tmp-prefer-binary/root/gos # status=0
cp -R $GVM_ROOT/bin $GVM_ROOT/scripts $GVM_ROOT/locales $GVM_ROOT/VERSION $GVM_ROOT/tmp-prefer-binary/root/ # status=0

## a failed download with --prefer-binary must announce the fallback and try
## the source install (which fails here on its dead URL or missing toolchain)
env GVM_ROOT=$GVM_ROOT/tmp-prefer-binary/root GVM_NO_GIT_BAK=1 GO_BINARY_BASE_URL=http://127.0.0.1:1 $GVM_ROOT/tmp-prefer-binary/root/bin/gvm install go1.99.99 --prefer-binary -s=http://127.0.0.1:1/nope 2>&1 # status!=0; match=/Failed to download binary go/; match=/Falling back to source installation of go1\.99\.99/
[ -e $GVM_ROOT/tmp-prefer-binary/root/environments/go1.99.99 ] || echo NO-ENV # match=/^NO-ENV$/

## a failed download with -B must still stop with a failure, without falling
## back, and must not leave a half-made environment behind
env GVM_ROOT=$GVM_ROOT/tmp-prefer-binary/root GVM_NO_GIT_BAK=1 GO_BINARY_BASE_URL=http://127.0.0.1:1 $GVM_ROOT/tmp-prefer-binary/root/bin/gvm install go1.99.99 -B 2>&1 # status!=0; match=/Failed to download binary go/; match!=/Falling back/
[ -e $GVM_ROOT/tmp-prefer-binary/root/environments/go1.99.99 ] || echo NO-ENV # match=/^NO-ENV$/
[ -d $GVM_ROOT/tmp-prefer-binary/root/gos/go1.99.99 ] || echo NO-GOS # match=/^NO-GOS$/

## a corrupt archive: download_binary skips the download when the archive is
## already present, so the failure moves to the extraction, which must fall
## back the same way
for f in linux-amd64 linux-arm64 linux-i386 linux-armv6l linux-ppc64le linux-s390x darwin-amd64 darwin-arm64 darwin-amd64-osx10.8 darwin-amd64-osx10.6; do echo corrupt > $GVM_ROOT/tmp-prefer-binary/root/archive/go1.99.99.$f.tar.gz; done # status=0
env GVM_ROOT=$GVM_ROOT/tmp-prefer-binary/root GVM_NO_GIT_BAK=1 GO_BINARY_BASE_URL=http://127.0.0.1:1 $GVM_ROOT/tmp-prefer-binary/root/bin/gvm install go1.99.99 --prefer-binary -s=http://127.0.0.1:1/nope 2>&1 # status!=0; match=/Failed to extract binary go/; match=/Falling back to source installation of go1\.99\.99/
[ -e $GVM_ROOT/tmp-prefer-binary/root/environments/go1.99.99 ] || echo NO-ENV # match=/^NO-ENV$/

## Cleanup test objects
rm -rf $GVM_ROOT/tmp-prefer-binary
