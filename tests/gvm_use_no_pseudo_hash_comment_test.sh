source $GVM_ROOT/scripts/gvm
## Regression test for issue 2: gvm use and gvm pkgset use collected their
## options in a _bash_pseudo_hash whose every write and read is a command
## substitution around a function that percent-encodes or decodes the value
## inside another one, some thirty forks per call, on the path cd() takes
## whenever a .go-version switches the version. The options are held in plain
## locals now. With set -T the DEBUG trap is inherited by command substitutions
## and pipelines, and BASH_SUBSHELL is greater than zero inside them, so every
## command that runs in a subshell leaves its text in a counter file (a variable
## would not survive the subshell): none of them may be a pseudo-hash accessor.
## The loop counter used to leak out of gvm use as a global, and every option
## form must still parse as before.
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-no-pseudo-hash $GVM_ROOT/gos/go0.0.9 $GVM_ROOT/pkgsets/go0.0.9 $GVM_ROOT/environments/go0.0.9 $GVM_ROOT/environments/go0.0.9@global $GVM_ROOT/environments/go0.0.9@extra
#######################

mkdir -p $GVM_ROOT/tmp-no-pseudo-hash $GVM_ROOT/gos/go0.0.9/bin $GVM_ROOT/pkgsets/go0.0.9/global # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.9"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.9"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.9/global"\nexport PATH; PATH="$GVM_ROOT/gos/go0.0.9/bin:$GVM_ROOT/bin:$PATH"\n' "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.9 # status=0
[ -f $GVM_ROOT/environments/default ] && cp $GVM_ROOT/environments/default $GVM_ROOT/tmp-no-pseudo-hash/default.bak; true # status=0
gvm use go0.0.9 --quiet # status=0
gvm pkgset create extra # status=0

## first prove the counter sees a subshell at all
rm -f $GVM_ROOT/tmp-no-pseudo-hash/subshell-commands # status=0
bash -c 'set -T; trap "[[ \$BASH_SUBSHELL -gt 0 ]] && echo \"\$BASH_COMMAND\" >> \"$GVM_ROOT/tmp-no-pseudo-hash/subshell-commands\"" DEBUG; v=$(echo probe); trap - DEBUG' # status=0
grep -c 'echo probe' $GVM_ROOT/tmp-no-pseudo-hash/subshell-commands # match=/^1$/

## no pseudo-hash accessor may run in a subshell during gvm use, with the
## options given in every form the command accepts
rm -f $GVM_ROOT/tmp-no-pseudo-hash/subshell-commands # status=0
bash -c 'source "$GVM_ROOT/scripts/gvm" > /dev/null 2>&1; set -T; trap "[[ \$BASH_SUBSHELL -gt 0 ]] && echo \"\$BASH_COMMAND\" >> \"$GVM_ROOT/tmp-no-pseudo-hash/subshell-commands\"" DEBUG; gvm use go0.0.9 --quiet; gvm use --version go0.0.9 --pkgset extra --quiet; gvm use go0.0.9@extra --quiet; gvm pkgset use extra --quiet; gvm pkgset use --pkgset global --quiet; rc=$?; trap - DEBUG; echo "rc=$rc name=$gvm_go_name pkgset=$gvm_pkgset_name"' # status=0; match=/^rc=0 name=go0.0.9 pkgset=global$/
grep -c 'FakeAssocArray\|_encode\|_decode' $GVM_ROOT/tmp-no-pseudo-hash/subshell-commands # status!=0; match=/^0$/
cat $GVM_ROOT/tmp-no-pseudo-hash/subshell-commands | wc -l # match=/^ *[1-9]/

## the loop counter stays inside gvm use and gvm pkgset use
bash -c 'source "$GVM_ROOT/scripts/gvm" > /dev/null 2>&1; i=7; gvm use go0.0.9 --quiet; gvm pkgset use extra --quiet; echo "i=$i"' # status=0; match=/^i=7$/

## every option form still parses: bare version, name@pkgset, explicit
## --version and --pkgset, --default, and the acknowledgement without --quiet
gvm use go0.0.9 --quiet # status=0; match!=/Now using/
echo "$gvm_go_name $gvm_pkgset_name" # match=/^go0.0.9 global$/
gvm use go0.0.9@extra --quiet # status=0
echo "$gvm_go_name $gvm_pkgset_name" # match=/^go0.0.9 extra$/
gvm use --version go0.0.9 --pkgset global --quiet # status=0
echo "$gvm_go_name $gvm_pkgset_name" # match=/^go0.0.9 global$/
gvm use go0.0.9 extra # status=0; match=/Now using version go0.0.9/
echo "$gvm_go_name $gvm_pkgset_name" # match=/^go0.0.9 extra$/
gvm pkgset use global # status=0; match=/Now using pkgset go0.0.9@global/
gvm pkgset use --pkgset extra --quiet # status=0; match!=/Now using/
echo "$gvm_pkgset_name" # match=/^extra$/
gvm use go0.0.9@extra --default --quiet # status=0
grep -c 'gvm_go_name="go0.0.9"' $GVM_ROOT/environments/default # match=/^1$/
GVM_DEBUG=1 gvm use go0.0.9 --pkgset extra --quiet 2>&1 | grep -E '^  \[--(version|pkgset)\]' # match=/\[--version\]: go0.0.9/; match=/\[--pkgset\]: extra/
gvm use --version # status!=0; match=/Please specify the version/
gvm use --version --quiet # status!=0; match=/Missing argument for: '--version'/
gvm use --bogus # status!=0; match=/Unrecognized command line argument/

## Cleanup test objects
cd $GVM_ROOT # status=0
[ -f $GVM_ROOT/tmp-no-pseudo-hash/default.bak ] && cp $GVM_ROOT/tmp-no-pseudo-hash/default.bak $GVM_ROOT/environments/default || rm -f $GVM_ROOT/environments/default; true # status=0
gvm uninstall go0.0.9 # status=0
rm -rf $GVM_ROOT/tmp-no-pseudo-hash $GVM_ROOT/gos/go0.0.9 $GVM_ROOT/pkgsets/go0.0.9 $GVM_ROOT/environments/go0.0.9 $GVM_ROOT/environments/go0.0.9@global $GVM_ROOT/environments/go0.0.9@extra
