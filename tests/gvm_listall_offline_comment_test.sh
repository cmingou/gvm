source $GVM_ROOT/scripts/gvm
## Regression test for issue 19: `gvm listall` sorted its output with a bare
## `sort -V` rather than the $SORT_PATH every other sort goes through, with no
## check that the sort on PATH takes -V: with one that does not, the whole list
## was lost to "sort: invalid option -- V" and only the header printed. The
## fetch was also run through a pipeline ending in sort, so a failed
## `git ls-remote` was never reported. Both are checked off the network, with
## a git shim that answers ls-remote with a fixed tag list (or fails), and a
## sort shim that rejects -V and otherwise defers to the real sort.
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-listall
#######################

mkdir -p $GVM_ROOT/tmp-listall/fakegit $GVM_ROOT/tmp-listall/oldsort $GVM_ROOT/tmp-listall/nogit # status=0
## (no shebang lines: tf reads a hash as the start of its assertions)
printf 'case "$1" in ls-remote) printf "%%s\\trefs/tags/%%s\\n" 1111 go1.10 2222 go1.9 3333 go1.2 4444 release.r60.3 5555 weekly.2011-12-22; exit 0 ;; esac\nexec "%s" "$@"\n' "$(command -v git)" > $GVM_ROOT/tmp-listall/fakegit/git # status=0
printf 'case "$1" in ls-remote) echo "fatal: unable to access" >&2; exit 128 ;; esac\nexec "%s" "$@"\n' "$(command -v git)" > $GVM_ROOT/tmp-listall/nogit/git # status=0
printf 'for arg; do [ "$arg" = -V ] && { echo "sort: invalid option -- V" >&2; exit 2; }; done\nexec "%s" "$@"\n' "$(command -v sort)" > $GVM_ROOT/tmp-listall/oldsort/sort # status=0
cp $GVM_ROOT/tmp-listall/fakegit/git $GVM_ROOT/tmp-listall/oldsort/git # status=0
chmod +x $GVM_ROOT/tmp-listall/fakegit/git $GVM_ROOT/tmp-listall/nogit/git $GVM_ROOT/tmp-listall/oldsort/sort $GVM_ROOT/tmp-listall/oldsort/git # status=0
PATH=$GVM_ROOT/tmp-listall/fakegit:$PATH git ls-remote -t x # status=0; match=/refs\/tags\/go1\.10/
PATH=$GVM_ROOT/tmp-listall/oldsort:$PATH sort -V < /dev/null # status!=0; match=/invalid option/
PATH=$GVM_ROOT/tmp-listall/oldsort:$PATH sort < /dev/null # status=0

## with a sort that takes -V the list is in version order, go1.9 before go1.10
PATH=$GVM_ROOT/tmp-listall/fakegit:$PATH gvm listall # status=0; match=/gvm gos \(available\)/; match=/go1\.2\n +go1\.9\n +go1\.10\n/; match=/release\.r60\.3/; match!=/weekly/
PATH=$GVM_ROOT/tmp-listall/fakegit:$PATH gvm listall --all # status=0; match=/weekly\.2011-12-22/

## with a sort that rejects -V the list is still complete
PATH=$GVM_ROOT/tmp-listall/oldsort:$PATH gvm listall 2>&1 # status=0; match=/^ +go1\.2$/; match=/^ +go1\.9$/; match=/^ +go1\.10$/; match=/release\.r60\.3/; match!=/invalid option/

## a failed fetch is reported and the command fails
PATH=$GVM_ROOT/tmp-listall/nogit:$PATH gvm listall 2>&1 # status!=0; match=/Failed to get version list/

## Cleanup test objects
rm -rf $GVM_ROOT/tmp-listall
