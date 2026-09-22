source $GVM_ROOT/scripts/gvm
## Regression test for issue 23: gvm_environment_sanitize must never rewrite an
## environment file with an empty GOROOT. A fake Go version whose selected go
## binary cannot report its GOROOT reproduces the "no usable go" condition.
## The environment file uses absolute paths, like the installer-generated
## environments/system file does.
## Cleanup test objects
rm -rf $GVM_ROOT/gos/go0.0.1 $GVM_ROOT/pkgsets/go0.0.1 $GVM_ROOT/environments/go0.0.1 $GVM_ROOT/environments/go0.0.1-e
#######################

mkdir -p $GVM_ROOT/gos/go0.0.1/bin $GVM_ROOT/pkgsets/go0.0.1/global/bin # status=0
printf 'exit 1\n' > $GVM_ROOT/pkgsets/go0.0.1/global/bin/go # status=0
chmod +x $GVM_ROOT/pkgsets/go0.0.1/global/bin/go # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.1"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="%s/gos/go0.0.1"\nexport GOPATH; GOPATH="%s/pkgsets/go0.0.1/global"\nexport PATH; PATH="%s/pkgsets/go0.0.1/global/bin:%s/gos/go0.0.1/bin:%s/bin:$PATH"\n' "$GVM_ROOT" "$GVM_ROOT" "$GVM_ROOT" "$GVM_ROOT" "$GVM_ROOT" "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.1 # status=0
gvm use go0.0.1 # status=0; match=/Now using version go0.0.1/; match!=/sed:/
grep -c "GOROOT=\"$GVM_ROOT/gos/go0.0.1\"" $GVM_ROOT/environments/go0.0.1 # status=0; match=/^1$/
gvm use go0.0.1 # status=0; match=/Now using version go0.0.1/; match!=/sed:/
grep -c "GOROOT=\"$GVM_ROOT/gos/go0.0.1\"" $GVM_ROOT/environments/go0.0.1 # status=0; match=/^1$/
echo $GOROOT # match=/\/gos\/go0\.0\.1$/
ls $GVM_ROOT/environments # match!=/go0\.0\.1-e/
gvm uninstall go0.0.1 # status=0

## The rewrite path must still work: when the active go reports a different
## GOROOT, the environment file is updated to it and sourced again.
mkdir -p $GVM_ROOT/gos/go0.0.2/bin $GVM_ROOT/pkgsets/go0.0.2/global/bin $GVM_ROOT/gos/go0.0.2-relocated/bin # status=0
printf 'echo %s/gos/go0.0.2-relocated\n' "$GVM_ROOT" > $GVM_ROOT/pkgsets/go0.0.2/global/bin/go # status=0
chmod +x $GVM_ROOT/pkgsets/go0.0.2/global/bin/go # status=0
printf 'export GVM_ROOT; GVM_ROOT="%s"\nexport gvm_go_name; gvm_go_name="go0.0.2"\nexport gvm_pkgset_name; gvm_pkgset_name="global"\nexport GOROOT; GOROOT="%s/gos/go0.0.2"\nexport GOPATH; GOPATH="%s/pkgsets/go0.0.2/global"\nexport PATH; PATH="%s/pkgsets/go0.0.2/global/bin:%s/gos/go0.0.2/bin:%s/bin:$PATH"\n' "$GVM_ROOT" "$GVM_ROOT" "$GVM_ROOT" "$GVM_ROOT" "$GVM_ROOT" "$GVM_ROOT" > $GVM_ROOT/environments/go0.0.2 # status=0
gvm use go0.0.2 # status=0; match=/Now using version go0.0.2/; match!=/sed:/
grep -c "GOROOT=\"$GVM_ROOT/gos/go0.0.2-relocated\"" $GVM_ROOT/environments/go0.0.2 # status=0; match=/^1$/
echo $GOROOT # match=/\/gos\/go0\.0\.2-relocated$/
ls $GVM_ROOT/environments # match!=/go0\.0\.2-e/
gvm uninstall go0.0.2 # status=0

## Cleanup test objects
rm -rf $GVM_ROOT/gos/go0.0.1 $GVM_ROOT/pkgsets/go0.0.1 $GVM_ROOT/environments/go0.0.1 $GVM_ROOT/environments/go0.0.1-e
rm -rf $GVM_ROOT/gos/go0.0.2 $GVM_ROOT/gos/go0.0.2-relocated $GVM_ROOT/pkgsets/go0.0.2 $GVM_ROOT/environments/go0.0.2 $GVM_ROOT/environments/go0.0.2-e
