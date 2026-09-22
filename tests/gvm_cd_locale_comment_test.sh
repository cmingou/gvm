## Regression test for issue 6: the cd() override must keep delegating to the
## real cd under a non-English locale. The override used to decide whether cd
## was a builtin by comparing the output of 'type cd' against the English
## message, so under any localized bash __gvm_oldcd was never defined and cd
## silently stopped changing directories while still returning 0.
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-cdlocale
#######################

mkdir -p $GVM_ROOT/tmp-cdlocale # status=0
export LC_ALL=de_DE.UTF-8
builtin cd /tmp # status=0
source $GVM_ROOT/scripts/gvm # status=0
builtin type cd # status=0
declare -f __gvm_oldcd > /dev/null # status=0
cd $GVM_ROOT/tmp-cdlocale # status=0
pwd # match=/tmp-cdlocale$/
cd $GVM_ROOT # status=0
pwd # match!=/tmp-cdlocale$/
unset LC_ALL

## the English locale must keep working too
export LC_ALL=C
source $GVM_ROOT/scripts/gvm # status=0
cd $GVM_ROOT/tmp-cdlocale # status=0
pwd # match=/tmp-cdlocale$/
cd $GVM_ROOT # status=0
unset LC_ALL

## Cleanup test objects
rm -rf $GVM_ROOT/tmp-cdlocale
