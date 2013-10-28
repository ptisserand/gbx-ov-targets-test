# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

#
# Original Author: Fargier Sylvain <sfargier@wyplay.com>
# Purpose: Install prebuilt targets
#
RESTRICT="mirror"
IUSE="prebuilt gpg"

BIN_TARGET_ARCHIVE="${PF}_root.tar.gz"
BIN_TARGET_URI="mirror://prebuilt/$CATEGORY/$PN/$PVR/$ARCH/$BIN_TARGET_ARCHIVE"
GPG_TARGET_ARCHIVE="${PF}_root.tar.gz.gpg"
GPG_TARGET_URI="mirror://prebuilt/$CATEGORY/$PN/$PVR/$ARCH/$GPG_TARGET_ARCHIVE"
SRC_URI="$SRC_URI prebuilt? ( $BIN_TARGET_URI )
				  gpg? ( $GPG_TARGET_URI )"


function prebuilt-postinst() {
	if use prebuilt || use gpg; then
		local target=$(cd "$ROOT/.."; pwd)
		local archive="$DISTDIR/$BIN_TARGET_ARCHIVE"
		mv "$target/root/var/cache/edb" "${T}/edb"
		rm -rf "$target/root"
		if use gpg; then
			einfo "Installing GPG prebuilt target ..."

			[ -e "$DISTDIR/$GPG_TARGET_ARCHIVE" ] || die "Can't find GPG prebuilt archive in distdir"
			rm -f $archive
			gpg --homedir /root/.gnupg -v -o $archive -d $DISTDIR/$GPG_TARGET_ARCHIVE || die "Could not decrypt the GPG Archive"

		else
			einfo "Installing prebuilt target ..."

			[ -e "$DISTDIR/$BIN_TARGET_ARCHIVE" ] || die "Can't find prebuilt archive in distdir"
		fi
		tar xfzp "$archive" -C "$target" || \
			die "Failed to unpack the prebuilt target"
		rm -rf "$target/root/var/cache/edb"
		mv "${T}/edb" "$target/root/var/cache/edb"
		# create PORTAGE_TMPDIR, we can't use portageq since profile
		# is not yet complete at this stage
		mkdir -p "${target}/build"
		echo "${CATEGORY}/${PN}-${PVR}" > ${target}/root/etc/prebuilt-release
	fi
}
