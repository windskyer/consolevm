# we always start with no errors
ERROR=0
PASS=0
FAILED_FUNCS=""
TIMESTAMP_FORMAT=${TIMESTAMP_FORMAT:-"%F %H/%M/%S"}


## Get log file dir
function log {
    local res=$1
    shift 1
    local msg="$@"
    local logfile="passed.log"
    if [[ $res -ne 0 ]] ; then
        logfile="failed.log"
    fi 
    [[ ! -n $LOG_DIR ]] && LOG_DIR="$(pwd)/log"
    [[ -d $LOG_DIR ]] && mkdir -p $LOG_DIR
    logfile=$LOG_DIR/$logfile 
    echo $(date +"${TIMESTAMP_FORMAT}") "[SCRIPT: $0 PID: $$]" >> $logfile
    echo $msg 2>&1 | tee -ai $logfile
}

function passed {
    local lineno=$(caller 0 | awk '{print $1}')
    local function=$(caller 0 | awk '{print $2}')
    local msg="$1"
    if [ -z "$msg" ]; then
        msg="OK"
    fi  
    PASS=$((PASS+1))
    log 0 $function:L $lineno $msg
}


function failed {
    local lineno=$(caller 0 | awk '{print $1}')
    local function=$(caller 0 | awk '{print $2}')
    local msg="$1"
    FAILED_FUNCS+="$function:L$lineno\n"
    log 1 "ERROR: $function:L$lineno!" "   $msg"
    ERROR=$((ERROR+1))
}

function assert_equal {
    local lineno=`caller 0 | awk '{print $1}'`
    local function=`caller 0 | awk '{print $2}'`
    local msg=$3
    if [[ "$1" != "$2" ]]; then
        FAILED_FUNCS+="$function:L$lineno\n"
        echo "ERROR: $1 != $2 in $function:L$lineno!"
        echo "  $msg"
        ERROR=$((ERROR+1))
    else
        PASS=$((PASS+1))
        echo "$function:L$lineno - ok"
    fi
}

log 1  "this is leidong"
log 0  "this is leidong"
