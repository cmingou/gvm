source $GVM_ROOT/scripts/gvm
## Regression test for issue 24: a failing "gvm get" must leave the git
## metadata in the layout it found it (git.bak, or .git for a GVM_NO_GIT_BAK
## development checkout) so that later gvm commands are not refused.
## When neither exists (a test root without git metadata) a throwaway
## repository is created as git.bak and removed again at the end.
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-getrepo
#######################

[[ -d $GVM_ROOT/.git || -d $GVM_ROOT/git.bak ]] || GVM_TEST_MADE_BAK=1
[[ -z $GVM_TEST_MADE_BAK ]] || git init -q $GVM_ROOT/tmp-getrepo # status=0
[[ -z $GVM_TEST_MADE_BAK ]] || mv $GVM_ROOT/tmp-getrepo/.git $GVM_ROOT/git.bak # status=0
GVM_TEST_LAYOUT=$(ls -d $GVM_ROOT/.git $GVM_ROOT/git.bak 2> /dev/null)
echo $GVM_TEST_LAYOUT # match=/\.git|git\.bak/
gvm get no-such-branch-for-issue-24 # status=1; match=/Failed to checkout no-such-branch-for-issue-24 branch/
[[ "$(ls -d $GVM_ROOT/.git $GVM_ROOT/git.bak 2> /dev/null)" == "$GVM_TEST_LAYOUT" ]] # status=0
gvm version # status=0; match=/Go Version Manager/

## Cleanup test objects
[[ -z $GVM_TEST_MADE_BAK ]] || rm -rf $GVM_ROOT/git.bak $GVM_ROOT/.git
rm -rf $GVM_ROOT/tmp-getrepo
unset GVM_TEST_MADE_BAK GVM_TEST_LAYOUT
