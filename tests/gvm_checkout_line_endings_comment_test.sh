source $GVM_ROOT/scripts/gvm
## Regression test for issue 22: a clone made with core.autocrlf=true (the
## Git for Windows default, often inherited by a checkout shared with WSL)
## must still produce scripts with LF line endings. Nothing pinned them, so
## every script came out with CRLF and gvm failed with the opaque
## "$'\r': command not found". The repository now pins LF in .gitattributes,
## which git honours on the initial checkout of a clone whatever
## core.autocrlf says. The clones are taken from $GVM_ROOT, which the
## installer leaves as a git checkout under GVM_NO_GIT_BAK=1.
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-crlf
#######################

mkdir -p $GVM_ROOT/tmp-crlf/home # status=0
git -C $GVM_ROOT rev-parse --show-toplevel # status=0
GVM_TEST_REV=$(git -C $GVM_ROOT rev-parse HEAD) # status=0
GVM_TEST_TMP=$(mktemp -d) # status=0
git -C $GVM_TEST_TMP rev-parse --show-toplevel # status!=0

## a plain clone under core.autocrlf=true: no script may carry a CR
git -c core.autocrlf=true clone -q $GVM_ROOT $GVM_ROOT/tmp-crlf/clone # status=0
grep -rlI $'\r' $GVM_ROOT/tmp-crlf/clone/scripts $GVM_ROOT/tmp-crlf/clone/bin $GVM_ROOT/tmp-crlf/clone/binscripts $GVM_ROOT/tmp-crlf/clone/tests | wc -l # match=/^ *0$/
grep -rlI $'\r' $GVM_ROOT/tmp-crlf/clone --exclude-dir=.git | wc -l # match=/^ *0$/
## and the scripts must load from it, in bash and in a shell with no rc
bash --norc -c 'export GVM_ROOT=$1 GVM_NO_GIT_BAK=1; . "$GVM_ROOT/scripts/functions" && . "$GVM_ROOT/scripts/function/_shell_compat" && . "$GVM_ROOT/scripts/function/_shell_compat" && echo LOADED' _ $GVM_ROOT/tmp-crlf/clone 2>&1 # status=0; match=/^LOADED$/; match!=/command not found/

## the installer's own clone, run by a user whose git config sets
## core.autocrlf=true, must produce a working install
printf '[core]\n\tautocrlf = true\n' > $GVM_ROOT/tmp-crlf/home/.gitconfig # status=0
(cd $GVM_TEST_TMP && HOME=$GVM_ROOT/tmp-crlf/home SRC_REPO=$GVM_ROOT GVM_NO_GIT_BAK=1 GVM_NO_UPDATE_PROFILE=1 bash $GVM_ROOT/binscripts/gvm-installer $GVM_TEST_REV $GVM_ROOT/tmp-crlf/dest) 2>&1 # status=0; match=/Installed GVM/; match!=/command not found/
grep -rlI $'\r' $GVM_ROOT/tmp-crlf/dest/gvm/scripts $GVM_ROOT/tmp-crlf/dest/gvm/bin | wc -l # match=/^ *0$/
bash --norc -c 'export GVM_NO_GIT_BAK=1; source "$1/scripts/gvm" > /dev/null 2>&1; gvm version' _ $GVM_ROOT/tmp-crlf/dest/gvm 2>&1 # status=0; match=/Go Version Manager v/; match!=/command not found/

## Cleanup test objects
rm -rf $GVM_ROOT/tmp-crlf $GVM_TEST_TMP
unset GVM_TEST_REV GVM_TEST_TMP
