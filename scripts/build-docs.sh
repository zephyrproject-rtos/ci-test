#!/bin/bash
#set -ex

TYPE=daily
RELEASE=dev

while getopts "dr:" opt; do
	case $opt in
		d)
			echo "Building daily docs" >&2
			TYPE=daily
			RELEASE=dev
			;;
		r)
			echo "Building release docs" >&2
			TYPE=release
			RELEASE=$OPTARG
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			;;
	esac
done

cd ${MAIN_REPO_STATE}

if [ "$TYPE" == "release" ]; then
	git checkout v${RELEASE}-branch
fi
source zephyr-env.sh
unset BUILDDIR

if [ -d /build/IN/docs_theme_repo/gitRepo -a ! -e doc/themes/zephyr-docs-theme ]; then
	cp -a /build/IN/docs_theme_repo/gitRepo doc/themes/zephyr-docs-theme
elif [ ! -e doc/themes/zephyr-docs-theme ]; then
	git clone https://github.com/zephyrproject-rtos/docs-theme.git doc/themes/zephyr-docs-theme
fi

echo "- Building docs for ${RELEASE} ..."
make DOC_TAG=${TYPE} htmldocs > doc.log 2>&1

echo "- Uploading to AWS S3..."
#aws s3 sync --quiet --delete doc/_build/html s3://docs.zephyrproject.org/online/${RELEASE}
aws s3 sync --quiet --delete doc/_build/html s3://zephyr-docs/online/${RELEASE}

echo "=> Done"
