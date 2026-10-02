source $GVM_ROOT/scripts/gvm
## Regression test for issue 17: scripts/gvm-check answered a missing git with
## "apt-get install mercurial" / "brew install mercurial", a leftover from the
## days Go's source lived in Mercurial, and hardcoded apt-get for every tool on
## every platform, with no macOS line at all for binutils, bison, gcc or make.
## The check is run against a PATH that links to everything on the system
## except the tools under test, with a fake uname to pick the platform and
## fake package managers to pick the advice, so the result does not depend on
## the machine running the test. Shebangs are spelled \043 because a literal #
## would end the tf command.
## Cleanup test objects
rm -rf $GVM_ROOT/tmp-check-advice
#######################

mkdir -p $GVM_ROOT/tmp-check-advice/bin $GVM_ROOT/tmp-check-advice/os # status=0
ln -s /usr/bin/* /bin/* /usr/local/bin/* $GVM_ROOT/tmp-check-advice/bin/ 2> /dev/null; true # status=0
rm -f $GVM_ROOT/tmp-check-advice/bin/git $GVM_ROOT/tmp-check-advice/bin/bison $GVM_ROOT/tmp-check-advice/bin/gcc $GVM_ROOT/tmp-check-advice/bin/make $GVM_ROOT/tmp-check-advice/bin/ar $GVM_ROOT/tmp-check-advice/bin/uname # status=0
rm -f $GVM_ROOT/tmp-check-advice/bin/apt-get $GVM_ROOT/tmp-check-advice/bin/dnf $GVM_ROOT/tmp-check-advice/bin/yum $GVM_ROOT/tmp-check-advice/bin/pacman $GVM_ROOT/tmp-check-advice/bin/zypper $GVM_ROOT/tmp-check-advice/bin/apk # status=0
PATH=$GVM_ROOT/tmp-check-advice/bin command -v git # status!=0
PATH=$GVM_ROOT/tmp-check-advice/bin command -v ls # status=0

## the platform and the package manager are stand-ins on PATH: uname prints
## FAKE_OS, and an empty executable stands for each package manager
printf '\043!/bin/sh\necho "${FAKE_OS:-Linux}"\n' > $GVM_ROOT/tmp-check-advice/os/uname # status=0
for pm in apt-get dnf yum pacman zypper apk; do printf '\043!/bin/sh\nexit 0\n' > $GVM_ROOT/tmp-check-advice/os/$pm; done # status=0
chmod +x $GVM_ROOT/tmp-check-advice/os/* # status=0
PATH=$GVM_ROOT/tmp-check-advice/os FAKE_OS=Darwin uname # match=/^Darwin$/

## a Debian-style Linux: git is answered with git, never with mercurial, and
## every tool gets an apt-get line
ln -sf $GVM_ROOT/tmp-check-advice/os/uname $GVM_ROOT/tmp-check-advice/bin/uname # status=0
ln -sf $GVM_ROOT/tmp-check-advice/os/apt-get $GVM_ROOT/tmp-check-advice/bin/apt-get # status=0
env PATH=$GVM_ROOT/tmp-check-advice/bin FAKE_OS=Linux GVM_ROOT=$GVM_ROOT $GVM_ROOT/scripts/gvm-check 2>&1 # status!=0; match=/Could not find git/; match=/apt-get install git/; match!=/mercurial/; match=/Could not find bison/; match=/apt-get install bison/; match=/apt-get install binutils/; match=/apt-get install gcc/; match=/apt-get install make/; match!=/brew/; match!=/xcode-select/

## a Fedora-style Linux gets dnf, Arch gets pacman, Alpine gets apk
rm -f $GVM_ROOT/tmp-check-advice/bin/apt-get # status=0
ln -sf $GVM_ROOT/tmp-check-advice/os/dnf $GVM_ROOT/tmp-check-advice/bin/dnf # status=0
env PATH=$GVM_ROOT/tmp-check-advice/bin FAKE_OS=Linux GVM_ROOT=$GVM_ROOT $GVM_ROOT/scripts/gvm-check 2>&1 # status!=0; match=/dnf install git/; match=/dnf install bison/; match!=/apt-get/; match!=/mercurial/
rm -f $GVM_ROOT/tmp-check-advice/bin/dnf # status=0
ln -sf $GVM_ROOT/tmp-check-advice/os/pacman $GVM_ROOT/tmp-check-advice/bin/pacman # status=0
env PATH=$GVM_ROOT/tmp-check-advice/bin FAKE_OS=Linux GVM_ROOT=$GVM_ROOT $GVM_ROOT/scripts/gvm-check 2>&1 # status!=0; match=/pacman -S git/; match=/pacman -S bison/; match!=/apt-get/
rm -f $GVM_ROOT/tmp-check-advice/bin/pacman # status=0
ln -sf $GVM_ROOT/tmp-check-advice/os/apk $GVM_ROOT/tmp-check-advice/bin/apk # status=0
env PATH=$GVM_ROOT/tmp-check-advice/bin FAKE_OS=Linux GVM_ROOT=$GVM_ROOT $GVM_ROOT/scripts/gvm-check 2>&1 # status!=0; match=/apk add git/; match=/apk add make/; match!=/apt-get/
rm -f $GVM_ROOT/tmp-check-advice/bin/apk # status=0

## with no recognised package manager the common ones are listed
env PATH=$GVM_ROOT/tmp-check-advice/bin FAKE_OS=Linux GVM_ROOT=$GVM_ROOT $GVM_ROOT/scripts/gvm-check 2>&1 # status!=0; match=/Could not find git/; match=/apt-get install git/; match=/pacman/; match!=/mercurial/

## macOS: the Xcode Command Line Tools provide git, ar, bison, gcc and make,
## so that is the advice, with no apt-get line anywhere
env PATH=$GVM_ROOT/tmp-check-advice/bin FAKE_OS=Darwin GVM_ROOT=$GVM_ROOT $GVM_ROOT/scripts/gvm-check 2>&1 # status!=0; match=/Could not find git/; match=/Could not find bison/; match=/Could not find gcc/; match=/Could not find make/; match=/Could not find binutils/; match=/xcode-select --install/; match!=/apt-get/; match!=/linux:/; match!=/mercurial/

## with everything present the check passes silently, on either platform
ln -sf "$(command -v true)" $GVM_ROOT/tmp-check-advice/bin/git # status=0
for t in bison gcc make ar; do ln -sf "$(command -v true)" $GVM_ROOT/tmp-check-advice/bin/$t; done # status=0
env PATH=$GVM_ROOT/tmp-check-advice/bin FAKE_OS=Linux GVM_ROOT=$GVM_ROOT $GVM_ROOT/scripts/gvm-check 2>&1 # status=0; match!=/Could not find/
env PATH=$GVM_ROOT/tmp-check-advice/bin FAKE_OS=Darwin GVM_ROOT=$GVM_ROOT $GVM_ROOT/scripts/gvm-check 2>&1 # status=0; match!=/Could not find/

## Cleanup test objects
rm -rf $GVM_ROOT/tmp-check-advice
