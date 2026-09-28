source $GVM_ROOT/scripts/gvm
## Regression test for issue 9: with cd already an alias (zoxide's
## `alias cd=z`, an `alias cd='cd -P'`), sourcing the shell integration
## aborted under zsh with "defining function based on alias" and gvm never
## loaded; under bash the alias was expanded inside the definition, so gvm's
## cd() was defined under the alias's own name, over the user's function, and
## cd stayed the alias. A child shell sources gvm behind such an alias, then
## cds into a directory with a .go-version: gvm must load, the auto-switch must
## run, and the aliased command must still be called. bash is always covered;
## zsh when it is installed (tests/shell_smoke.sh covers it in CI).
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-cd-alias $GVM_ROOT/gos/go0.0.9 $GVM_ROOT/pkgsets/go0.0.9 $GVM_ROOT/environments/go0.0.9
#######################

mkdir -p $GVM_ROOT/tmp-cd-alias/proj $GVM_ROOT/gos/go0.0.9/bin $GVM_ROOT/pkgsets/go0.0.9/global # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.9"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.9"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.9/global"\nexport PATH; PATH="$GVM_ROOT/gos/go0.0.9/bin:$GVM_ROOT/bin:$PATH"\n' "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.9 # status=0
echo go0.0.9 > $GVM_ROOT/tmp-cd-alias/proj/.go-version # status=0

## a script with an alias on cd that calls a function of its own, as zoxide
## does; FUNCNEST stops a cd that recurses into itself instead of hanging (no
## shebang line: tf reads a hash as the start of its assertions)
printf '[ -n "${BASH_VERSION:-}" ] && shopt -s expand_aliases && FUNCNEST=64\nunset GVM_DEBUG\n__test_jump() { echo "jump $(basename "$1")" >&2; builtin cd "$@"; }\nalias cd=__test_jump\n. "$GVM_ROOT/scripts/gvm" > /dev/null\necho "sourced rc=$?"\ncd "$GVM_ROOT/tmp-cd-alias/proj" > /dev/null\necho "version=$gvm_go_name pwd=$(basename "$PWD")"\n__test_jump "$GVM_ROOT/tmp-cd-alias"\nalias cd > /dev/null 2>&1 && echo "cd is still an alias"\ntrue\n' > $GVM_ROOT/tmp-cd-alias/jump.sh # status=0
bash $GVM_ROOT/tmp-cd-alias/jump.sh 2>&1 # status=0; match=/sourced rc=0/; match=/^jump proj$/; match=/version=go0.0.9 pwd=proj/; match=/^jump tmp-cd-alias$/; match!=/still an alias/; match!=/parse error/
{ command -v zsh > /dev/null && zsh -f $GVM_ROOT/tmp-cd-alias/jump.sh 2>&1 || echo "zsh not installed: skipped"; } # status=0; match=/(sourced rc=0|zsh not installed)/; match!=/parse error/
{ command -v zsh > /dev/null && zsh -f $GVM_ROOT/tmp-cd-alias/jump.sh 2>&1 || echo "zsh not installed: skipped"; } # match=/(^jump proj$|zsh not installed)/; match=/(version=go0.0.9 pwd=proj|zsh not installed)/; match!=/still an alias/

## an alias for cd itself must reach the builtin, not recurse into gvm's cd()
printf '[ -n "${BASH_VERSION:-}" ] && shopt -s expand_aliases && FUNCNEST=64\nunset GVM_DEBUG\nalias cd="cd -P"\n. "$GVM_ROOT/scripts/gvm" > /dev/null\necho "sourced rc=$?"\ncd "$GVM_ROOT/tmp-cd-alias/proj" > /dev/null\necho "version=$gvm_go_name pwd=$(basename "$PWD")"\ntrue\n' > $GVM_ROOT/tmp-cd-alias/self.sh # status=0
bash $GVM_ROOT/tmp-cd-alias/self.sh 2>&1 # status=0; match=/sourced rc=0/; match=/version=go0.0.9 pwd=proj/; match!=/FUNCNEST|recursion|parse error/
{ command -v zsh > /dev/null && zsh -f $GVM_ROOT/tmp-cd-alias/self.sh 2>&1 || echo "zsh not installed: skipped"; } # status=0; match=/(version=go0.0.9 pwd=proj|zsh not installed)/; match!=/nested|parse error/

## Cleanup test objects
cd $GVM_ROOT # status=0
rm -rf $GVM_ROOT/tmp-cd-alias $GVM_ROOT/gos/go0.0.9 $GVM_ROOT/pkgsets/go0.0.9 $GVM_ROOT/environments/go0.0.9
