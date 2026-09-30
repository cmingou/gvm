gvmdir = $(bindir)/
gvm_SCRIPTS = bin/gvm
install_dir = $(prefix)/gvm

# The install itself is done by binscripts/gvm-make-install: a plain
# `cp -rf .` copied the checkout's .git along, and gvm refuses to run from a
# root that has one (issue #39). The third argument is the root's path at
# runtime, which differs from the second only under a DESTDIR staging install.
install-exec-hook:
	"$(abs_top_srcdir)/binscripts/gvm-make-install" "$(abs_top_srcdir)" "$(DESTDIR)$(install_dir)" "$(install_dir)"
