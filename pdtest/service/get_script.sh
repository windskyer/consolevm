#!/usr/bin/env bash

#author leidong

TOP_DIR=$(cd $(dirname "$0")/.. && pwd)

source $TOP_DIR/unit/functions

clientdir=$TOP_DIR/client/

function usage {
    printf "Usage:\n %s\t-f [script fullname]
    \t\t-d [script dir ] 
    \t\t-n [scritp name]
    \t\t-s [script subnames]
    \t\t-v [script version]
    \t\t-h or -? hellp \n" $(basename $0) >&2
}

dflag=0
nflag=0
sflag=0
vflag=0

while getopts 'd:n:s:v:h' OPTION
do
    case $OPTION in
        d)  dflag=1
            dirnames="$OPTARG"
            ;;

        n)  nflag=1
            scriptnames="$OPTARG"
            ;;

        s)  sflag=1
            subscriptnames="$OPTARG"
            ;;

        v)  vflag=1
            scriptversion="$OPTARG"
            ;;

        h)  usage
            exit 1
            ;;

        ?)  usage
            exit 1
            ;;
    esac
done

rets=
[[ $dflag -eq 1 ]]  && dir=$TOP_DIR/client/$dirnames || dir=$TOP_DIR/client

if [[ $sflag -eq 1 ]]; then
    for name in $subscriptnames
    do
        if [[ $vflag -eq 1 ]] ; then
        for version in $scriptversion
        do
            #ret=$(find $dir -name "get_${name}_info_${version}.sh" -type f -exec printf {} \;)
            ret=$(find $dir -name "get_${name}_info_${version}.sh" -type f )
            [[ -n "$ret" ]] || failed "Not Found $dir/get_${name}_info_${version}.sh file" && rets="$rets $ret"
        done
        else
            ret=$(find $dir -name "get_${name}_info*.sh" -type f)
            [[ -n "$ret" ]] || failed "Not Found $dir/get_${name}_info*.sh file" && rets="$rets $ret"
        fi
    done
else
    if [[ $vflag -eq 1 ]] ; then
        for version in $scriptversion
        do
            ret=$(find $dir -name "get_*_info_${version}.sh" -type f)
            [[ -n "$ret" ]] || failed "Not Found $dir/get_*_info_${version}.sh file" && rets="$rets $ret"
        done
    else
        ret=$(find  $dir -name "get_*_info*.sh" -type f)
    fi
fi
#echo $ret
#exit 0
for i in $rets
do
    echo $i

done

