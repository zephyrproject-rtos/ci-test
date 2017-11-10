#!/bin/bash

TYPE=daily
RELEASE=

while getopts "dr:" opt; do
	case $opt in
		d)
			echo "Building daily docs" >&2
			TYPE=daily
			RELEASE=
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

if [ -n "$MAIN_REPO_STATE" ]; then
	cd ${MAIN_REPO_STATE}
fi

if [ "$TYPE" == "release" ]; then
	git checkout v${RELEASE}-branch
fi
pwd
source ./zephyr-env.sh
unset BUILDDIR

if [ -d /build/IN/docs_theme_repo/gitRepo -a ! -e doc/themes/zephyr-docs-theme ]; then
	cp -a /build/IN/docs_theme_repo/gitRepo doc/themes/zephyr-docs-theme
elif [ ! -e doc/themes/zephyr-docs-theme ]; then
	git clone https://github.com/zephyrproject-rtos/docs-theme.git doc/themes/zephyr-docs-theme
fi

echo "- Building docs for ${RELEASE:-development tree} ..."

ls -la doc/extensions/zephyr/application.py

make -C doc DOC_TAG=${TYPE} htmldocs
if [ "$?" == "0" ]; then
	echo "- Uploading to AWS S3..."
	aws s3 sync --quiet doc/_build/html s3://docs.zephyrproject.org/${RELEASE}
else
	echo "- Failed"
fi

echo "=> Done"
