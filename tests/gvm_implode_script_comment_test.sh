source $GVM_ROOT/scripts/gvm
## Regression test for issue 32: `bin/gvm implode`, run as a script rather
## than through the gvm shell function, must actually implode and must report
## failure with a non-zero status. gvm_implode lives in scripts/env/implode,
## which only the shell function loaded, so the script failed with
## "gvm_implode: command not found" and its hardcoded `exit 0` reported
## success while nothing happened. The script runs against a throwaway copy of
## the root, so the suite's own root survives.
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-implode $GVM_ROOT/tmp-implode-bin
#######################

mkdir -p $GVM_ROOT/tmp-implode $GVM_ROOT/tmp-implode-bin # status=0
cp -R $GVM_ROOT/bin $GVM_ROOT/scripts $GVM_ROOT/locales $GVM_ROOT/VERSION $GVM_ROOT/tmp-implode/ # status=0

## answering no must cancel, without a "command not found"
echo n | env GVM_ROOT=$GVM_ROOT/tmp-implode GVM_NO_GIT_BAK=1 $GVM_ROOT/tmp-implode/bin/gvm implode 2>&1 # status=0; match=/Action cancelled/; match!=/command not found/
[ -d $GVM_ROOT/tmp-implode/scripts ] && echo STILL-THERE # match=/^STILL-THERE$/

## a failed removal must be reported and must not exit 0: rm is shadowed on
## PATH by one that always fails (no shebang line: tf reads a hash as the start
## of its assertions)
printf 'exit 1\n' > $GVM_ROOT/tmp-implode-bin/rm # status=0
chmod +x $GVM_ROOT/tmp-implode-bin/rm # status=0
echo y | env PATH="$GVM_ROOT/tmp-implode-bin:$PATH" GVM_ROOT=$GVM_ROOT/tmp-implode GVM_NO_GIT_BAK=1 $GVM_ROOT/tmp-implode/bin/gvm implode 2>&1 # status!=0; match=/Failed to uninstall gvm/; match!=/command not found/
[ -d $GVM_ROOT/tmp-implode/scripts ] && echo STILL-THERE # match=/^STILL-THERE$/

## answering yes must remove the root and report success
echo y | env GVM_ROOT=$GVM_ROOT/tmp-implode GVM_NO_GIT_BAK=1 $GVM_ROOT/tmp-implode/bin/gvm implode 2>&1 # status=0; match=/GVM successfully removed/; match!=/command not found/
[ -d $GVM_ROOT/tmp-implode ] || echo GONE # match=/^GONE$/

## Cleanup test objects
rm -rf $GVM_ROOT/tmp-implode $GVM_ROOT/tmp-implode-bin
