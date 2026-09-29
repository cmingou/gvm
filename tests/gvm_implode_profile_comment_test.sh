source $GVM_ROOT/scripts/gvm
## Regression test for issue 31: `gvm implode` must remove the source line
## that the installer appended to the user's shell profile. It only removed
## $GVM_ROOT, so every later shell kept sourcing a file that no longer
## existed; the `[[ -s ... ]]` guard hid the failure but the line stayed
## behind for good. The implode runs against a throwaway copy of the root and
## a throwaway HOME, so neither the suite's root nor any real profile is
## touched. GVM_NO_UPDATE_PROFILE is cleared for the calls that must edit
## the profiles: CI sets it to keep the runner's profile untouched.
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-implode-profile
#######################

mkdir -p $GVM_ROOT/tmp-implode-profile/root $GVM_ROOT/tmp-implode-profile/home/dotfiles # status=0
cp -R $GVM_ROOT/bin $GVM_ROOT/scripts $GVM_ROOT/locales $GVM_ROOT/VERSION $GVM_ROOT/tmp-implode-profile/root/ # status=0
GVM_TEST_ROOT=$GVM_ROOT/tmp-implode-profile/root
GVM_TEST_HOME=$GVM_ROOT/tmp-implode-profile/home
## the line exactly as binscripts/gvm-installer writes it, for this root and
## for an unrelated root that must be left alone
GVM_TEST_LINE="[[ -s \"$GVM_TEST_ROOT/scripts/gvm\" ]] && source \"$GVM_TEST_ROOT/scripts/gvm\""
GVM_TEST_OTHER="[[ -s \"$GVM_TEST_HOME/other-gvm/scripts/gvm\" ]] && source \"$GVM_TEST_HOME/other-gvm/scripts/gvm\""
printf '%s\n' 'export EDITOR=vi' '' "$GVM_TEST_LINE" 'alias ll="ls -l"' > $GVM_TEST_HOME/.bashrc # status=0
printf '%s\n' "$GVM_TEST_LINE" > $GVM_TEST_HOME/.zshrc # status=0
printf '%s\n' ': other' "$GVM_TEST_OTHER" > $GVM_TEST_HOME/.profile # status=0
## a profile kept in a dotfiles repository behind a symlink must stay a symlink
printf '%s\n' 'umask 022' "$GVM_TEST_LINE" > $GVM_TEST_HOME/dotfiles/bash_profile # status=0
ln -s dotfiles/bash_profile $GVM_TEST_HOME/.bash_profile # status=0
chmod 600 $GVM_TEST_HOME/.bashrc # status=0
grep -c 'scripts/gvm' $GVM_TEST_HOME/.bashrc $GVM_TEST_HOME/.zshrc $GVM_TEST_HOME/.profile $GVM_TEST_HOME/.bash_profile # match=/\.bashrc:1/; match=/\.zshrc:1/; match=/\.profile:1/; match=/\.bash_profile:1/

## answering no must leave every profile alone
echo n | env HOME=$GVM_TEST_HOME GVM_ROOT=$GVM_TEST_ROOT GVM_NO_GIT_BAK=1 GVM_NO_UPDATE_PROFILE= $GVM_TEST_ROOT/bin/gvm implode 2>&1 # status=0; match=/Action cancelled/; match!=/Removed/
grep -c 'scripts/gvm' $GVM_TEST_HOME/.bashrc $GVM_TEST_HOME/.zshrc # match=/\.bashrc:1/; match=/\.zshrc:1/

## answering yes must remove the root and the line, from every profile that
## has it, and say which profiles were cleaned
echo y | env HOME=$GVM_TEST_HOME GVM_ROOT=$GVM_TEST_ROOT GVM_NO_GIT_BAK=1 GVM_NO_UPDATE_PROFILE= $GVM_TEST_ROOT/bin/gvm implode 2>&1 # status=0; match=/GVM successfully removed/; match=/Removed the gvm source line from .*\.bashrc/; match=/\.zshrc/; match=/\.bash_profile/; match!=/\.profile/
[ -d $GVM_TEST_ROOT ] || echo GONE # match=/^GONE$/
grep -c "$GVM_TEST_ROOT" $GVM_TEST_HOME/.bashrc $GVM_TEST_HOME/.zshrc $GVM_TEST_HOME/.bash_profile $GVM_TEST_HOME/dotfiles/bash_profile # status!=0; match=/\.bashrc:0/; match=/\.zshrc:0/; match=/\.bash_profile:0/; match=/dotfiles\/bash_profile:0/
## the other lines survive, in order, and the unrelated root's line stays
cat $GVM_TEST_HOME/.bashrc # match=/^export EDITOR=vi$/; match=/^alias ll="ls -l"$/
grep -n . $GVM_TEST_HOME/.bashrc # match=/^1:export EDITOR=vi$/; match=/^3:alias ll="ls -l"$/
cat $GVM_TEST_HOME/.zshrc | wc -c # match=/^ *0$/
grep -c 'other-gvm/scripts/gvm' $GVM_TEST_HOME/.profile # match=/^1$/
cat $GVM_TEST_HOME/dotfiles/bash_profile # match=/^umask 022$/
[ -L $GVM_TEST_HOME/.bash_profile ] && echo STILL-A-SYMLINK # match=/^STILL-A-SYMLINK$/
ls -l $GVM_TEST_HOME/.bashrc # match=/^-rw-------/

## with GVM_NO_UPDATE_PROFILE set the profiles are not touched, as with the
## installer
mkdir -p $GVM_TEST_ROOT # status=0
cp -R $GVM_ROOT/bin $GVM_ROOT/scripts $GVM_ROOT/locales $GVM_ROOT/VERSION $GVM_TEST_ROOT/ # status=0
printf '%s\n' "$GVM_TEST_LINE" > $GVM_TEST_HOME/.bashrc # status=0
echo y | env HOME=$GVM_TEST_HOME GVM_ROOT=$GVM_TEST_ROOT GVM_NO_GIT_BAK=1 GVM_NO_UPDATE_PROFILE=1 $GVM_TEST_ROOT/bin/gvm implode 2>&1 # status=0; match=/GVM successfully removed/; match!=/Removed the gvm source line/
grep -c 'scripts/gvm' $GVM_TEST_HOME/.bashrc # match=/^1$/

## Cleanup test objects
rm -rf $GVM_ROOT/tmp-implode-profile
unset GVM_TEST_ROOT GVM_TEST_HOME GVM_TEST_LINE GVM_TEST_OTHER
