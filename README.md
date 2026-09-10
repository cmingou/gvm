# gvm

GVM provides an interface to manage Go versions.

> **This is a fork.** The upstream project, [moovweb/gvm](https://github.com/moovweb/gvm),
> is no longer actively maintained, and its shell integration had become slow
> enough to be noticeable on every shell startup and every `cd`. This fork exists
> to fix that. It is maintained at [cmingou/gvm](https://github.com/cmingou/gvm).
>
> Upstream compatibility is **not** a goal and changes here are not submitted back.
> If you want the original, use [moovweb/gvm](https://github.com/moovweb/gvm).
>
> gvm is MIT licensed and remains so; see [License and attribution](#license-and-attribution).

What's different in this fork
=============================

**Shell startup no longer forks a process per character.** `_encode()` in
`scripts/function/_bash_pseudo_hash` spawned one `hexdump` subprocess for every
character outside `[A-Za-z0-9.~_-]`. Because gvm stores `GOROOT`, `GOPATH`,
`PATH`, `LD_LIBRARY_PATH` and friends as percent-encoded values, a typical
`environments/default` triggers around 76 forks — on every login, and again on
every `cd`, since gvm overrides `cd()` and re-resolves the default environment
each time. The encoding is now done with the shell's own `printf` builtin.

Measured on macOS 26 / arm64 with 7 installed Go versions,
`source $GVM_ROOT/scripts/gvm`:

| | before | after |
|---|---|---|
| cold | ~1.05s | ~0.19s |
| warm | ~0.6s | ~0.15s |

Output is byte-for-byte identical to the previous implementation for all 255
possible byte values and for real environment-file values, verified under
bash 5.3, bash 3.2 (the version macOS ships), zsh with `KSH_ARRAYS`, and under a
UTF-8 locale. `hexdump` is no longer a runtime dependency.

Remaining performance work is tracked in
[issues](https://github.com/cmingou/gvm/issues).

Features
========
* Install/Uninstall Go versions with `gvm install [tag]` where tag is "60.3", "go1", "weekly.2011-11-08", or "tip"
* List added/removed files in GOROOT with `gvm diff`
* Manage GOPATHs with `gvm pkgset [create/use/delete] [name]`. Use `--local` as `name` to manage repository under local path (`/path/to/repo/.gvm_local`).
* List latest release tags with `gvm listall`. Use `--all` to list weekly as well.
* Cache a clean copy of the latest Go source for multiple version installs.
* Link project directories into GOPATH

Background
==========

From the original project, in Josh Bussdieker's words:

> When we started developing in Go mismatched dependencies and API changes plagued our build process and made it extremely difficult to merge with other peoples changes.
>
> After nuking my entire GOROOT several times and rebuilding I decided to come up with a tool to oversee the process. It eventually evolved into what gvm is today.

Installing
==========

To install:

1.  Install [Bison](https://www.gnu.org/software/bison/):

    ```
    sudo apt-get install bison
    ```

1.  Install gvm:

    ```
    bash < <(curl -s -S -L https://raw.githubusercontent.com/cmingou/gvm/master/binscripts/gvm-installer)
    ```

Or if you are using zsh just change `bash` with `zsh`

The installer clones whatever `SRC_REPO` points at, defaulting to this fork. To
install a different repository — upstream, or your own fork — override it:

```
SRC_REPO=https://github.com/moovweb/gvm.git \
  bash < <(curl -s -S -L https://raw.githubusercontent.com/cmingou/gvm/master/binscripts/gvm-installer)
```

Installing Go
=============
    gvm install go1.4
    gvm use go1.4 [--default]
Once this is done Go will be in the path and ready to use. $GOROOT and $GOPATH are set automatically.

Additional options can be specified when installing Go:

    Usage: gvm install [version] [options]
        -s,  --source=SOURCE      Install Go from specified source.
        -n,  --name=NAME          Override the default name for this version.
        -pb, --with-protobuf      Install Go protocol buffers.
        -b,  --with-build-tools   Install package build tools.
        -B,  --binary             Only install from binary.
             --prefer-binary      Attempt a binary install, falling back to source.
        -h,  --help               Display this message.

### A Note on Compiling Go 1.5+
Go 1.5+ removed the C compilers from the toolchain and [replaced][compiler_note] them with one written in Go. Obviously, this creates a bootstrapping problem if you don't already have a working Go install. In order to compile Go 1.5+, make sure Go 1.4 is installed first. If Go 1.4 won't install try a later version (e.g. go1.5), just make sure you have the `-B` option after the version number.

```
gvm install go1.4 -B
gvm use go1.4
export GOROOT_BOOTSTRAP=$GOROOT
gvm install go1.7
```

### A Note on ARMv6 and ARMv7 architectures (32 bit)
Binary versions for ARMv6 architecture are available [starting from Go 1.6](https://go.dev/dl/#go1.6). So, it is necessary to bootstrap with an existing binary version, then it will be possible compiling other versions. For instance, to bootstrap a setup, version `1.21.0` may be used:

```
gvm install go1.21.0 -B
gvm use go1.21.0
```

And then, compile any other version:

```
gvm install go1.20.7
```

#### To install Go 1.20+
Go 1.20+ requires go1.17.3+. Use the below:

```
gvm install go1.4 -B
gvm use go1.4
export GOROOT_BOOTSTRAP=$GOROOT
gvm install go1.17.13
gvm use go1.17.13
export GOROOT_BOOTSTRAP=$GOROOT
gvm install go1.20
gvm use go1.20
```

[compiler_note]: https://docs.google.com/document/d/1OaatvGhEAq7VseQ9kkavxKNAfepWy2yhPUBs96FGV28/edit

List Go Versions
================
To list all installed Go versions (The current version is prefixed with "=>"):

    gvm list

To list all Go versions available for download:

    gvm listall

Uninstalling
============
To completely remove gvm and all installed Go versions and packages:

    gvm implode

If that doesn't work see the troubleshooting steps at the bottom of this page.

Mac OS X Requirements
====================
 * Install Mercurial from https://www.mercurial-scm.org/downloads
 * Install Xcode Command Line Tools from the App Store.

```
xcode-select --install
brew update
brew install mercurial
```

Linux Requirements
==================

Debian/Ubuntu
==================
    sudo apt-get install curl git mercurial make binutils bison gcc build-essential

Redhat/Centos
==================

    sudo yum install curl
    sudo yum install git
    sudo yum install make
    sudo yum install bison
    sudo yum install gcc
    sudo yum install glibc-devel

 * Install Mercurial from http://pkgs.repoforge.org/mercurial/

FreeBSD Requirements
====================

    sudo pkg_add -r bash
    sudo pkg_add -r git
    sudo pkg_add -r mercurial

Vendoring Native Code and Dependencies
==================================================
GVM supports vendoring package set-specific native code and related
dependencies, which is useful if you need to qualify a new configuration
or version of one of these dependencies against a last-known-good version
in an isolated manner.  Such behavior is critical to maintaining good release
engineering and production environment hygiene.

As a convenience matter, GVM will furnish the following environment variables to
aid in this manner if you want to decouple your work from what the operating
system provides:

1. ``${GVM_OVERLAY_PREFIX}`` functions in a manner akin to a root directory
  hierarchy suitable for auto{conf,make,tools} where it could be passed in
  to ``./configure --prefix=${GVM_OVERLAY_PREFIX}`` and not conflict with any
  existing operating system artifacts and hermetically be used by your
  workspace.  This is suitable to use with ``C{PP,XX}FLAGS and LDFLAGS``, but you will have
  to manage these yourself, since each tool that uses them is different.

2. ``${PATH}`` includes ``${GVM_OVERLAY_PREFIX}/bin`` so that any tools you
  manually install will reside there, available for you.

3. ``${LD_LIBRARY_PATH}`` includes ``${GVM_OVERLAY_PREFIX}/lib`` so that any
  runtime library searching can be fulfilled there on FreeBSD and Linux.

4. ``${DYLD_LIBRARY_PATH}`` includes ``${GVM_OVERLAY_PREFIX}/lib`` so that any
  runtime library searching can be fulfilled there on Mac OS X.

5. ``${PKG_CONFIG_PATH}`` includes ``${GVM_OVERLAY_PREFIX}/lib/pkgconfig`` so
  that ``pkg-config`` can automatically resolve any vendored dependencies.

Recipe for success:

    gvm use go1.1
    gvm pkgset use current-known-good
    # Let's assume that this includes some C headers and native libraries, which
    # Go's CGO facility wraps for us.  Let's assume that these native
    # dependencies are at version V.
    gvm pkgset create trial-next-version
    # Let's assume that V+1 has come along and you want to safely trial it in
    # your workspace.
    gvm pkgset use trial-next-version
    # Do your work here replicating current-known-good from above, but install
    # V+1 into ${GVM_OVERLAY_PREFIX}.

See examples/native for a working example.

Hacking on gvm
==============

The installer clones this repository into `$GVM_ROOT` and then renames `.git` to
`git.bak`, so an installed gvm is not a usable checkout. If you want to develop
against a live install instead of reinstalling every time, keep `.git` in place
and tell gvm not to complain about it:

```
mv "$GVM_ROOT/git.bak" "$GVM_ROOT/.git"
```

then, **before** the line that sources gvm in your shell profile:

```
export GVM_NO_GIT_BAK=1
```

Without `GVM_NO_GIT_BAK`, `scripts/env/gvm` refuses to run when `.git` is present
and tells you to reinstall. With it, updating is just `git -C "$GVM_ROOT" pull`.

Note that `binscripts/gvm-installer` deliberately refuses to run when `$GVM_ROOT`
already exists and suggests `rm -rf` — that would take every installed Go version
and package set with it. `gos/`, `pkgsets/`, `environments/` and `archive/` are
gitignored, so pulling into an existing checkout is safe; reinstalling is not.

Troubleshooting
===============
The state of gvm's files can get mixed up, especially when upgrading from
versions older than 0.0.8. `rm -rf ~/.gvm` will always remove gvm — along with
every Go version and package set it manages.

License and attribution
=======================

gvm is released under the MIT license. The full text, including the copyright
notice that must be retained in copies and derivative works, is in
[LICENSE](LICENSE):

> Copyright (C) 2012 Moov Corp.

Originally written by Josh Bussdieker (jbuss, jaja, jbussdieker) while working at
[Moovweb](https://www.moovweb.com), and subsequently maintained upstream by
[Benjamin Knigge](https://github.com/BenKnigge). See [AUTHORS](AUTHORS) and
[ChangeLog](ChangeLog).

This fork keeps that license unchanged; modifications made here are offered under
the same terms.
