# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=1

inherit target

DESCRIPTION="Minimal test target to check git and http retrieving"
HOMEPAGE="http://www.wyplay.com"
SRC_URI=""

LICENSE="Wyplay"
SLOT="0"
KEYWORDS="betty"
IUSE="+redist"

DEPEND=""
RDEPEND="${DEPEND}"

EGIT_REPO_URI="gbx-profile-abby-test.git"
: ${EGIT_BRANCH:="master"}
: ${EGIT_REVISION:=""}

XOV_MAIN_PROTO="git"
XOV_MAIN_URI="${EGIT_BASE_URI}/gbx-ov-master-test.git"
XOV_MAIN_REVISION=""
XOV_MAIN_BRANCH="master"
XOV_MAIN_PORTDIR="True"

XOV_BETTY_PROTO="git"
XOV_BETTY_URI="${EGIT_BASE_URI}/gbx-ov-bsp-betty-test.git"
XOV_BETTY_REVISION=""
XOV_BETTY_BRANCH="master"

TARGET_OV_LIST="main"
