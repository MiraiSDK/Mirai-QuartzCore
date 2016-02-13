#!/bin/bash

checkError()
{
    if [ "${1}" -ne "0" ]; then
        echo "*** Error: ${2}"
        exit ${1}
    fi
}

## CAGLAndroidBridge require TNJavaHelper, we need build this framework first
if [ ! -f $MIRAI_SDK_PREFIX/lib/libTNJavaHelper.so ]; then
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-UIKit/TNJavaHelper
	xcodebuild -target TNJavaHelper-Android -xcconfig xcconfig/Android-$ABI.xcconfig
	checkError $? "build JavaHelper failed"
	
	#clean up
	rm -r build
	popd
fi

if [ ! -f $MIRAI_SDK_PREFIX/lib/libQuartzCore.so ] || 
	[ "$OPTION_REBUILD_COCOA" == "yes" ]; then
	echo "build QuartzCore..."
	
	pushd $MIRAI_PROJECT_ROOT_PATH/Mirai-QuartzCore
	xcodebuild -target GSQuartzCore-Android -xcconfig xcconfig/Android-$ABI.xcconfig clean
	
	xcodebuild -target GSQuartzCore-Android -xcconfig xcconfig/Android-$ABI.xcconfig
	checkError $? "build QuartzCore failed"
	
	#clean up
	rm -r build
	popd
fi