source $GVM_ROOT/scripts/gvm
## Regression test for issue 26: a binary install of a release before go1.4.3
## on macOS needs the -osx10.6 or -osx10.8 suffix in the archive name, and
## download_binary assigned it only when the macOS major version was 10. On
## macOS 11 and later the suffix stayed empty, so `gvm install go1.4 -B`, the
## bootstrap the README asks for, requested a URL that does not exist while
## the right one does. And on Apple Silicon no release before go1.16 has a
## darwin/arm64 archive at all, which surfaced only as the generic "Failed to
## download binary go". The install runs against a throwaway copy of the root
## with a fake uname, sw_vers and curl on PATH: curl records the URL it was
## asked for and fails, so nothing is downloaded. Shebangs are spelled \043
## because a literal # would end the tf command.
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-darwin-binary
#######################

mkdir -p $GVM_ROOT/tmp-darwin-binary/root/logs $GVM_ROOT/tmp-darwin-binary/root/archive $GVM_ROOT/tmp-darwin-binary/root/environments $GVM_ROOT/tmp-darwin-binary/root/gos $GVM_ROOT/tmp-darwin-binary/bin # status=0
cp -R $GVM_ROOT/bin $GVM_ROOT/scripts $GVM_ROOT/locales $GVM_ROOT/VERSION $GVM_ROOT/tmp-darwin-binary/root/ # status=0

## the fakes: uname answers Darwin and the architecture in FAKE_ARCH, sw_vers
## the macOS version in FAKE_MACOS, and curl appends its arguments to
## FAKE_CURL_LOG and fails with curl's own "HTTP error" status
printf '\043!/bin/sh\ncase "$1" in -m) echo "${FAKE_ARCH:-x86_64}" ;; *) echo Darwin ;; esac\n' > $GVM_ROOT/tmp-darwin-binary/bin/uname # status=0
printf '\043!/bin/sh\necho "${FAKE_MACOS:-14.5}"\n' > $GVM_ROOT/tmp-darwin-binary/bin/sw_vers # status=0
printf '\043!/bin/sh\necho "$@" >> "$FAKE_CURL_LOG"\nexit 22\n' > $GVM_ROOT/tmp-darwin-binary/bin/curl # status=0
chmod +x $GVM_ROOT/tmp-darwin-binary/bin/uname $GVM_ROOT/tmp-darwin-binary/bin/sw_vers $GVM_ROOT/tmp-darwin-binary/bin/curl # status=0
PATH=$GVM_ROOT/tmp-darwin-binary/bin:$PATH uname # match=/^Darwin$/
PATH=$GVM_ROOT/tmp-darwin-binary/bin:$PATH FAKE_ARCH=arm64 uname -m # match=/^arm64$/

## macOS 14 on Intel: go1.4 must be requested as the -osx10.8 build
rm -f $GVM_ROOT/tmp-darwin-binary/curl.log # status=0
env PATH=$GVM_ROOT/tmp-darwin-binary/bin:$PATH GVM_ROOT=$GVM_ROOT/tmp-darwin-binary/root GVM_NO_GIT_BAK=1 FAKE_MACOS=14.5 FAKE_ARCH=x86_64 FAKE_CURL_LOG=$GVM_ROOT/tmp-darwin-binary/curl.log $GVM_ROOT/tmp-darwin-binary/root/bin/gvm install go1.4 -B 2>&1 # status!=0; match=/Failed to download binary go/
cat $GVM_ROOT/tmp-darwin-binary/curl.log # match=/\/go1\.4\.darwin-amd64-osx10\.8\.tar\.gz/; match!=/go1\.4\.darwin-amd64\.tar\.gz/

## macOS 11 (the first major after 10) likewise
rm -f $GVM_ROOT/tmp-darwin-binary/curl.log # status=0
env PATH=$GVM_ROOT/tmp-darwin-binary/bin:$PATH GVM_ROOT=$GVM_ROOT/tmp-darwin-binary/root GVM_NO_GIT_BAK=1 FAKE_MACOS=11.0.1 FAKE_ARCH=x86_64 FAKE_CURL_LOG=$GVM_ROOT/tmp-darwin-binary/curl.log $GVM_ROOT/tmp-darwin-binary/root/bin/gvm install go1.4.2 -B 2>&1 # status!=0; match=/Failed to download binary go/
cat $GVM_ROOT/tmp-darwin-binary/curl.log # match=/\/go1\.4\.2\.darwin-amd64-osx10\.8\.tar\.gz/

## the 10.x cases that already worked must keep working: 10.9 takes the 10.8
## build and 10.7 the 10.6 build
rm -f $GVM_ROOT/tmp-darwin-binary/curl.log # status=0
env PATH=$GVM_ROOT/tmp-darwin-binary/bin:$PATH GVM_ROOT=$GVM_ROOT/tmp-darwin-binary/root GVM_NO_GIT_BAK=1 FAKE_MACOS=10.9.5 FAKE_ARCH=x86_64 FAKE_CURL_LOG=$GVM_ROOT/tmp-darwin-binary/curl.log $GVM_ROOT/tmp-darwin-binary/root/bin/gvm install go1.4 -B 2>&1 # status!=0; match=/Failed to download binary go/
cat $GVM_ROOT/tmp-darwin-binary/curl.log # match=/\/go1\.4\.darwin-amd64-osx10\.8\.tar\.gz/
rm -f $GVM_ROOT/tmp-darwin-binary/curl.log # status=0
env PATH=$GVM_ROOT/tmp-darwin-binary/bin:$PATH GVM_ROOT=$GVM_ROOT/tmp-darwin-binary/root GVM_NO_GIT_BAK=1 FAKE_MACOS=10.7.5 FAKE_ARCH=x86_64 FAKE_CURL_LOG=$GVM_ROOT/tmp-darwin-binary/curl.log $GVM_ROOT/tmp-darwin-binary/root/bin/gvm install go1.4 -B 2>&1 # status!=0; match=/Failed to download binary go/
cat $GVM_ROOT/tmp-darwin-binary/curl.log # match=/\/go1\.4\.darwin-amd64-osx10\.6\.tar\.gz/

## from go1.4.3 on there is no suffix, on any macOS
rm -f $GVM_ROOT/tmp-darwin-binary/curl.log # status=0
env PATH=$GVM_ROOT/tmp-darwin-binary/bin:$PATH GVM_ROOT=$GVM_ROOT/tmp-darwin-binary/root GVM_NO_GIT_BAK=1 FAKE_MACOS=14.5 FAKE_ARCH=x86_64 FAKE_CURL_LOG=$GVM_ROOT/tmp-darwin-binary/curl.log $GVM_ROOT/tmp-darwin-binary/root/bin/gvm install go1.5 -B 2>&1 # status!=0; match=/Failed to download binary go/
cat $GVM_ROOT/tmp-darwin-binary/curl.log # match=/\/go1\.5\.darwin-amd64\.tar\.gz/; match!=/osx10/

## Apple Silicon: a release before go1.16 must be refused with an explanation
## before anything is requested, and must not leave a version directory behind
rm -f $GVM_ROOT/tmp-darwin-binary/curl.log # status=0
env PATH=$GVM_ROOT/tmp-darwin-binary/bin:$PATH GVM_ROOT=$GVM_ROOT/tmp-darwin-binary/root GVM_NO_GIT_BAK=1 FAKE_MACOS=14.5 FAKE_ARCH=arm64 FAKE_CURL_LOG=$GVM_ROOT/tmp-darwin-binary/curl.log $GVM_ROOT/tmp-darwin-binary/root/bin/gvm install go1.4 -B 2>&1 # status!=0; match=/darwin\/arm64/; match=/before go1\.16/; match=/gvm install go1\.16 -B/; match!=/Failed to download binary go/
[ -e $GVM_ROOT/tmp-darwin-binary/curl.log ] || echo NO-DOWNLOAD # match=/^NO-DOWNLOAD$/
[ -d $GVM_ROOT/tmp-darwin-binary/root/gos/go1.4 ] || echo NO-GOS # match=/^NO-GOS$/

## with --prefer-binary the refusal must still fall back to a source build
## (which fails here on its dead source URL or missing toolchain)
env PATH=$GVM_ROOT/tmp-darwin-binary/bin:$PATH GVM_ROOT=$GVM_ROOT/tmp-darwin-binary/root GVM_NO_GIT_BAK=1 FAKE_MACOS=14.5 FAKE_ARCH=arm64 FAKE_CURL_LOG=$GVM_ROOT/tmp-darwin-binary/curl.log $GVM_ROOT/tmp-darwin-binary/root/bin/gvm install go1.4 --prefer-binary -s=http://127.0.0.1:1/nope 2>&1 # status!=0; match=/darwin\/arm64/; match=/Falling back to source installation of go1\.4/

## go1.16 and later are requested as darwin-arm64 archives
rm -f $GVM_ROOT/tmp-darwin-binary/curl.log # status=0
env PATH=$GVM_ROOT/tmp-darwin-binary/bin:$PATH GVM_ROOT=$GVM_ROOT/tmp-darwin-binary/root GVM_NO_GIT_BAK=1 FAKE_MACOS=14.5 FAKE_ARCH=arm64 FAKE_CURL_LOG=$GVM_ROOT/tmp-darwin-binary/curl.log $GVM_ROOT/tmp-darwin-binary/root/bin/gvm install go1.16 -B 2>&1 # status!=0; match=/Failed to download binary go/; match!=/before go1\.16/
cat $GVM_ROOT/tmp-darwin-binary/curl.log # match=/\/go1\.16\.darwin-arm64\.tar\.gz/

## Cleanup test objects
rm -rf $GVM_ROOT/tmp-darwin-binary
