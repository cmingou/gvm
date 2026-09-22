source $GVM_ROOT/scripts/gvm
## Regression test for issue 15: the tool paths resolved by
## scripts/function/tools must be exported, and gvm_export_path must never
## wipe PATH. The variables were plain shell variables, so an environment that
## carries gvm's functions but not its unexported variables ran the pipeline in
## gvm_export_path with empty commands, which left PATH as "$GVM_ROOT/bin:"
## and returned 0.
#######################

## the tool paths must be exported
declare -p TR_PATH # status=0; match=/^declare -x TR_PATH=/
declare -p LS_PATH SED_PATH GREP_PATH EGREP_PATH SORT_PATH HEAD_PATH # status=0; match!=/declare -- /
declare -p LS_PATH SED_PATH GREP_PATH EGREP_PATH SORT_PATH HEAD_PATH | grep -c 'declare -x' # match=/^6$/

## with the tool paths gone, gvm_export_path must reload them and keep PATH intact
GVM_TEST_PATH="$PATH"
export PATH="/opt/gvm-export-marker/bin:$PATH"
unset TR_PATH GREP_PATH EGREP_PATH SED_PATH
gvm_export_path # status=0
echo "$PATH" # match=/^[^:]*\/bin:\/opt\/gvm-export-marker\/bin:/; match!=/^[^:]*\/bin:$/
declare -p TR_PATH # status=0; match=/^declare -x TR_PATH=/

## and when they cannot be reloaded it must refuse, report, and leave PATH alone
export PATH="/opt/gvm-export-marker/bin:$GVM_TEST_PATH"
unset TR_PATH GREP_PATH EGREP_PATH SED_PATH
GVM_TEST_ROOT="$GVM_ROOT"
GVM_ROOT="$GVM_ROOT/tmp-export-path-no-such-root"
gvm_export_path # status!=0; match=/ERROR/
echo "$PATH" # match=/^\/opt\/gvm-export-marker\/bin:/
GVM_ROOT="$GVM_TEST_ROOT"

## the normal case must behave exactly as before: gvm's bin first, gvm entries stripped, the rest kept
export PATH="$GVM_ROOT/gos/go0.0.0/bin:/opt/gvm-export-marker/bin:$GVM_ROOT/bin:$GVM_TEST_PATH"
. $GVM_ROOT/scripts/function/tools # status=0
gvm_export_path # status=0
echo "$PATH" # match=/^[^:]*\/bin:\/opt\/gvm-export-marker\/bin:/; match!=/gos\/go0\.0\.0/
echo "${PATH%%:*}" # match=/\/bin$/
[ "${PATH%%:*}" = "$GVM_ROOT/bin" ] && echo GVM-BIN-FIRST # match=/GVM-BIN-FIRST/
[ "$GVM_PATH_BACKUP" = "$PATH" ] && echo BACKUP-UPDATED # match=/BACKUP-UPDATED/

## Cleanup test objects
export PATH="$GVM_TEST_PATH"
unset GVM_TEST_PATH GVM_TEST_ROOT
