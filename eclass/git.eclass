# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/git.eclass,v 1.7 2007/11/14 20:43:43 ferdy Exp $

## --------------------------------------------------------------------------- #
# subversion.eclass author: Akinori Hattori <hattya@gentoo.org>
# modified for git by Donnie Berkholz <spyderous@gentoo.org>
# improved by Fernando J. Pereda <ferdy@gentoo.org>
# improved by Sylvain Fargier <sfargier@wyplay.com>
#
# The git eclass is written to fetch the software sources from
# git repositories like the subversion eclass.
#
#
# Description:
#   If you use this eclass, the ${S} is ${WORKDIR}/${P}.
#   It is necessary to define the EGIT_REPO_URI variable at least.
#
## --------------------------------------------------------------------------- #

inherit eutils

EGIT="git.eclass"

EXPORT_FUNCTIONS src_unpack

HOMEPAGE="http://git.or.cz/"
DESCRIPTION="Based on the ${ECLASS} eclass"


## -- add git in DEPEND
#
DEPEND=">=dev-util/git-1.7.0.2-r1"


## -- EGIT_STORE_DIR:  git sources store directory
#
EGIT_STORE_DIR="${PORTAGE_ACTUAL_DISTDIR-${DISTDIR}}/git-src"


## -- EGIT_FETCH_CMD:  git clone command
#
EGIT_FETCH_CMD="git clone --bare"

## -- EGIT_UPDATE_CMD:  git fetch command
#
EGIT_UPDATE_CMD="git fetch -f -u"

## -- EGIT_DIFFSTAT_CMD: Command to get diffstat output
#
EGIT_DIFFSTAT_CMD="git diff --stat"


## -- EGIT_OPTIONS:
#
# the options passed to clone and fetch
#
: ${EGIT_OPTIONS:=}


## -- EGIT_BASE_URI / EGIT_REPO_URI:  repository uri
#
# e.g. http://foo, git://bar
#
# supported protocols:
#   http://
#   https://
#   git://
#   git+ssh://
#   rsync://
#   ssh://
#
: ${EGIT_BASE_URI:=}
: ${EGIT_REPO_URI:=}

## -- EGIT_REV: Hash revision we want to fetch
#
# Hash revision you want to use - will not be used it empty,
# which means you'll checkout HEAD

# allow usage of EGIT_REVISION since it's more coherent with variable name used
# in mercurial eclass
: ${EGIT_REVISION:=}
: ${EGIT_REV:=${EGIT_REVISION}}

## -- EGIT_PROJECT:  project name of your ebuild
#
# git eclass will check out the git repository like:
#
#   ${EGIT_STORE_DIR}/${EGIT_PROJECT}/${EGIT_REPO_URI##*/}
#
# so if you define EGIT_REPO_URI as http://git.collab.net/repo/git or
# http://git.collab.net/repo/git. and PN is subversion-git.
# it will check out like:
#
#   ${EGIT_STORE_DIR}/subversion
#
# default: ${PN/-git}.
#
: ${EGIT_PROJECT:=${PN/-git}}


## -- EGIT_BRANCH:
#
# git eclass can fetch any branch in git_fetch().
# Defaults to 'master'
#
: ${EGIT_BRANCH:=}


## -- EGIT_TREE:
#
# DEPRECATED
# git eclass can checkout any tree.
# Defaults to EGIT_BRANCH.
#
: ${EGIT_TREE:=}


## - EGIT_REPACK:
#
# git eclass will repack objects to save disk space. However this can take a
# long time with VERY big repositories. If this is your case set:
# EGIT_REPACK=false
#
: ${EGIT_REPACK:=false}

## - EGIT_PRUNE:
#
# git eclass can prune the local clone. This is useful if upstream rewinds and
# rebases branches too often. If you don't want this to happen, set:
# EGIT_PRUNE=false
#
: ${EGIT_PRUNE:=false}


## - EGIT_CUSTOM:
#
# git eclass can avoid cloning EGIT_REPO_URI and work from a local git repository
#
# set this to the directory containing your local repository
: ${EGIT_CUSTOM:=}

## -- git__get_repo_uri() ------------------------------------------------- #

function git__get_repo_uri() {
	if [ -z "${EGIT_BASE_URI}" ] ; then
		echo "${EGIT_REPO_URI}"
	elif [[ "${EGIT_REPO_URI}" =~ :// ]]; then
		echo "${EGIT_REPO_URI}"
	else
		echo "${EGIT_BASE_URI}/${EGIT_REPO_URI}"
	fi
}

## -- git_fetch() ------------------------------------------------- #

git_fetch() {

	local EGIT_CLONE_DIR
	if [[ -n "${EGIT_REV%%:*}" && `echo ${EGIT_REV:6}` == "" ]]; then
		die "${EGIT}: EGIT_REV needs at least 7 chars."
	fi

	repo_uri=$(git__get_repo_uri)
	# EGIT_REPO_URI is empty.
	[ -z "$repo_uri" ] && die "${EGIT}: EGIT_REPO_URI is empty."

	# check for the protocol or pull from a local repo.
	if [[ -z ${repo_uri%%:*} ]] ; then
		case ${repo_uri%%:*} in
			git*|http|https|rsync|ssh)
				;;
			*)
				die "${EGIT}: fetch from "${repo_uri%:*}" is not yet implemented."
				;;
		esac
	fi

	if [[ ! -d ${EGIT_STORE_DIR} ]] ; then
		debug-print "${FUNCNAME}: initial clone. creating git directory"
		addwrite /
		mkdir -p "${EGIT_STORE_DIR}" \
			|| die "${EGIT}: can't mkdir ${EGIT_STORE_DIR}."
		chmod -f o+rw "${EGIT_STORE_DIR}" \
			|| die "${EGIT}: can't chmod ${EGIT_STORE_DIR}."
		export SANDBOX_WRITE="${SANDBOX_WRITE%%:/}"
	fi

	cd -P "${EGIT_STORE_DIR}" || die "${EGIT}: can't chdir to ${EGIT_STORE_DIR}"
	EGIT_STORE_DIR=${PWD}

	# every time
	addwrite "${EGIT_STORE_DIR}"

	[[ -z ${repoi_uri##*/} ]] && repo_uri="${repo_uri%/}"
	EGIT_CLONE_DIR="${EGIT_PROJECT}"

	debug-print "${FUNCNAME}: EGIT_OPTIONS = \"${EGIT_OPTIONS}\""

	if [[ -z ${EGIT_CUSTOM} ]]; then
		export GIT_DIR="${EGIT_CLONE_DIR}"

		if [[ ! -d ${EGIT_CLONE_DIR} ]] ; then
			# first clone
			einfo "git clone start -->"
			einfo "   repository: ${repo_uri}"

			${EGIT_FETCH_CMD} ${EGIT_OPTIONS} "${repo_uri}" ${EGIT_PROJECT} \
				|| die "${EGIT}: can't fetch from ${repo_uri}."

			# We use --bare cloning, so git doesn't do this for us.
			git config remote.origin.url "${repo_uri}"

		else
			# Git urls might change, so unconditionally set it here
			git config remote.origin.url "${repo_uri}"

			# fetch updates
			einfo "git update start -->"
			einfo "   repository: ${repo_uri}"

			if [ -n "${EGIT_BRANCH}" ]; then
				local oldsha1=$(git rev-parse ${EGIT_BRANCH})

				${EGIT_UPDATE_CMD} ${EGIT_OPTIONS} origin ${EGIT_BRANCH}:${EGIT_BRANCH} \
					|| die "${EGIT}: can't update from ${repo_uri}."

				# piping through cat is needed to avoid a stupid Git feature
				${EGIT_DIFFSTAT_CMD} ${oldsha1}..${EGIT_BRANCH} | cat
			else
				for b in $(git branch | cut -c 3-); do
					${EGIT_UPDATE_CMD} ${EGIT_OPTIONS} origin ${b}:${b} \
						|| ewarn "${EGIT}: can't update ${b} from ${repo_uri}"
				done
			fi
		fi

		if ${EGIT_REPACK} || ${EGIT_PRUNE} ; then
			ebegin "Garbage collecting the repository"
			git gc $(${EGIT_PRUNE} && echo '--prune')
			eend $?
		fi
	else
		export GIT_DIR="${EGIT_CUSTOM}"
		EGIT_REV="HEAD"
	fi


	if [ -n "${EGIT_REV}"  ]; then
		if [ -n "${EGIT_BRANCH}" ]; then # Let's check EGIT_BRANCH against EGIT_REV
			[ $(git-merge-base "$EGIT_REV" "$EGIT_BRANCH") == $(git-rev-parse "$EGIT_REV") ] \
				|| die "$EGIT: Branch mismatch, $EGIT_REV is not on $EGIT_BRANCH"
		fi
		REV="${EGIT_REV}"
	elif [ -n "${EGIT_TREE}" ]; then
		ewarn "EGIT_TREE is deprecated, please use EGIT_REV and EGIT_BRANCH instead"
		REV="${EGIT_TREE}"
	elif [ -n "${EGIT_BRANCH}" ]; then
		REV="${EGIT_BRANCH}"
	fi

	einfo "   committish: ${REV}"
	REV=$(git-rev-parse --short "$REV")

	# export to the ${WORKDIR}
	if [ "${SCM_WORKDIR}" == "True" ]; then
		einfo "Cloning working copy to ${S}"
		CLONE_DIR="$GIT_DIR"
		unset GIT_DIR

		git clone -q -n "${CLONE_DIR}" "${S}"
		cd "${S}"
		git config remote.origin.url "${repo_uri}"
		git checkout -q "${REV}"
	else
		einfo "Copying sources to ${S}"
		mkdir -p "${S}"
		git archive --format=tar "${REV}" | ( cd "${S}" ; tar xf - )
	fi
	einfo "Working copy is at $REV"
}


## -- git_src_unpack() ------------------------------------------------ #

git_src_unpack() {
	git_fetch     || die "${EGIT}: unknown problem in git_fetch()."
	cd "${S}"
}

