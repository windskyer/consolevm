#!/usr/bin/ksh
#get_lu_map_info.sh 172.30.126.11 padmin clustername spname luudid

catchException() {
        
	error_result=$(cat $1)
	          
}

throwException() {
            
	result=$1
	error_code=$2
	           
	if [ "${result}" != "" ]
	then
		if [ "$(echo "$result" | grep "VIOSE" | sed 's/ //g')" != "" ]
		then
			echo "ERROR-${error_code}:"$(echo "$result" | awk -F']' '{print $2}') >&2
		else
			echo "ERROR-${error_code}: $result" >&2
		fi
		
		if [ "$log_flag" == "0" ]
		then
			rm -f "${error_log}" 2> /dev/null
			rm -f "$out_log" 2> /dev/null
		fi
		exit 1
	fi

}

ivm_ip=$1
ivm_user=$2
clustername=$3
spname=$4
lu_udid=$5

DateNow=$(date +%Y%m%d%H%M%S)
random=$(perl -e 'my $random = int(rand(9999)); print "$random";')
out_log="out_get_lu_map_info_${DateNow}_${random}.log"
error_log="error_get_lu_map_info_${DateNow}_${random}.log"

aix_getinfo() {
	i=0
	echo "[\c"
	while [ $i -lt $length ]
	do
		echo "{\c"
		echo "\"luname\":\"${lu_name[$i]}\", \c"
		echo "\"luudid\":\"${lu_udid[$i]}\", \c"
		echo "\"hosts\":[\c"
		node_serial_num=$(echo "$ssp_lu_map_list" | awk -F":" '{if($3==luname"."luudid) {print $1} }' luname=${lu_name[$i]} luudid=${lu_udid[$i]} | awk -F[.-] '{print $3}')
		if [ "$node_serial_num" != "" ]
		then
			node_list=$(echo "$node_serial_num"|sort -u)
			node_num=$(echo $node_list|awk '{print NF}')
			
			j=0
			echo "$node_list"|while read nodesn
			do
				nodename=$(echo "$ssp_node_list"|grep $nodesn|awk -F":" '{print $1}' 2>/dev/null)
				echo "{\c"
				echo "\"host\":\"${nodename}\", \c"
				echo "\"vms\":[\c"
				vms=$(echo "$ssp_lu_map_list"|grep $nodesn| awk -F":" '{if($3==luname"."luudid) {printf "%d\n",$2} }' luname=${lu_name[$i]} luudid=${lu_udid[$i]} 2>/dev/null)
				vms_num=$(echo $vms|awk '{print NF}')
				
				k=0
				echo "$vms"|while read vm
				do
					echo "\"${vm}\" \c"
					
					k=$(expr $k + 1)
					if [ "$k" != "${vms_num}" ]
					then
						echo ",\c"
					fi
				done
				echo "] \c"
				echo "}\c"
				
				j=$(expr $j + 1)
				if [ "$j" != "${node_num}" ]
				then
					echo ",\c"
				fi
			done
			echo "] \c"
		else
			
			echo "] \c"
	
		fi
	
		i=$(expr $i + 1)
		echo "}\c"
		if [ "$i" != "${length}" ]
		then
			echo ",\c"
		fi
		
	done
	echo "] \c"

}


linux_getinfo() {
	i=0
	echo -e "[\c"
	while [ $i -lt $length ]
	do
		echo -e "{\c"
		echo -e "\"luname\":\"${lu_name[$i]}\", \c"
		echo -e "\"luudid\":\"${lu_udid[$i]}\", \c"
		echo -e "\"hosts\":[\c"
		node_serial_num=$(echo "$ssp_lu_map_list" | awk -F":" '{if($3==luname"."luudid) {print $1} }' luname=${lu_name[$i]} luudid=${lu_udid[$i]} | awk -F[.-] '{print $3}')
		if [ "$node_serial_num" != "" ]
		then
			node_list=$(echo "$node_serial_num"|sort -u)
			node_num=$(echo $node_list|awk '{print NF}')
			
			j=0
			echo "$node_list"|while read nodesn
			do
				nodename=$(echo "$ssp_node_list"|grep $nodesn|awk -F":" '{print $1}' 2>/dev/null)
				echo -e "{\c"
				echo -e "\"host\":\"${nodename}\", \c"
				echo -e "\"vms\":[\c"
				vms=$(echo "$ssp_lu_map_list"|grep $nodesn| awk --posix -F":" '{if($3==luname"."luudid) {printf "%d\n",$2} }' luname=${lu_name[$i]} luudid=${lu_udid[$i]} 2>/dev/null)
				vms_num=$(echo $vms|awk '{print NF}')
				
				k=0
				echo "$vms"|while read vm
				do
					echo -e "\"${vm}\" \c"
					
					k=$(expr $k + 1)
					if [ "$k" != "${vms_num}" ]
					then
						echo -e ",\c"
					fi
				done
				echo -e "] \c"
				echo -e "}\c"
				
				j=$(expr $j + 1)
				if [ "$j" != "${node_num}" ]
				then
					echo -e ",\c"
				fi
			done
			echo -e "] \c"
		else
			
			echo -e "] \c"
	
		fi
	
		i=$(expr $i + 1)
		echo -e "}\c"
		if [ "$i" != "${length}" ]
		then
			echo -e ",\c"
		fi
		
	done
	echo -e "] \c"

}



ssp_lu_list=$(ssh ${ivm_user}@${ivm_ip} "ioscli lssp -clustername ${clustername} -sp ${spname} -bd -field luname luudid -fmt :" 2> "${error_log}")
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	throwException "$error_result" "105015"
fi
ssp_lu_map_list=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -clustername ${clustername} -all -field Physloc ClientID backing -fmt :" 2> "${error_log}")
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	throwException "$error_result" "105015"
fi
ssp_node_list=$(ssh ${ivm_user}@${ivm_ip} "ioscli cluster -status -clustername ${clustername} -field node_name node_mtm -fmt :" 2> "${error_log}")
catchException "${error_log}"
if [ "${error_result}" != "" ]
then
	throwException "$error_result" "105015"
fi

if [ "$lu_udid" == "" ]
then
	length=0
	echo "$ssp_lu_list"|while read param
	do
		lu_name[$length]=$(echo $param | awk -F":" '{print $1}')
		lu_udid[$length]=$(echo $param | awk -F":" '{print $2}')
		length=$(expr $length + 1)
	done
else
	length=0
	echo "$lu_udid"|while read param
	do
		lu_udid[$length]=$(echo $param)
		lu_name[$length]=$(echo "$ssp_lu_list" | awk -F":" '{ if($2 == luudid) { print $1 } }' luudid=${lu_udid[$length]})
		length=$(expr $length + 1)
	done
fi




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
	*) linux_getinfo;;
esac


