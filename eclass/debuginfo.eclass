# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Original Author: Fargier Sylvain <sfargier@wyplay.com> 
# Purpose: Install debuginfo targets
#
RESTRICT="mirror"
IUSE="debuginfo gpg"

DEBUG_TARGET_ARCHIVE="${PF}_debuginfo.tar.gz"
DEBUG_TARGET_URI="mirror://prebuilt/$CATEGORY/$PN/$PVR/$ARCH/$DEBUG_TARGET_ARCHIVE"
GPGDEBUG_TARGET_ARCHIVE="${PF}_debuginfo.tar.gz.gpg"
GPGDEBUG_TARGET_URI="mirror://prebuilt/$CATEGORY/$PN/$PVR/$ARCH/$GPGDEBUG_TARGET_ARCHIVE"
SRC_URI="$SRC_URI debuginfo? ( !gpg? ( $DEBUG_TARGET_URI ) )
                        gpg? ( $GPGDEBUG_TARGET_URI )"

function debuginfo-postinst() {
	if use debuginfo && use gpg; then
		local target=$(cd "$ROOT/.."; pwd)
		local archive="$DISTDIR/$DEBUG_TARGET_ARCHIVE"

		einfo "Installing debuginfo target ..."
		[ -e "$DISTDIR/$GPGDEBUG_TARGET_ARCHIVE" ] || die "Can't find GPG debuginfo archive in distdir"
		rm -f $archive
		gpg --homedir /root/.gnupg -v -o $archive -d $DISTDIR/$GPGDEBUG_TARGET_ARCHIVE || die "Could not decrypt the GPG debuginfo archive"
		rm -rf "$target/root/usr/lib/debug"
		tar xfzp "$archive" -C "$target" || \
			die "Failed to unpack the debuginfo target"
	elif use debuginfo && ! use gpg; then
		local target=$(cd "$ROOT/.."; pwd)
		local archive="$DISTDIR/$DEBUG_TARGET_ARCHIVE"

		einfo "Installing debuginfo target ..."
		[ -e "$DISTDIR/$DEBUG_TARGET_ARCHIVE" ] || die "Can't find debuginfo archive in distdir"
		rm -rf "$target/root/usr/lib/debug"
		tar xfzp "$archive" -C "$target" || \
			die "Failed to unpack the debuginfo target"
	fi
}


