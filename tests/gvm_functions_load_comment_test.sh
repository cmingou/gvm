source $GVM_ROOT/scripts/gvm
## Regression test for issue 3: scripts/functions must be loaded once per
## shell, and scripts/function/tools must resolve the tool paths without a
## subshell per tool. Both sit on the shell startup path: every startup read
## the 16 function files twice and forked 7 command substitutions each time,
## purely to fill LS_PATH, TR_PATH, SED_PATH, GREP_PATH, EGREP_PATH, SORT_PATH
## and HEAD_PATH. The assertions count subshell commands and observe reloads
## rather than timing anything, so they hold on any machine.
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-functions
#######################

mkdir -p $GVM_ROOT/tmp-functions # status=0

## sourcing scripts/functions again in a shell that already has them is a no-op
display_message() { echo REDEFINED; }
. $GVM_ROOT/scripts/functions # status=0
display_message x # match=/^REDEFINED$/

## while sourcing the shell integration itself must reload them
source $GVM_ROOT/scripts/gvm # status=0
display_message x # match=/^x$/

## a child process has its own pid, so it loads them even if the guard leaked into its environment
__gvm_functions_loaded=$$ bash -c '. "$GVM_ROOT/scripts/functions"; display_message child' # status=0; match=/^child$/

## The tool paths must be resolved without a subshell per tool. With set -T
## the DEBUG trap is inherited by command substitutions, and BASH_SUBSHELL is
## greater than zero inside one, so every command that runs in a subshell
## while tools is sourced leaves a line in a counter file (a variable would
## not survive the subshell). First prove the counter sees a subshell at all.
rm -f $GVM_ROOT/tmp-functions/subshell-commands # status=0
bash -c 'set -T; trap "[[ \$BASH_SUBSHELL -gt 0 ]] && echo x >> \"$GVM_ROOT/tmp-functions/subshell-commands\"" DEBUG; v=$(echo probe); trap - DEBUG' # status=0
cat $GVM_ROOT/tmp-functions/subshell-commands | wc -l # match=/^ *[1-9]/
rm -f $GVM_ROOT/tmp-functions/subshell-commands # status=0
bash -c 'set -T; trap "[[ \$BASH_SUBSHELL -gt 0 ]] && echo x >> \"$GVM_ROOT/tmp-functions/subshell-commands\"" DEBUG; . "$GVM_ROOT/scripts/function/tools"; trap - DEBUG; echo "LS_PATH=$LS_PATH SORT_PATH=$SORT_PATH HEAD_PATH=$HEAD_PATH"' # status=0; match=/^LS_PATH=\/.*\/ls SORT_PATH=\/.*\/sort HEAD_PATH=\/.*\/head$/
cat $GVM_ROOT/tmp-functions/subshell-commands 2> /dev/null | wc -l # match=/^ *0$/

## the resolved path is the binary, even when a shell function shadows the tool
bash -c 'grep() { echo FUNCTION; }; . "$GVM_ROOT/scripts/function/tools"; echo "$GREP_PATH"' # status=0; match=/^\/.*\/grep$/

## and a tool that is not on PATH is still reported as missing (the tool paths
## are exported, so the inherited value is cleared first)
bash -c 'display_error() { echo "ERROR: $1" >&2; return 1; }; unset LS_PATH; PATH=$GVM_ROOT/tmp-functions; . "$GVM_ROOT/scripts/function/tools"; echo "rc=$? LS_PATH=[$LS_PATH]"' # match=/GVM couldn.t find ls/; match=/^rc=1 LS_PATH=\[\]$/

## Cleanup test objects
rm -rf $GVM_ROOT/tmp-functions
