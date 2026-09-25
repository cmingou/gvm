source $GVM_ROOT/scripts/gvm
## Regression test for issue 11: a .go-version or .go-pkgset at the root of a
## project must apply from every directory inside it. __gvm_find_path_upwards
## only looked in $PWD, and so did the lookup cd() performs, so the files were
## honoured only in the one directory holding them. The search now walks up
## to $HOME (or /) with shell builtins, and cd() switches only when the
## current version or pkgset differs from what the file asks for, so moving
## around inside a project stays fork-free. Uses fake Go versions so that no
## toolchain is needed.
## Cleanup test objects
rm -rf $GVM_ROOT/gos/go0.0.16 $GVM_ROOT/gos/go0.0.17 $GVM_ROOT/pkgsets/go0.0.16 $GVM_ROOT/pkgsets/go0.0.17 $GVM_ROOT/environments/go0.0.16 $GVM_ROOT/environments/go0.0.16@* $GVM_ROOT/environments/go0.0.17 $GVM_ROOT/environments/go0.0.17@* $GVM_ROOT/tmp-cd-up
#######################

mkdir -p $GVM_ROOT/gos/go0.0.16/bin $GVM_ROOT/gos/go0.0.17/bin $GVM_ROOT/pkgsets/go0.0.16/global $GVM_ROOT/pkgsets/go0.0.17/global "$GVM_ROOT/tmp-cd-up/proj/cmd/sub dir/deep" $GVM_ROOT/tmp-cd-up/proj/cmd/legacy/sub $GVM_ROOT/tmp-cd-up/plain/deeper $GVM_ROOT/tmp-cd-up/home/proj/sub # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.16"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.16"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.16/global"\nexport PATH; PATH="$GVM_ROOT/gos/go0.0.16/bin:$GVM_ROOT/bin:$PATH"\n' "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.16 # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.17"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.17"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.17/global"\nexport PATH; PATH="$GVM_ROOT/gos/go0.0.17/bin:$GVM_ROOT/bin:$PATH"\n' "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.17 # status=0
printf 'go0.0.17\n' > $GVM_ROOT/tmp-cd-up/proj/.go-version # status=0
printf 'upwards\n' > $GVM_ROOT/tmp-cd-up/proj/.go-pkgset # status=0
printf 'go0.0.16\n' > $GVM_ROOT/tmp-cd-up/proj/cmd/legacy/.go-version # status=0
gvm use go0.0.17 --quiet # status=0
gvm pkgset create upwards # status=0
gvm use go0.0.16 --quiet # status=0
gvm pkgset create upwards # status=0
gvm use go0.0.16 --quiet # status=0

## __gvm_find_path_upwards finds a file or directory in a parent directory
builtin cd "$GVM_ROOT/tmp-cd-up/proj/cmd/sub dir/deep" # status=0
__gvm_find_path_upwards .go-version # status=0; match=/\/tmp-cd-up\/proj\/\.go-version$/
__gvm_find_path_upwards legacy # status=0; match=/\/tmp-cd-up\/proj\/cmd\/legacy$/
__gvm_find_path_upwards .go-version "$GVM_ROOT/tmp-cd-up/proj/cmd/legacy/sub" # status=0; match=/\/cmd\/legacy\/\.go-version$/

## the search includes the final directory and stops there
__gvm_find_path_upwards .go-version "$PWD" "$GVM_ROOT/tmp-cd-up/proj" # status=0; match=/\/tmp-cd-up\/proj\/\.go-version$/
__gvm_find_path_upwards .go-version "$PWD" "$GVM_ROOT/tmp-cd-up/proj/cmd" # status=1; match=/^$/
__gvm_find_path_upwards no-such-file # status=1; match=/^$/
builtin cd $GVM_ROOT # status=0

## cd into a subdirectory of the project applies the project's .go-version and .go-pkgset
cd "$GVM_ROOT/tmp-cd-up/proj/cmd/sub dir/deep" # status=0; match=/Now using version go0.0.17/
echo $gvm_go_name # match=/^go0\.0\.17$/
echo $gvm_pkgset_name # match=/^upwards$/

## Moving around inside the project must not switch again: every call cd()
## makes to gvm is recorded in a file (a counter variable would not survive a
## subshell), and no `use` or `pkgset use` is expected while the version and
## pkgset already match. Only those two are counted: on a root with neither a
## default nor a system environment, cd() also resolves its fallback version
## through `gvm list --porcelain`, which is unrelated to the switch.
eval "__gvm_real_gvm() $(declare -f gvm | tail -n +2)" # status=0
gvm() { echo "$*" >> "$GVM_ROOT/tmp-cd-up/gvm-calls"; __gvm_real_gvm "$@"; } # status=0
cd $GVM_ROOT/tmp-cd-up/proj/cmd # status=0; match!=/Now using/
cd $GVM_ROOT/tmp-cd-up/proj # status=0; match!=/Now using/
grep -E '^(use|pkgset use) ' $GVM_ROOT/tmp-cd-up/gvm-calls 2> /dev/null | wc -l # match=/^ *0$/
echo $gvm_go_name # match=/^go0\.0\.17$/
echo $gvm_pkgset_name # match=/^upwards$/

## a .go-version closer to the current directory wins over one further up;
## this switch is one `gvm use` plus one `gvm pkgset use` for the .go-pkgset
## further up, which the new version's global pkgset no longer satisfies
cd $GVM_ROOT/tmp-cd-up/proj/cmd/legacy/sub # status=0; match=/Now using version go0.0.16/
echo $gvm_go_name $gvm_pkgset_name # match=/^go0\.0\.16 upwards$/
grep -E '^(use|pkgset use) ' $GVM_ROOT/tmp-cd-up/gvm-calls | wc -l # match=/^ *2$/
grep -E '^(use|pkgset use) ' $GVM_ROOT/tmp-cd-up/gvm-calls # match=/^use go0\.0\.16\npkgset use upwards$/
unset -f gvm # status=0
eval "gvm() $(declare -f __gvm_real_gvm | tail -n +2)" # status=0
unset -f __gvm_real_gvm # status=0

## leaving the project keeps the current version, as before
cd $GVM_ROOT/tmp-cd-up/plain/deeper # status=0; match!=/Now using/
echo $gvm_go_name # match=/^go0\.0\.16$/

## the search does not go above $HOME, so a file outside the home directory is not seen from inside it
printf 'go0.0.17\n' > $GVM_ROOT/tmp-cd-up/.go-version # status=0
__gvm_saved_home=$HOME # status=0
export HOME=$GVM_ROOT/tmp-cd-up/home # status=0
cd $GVM_ROOT/tmp-cd-up/home/proj/sub # status=0; match!=/Now using/
echo $gvm_go_name # match=/^go0\.0\.16$/
printf 'go0.0.17\n' > $GVM_ROOT/tmp-cd-up/home/.go-version # status=0
cd $GVM_ROOT/tmp-cd-up/home/proj # status=0; match=/Now using version go0.0.17/
export HOME=$__gvm_saved_home # status=0
unset __gvm_saved_home # status=0
cd $GVM_ROOT # status=0

## Cleanup test objects
gvm uninstall go0.0.16 # status=0
gvm uninstall go0.0.17 # status=0
rm -rf $GVM_ROOT/gos/go0.0.16 $GVM_ROOT/gos/go0.0.17 $GVM_ROOT/pkgsets/go0.0.16 $GVM_ROOT/pkgsets/go0.0.17 $GVM_ROOT/environments/go0.0.16 $GVM_ROOT/environments/go0.0.16@* $GVM_ROOT/environments/go0.0.17 $GVM_ROOT/environments/go0.0.17@* $GVM_ROOT/tmp-cd-up
