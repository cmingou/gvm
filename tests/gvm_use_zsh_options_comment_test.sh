source $GVM_ROOT/scripts/gvm
## Regression test for issue 81: under zsh, `gvm use --version <v>`,
## `gvm pkgset use --pkgset <p>` and `gvm use <v>@<p>` were rejected while the
## plain forms worked. The option parsers read the last element of their
## accumulator with the bash idiom ${arr[${#arr[@]}-1]}, which names the element
## before the last one in zsh's 1-based arrays, so the `--version <v>` and
## `--pkgset <p>` branches never matched; and GVM_REMATCH[1] was the whole
## `<v>@<p>` string under zsh instead of the version group. A child shell of
## each kind sources gvm against a fake version with a pkgset and runs the
## three forms. bash is always covered; zsh when it is installed
## (tests/shell_smoke.sh covers it in CI).
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-use-options $GVM_ROOT/gos/go0.0.9 $GVM_ROOT/pkgsets/go0.0.9 $GVM_ROOT/environments/go0.0.9 $GVM_ROOT/environments/go0.0.9@optparse
#######################

mkdir -p $GVM_ROOT/tmp-use-options $GVM_ROOT/gos/go0.0.9/bin $GVM_ROOT/pkgsets/go0.0.9/global $GVM_ROOT/pkgsets/go0.0.9/optparse/overlay/bin # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.9"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.9"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.9/global"\nexport PATH; PATH="$GVM_ROOT/gos/go0.0.9/bin:$GVM_ROOT/bin:$PATH"\n' "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.9 # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\n. "${GVM_ROOT}/environments/go0.0.9" || return 1\nexport gvm_go_name; gvm_go_name="go0.0.9"\nexport gvm_pkgset_name; gvm_pkgset_name="optparse"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.9/optparse:$GOPATH"\nexport PATH; PATH="$GVM_ROOT/pkgsets/go0.0.9/optparse/bin:$PATH"\n' "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.9@optparse # status=0

## the three option forms, each followed by a reset to the global pkgset so
## that every form is seen to do its own switch (no shebang line: tf reads a
## hash as the start of its assertions)
printf 'unset GVM_DEBUG\n. "$GVM_ROOT/scripts/gvm" > /dev/null 2>&1\ngvm use --version go0.0.9 --pkgset optparse --quiet\necho "flags rc=$? $gvm_go_name $gvm_pkgset_name"\ngvm pkgset use --pkgset global --quiet\necho "pkgset-flag rc=$? $gvm_go_name $gvm_pkgset_name"\ngvm use go0.0.9@optparse --quiet\necho "at rc=$? $gvm_go_name $gvm_pkgset_name"\ngvm use go0.0.9 --quiet\necho "plain rc=$? $gvm_go_name $gvm_pkgset_name"\ntrue\n' > $GVM_ROOT/tmp-use-options/forms.sh # status=0
bash $GVM_ROOT/tmp-use-options/forms.sh 2>&1 # status=0; match=/^flags rc=0 go0\.0\.9 optparse$/; match=/^pkgset-flag rc=0 go0\.0\.9 global$/; match=/^at rc=0 go0\.0\.9 optparse$/; match=/^plain rc=0 go0\.0\.9 global$/; match!=/Unrecognized command line argument/
{ command -v zsh > /dev/null && zsh -f $GVM_ROOT/tmp-use-options/forms.sh 2>&1 || echo "zsh not installed: skipped"; } # status=0; match=/(^flags rc=0 go0\.0\.9 optparse$|zsh not installed)/; match=/(^pkgset-flag rc=0 go0\.0\.9 global$|zsh not installed)/; match!=/Unrecognized command line argument/
{ command -v zsh > /dev/null && zsh -f $GVM_ROOT/tmp-use-options/forms.sh 2>&1 || echo "zsh not installed: skipped"; } # match=/(^at rc=0 go0\.0\.9 optparse$|zsh not installed)/; match=/(^plain rc=0 go0\.0\.9 global$|zsh not installed)/; match!=/doesn't look like Go has been installed/

## a flag left without its value is still reported, in both shells
printf 'unset GVM_DEBUG\n. "$GVM_ROOT/scripts/gvm" > /dev/null 2>&1\ngvm use --version --pkgset optparse --quiet\necho "missing rc=$?"\ntrue\n' > $GVM_ROOT/tmp-use-options/missing.sh # status=0
bash $GVM_ROOT/tmp-use-options/missing.sh 2>&1 # status=0; match=/Missing argument for: '--version'/; match=/^missing rc=1$/
{ command -v zsh > /dev/null && zsh -f $GVM_ROOT/tmp-use-options/missing.sh 2>&1 || echo "zsh not installed: skipped"; } # status=0; match=/(Missing argument for: '--version'|zsh not installed)/; match=/(^missing rc=1$|zsh not installed)/

## Cleanup test objects
cd $GVM_ROOT # status=0
rm -rf $GVM_ROOT/tmp-use-options $GVM_ROOT/gos/go0.0.9 $GVM_ROOT/pkgsets/go0.0.9 $GVM_ROOT/environments/go0.0.9 $GVM_ROOT/environments/go0.0.9@optparse
