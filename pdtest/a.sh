#echo $@
while getopts 'n:v:' OPTION
do
    case $OPTION in
        n)scriptnames="$OPTARG"
            ;;

        v)scriptversion="$OPTARG"
            ;;
    esac
done
echo $scriptnames
echo $scriptversion
