source $GVM_ROOT/scripts/gvm
## Regression test for issue 37: `gvm pkgset use --local <path>` must accept
## any absolute path. The pattern that recognised a local pkgset path was
## written as "[^:\\\n\\\0]" inside a double-quoted string, which reached the
## regex engine as a set excluding the letters "n" and "0" instead of newline
## and NUL, so any path containing either character -- most of them -- was
## rejected with "Unrecognized command line argument". The branch that takes
## a bare path was also missing its opening "[[", so it printed "0: command
## not found" and never matched. Uses a fake Go version so that no toolchain
## is needed.
## Cleanup test objects
rm -rf $GVM_ROOT/gos/go0.0.6 $GVM_ROOT/pkgsets/go0.0.6 $GVM_ROOT/environments/go0.0.6 $GVM_ROOT/environments/go0.0.6@* $GVM_ROOT/tmp-john0
#######################

mkdir -p $GVM_ROOT/gos/go0.0.6/bin $GVM_ROOT/pkgsets/go0.0.6/global $GVM_ROOT/tmp-john0/proj # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.6"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.6"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.6/global"\nexport PATH; PATH="$GVM_ROOT/gos/go0.0.6/bin:$GVM_ROOT/bin:$PATH"\n' "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.6 # status=0
gvm use go0.0.6 --quiet # status=0
cd $GVM_ROOT/tmp-john0/proj # status=0
gvm pkgset create --local # status=0
cd $GVM_ROOT # status=0

## a local pkgset path containing "n" and "0" must be accepted as the --local value
gvm pkgset use --local $GVM_ROOT/tmp-john0/proj --quiet # status=0; match!=/Unrecognized/; match!=/command not found/
echo $gvm_pkgset_name # match=/^__local__$/
echo $GVM_OVERLAY_PREFIX # match=/tmp-john0\/proj\/\.gvm_local\/pkgsets\/go0\.0\.6\/local\/overlay$/

## and as a bare path argument
gvm use go0.0.6 --quiet # status=0
echo $gvm_pkgset_name # match=/^global$/
gvm pkgset use $GVM_ROOT/tmp-john0/proj --quiet # status=0; match!=/Unrecognized/; match!=/command not found/
echo $gvm_pkgset_name # match=/^__local__$/

## a directory that holds no local pkgset is still refused
gvm use go0.0.6 --quiet # status=0
gvm pkgset use --local $GVM_ROOT/tmp-john0 # status!=0; match=/Cannot find local package set/
echo $gvm_pkgset_name # match=/^global$/

## and a standard pkgset name is still parsed as one
gvm pkgset create john0 # status=0
gvm pkgset use john0 --quiet # status=0
echo $gvm_pkgset_name # match=/^john0$/

## Cleanup test objects
cd $GVM_ROOT # status=0
gvm uninstall go0.0.6 # status=0
rm -rf $GVM_ROOT/gos/go0.0.6 $GVM_ROOT/pkgsets/go0.0.6 $GVM_ROOT/environments/go0.0.6 $GVM_ROOT/environments/go0.0.6@* $GVM_ROOT/tmp-john0
