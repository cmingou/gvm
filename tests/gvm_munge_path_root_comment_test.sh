source $GVM_ROOT/scripts/gvm
## Regression test for issue 13: __gvm_munge_path must rank the PATH entries
## below $GVM_ROOT (and inside a project's .gvm_local) ahead of the rest, not
## the entries containing the literal ".gvm". With a root not named .gvm the
## selected toolchain was left among the general entries, and any unrelated
## entry containing ".gvm" was promoted above it, so a decoy go there won
## over the active one. The expected values are built from $GVM_ROOT, hence
## the test/echo form. Uses a fake Go version so that no toolchain is needed.
## Cleanup test objects
rm -rf $GVM_ROOT/gos/go0.0.7 $GVM_ROOT/pkgsets/go0.0.7 $GVM_ROOT/environments/go0.0.7 ${TMPDIR:-/tmp}/gvm-test-decoy.gvm
#######################

## entries below $GVM_ROOT come first; an unrelated entry containing ".gvm" does not
test "$(__gvm_munge_path "/usr/bin:/tmp/decoy.gvm/bin:$GVM_ROOT/gos/go0.0.7/bin:/bin")" = "$GVM_ROOT/gos/go0.0.7/bin:/usr/bin:/tmp/decoy.gvm/bin:/bin" && echo ORDER-OK # status=0; match=/^ORDER-OK$/

## a local pkgset's .gvm_local entries rank with the gvm entries, in their PATH order
test "$(__gvm_munge_path "/usr/bin:/proj/.gvm_local/pkgsets/go0.0.7/local/bin:$GVM_ROOT/gos/go0.0.7/bin:/bin")" = "/proj/.gvm_local/pkgsets/go0.0.7/local/bin:$GVM_ROOT/gos/go0.0.7/bin:/usr/bin:/bin" && echo ORDER-OK # status=0; match=/^ORDER-OK$/

## rvm entries still come before gvm entries, and duplicates are still removed
test "$(__gvm_munge_path "/usr/bin:$GVM_ROOT/bin:/home/a b/.rvm/bin:/usr/bin")" = "/home/a b/.rvm/bin:$GVM_ROOT/bin:/usr/bin" && echo ORDER-OK # status=0; match=/^ORDER-OK$/

## a root containing spaces and regex metacharacters needs no escaping, and a trailing slash is tolerated
test "$(GVM_ROOT="/opt/go+gvm (1)/" __gvm_munge_path "/usr/bin:/opt/go+gvm (1)/gos/go1/bin:/opt/go+gvmX/bin:/bin")" = "/opt/go+gvm (1)/gos/go1/bin:/usr/bin:/opt/go+gvmX/bin:/bin" && echo ORDER-OK # status=0; match=/^ORDER-OK$/

## and after gvm use, the active toolchain must win over a decoy go whose directory contains ".gvm"
mkdir -p $GVM_ROOT/gos/go0.0.7/bin $GVM_ROOT/pkgsets/go0.0.7/global ${TMPDIR:-/tmp}/gvm-test-decoy.gvm/bin # status=0
printf 'echo real\n' > $GVM_ROOT/gos/go0.0.7/bin/go # status=0
printf 'echo decoy\n' > ${TMPDIR:-/tmp}/gvm-test-decoy.gvm/bin/go # status=0
chmod +x $GVM_ROOT/gos/go0.0.7/bin/go ${TMPDIR:-/tmp}/gvm-test-decoy.gvm/bin/go # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.7"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="$GVM_ROOT/gos/go0.0.7"\nexport GOPATH; GOPATH="$GVM_ROOT/pkgsets/go0.0.7/global"\nexport PATH; PATH="$GVM_ROOT/gos/go0.0.7/bin:$GVM_ROOT/bin:$PATH"\n' "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.7 # status=0
export PATH="$PATH:${TMPDIR:-/tmp}/gvm-test-decoy.gvm/bin"
gvm use go0.0.7 --quiet # status=0
go # status=0; match=/^real$/
command -v go # match=/\/gos\/go0\.0\.7\/bin\/go$/

## Cleanup test objects
gvm uninstall go0.0.7 # status=0
rm -rf $GVM_ROOT/gos/go0.0.7 $GVM_ROOT/pkgsets/go0.0.7 $GVM_ROOT/environments/go0.0.7 ${TMPDIR:-/tmp}/gvm-test-decoy.gvm
