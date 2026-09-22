source $GVM_ROOT/scripts/gvm
## Regression test for issue 8: the cd() override must return the real cd's
## exit status. It used to fall through to "return 0" after a failed cd, so
## "cd dir && command" ran the command in the wrong directory.
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-cdstatus
#######################

mkdir -p $GVM_ROOT/tmp-cdstatus/exists # status=0
cd $GVM_ROOT # status=0
cd $GVM_ROOT/tmp-cdstatus/does-not-exist # status!=0
pwd # match!=/does-not-exist/
cd $GVM_ROOT/tmp-cdstatus/does-not-exist && echo AND-BRANCH-TAKEN # status!=0; match!=/AND-BRANCH-TAKEN/
cd $GVM_ROOT/tmp-cdstatus/does-not-exist || echo OR-BRANCH-TAKEN # status=0; match=/OR-BRANCH-TAKEN/

## a successful cd must still return 0 and change directory
cd $GVM_ROOT/tmp-cdstatus/exists # status=0
pwd # match=/tmp-cdstatus\/exists$/
cd $GVM_ROOT # status=0

## Cleanup test objects
rm -rf $GVM_ROOT/tmp-cdstatus
