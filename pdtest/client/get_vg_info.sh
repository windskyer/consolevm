#!/usr/bin/ksh

#begin add by wansan 20130812
pd_error() {
    err=$1
	error_code=$2
	echo "0|0|ERROR-${err}: ${error_code}"
	exit 1
}

get_vg_pv_uniqueid_info() {
	vg_name=$1
	vg_pv_name_list=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg -pv $vg_name -field PV_NAME -fmt :")
	
	vg_pv_len=0
	if [ "$vg_pv_name_list" != "" ]
	then
		for vg_pv in $(echo ${vg_pv_name_list})
		do
			vgpvs[$vg_pv_len]=$vg_pv
			vgpvsstr=${vgpvsstr}" "${vgpvs[$vg_pv_len]}
			vg_pv_len=$(expr $vg_pv_len + 1)
		done
		
		if [ "$vgpvsstr" == "" ]
		then
			pd_error "param error" "100000"
		fi
	fi

	vg_pv_i=0
	while [ $vg_pv_i -lt $vg_pv_len ]
	do
		uniqueid[$vg_pv_i]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${vgpvs[$vg_pv_i]} -attr unique_id|grep -v value|grep -v ^$" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
				pd_error "$uniqueid[$vg_pv_i]" "1000038"
		fi
		vg_pv_i=$(expr $vg_pv_i + 1)
	done
}

get_lv_pv_uniqueid_info() {
	lv_name=$1
	lv_pv_name_list=$(ssh ${ivm_user}@${ivm_ip} "ioscli lslv -pv $lv_name -field PV -fmt :")
	
	lv_pv_len=0
	if [ "$lv_pv_name_list" != "" ]
	then
		for lv_pv in $(echo ${lv_pv_name_list})
		do
			lvpvs[$lv_pv_len]=$lv_pv
			lvpvsstr=${lvpvsstr}" "${lvpvs[$lv_pv_len]}
			lv_pv_len=$(expr $lv_pv_len + 1)
		done
		
		if [ "$lvpvsstr" == "" ]
		then
			pd_error "param error" "100000"
		fi
	fi

	lv_pv_i=0
	while [ $lv_pv_i -lt $lv_pv_len ]
	do
		uniqueid[$lv_pv_i]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${lvpvs[$lv_pv_i]} -attr unique_id|grep -v value|grep -v ^$" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
				pd_error "$uniqueid[$lv_pv_i]" "1000038"
		fi
		lv_pv_i=$(expr $lv_pv_i + 1)
	done
}
#end add by wansan 20130812

ivm_ip=$1
ivm_user=$2
vg_name=$3

if [ "$vg_name" != "" ]
then
	err=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg $vg_name" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		echo "$err" >&2
		exit 1
	fi
fi

if [ "$vg_name" == "" ]
then
	vg_name_list=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg")
else
	vg_name_list=$vg_name
fi

vg_remove_list=$(cat get_vg_info.cfg 2>/dev/null |awk -F":" '{if(NF==1) print $1}')

echo "$vg_remove_list"|while read line
do
	if [ "$line" != "" ]
	then
		vg_name_list=$(echo $vg_name_list | awk '{ for(i=1;i<=NF;i++) { if($i != vg_name) { print $i } } }' vg_name="$line")
	fi

done

vg_length=0
if [ "$vg_name_list" != "" ]
then
	for vg in $(echo ${vg_name_list})
	do
		if [ "$vg" == "rootvg" ]
		then                 
			vg_info=$(ssh ${ivm_user}@${ivm_ip} 2>/dev/null "ioscli lsvg $vg -field vgstate vgid maxlvs numlvs totalpvs totalpps freepps usedpps pppervg maxpvs ppperpv -fmt :")
		else
			vg_info=$(ssh ${ivm_user}@${ivm_ip} 2>/dev/null "ioscli lsvg $vg -field vgstate vgid maxlvs numlvs totalpvs totalpps freepps usedpps pppervg maxpvs -fmt :")
		fi
		
		vg_lvs=$(ssh ${ivm_user}@${ivm_ip} 2>/dev/null "ioscli lsvg -lv $vg -field lvname -fmt :")

		name[$vg_length]=$vg
		ppsize[$vg_length]=$(ssh ${ivm_user}@${ivm_ip} 2>/dev/null "ioscli lsvg $vg" | grep "PP SIZE" | awk '{print $6}' | sed 's/ //g')
		state[$vg_length]=$(echo "$vg_info" | awk -F":" '{print $1}')
		vgid[$vg_length]=$(echo "$vg_info" | awk -F":" '{print $2}')
		maxlvs[$vg_length]=$(echo "$vg_info" | awk -F":" '{print $3}')
		numlvs[$vg_length]=$(echo "$vg_info" | awk -F":" '{print $4}')
		totalpvs[$vg_length]=$(echo "$vg_info" | awk -F":" '{print $5}')
		totalpps[$vg_length]=$(echo "$vg_info" | awk -F":" '{print $6}' | sed 's/(//g' | awk '{print $2}')
		freepps[$vg_length]=$(echo "$vg_info" | awk -F":" '{print $7}' | sed 's/(//g' | awk '{print $2}')
		usedpps[$vg_length]=$(echo "$vg_info" | awk -F":" '{print $8}' | sed 's/(//g' | awk '{print $2}')
		pppervg[$vg_length]=$(echo "$vg_info" | awk -F":" '{print $9}')
		maxpvs[$vg_length]=$(echo "$vg_info" | awk -F":" '{print $10}')
		ppperpv[$vg_length]=$(echo "$vg_info" | awk -F":" '{print $11}')
		
		lvs_num[$vg_length]=0
		if [ "$vg_lvs" != "" ]
		then
			lv_name_list=$(echo "$vg_lvs" | grep -v $vg | grep -v "LV NAME")
			for lv in $lv_name_list
			do
				if [ "$(cat get_vg_info.cfg 2>/dev/null|grep "^${vg}:"|awk -F":" '{ for(i=2;i<=NF;i++) {if($i==lv) {print $i}}}' lv="$lv" 2> /dev/null)" != "" ]
				then
					continue
				fi
	
				if [ "$lv" == "VMLibrary" ]
				then
					continue
				fi
				lv_info[$vg_length]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lslv $lv -field lvname maxlps ppsize pps lvid lvstate -fmt :" 2> /dev/null)"|"${lv_info[$vg_length]}
				lvs_num[$vg_length]=$(expr ${lvs_num[$vg_length]} + 1)
			done
			lv_info[$vg_length]=$(echo "${lv_info[$vg_length]}" | awk '{print substr($0,0,length($0)-1)}')
			
		fi
		vg_length=$(expr $vg_length + 1)
	done
else
	echo "[]"
	exit 1
fi

aix_getinfo() {
	i=0
	echo "[\c"
	if [ "$vg_length" != "0" ]
	then
		while [ $i -lt $vg_length ]
		do
			echo "{\c"
			echo "\"name\":\"${name[$i]}\", \c"
			echo "\"ppsize\":\"${ppsize[$i]}\", \c"
			echo "\"state\":\"${state[$i]}\", \c"
			echo "\"vgid\":\"${vgid[$i]}\", \c"
			echo "\"maxlvs\":\"${maxlvs[$i]}\", \c"
			echo "\"totalpvs\":\"${totalpvs[$i]}\", \c"
			echo "\"totalpps\":\"${totalpps[$i]}\", \c"
			echo "\"freepps\":\"${freepps[$i]}\", \c"
			echo "\"usedpps\":\"${usedpps[$i]}\", \c"
			echo "\"pppervg\":\"${pppervg[$i]}\", \c"
			echo "\"ppperpv\":\"${ppperpv[$i]}\", \c"
			echo "\"maxpvs\":\"${maxpvs[$i]}\", \c"
			
			get_vg_pv_uniqueid_info ${name[$i]}
			echo "\"pvUniqueIds\":\c"
			echo "[\c"
			m=0
			while [ $m -lt $vg_pv_len ]
			do
				echo "\"${uniqueid[$m]}\"\c"
				m=$(expr $m + 1)
				if [ "$m" != "$vg_pv_len" ]
				then
						echo ", \c"
				fi
			done
			echo "],\c"
			
			echo "\"lv\":\c"
			echo "[\c"
			j=0
			if [ "${lv_info[$i]}" != "" ]
			then
				lv_num=0
				echo "${lv_info[$i]}" | awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read lva
				do
					lv[$lv_num]=$lva
					lv_num=$(expr $lv_num + 1)
				done
				
				k=0
				while [ k -lt $lv_num ]
				do
					echo "{\c"
					echo "\"lv_name\":\"$(echo ${lv[$k]} | awk -F":" '{print $1}')\", \c"
					echo "\"lv_id\":\"$(echo ${lv[$k]} | awk -F":" '{print $5}')\", \c"
					lv_state=$(echo "${lv[$k]}" | awk -F":" '{print $6}')
					case $lv_state in
						"opened/syncd")
										lv_state=1;;
						"closed/syncd")
										lv_state=2;;
						*)
										lv_state=3;;
					esac
					echo "\"lv_state\":\"$lv_state\", \c"
					echo "\"lv_max_lps\":\"$(echo ${lv[$k]} | awk -F":" '{print $2}')\", \c"
					echo "\"lv_ppsize\":\"$(echo ${lv[$k]} | awk -F":" '{print $3}' | awk '{print $1}' | sed 's/ //g')\", \c"
					echo "\"lv_pps\":\"$(echo ${lv[$k]} | awk -F":" '{print $4}')\", \c"
					
					lvname=$(echo ${lv[$k]} | awk -F":" '{print $1}')
					get_lv_pv_uniqueid_info $lvname
					
					echo "\"pvUniqueIds\":\c"
					echo "[\c"
					n=0
					while [ $n -lt $lv_pv_len ]
					do
						echo "\"${uniqueid[$n]}\"\c"
						n=$(expr $n + 1)
						if [ "$n" != "$lv_pv_len" ]
						then
								echo ", \c"
						fi
					done
					echo "]\c"
					
					echo "}\c"
					j=$(expr $j + 1)
					if [ "$j" != "${lvs_num[$i]}" ]
					then
						echo ", \c"
					fi
					
					k=$(expr $k + 1)
				done
			fi
			echo "],\c"	
			
			echo "\"pv\":[\c"
			vm_pv[$i]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg -pv ${name[$i]} -field PV_NAME -fmt :")
			vios_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F lpar_id,lpar_env" | awk -F"," '{if($2=="vioserver") print $1}')
			
			pv_count=0
			for pv in ${vm_pv[$i]}
			do
				pv_count=$(expr $pv_count + 1)
			done
			
			j=0
			for pv in ${vm_pv[$i]}
			do
				if [ "$pv" != "" ]
				then
					g=0
					for disk in $(echo "${vm_disk[$i]}" | awk -F":" '{for(i=1;i<=NF;i++) print $i}')
					do
						if [ "$disk" == "$pv" ]
						then
							pv_num=$g
						fi
						g=$(expr $g + 1)
					done
					
					pv_size=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -size $pv")
					unique_id=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev $pv -attr unique_id" | grep -v value | grep -v ^$)
					pv_id=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev $pv -attr pvid" | grep -v value | grep -v ^$)
					pv_status=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev $pv -field status -fmt :")
					if [ "${pv_id}" == "none" ]
					then
						pv_id=""
					fi
					if [ "$pv_size" == "" ]||[ "$unique_id" == "" ]||[ "$pv_status" == "" ]
					then
						continue
					fi
					echo "{\c"
					echo "\"serial_num\":\"$pv_num\", \c"
					echo "\"vios_id\":\"$vios_id\", \c"
					echo "\"unique_id\":\"$unique_id\", \c"
					echo "\"pv_id\":\"$pv_id\", \c"
					echo "\"pv_name\":\"$pv\", \c"
					echo "\"pv_status\":\"$pv_status\", \c"
					echo "\"pv_size\":\"$pv_size\"\c"
					echo "}\c"
				fi
				j=$(expr $j + 1)
				if [ "$j" != "$pv_count" ]
				then
					echo ",\c"
				fi
			done
			
			echo "]\c"
			echo "}\c"
			i=$(expr $i + 1)
			if [ "$i" != "$vg_length" ]
			then
				echo ", \c"
			fi
		done
	fi
	echo "]"
}

linux_getinfo() {
	i=0
	echo -e "[\c"
	if [ "$vg_length" != "0" ]
	then
		while [ $i -lt $vg_length ]
		do
			echo -e "{\c"
			echo -e "\"name\":\"${name[$i]}\", \c"
			echo -e "\"ppsize\":\"${ppsize[$i]}\", \c"
			echo -e "\"state\":\"${state[$i]}\", \c"
			echo -e "\"vgid\":\"${vgid[$i]}\", \c"
			echo -e "\"maxlvs\":\"${maxlvs[$i]}\", \c"
			echo -e "\"totalpvs\":\"${totalpvs[$i]}\", \c"
			echo -e "\"totalpps\":\"${totalpps[$i]}\", \c"
			echo -e "\"freepps\":\"${freepps[$i]}\", \c"
			echo -e "\"usedpps\":\"${usedpps[$i]}\", \c"
			echo -e "\"pppervg\":\"${pppervg[$i]}\", \c"
			echo -e "\"ppperpv\":\"${ppperpv[$i]}\", \c"
			echo -e "\"maxpvs\":\"${maxpvs[$i]}\", \c"
			
			get_vg_pv_uniqueid_info ${name[$i]}	
			echo -e "\"pvUniqueIds\":\c"
			echo -e "[\c"
			m=0
			while [ $m -lt $vg_pv_len ]
			do
				echo -e "\"${uniqueid[$m]}\"\c"
				m=$(expr $m + 1)
				if [ "$m" != "$vg_pv_len" ]
				then
						echo -e ", \c"
				fi
			done
			echo -e "],\c"
			
			echo -e "\"lv\":\c"
			echo -e "[\c"
			j=0
			if [ "${lv_info[$i]}" != "" ]
			then
				lv_num=0
				echo "${lv_info[$i]}" | awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read lva
				do
					lv[$lv_num]=$lva
					lv_num=$(expr $lv_num + 1)
				done
				
				k=0
				while [ k -lt $lv_num ]
				do
					echo -e "{\c"
					echo -e "\"lv_name\":\"$(echo ${lv[$k]} | awk -F":" '{print $1}')\", \c"
					echo -e "\"lv_id\":\"$(echo ${lv[$k]} | awk -F":" '{print $5}')\", \c"
					lv_state=$(echo "${lv[$k]}" | awk -F":" '{print $6}')
					case $lv_state in
						"opened/syncd")
										lv_state=1;;
						"closed/syncd")
										lv_state=2;;
						*)
										lv_state=3;;
					esac
					echo -e "\"lv_state\":\"$lv_state\", \c"
					echo -e "\"lv_max_lps\":\"$(echo ${lv[$k]} | awk -F":" '{print $2}')\", \c"
					echo -e "\"lv_ppsize\":\"$(echo ${lv[$k]} | awk -F":" '{print $3}' | awk '{print $1}' | sed 's/ //g')\", \c"
					echo -e "\"lv_pps\":\"$(echo ${lv[$k]} | awk -F":" '{print $4}')\", \c"
					
					lvname=$(echo ${lv[$k]} | awk -F":" '{print $1}')
					get_lv_pv_uniqueid_info $lvname
					
					echo -e "\"pvUniqueIds\":\c"
					echo -e "[\c"
					n=0
					while [ $n -lt $lv_pv_len ]
					do
						echo -e "\"${uniqueid[$n]}\"\c"
						n=$(expr $n + 1)
						if [ "$n" != "$lv_pv_len" ]
						then
								echo -e ", \c"
						fi
					done
					echo -e "]\c"
					
					echo -e "}\c"
					j=$(expr $j + 1)
					if [ "$j" != "${lvs_num[$i]}" ]
					then
						echo -e ", \c"
					fi
					
					k=$(expr $k + 1)
				done
			fi
			echo -e "],\c"	
			
			echo -e "\"pv\":[\c"
			vm_pv[$i]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsvg -pv ${name[$i]} -field PV_NAME -fmt :")
			vios_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F lpar_id,lpar_env" | awk -F"," '{if($2=="vioserver") print $1}')
			
			pv_count=0
			for pv in ${vm_pv[$i]}
			do
				pv_count=$(expr $pv_count + 1)
			done
			
			j=0
			for pv in ${vm_pv[$i]}
			do
				if [ "$pv" != "" ]
				then
					g=0
					for disk in $(echo "${vm_disk[$i]}" | awk -F":" '{for(i=1;i<=NF;i++) print $i}')
					do
						if [ "$disk" == "$pv" ]
						then
							pv_num=$g
						fi
						g=$(expr $g + 1)
					done
					
					pv_size=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -size $pv")
					unique_id=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev $pv -attr unique_id" | grep -v value | grep -v ^$)
					pv_id=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev $pv -attr pvid" | grep -v value | grep -v ^$)
					pv_status=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev $pv -field status -fmt :")
					if [ "${pv_id}" == "none" ]
					then
						pv_id=""
					fi
					if [ "$pv_size" == "" ]||[ "$unique_id" == "" ]||[ "$pv_status" == "" ]
					then
						continue
					fi
					echo -e "{\c"
					echo -e "\"serial_num\":\"$pv_num\", \c"
					echo -e "\"vios_id\":\"$vios_id\", \c"
					echo -e "\"unique_id\":\"$unique_id\", \c"
					echo -e "\"pv_id\":\"$pv_id\", \c"
					echo -e "\"pv_name\":\"$pv\", \c"
					echo -e "\"pv_status\":\"$pv_status\", \c"
					echo -e "\"pv_size\":\"$pv_size\"\c"
					echo -e "}\c"
				fi
				j=$(expr $j + 1)
				if [ "$j" != "$pv_count" ]
				then
					echo -e ",\c"
				fi
			done
			
			echo -e "]\c"
			echo -e "}\c"
			i=$(expr $i + 1)
			if [ "$i" != "$vg_length" ]
			then
				echo -e ", \c"
			fi
		done
	fi
	echo -e "]"
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
