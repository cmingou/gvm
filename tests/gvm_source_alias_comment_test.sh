source $GVM_ROOT/scripts/gvm
## Regression test for issue 21: gvm's own `.` calls were plain `.`, so a user
## alias on `.` (a common one echoes the file it is given) fired on gvm's lines
## when the shell integration was sourced, gvm-default never loaded and
## `gvm use` ended in "command not found". The functions sourced into the
## shell are exercised behind such an alias in a child shell of each kind; the
## alias must still be in place afterwards. The same report covers
## scripts/env/applymod, the one sourced file that still called bare grep,
## cat, tr and wc: an `alias grep='grep --color=always'` wrote ANSI escapes
## into the version it read from go.mod. bash is always covered; zsh when it
## is installed (tests/shell_smoke.sh covers it in CI).
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-source-alias $GVM_ROOT/gos/go0.0.9 $GVM_ROOT/pkgsets/go0.0.9 $GVM_ROOT/environments/go0.0.9 $GVM_ROOT/environments/go0.0.9@dotalias
#######################

mkdir -p $GVM_ROOT/tmp-source-alias/proj $GVM_ROOT/tmp-source-alias/mod $GVM_ROOT/tmp-source-alias/bin $GVM_ROOT/gos/go0.0.9/bin $GVM_ROOT/pkgsets/go0.0.9/global # status=0
## a git whose ls-remote fails keeps `gvm listall` off the network should
## applymod not find the version among the installed ones
printf 'case "$1" in ls-remote) exit 1 ;; esac\nexec "%s" "$@"\n' "$(command -v git)" > $GVM_ROOT/tmp-source-alias/bin/git # status=0
chmod +x $GVM_ROOT/tmp-source-alias/bin/git # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.9"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.9"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.9/global"\nexport PATH; PATH="$GVM_ROOT/gos/go0.0.9/bin:$GVM_ROOT/bin:$PATH"\n' "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.9 # status=0
echo go0.0.9 > $GVM_ROOT/tmp-source-alias/proj/.go-version # status=0
printf 'module example.com/mod\n\ngo 0.0\n' > $GVM_ROOT/tmp-source-alias/mod/go.mod # status=0

## gvm sourced with the `source` keyword while `.` is an alias, as in the
## report; every gvm command that sources a file of its own must still work
## (no shebang line: tf reads a hash as the start of its assertions)
printf '[ -n "${BASH_VERSION:-}" ] && shopt -s expand_aliases\nunset GVM_DEBUG\nalias .="echo ALIASED_DOT"\nsource "$GVM_ROOT/scripts/gvm" > /dev/null\necho "sourced rc=$?"\ngvm use go0.0.9 --quiet\necho "use rc=$? $gvm_go_name"\ngvm pkgset create dotalias > /dev/null 2>&1\ngvm pkgset use dotalias --quiet\necho "pkgset rc=$? $gvm_pkgset_name"\ngvm use go0.0.9 --quiet\ncd "$GVM_ROOT/tmp-source-alias/proj" > /dev/null\necho "cd version=$gvm_go_name pwd=$(basename "$PWD")"\ngvm list > /dev/null\necho "list rc=$?"\nalias . > /dev/null 2>&1 && echo "dot is still an alias"\ntrue\n' > $GVM_ROOT/tmp-source-alias/dot.sh # status=0
bash $GVM_ROOT/tmp-source-alias/dot.sh 2>&1 # status=0; match=/^sourced rc=0$/; match=/^use rc=0 go0\.0\.9$/; match=/^pkgset rc=0 dotalias$/; match=/^cd version=go0\.0\.9 pwd=proj$/; match=/^list rc=0$/; match=/dot is still an alias/; match!=/ALIASED_DOT/; match!=/command not found/
{ command -v zsh > /dev/null && zsh -f $GVM_ROOT/tmp-source-alias/dot.sh 2>&1 || echo "zsh not installed: skipped"; } # status=0; match=/(^sourced rc=0$|zsh not installed)/; match=/(^use rc=0 go0\.0\.9$|zsh not installed)/; match=/(^pkgset rc=0 dotalias$|zsh not installed)/; match!=/ALIASED_DOT/
{ command -v zsh > /dev/null && zsh -f $GVM_ROOT/tmp-source-alias/dot.sh 2>&1 || echo "zsh not installed: skipped"; } # match=/(^cd version=go0\.0\.9 pwd=proj$|zsh not installed)/; match=/(^list rc=0$|zsh not installed)/; match=/(dot is still an alias|zsh not installed)/; match!=/command not found/

## gvm applymod behind a colourising alias on grep (and a pager-style alias
## on cat): the version read from go.mod must be the plain text
printf '[ -n "${BASH_VERSION:-}" ] && shopt -s expand_aliases\nunset GVM_DEBUG\nalias grep="grep --color=always"\nalias cat="cat -A"\nsource "$GVM_ROOT/scripts/gvm" > /dev/null\ngvm use go0.0.9 --quiet\ncd "$GVM_ROOT/tmp-source-alias/mod" > /dev/null\nPATH="$GVM_ROOT/tmp-source-alias/bin:$PATH" gvm applymod\necho "applymod rc=$? $gvm_go_name"\ntrue\n' > $GVM_ROOT/tmp-source-alias/grep.sh # status=0
bash $GVM_ROOT/tmp-source-alias/grep.sh 2>&1 # status=0; match=/use go version: go0\.0$/; match=/^applymod rc=0 go0\.0\.9$/; match!=/can not find a go version/; match!=/\x1b\[/
{ command -v zsh > /dev/null && zsh -f $GVM_ROOT/tmp-source-alias/grep.sh 2>&1 || echo "zsh not installed: skipped"; } # status=0; match=/(^applymod rc=0 go0\.0\.9$|zsh not installed)/; match!=/can not find a go version/; match!=/\x1b\[/

## Cleanup test objects
cd $GVM_ROOT # status=0
rm -rf $GVM_ROOT/tmp-source-alias $GVM_ROOT/gos/go0.0.9 $GVM_ROOT/pkgsets/go0.0.9 $GVM_ROOT/environments/go0.0.9 $GVM_ROOT/environments/go0.0.9@dotalias
