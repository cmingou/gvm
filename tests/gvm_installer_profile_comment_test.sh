source $GVM_ROOT/scripts/gvm
## Regression test for issue 4: on a Mac whose login shell is bash, the
## installer appended its source line to ~/.profile ahead of ~/.bash_profile.
## A bash login shell reads only the first of ~/.bash_profile, ~/.bash_login
## and ~/.profile that exists, so with both files present gvm was never loaded
## while the installer reported success. The installer's macOS branch is
## exercised on every platform through shims for uname and finger, and every
## run installs from a fresh HOME into a throwaway destination so that no real
## profile is touched. The installer clones from $GVM_ROOT, so it runs from a
## directory outside any git checkout.
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-installer-profile
#######################

mkdir -p $GVM_ROOT/tmp-installer-profile/bin # status=0
## (no shebang lines: tf reads a hash as the start of its assertions)
printf 'echo Darwin\n' > $GVM_ROOT/tmp-installer-profile/bin/uname # status=0
printf 'echo "Directory: /Users/me                    Shell: /bin/bash"\n' > $GVM_ROOT/tmp-installer-profile/bin/finger # status=0
chmod +x $GVM_ROOT/tmp-installer-profile/bin/uname $GVM_ROOT/tmp-installer-profile/bin/finger # status=0
PATH=$GVM_ROOT/tmp-installer-profile/bin:$PATH uname # match=/^Darwin$/
GVM_TEST_REV=$(git -C $GVM_ROOT rev-parse HEAD) # status=0
GVM_TEST_TMP=$(mktemp -d) # status=0
git -C $GVM_TEST_TMP rev-parse --show-toplevel # status!=0

## both ~/.profile and ~/.bash_profile: bash reads only ~/.bash_profile
mkdir -p $GVM_ROOT/tmp-installer-profile/both/home # status=0
touch $GVM_ROOT/tmp-installer-profile/both/home/.profile $GVM_ROOT/tmp-installer-profile/both/home/.bash_profile # status=0
(cd $GVM_TEST_TMP && HOME=$GVM_ROOT/tmp-installer-profile/both/home PATH=$GVM_ROOT/tmp-installer-profile/bin:$PATH SRC_REPO=$GVM_ROOT GVM_NO_GIT_BAK=1 GVM_NO_UPDATE_PROFILE= bash $GVM_ROOT/binscripts/gvm-installer $GVM_TEST_REV $GVM_ROOT/tmp-installer-profile/both/dest) 2>&1 # status=0; match=/macOS detected/; match=/Installed GVM/; match!=/Unable to locate profile/
grep -c 'scripts/gvm' $GVM_ROOT/tmp-installer-profile/both/home/.bash_profile # match=/^1$/
grep -c 'scripts/gvm' $GVM_ROOT/tmp-installer-profile/both/home/.profile # status!=0; match=/^0$/

## ~/.bash_login and ~/.profile: bash reads only ~/.bash_login
mkdir -p $GVM_ROOT/tmp-installer-profile/login/home # status=0
touch $GVM_ROOT/tmp-installer-profile/login/home/.profile $GVM_ROOT/tmp-installer-profile/login/home/.bash_login # status=0
(cd $GVM_TEST_TMP && HOME=$GVM_ROOT/tmp-installer-profile/login/home PATH=$GVM_ROOT/tmp-installer-profile/bin:$PATH SRC_REPO=$GVM_ROOT GVM_NO_GIT_BAK=1 GVM_NO_UPDATE_PROFILE= bash $GVM_ROOT/binscripts/gvm-installer $GVM_TEST_REV $GVM_ROOT/tmp-installer-profile/login/dest) 2>&1 # status=0; match=/Installed GVM/; match!=/Unable to locate profile/
grep -c 'scripts/gvm' $GVM_ROOT/tmp-installer-profile/login/home/.bash_login # match=/^1$/
grep -c 'scripts/gvm' $GVM_ROOT/tmp-installer-profile/login/home/.profile # status!=0; match=/^0$/

## only ~/.profile: it is the file bash reads, so it still gets the line
mkdir -p $GVM_ROOT/tmp-installer-profile/profile/home # status=0
touch $GVM_ROOT/tmp-installer-profile/profile/home/.profile # status=0
(cd $GVM_TEST_TMP && HOME=$GVM_ROOT/tmp-installer-profile/profile/home PATH=$GVM_ROOT/tmp-installer-profile/bin:$PATH SRC_REPO=$GVM_ROOT GVM_NO_GIT_BAK=1 GVM_NO_UPDATE_PROFILE= bash $GVM_ROOT/binscripts/gvm-installer $GVM_TEST_REV $GVM_ROOT/tmp-installer-profile/profile/dest) 2>&1 # status=0; match=/Installed GVM/; match!=/Unable to locate profile/
grep -c 'scripts/gvm' $GVM_ROOT/tmp-installer-profile/profile/home/.profile # match=/^1$/
ls -A $GVM_ROOT/tmp-installer-profile/profile/home # match!=/bash_profile/; match!=/bash_login/

## none of the three: the installer must say so and print the line to add,
## and must not create a profile of its own
mkdir -p $GVM_ROOT/tmp-installer-profile/none/home # status=0
(cd $GVM_TEST_TMP && HOME=$GVM_ROOT/tmp-installer-profile/none/home PATH=$GVM_ROOT/tmp-installer-profile/bin:$PATH SRC_REPO=$GVM_ROOT GVM_NO_GIT_BAK=1 GVM_NO_UPDATE_PROFILE= bash $GVM_ROOT/binscripts/gvm-installer $GVM_TEST_REV $GVM_ROOT/tmp-installer-profile/none/dest) 2>&1 # status=0; match=/Unable to locate profile/; match=/manually add/; match=/scripts\/gvm/
ls -A $GVM_ROOT/tmp-installer-profile/none/home | grep -cE '^\.(bash_profile|bash_login|profile|bashrc|zshrc)$' # status!=0; match=/^0$/

## the Linux branch is unchanged: ~/.bashrc first, even next to ~/.bash_profile
printf 'echo Linux\n' > $GVM_ROOT/tmp-installer-profile/bin/uname # status=0
mkdir -p $GVM_ROOT/tmp-installer-profile/linux/home # status=0
touch $GVM_ROOT/tmp-installer-profile/linux/home/.bashrc $GVM_ROOT/tmp-installer-profile/linux/home/.bash_profile # status=0
(cd $GVM_TEST_TMP && HOME=$GVM_ROOT/tmp-installer-profile/linux/home PATH=$GVM_ROOT/tmp-installer-profile/bin:$PATH SRC_REPO=$GVM_ROOT GVM_NO_GIT_BAK=1 GVM_NO_UPDATE_PROFILE= bash $GVM_ROOT/binscripts/gvm-installer $GVM_TEST_REV $GVM_ROOT/tmp-installer-profile/linux/dest) 2>&1 # status=0; match=/Installed GVM/; match!=/Unable to locate profile/
grep -c 'scripts/gvm' $GVM_ROOT/tmp-installer-profile/linux/home/.bashrc # match=/^1$/
grep -c 'scripts/gvm' $GVM_ROOT/tmp-installer-profile/linux/home/.bash_profile # status!=0; match=/^0$/

## Cleanup test objects
rm -rf $GVM_ROOT/tmp-installer-profile $GVM_TEST_TMP
unset GVM_TEST_REV GVM_TEST_TMP
