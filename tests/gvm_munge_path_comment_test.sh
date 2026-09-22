source $GVM_ROOT/scripts/gvm
## Regression test for issue 12: __gvm_munge_path must split PATH on ':' only.
## It used to split on spaces as well and left its expansions unquoted, so an
## entry containing whitespace was torn apart and an entry containing a glob
## character was pathname-expanded, on every login and every gvm use.
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-munge $GVM_ROOT/gos/go0.0.4 $GVM_ROOT/pkgsets/go0.0.4 $GVM_ROOT/environments/go0.0.4
#######################

mkdir -p $GVM_ROOT/tmp-munge/aa $GVM_ROOT/tmp-munge/ab # status=0
__gvm_munge_path "/usr/bin:/opt/My Tools/bin:/bin" # status=0; match=/^\/usr\/bin:\/opt\/My Tools\/bin:\/bin$/
__gvm_munge_path "/usr/bin:$GVM_ROOT/tmp-munge/a*:/bin" # status=0; match=/tmp-munge\/a\*:\/bin$/; match!=/tmp-munge\/aa/
__gvm_munge_path "/usr/bin:/opt/My Tools/bin:/bin" false # status=0; match=/^\/usr\/bin:\/opt\/My Tools\/bin:\/bin$/

## gvm and rvm entries containing spaces must still be recognised and ordered first, and duplicates removed
__gvm_munge_path "/usr/bin:/home/a b/.rvm/bin:/home/a b/.gvm/bin:/usr/bin:/bin" # status=0; match=/^\/home\/a b\/.rvm\/bin:\/home\/a b\/.gvm\/bin:\/usr\/bin:\/bin$/

## the munged PATH must survive sourcing gvm and gvm use with a fake Go version
mkdir -p $GVM_ROOT/gos/go0.0.4/bin $GVM_ROOT/pkgsets/go0.0.4/global # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.4"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.4"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.4/global"\nexport PATH; PATH="$GVM_ROOT/gos/go0.0.4/bin:$GVM_ROOT/bin:$PATH"\n' "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.4 # status=0
export PATH="/opt/My Tools/bin:$PATH"
source $GVM_ROOT/scripts/gvm # status=0
echo "$PATH" # match=/:\/opt\/My Tools\/bin:/; match!=/\/opt\/My:/
gvm use go0.0.4 --quiet # status=0
echo "$PATH" # match=/gos\/go0\.0\.4\/bin:/; match=/:\/opt\/My Tools\/bin:/; match!=/\/opt\/My:/

## Cleanup test objects
gvm uninstall go0.0.4 # status=0
rm -rf $GVM_ROOT/tmp-munge $GVM_ROOT/gos/go0.0.4 $GVM_ROOT/pkgsets/go0.0.4 $GVM_ROOT/environments/go0.0.4
