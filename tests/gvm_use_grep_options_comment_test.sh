source $GVM_ROOT/scripts/gvm
## Regression test for issue 14: gvm use, gvm pkgset use and the subcommand
## scripts pipe version and pkgset names through grep and use the result as a
## path. BSD grep, the one macOS ships, reads GREP_OPTIONS, so a
## `--color=always` there wrote ANSI escapes into the name and `gvm use`
## failed with "Couldn't source environment". GNU grep 3.6+ ignores the
## variable, so a grep shim that honours it the way BSD grep does stands first
## on PATH (its shebang is spelled \043 because a literal # would end the tf
## command): gvm resolves GREP_PATH by walking PATH, so both the sourced shell
## functions and the scripts run through bin/gvm pick the shim up. The user's
## own GREP_OPTIONS must survive: gvm neutralises it for its own grep calls
## only.
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-grep-options $GVM_ROOT/gos/go0.0.12 $GVM_ROOT/pkgsets/go0.0.12 $GVM_ROOT/environments/go0.0.12 $GVM_ROOT/environments/go0.0.12@global $GVM_ROOT/environments/go0.0.12@colour
#######################

mkdir -p $GVM_ROOT/tmp-grep-options/bin $GVM_ROOT/gos/go0.0.12/bin $GVM_ROOT/pkgsets/go0.0.12/global # status=0
printf '\043!/bin/sh\nexec /usr/bin/grep $GREP_OPTIONS "$@"\n' > $GVM_ROOT/tmp-grep-options/bin/grep # status=0
chmod +x $GVM_ROOT/tmp-grep-options/bin/grep # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.12"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.12"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.12/global"\nexport PATH; PATH="$GVM_ROOT/gos/go0.0.12/bin:$GVM_ROOT/bin:$PATH"\n' "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.12 # status=0

## first prove the shim colourises the way BSD grep does
echo go0.0.12 | env GREP_OPTIONS=--color=always $GVM_ROOT/tmp-grep-options/bin/grep go0.0.12 | cat -v # status=0; match=/\^\[/

## with the shim as gvm's grep and GREP_OPTIONS=--color=always in the
## environment, gvm use, gvm pkgset use and gvm uninstall must resolve their
## names cleanly, and the user's GREP_OPTIONS must be left as it was
env PATH=$GVM_ROOT/tmp-grep-options/bin:$PATH GREP_OPTIONS=--color=always bash -c 'source "$GVM_ROOT/scripts/gvm" > /dev/null 2>&1; echo "GREP_PATH=$GREP_PATH"; gvm use go0.0.12 --quiet; echo "use=$? name=$gvm_go_name"; gvm pkgset create colour > /dev/null 2>&1; gvm pkgset use colour --quiet; echo "pkgset=$? name=$gvm_pkgset_name"; gvm pkgset use global --quiet; echo "opts=$GREP_OPTIONS"; gvm uninstall go0.0.12' 2>&1 | cat -v # status=0; match=/GREP_PATH=.*tmp-grep-options\/bin\/grep/; match=/^use=0 name=go0.0.12$/; match=/^pkgset=0 name=colour$/; match=/^opts=--color=always$/; match=/Uninstalled version go0.0.12/; match!=/\^\[/; match!=/ERROR/

## Cleanup test objects
cd $GVM_ROOT # status=0
rm -rf $GVM_ROOT/tmp-grep-options $GVM_ROOT/gos/go0.0.12 $GVM_ROOT/pkgsets/go0.0.12 $GVM_ROOT/environments/go0.0.12 $GVM_ROOT/environments/go0.0.12@global $GVM_ROOT/environments/go0.0.12@colour
