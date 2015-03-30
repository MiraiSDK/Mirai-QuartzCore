#!/bin/bash

checkError()
{
    if [ "${1}" -ne "0" ]; then
        echo "*** Error: ${2}"
        exit ${1}
    fi
}

if [ ! -f $MIRAI_SDK_PREFIX/lib/libQuartzCore.so ]; then
	echo "build QuartzCore..."
	
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-QuartzCore
	xcodebuild -target GSQuartzCore-Android -xcconfig xcconfig/Android-$ABI.xcconfig clean
	
	xcodebuild -target GSQuartzCore-Android -xcconfig xcconfig/Android-$ABI.xcconfig
	checkError $? "build QuartzCore failed"
	
	#clean up
	rm -r build
	popd
fi