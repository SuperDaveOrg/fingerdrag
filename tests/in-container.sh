#!/usr/bin/env bash
# End-to-end test, run as root inside a throwaway Debian or Ubuntu based
# container with the repository mounted at /src. Exercises: doctor, the
# backport gate on old releases, the missing build-dependency path, install
# with a chosen finger count, a rebuild on top of a patched build, the apt
# hook after a simulated upgrade, a flag-free restore, and uninstall.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
MARK=LIBINPUT_DRAG_3FG_DEFAULT
STATE=/var/lib/fingerdrag/enabled

pass() { printf '\033[32mPASS\033[0m %s\n' "$*"; }
fail() {
	printf '\033[31mFAIL\033[0m %s\n' "$*"
	exit 1
}
lib() { dpkg -L libinput10 | grep -m1 -E '/libinput\.so\.[0-9]+$'; }
ver() { dpkg-query -W -f='${Version}' libinput10; }
has() { grep -a -c "$1" "$(lib)" >/dev/null; }

apt-get -qq update
apt-get -qq install -y --no-install-recommends \
	libinput10 libinput-bin build-essential dpkg-dev fakeroot patch ca-certificates >/dev/null
cd /src
stock=$(ver)

echo "### doctor on a stock system"
doctor=$(./fingerdrag doctor)
echo "$doctor"
has "$MARK" && fail "stock library already contains the marker"

flags=()
if grep -c 'too old' <<<"$doctor" >/dev/null; then
	echo "### old libinput: install must refuse without --backport"
	if out=$(./fingerdrag install 2>&1); then
		fail "install succeeded on an old libinput without --backport"
	fi
	grep -c -- 'fingerdrag install --backport' <<<"$out" >/dev/null || {
		echo "$out"
		fail "no backport hint printed"
	}
	[[ $(ver) == "$stock" ]] || fail "refused install changed the system"
	pass "refused, with a backport hint"
	flags=(--backport)
fi

echo "### install without build dependencies"
if out=$(./fingerdrag install "${flags[@]}" 2>&1); then
	echo "$out"
	fail "install succeeded without build dependencies"
fi
deps=$(sed -n 's/^  sudo apt-get install --no-install-recommends //p' <<<"$out")
[[ -n $deps ]] || {
	echo "$out"
	fail "no build-dependency hint printed"
}
pass "missing build dependencies reported: $deps"
# shellcheck disable=SC2086
apt-get -qq install -y --no-install-recommends $deps >/dev/null

echo "### install with no finger count: three is the default, and it says so"
./fingerdrag install "${flags[@]}" | tee /tmp/install.log
has "$MARK" || fail "installed library is not patched"
has 'FINGERDRAG_BUILTIN_NFINGERS=3' || fail "three-finger default not compiled in"
grep -c 'DRAG WITH THREE FINGERS' /tmp/install.log >/dev/null || fail "install did not announce the finger count"
grep -c -- 'fingerdrag install --fingers 4' /tmp/install.log >/dev/null || fail "install did not say how to change it"
[[ $(ver) == *+fingerdrag1 ]] || fail "unexpected version $(ver)"
if [[ ${#flags[@]} -gt 0 ]]; then
	[[ $(ver) == *~bpo+fingerdrag1 ]] || fail "backport version lacks ~bpo: $(ver)"
	dpkg --compare-versions "$(ver)" gt "$stock" || fail "backport does not sort above stock"
fi
[[ -f /etc/apt/apt.conf.d/99fingerdrag && -x /usr/local/bin/fingerdrag ]] || fail "hook or tool missing"
[[ -n $(find /var/lib/fingerdrag/rollback -name '*.deb') ]] || fail "no rollback packages saved"
[[ $(sed -n 's/^stock=//p' $STATE) == "$stock" ]] || fail "state file has the wrong stock version"
fingerdrag doctor | grep -c 'Drag mode .*three fingers (built in)' >/dev/null || fail "doctor does not report the mode"
apt-get check >/dev/null || fail "apt reports broken dependencies"
pass "patched build installed: $(ver)"

echo "### rebuild on top of a patched build, switching to four fingers"
fingerdrag install --fingers 4 >/tmp/install4.log
[[ $(ver) == *+fingerdrag2 ]] || fail "revision did not increment: $(ver)"
has 'FINGERDRAG_BUILTIN_NFINGERS=4' || fail "four-finger default not compiled in"
grep -c 'DRAG WITH FOUR FINGERS' /tmp/install4.log >/dev/null || fail "install did not announce four fingers"
fingerdrag doctor | grep -c 'Drag mode .*four fingers (built in)' >/dev/null || fail "doctor does not report four fingers"
pass "revision incremented: $(ver)"

echo "### set is refused on X11"
if XDG_SESSION_TYPE=x11 fingerdrag set 3 >/tmp/set.log 2>&1; then
	fail "set claimed to work on X11"
fi
grep -c -- 'fingerdrag install --fingers 3' /tmp/set.log >/dev/null || fail "set gave no X11 advice"
pass "set points X11 users at install --fingers"

echo "### simulated upgrade back to stock"
apt-get install -y --reinstall --allow-downgrades "libinput10=$stock" "libinput-bin=$stock" >/tmp/revert.log 2>&1 || {
	cat /tmp/revert.log
	fail "could not reinstall stock packages"
}
grep -c 'a package upgrade replaced the patched libinput' /tmp/revert.log >/dev/null || {
	cat /tmp/revert.log
	fail "apt hook did not warn"
}
pass "apt hook warned: $(grep 'fingerdrag:' /tmp/revert.log)"
fingerdrag doctor | grep -c 'A system upgrade replaced the patched build' >/dev/null || fail "doctor missed the reversion"

echo "### restore with no flags, then uninstall"
fingerdrag install >/dev/null
has 'FINGERDRAG_BUILTIN_NFINGERS=4' || fail "restore did not keep the remembered settings"
pass "restored: $(ver)"
fingerdrag uninstall
has "$MARK" && fail "library still patched after uninstall"
[[ ! -e /etc/apt/apt.conf.d/99fingerdrag && ! -e /usr/local/bin/fingerdrag && ! -e /var/lib/fingerdrag ]] ||
	fail "uninstall left files behind"
[[ $(ver) == "$stock" ]] || fail "uninstall left version $(ver), expected $stock"
apt-get check >/dev/null || fail "apt reports broken dependencies after uninstall"
pass "uninstall restored $(ver)"

echo
# shellcheck disable=SC1091
pass "ALL TESTS PASSED on $(. /etc/os-release && echo "$PRETTY_NAME"), libinput $stock"
