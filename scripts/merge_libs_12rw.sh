#!/bin/bash

usage() {
    echo $0 "<output_path>"
}

DIR=`dirname $0`
OUT=${1%/}

if [ -z "${OUT}" ]; then
    echo error: output path must be specified
    usage
    exit
fi

#cleanup
mkdir -p $OUT
rm -f $OUT/libfirebase*.a

#combine firebase_app + firebase_app_check + firebase_rest_lib + all 3rd party to firebase_app
APP_DEPS=`find . -name "lib*.a" ! -name "libfirebase*.a" ! -name "libfirestore*.a"`
APP_DEPS+=$'\n'`find . -name "libfirebase_app.a"`
APP_DEPS+=$'\n'`find . -name "libfirebase_app_check.a"`
APP_DEPS+=$'\n'`find . -name "libfirebase_rest_lib.a"`
echo generating combined firebase_app...
python3 $DIR/merge_libraries.py --output=$OUT/libfirebase_app.a --platform=linux $APP_DEPS

#combine firebase_firestore with firestore libs
FIRESTORE_DEPS=`find . -name "libfirestore*.a"`
FIRESTORE_DEPS+=$'\n'`find . -name "libfirebase_firestore.a"`
echo generating combined firebase_firestore...
python3 $DIR/merge_libraries.py --output=$OUT/libfirebase_firestore.a --platform=linux $FIRESTORE_DEPS

#copy other firebase libs
OTHER_LIBS=`find . -name "libfirebase*.a" ! -name "libfirebase_firestore.a" ! -name "libfirebase_app*.a" ! -name "libfirebase_rest_lib.a"`
echo copy other libs...
echo "$OTHER_LIBS" | while read LIB
do
    FILE=`basename $LIB`
    cp $LIB $OUT/$FILE
done

