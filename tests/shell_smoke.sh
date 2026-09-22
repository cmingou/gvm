#!/usr/bin/env bash
#
# Shell integration smoke test, runnable under both bash and zsh.
#
# The tf-based tests under tests/*_comment_test.sh only run under bash: tf
# selects its runner from a shebang line and its exit-status capture is
# unreliable under zsh, which reports every gvm call as failed even when the
# same call succeeds in a real zsh. This script therefore covers the shell
# integration a second time, using plain assertions, so that CI can gate on
# zsh without tf in the way.
#
# Usage: GVM_ROOT must point at an installed gvm; run it with the shell under
# test, e.g. `zsh tests/zsh_smoke.sh` or `bash tests/zsh_smoke.sh`.

# No `set -e` here: gvm's cd() override calls a helper that returns non-zero
# when the current directory has no .go-version, so every cd -- including the
# `cd .` that sourcing the integration performs -- would abort an errexit
# shell. Failures are counted explicitly instead.

[ -n "$GVM_ROOT" ] || { echo "FAIL: GVM_ROOT is not set"; exit 1; }
[ -r "$GVM_ROOT/scripts/gvm" ] || { echo "FAIL: no gvm at $GVM_ROOT"; exit 1; }

failures=0
shell_name="bash ${BASH_VERSION:-}"
[ -n "$ZSH_VERSION" ] && shell_name="zsh $ZSH_VERSION"
echo "## smoke test under $shell_name"

# assert_match <description> <regex> <actual>
assert_match() {
	case "$3" in
		*$2*) echo "ok   - $1" ;;
		*) echo "FAIL - $1: expected '$2' in '$3'"; failures=$((failures + 1)) ;;
	esac
}

# assert_equal <description> <expected> <actual>
assert_equal() {
	if [ "$2" = "$3" ]; then
		echo "ok   - $1"
	else
		echo "FAIL - $1: expected '$2', got '$3'"
		failures=$((failures + 1))
	fi
}

version="go0.0.9"
pkgset="smoketest"
workdir="$GVM_ROOT/tmp-smoke"

cleanup() {
	rm -rf "$GVM_ROOT/gos/$version" "$GVM_ROOT/pkgsets/$version" \
		"$GVM_ROOT/environments/$version" "$GVM_ROOT/environments/$version@$pkgset" \
		"$workdir"
}
cleanup

mkdir -p "$GVM_ROOT/gos/$version/bin" "$GVM_ROOT/pkgsets/$version/global"
mkdir -p "$workdir/plain" "$workdir/versioned"
printf 'export GVM_ROOT; GVM_ROOT="%s"\n' "$GVM_ROOT" > "$GVM_ROOT/environments/$version"
{
	printf 'export gvm_go_name; gvm_go_name="%s"\n' "$version"
	printf 'export gvm_pkgset_name; gvm_pkgset_name="global"\n'
	printf 'export GOROOT; GOROOT="$GVM_ROOT/gos/%s"\n' "$version"
	printf 'export GOPATH; GOPATH="$GVM_ROOT/pkgsets/%s/global"\n' "$version"
	printf 'export PATH; PATH="$GVM_ROOT/gos/%s/bin:$GVM_ROOT/bin:$PATH"\n' "$version"
} >> "$GVM_ROOT/environments/$version"
printf '%s\n' "$version" > "$workdir/versioned/.go-version"
printf '%s\n' "$pkgset" > "$workdir/versioned/.go-pkgset"

# sourcing the shell integration must succeed and define the overrides
. "$GVM_ROOT/scripts/gvm"
assert_match "gvm version reports itself" "Go Version Manager" "$(gvm version)"
assert_match "cd is overridden" "cd" "$(command -v cd)"

# gvm use
gvm use "$version" --quiet
assert_equal "gvm use sets gvm_go_name" "$version" "$gvm_go_name"
assert_equal "gvm use sets GOROOT" "$GVM_ROOT/gos/$version" "$GOROOT"

# pkgset
gvm pkgset create "$pkgset" > /dev/null
assert_match "gvm pkgset list shows the new pkgset" "$pkgset" "$(gvm pkgset list)"

# cd must not switch anything in a directory without dot files (issue #1)
cd "$workdir/plain"
assert_equal "cd into a plain directory keeps the version" "$version" "$gvm_go_name"

# cd must auto-switch where .go-version / .go-pkgset are present
cd "$workdir/versioned" > /dev/null
assert_equal "cd auto-switches the version" "$version" "$gvm_go_name"
assert_equal "cd auto-switches the pkgset" "$pkgset" "$gvm_pkgset_name"

# a failing cd must report failure and must not move (issue #6, issue #8)
cd "$workdir/does-not-exist" 2> /dev/null
rslt=$?
assert_equal "a failing cd returns non-zero" "1" "$([ "$rslt" -ne 0 ] && echo 1 || echo 0)"
assert_match "a failing cd does not change directory" "versioned" "$PWD"

# PATH munging must keep entries containing whitespace intact (issue #12)
munged="$(__gvm_munge_path "/usr/bin:/opt/My Tools/bin:/bin")"
assert_equal "munge_path splits on ':' only" "/usr/bin:/opt/My Tools/bin:/bin" "$munged"

cd "$GVM_ROOT"
gvm uninstall "$version" > /dev/null 2>&1 || true
cleanup

if [ "$failures" -ne 0 ]; then
	echo "## $failures assertion(s) failed under $shell_name"
	exit 1
fi
echo "## all assertions passed under $shell_name"
