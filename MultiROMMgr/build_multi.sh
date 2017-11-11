#!/bin/bash
#timer counter
START=$(date +%s.%N);
START2="$(date)";
echo -e "\n Script start $(date)\n";

# simple build sh to build a apk check folder and sign ...set on yours .bashrc to call this sh from anywhere alias bt='/home/user/this.sh'
# How to build it set the below path/folders and install java and Download android sdk, setup a key to sigh or set SIGN to 0 and use debug.apk
# the rest must work without problems

# Folders Folder= yours app main folder, SDK_FOLDER android sdk folder
FOLDER="$HOME"/android/rr/MultiROMMgr;
SDK_FOLDER="$HOME"/android/sdk;
SDK_DIR="sdk.dir=$SDK_FOLDER";

# app sign key
#Generate and use a sign key https://developer.android.com/studio/publish/app-signing.html
#keytool -genkey -v -keystore key_name.key -alias <chose_a_alias> -keyalg RSA -keysize 2048 -validity 10000
#sign with
#jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -storepass <yours_password> -keystore <file_path.apk> <new_file_path.apk> <chose_a_alias>
#check
# jarsigner -verify -verbose -certs <my_application.apk>
# for play auto sign tool
#java -jar pepk.jar --keystore=fgl.key --alias=felipe_leon --output=fgl.keystore --encryptionkey=eb10fe8f7c7c9df715022017b00c6471f8ba8170b13049a11e6c09ffe3056a104a3bbe4ac5a955f4ba4fe93fc8cef27558a3eb9d2a529a2092761fb833b656cd48b9de6a
#keytool -genkey -v -keystore fgl_pem.key -alias felipe_leon -keyalg RSA -keysize 2048 -validity 10000
#
#keytool -export -rfc -keystore fgl_pem.key -alias felipe_leon -file fgl_pem.pem
SIGN=1;
KEY_FOLDER="$HOME"/android/temp/sign/fgl.key;
KEY_PASS=$(</"$HOME"/android/temp/sign/pass);

# make zip only used if you have the need to make a zip of this a flash zip template is need
# Auto sign zip Download from my folder link below extract and set the folder below on yours machine
# https://www.androidfilehost.com/?fid=312978532265364585
ZIP_SIGN_FOLDER="$HOME"/android/ZipScriptSign;

#Bellow this line theoretically noting need to be changed

# sdk tool and zipzlign path
TOOLVERSION=$(grep buildToolsVersion "$FOLDER"/MultiROMMgr/build.gradle | head -n1 | cut -d\" -f2);
ZIPALIGN_FOLDER=$SDK_FOLDER/build-tools/$TOOLVERSION/zipalign;

# out app folder and out app name
VERSION=$(grep versionName "$FOLDER"/MultiROMMgr/build.gradle | head -n1 | cut -d\" -f2 | sed 's/\./_/');
OUT_FOLDER="$FOLDER"/MultiROMMgr/build/outputs/apk/release;
APP_FINAL_NAME=MultiROMMgr.apk;

#making start here...

cd "$FOLDER" || exit;

if [ ! -e ./local.properties ]; then
	echo -e "$\n local.properties not found...\nMaking a local.properties files using script information\n
\n local.properties done starting the build";
	touch "$FOLDER".local.properties;
	echo "$SDK_DIR" > local.properties;
fi;
localproperties=$(cat < local.properties | head -n1);
if [ "$localproperties" != "$SDK_DIR" ]; then
	echo -e "\nSDK folder set as \n$SDK_DIR in the script \nbut local.properties file content is\n$localproperties\nfix it using script value";
	rm -rf .local.properties;
	touch "$FOLDER".local.properties;
	echo "$SDK_DIR" > local.properties;
fi;

./gradlew clean
echo -e "\n The above is just the cleaning build start now\n";
rm -rf MultiROMMgr/build/outputs/apk/release/**
./gradlew build 2>&1 | tee build_log.txt

if [ ! -e ./MultiROMMgr/build/outputs/apk/release/MultiROMMgr-release-unsigned.apk ]; then
	echo -e "\nApp not build$\n"
	exit 1;
elif [ $SIGN == 1 ]; then
	jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 -storepass "$KEY_PASS" -keystore "$KEY_FOLDER" "$OUT_FOLDER"/MultiROMMgr-release-unsigned.apk Felipe_Leon
	"$ZIPALIGN_FOLDER" -v 4 "$OUT_FOLDER"/MultiROMMgr-release-unsigned.apk "$OUT_FOLDER"/"$APP_FINAL_NAME"
	cp "$OUT_FOLDER"/"$APP_FINAL_NAME" "$OUT_FOLDER"/MultiROMMgr"$(date +%s)".apk
fi;

END2="$(date)";
END=$(date +%s.%N);

if [ -e "$OUT_FOLDER"/"$APP_FINAL_NAME" ]; then
	echo -e "\nLint issues:\n";
	grep issues build_log.txt;
	echo -e "\nBuild deprecation:\n";
	grep deprecation build_log.txt;

	echo -e "\nApp saved at $OUT_FOLDER"/"$APP_FINAL_NAME\n"
fi;
rm -rf build_log.txt
echo -e "*** Build END ***"
echo -e "\nTotal elapsed time of the script: $(echo "($END - $START) / 60"|bc ):$(echo "(($END - $START) - (($END - $START) / 60) * 60)"|bc ) (minutes:seconds).\n";
exit 1;
