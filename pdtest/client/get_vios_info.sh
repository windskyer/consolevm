#!/usr/bin/ksh

ivm_ip=$1
ivm_user=$2

DateNow=$(date +%Y%m%d%H%M%S)
out_log="out_startup_${DateNow}.log"
error_log="error_startup_${DateNow}.log"


vm_sys_info=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F lpar_id,name,lpar_env,state")

length=0
echo "$vm_sys_info" | while read sys
do
	if [ "$(echo $sys | awk -F"," '{print $3}')" == "vioserver" ]
	then
		vios_id[$length]=$(echo $sys | awk -F"," '{print $1}')
		vios_name[$length]=$(echo $sys | awk -F"," '{print $2}')
		vios_state[$length]=$(echo $sys | awk -F"," '{print $4}')
		length=$(expr $length + 1)
	fi
done


aix_getinfo() {
	i=0
	echo "[\c"
	while [ $i -lt $length ]
	do
		echo "{\c"
		echo "\"vios_id\":\"${vios_id[$i]}\", \c"
		echo "\"vios_name\":\"${vios_name[$i]}\", \c"
		echo "\"vios_state\":\"${vios_state[$i]}\"\c"
		echo "}\c"
		
		i=$(expr $i + 1)
		if [ "$i" != "$length" ]
		then
			echo ", \c"
		fi
	done
	echo "]"
}

linux_getinfo() {
	i=0
	echo -e "[\c"
	while [ $i -lt $length ]
	do
		echo -e "{\c"
		echo -e "\"vios_id\":\"${vios_id[$i]}\", \c"
		echo -e "\"vios_name\":\"${vios_name[$i]}\", \c"
		echo -e "\"vios_state\":\"${vios_state[$i]}\"\c"
		echo -e "}\c"
		
		i=$(expr $i + 1)
		if [ "$i" != "$length" ]
		then
			echo -e ", \c"
		fi
	done
	echo "]"
}

case $(uname -s) in
	AIX)
		aix_getinfo;;
	Linux)
		linux_getinfo;;
	*BSD)
		bsd_getinfo;;
	SunOS)
		sun_getinfo;;
	HP-UX)
		hp_getinfo;;
	*) echo "unknown";;
esac