source $GVM_ROOT/scripts/gvm
## Regression test for issue 16: gvm_export_path must rebuild PATH with shell
## builtins, and egrep must not be a hard dependency. The old pipeline
## (tr | grep -v | egrep -v | tr | sed) forked five processes on every gvm use,
## gvm pkgset use and login; it was the only user of egrep, which GNU grep 3.8+
## answers with an "obsolescent" warning that leaked to the terminal, and a
## system without an egrep binary made scripts/function/tools give up before
## SORT_PATH and HEAD_PATH were set. The assertions count subshell commands and
## observe the tool resolution rather than timing anything.
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-export-nofork
#######################

mkdir -p $GVM_ROOT/tmp-export-nofork/bin $GVM_ROOT/tmp-export-nofork/noegrep # status=0

## gvm_export_path must not run anything in a subshell. With set -T the DEBUG
## trap is inherited by command substitutions and pipelines, and BASH_SUBSHELL
## is greater than zero inside them, so every command that runs in a subshell
## leaves a line in a counter file (a variable would not survive the subshell).
## First prove the counter sees a subshell at all.
rm -f $GVM_ROOT/tmp-export-nofork/subshell-commands # status=0
bash -c 'set -T; trap "[[ \$BASH_SUBSHELL -gt 0 ]] && echo x >> \"$GVM_ROOT/tmp-export-nofork/subshell-commands\"" DEBUG; v=$(echo probe); trap - DEBUG' # status=0
cat $GVM_ROOT/tmp-export-nofork/subshell-commands | wc -l # match=/^ *[1-9]/
rm -f $GVM_ROOT/tmp-export-nofork/subshell-commands # status=0
bash -c '. "$GVM_ROOT/scripts/functions"; set -T; trap "[[ \$BASH_SUBSHELL -gt 0 ]] && echo x >> \"$GVM_ROOT/tmp-export-nofork/subshell-commands\"" DEBUG; gvm_export_path; trap - DEBUG; echo "rc=$? first=${PATH%%:*}"' # status=0; match=/^rc=0 first=.*\/bin$/
cat $GVM_ROOT/tmp-export-nofork/subshell-commands 2> /dev/null | wc -l # match=/^ *0$/

## the result must be what the pipeline produced: gvm's bin first, every entry
## below gvm's pkgsets, gos or bin dropped, empty entries dropped, the rest kept
## in order with spaces intact, no trailing colon, and the backup updated
GVM_TEST_PATH="$PATH"
export PATH="$GVM_ROOT/gos/go0.0.0/bin:/opt/My Tools/bin::$GVM_ROOT/pkgsets/go0.0.0/global/bin:/usr/bin:$GVM_ROOT/bin:/bin:"
gvm_export_path # status=0
echo "[$PATH]" # match=/^\[[^:]*\/bin:\/opt\/My Tools\/bin:\/usr\/bin:\/bin\]$/; match!=/gos\/go0\.0\.0/; match!=/pkgsets/
[ "${PATH%%:*}" = "$GVM_ROOT/bin" ] && echo GVM-BIN-FIRST # match=/GVM-BIN-FIRST/
[ "$GVM_PATH_BACKUP" = "$PATH" ] && echo BACKUP-UPDATED # match=/BACKUP-UPDATED/
export PATH="$GVM_TEST_PATH"

## a warning from egrep must not reach the terminal: GNU grep 3.8+ prints
## "egrep: warning: egrep is obsolescent" to stderr, which the command
## substitution around the old pipeline let through on every gvm use
## (no shebang line: tf reads a hash as the start of its assertions)
printf 'echo "egrep: warning: egrep is obsolescent; using grep -E" >&2\nexec grep -E "$@"\n' > $GVM_ROOT/tmp-export-nofork/bin/egrep # status=0
chmod +x $GVM_ROOT/tmp-export-nofork/bin/egrep # status=0
export PATH="$GVM_ROOT/tmp-export-nofork/bin:$PATH"
. $GVM_ROOT/scripts/function/tools # status=0
gvm_export_path 2>&1 # status=0; match!=/obsolescent/
export PATH="$GVM_TEST_PATH"
. $GVM_ROOT/scripts/function/tools # status=0

## and a PATH with every tool but egrep must resolve all the tool paths
for t in ls tr sed grep sort head; do ln -sf "$(command -v $t)" $GVM_ROOT/tmp-export-nofork/noegrep/$t; done # status=0
bash -c 'display_error() { echo "ERROR: $1" >&2; return 1; }; unset LS_PATH TR_PATH SED_PATH GREP_PATH SORT_PATH HEAD_PATH; PATH=$GVM_ROOT/tmp-export-nofork/noegrep; . "$GVM_ROOT/scripts/function/tools"; echo "rc=$? SORT_PATH=[$SORT_PATH] HEAD_PATH=[$HEAD_PATH]"' 2>&1 # match=/^rc=0 SORT_PATH=\[\/.*\/sort\] HEAD_PATH=\[\/.*\/head\]$/; match!=/couldn.t find/

## Cleanup test objects
export PATH="$GVM_TEST_PATH"
unset GVM_TEST_PATH
rm -rf $GVM_ROOT/tmp-export-nofork
