#!/usr/bin/ksh


ivm_ip=$1
ivm_user=$2

host_info=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r sys -F type_model,serial_num,state,max_lpars,service_lpar_id && lshwres -r proc --level sys -F curr_avail_sys_proc_units,configurable_sys_proc_units,installed_sys_proc_units && lshwres -r mem --level sys -F configurable_sys_mem,curr_avail_sys_mem,installed_sys_mem,sys_firmware_mem")
ssh_out=$(exec ./ssh.exp ${ivm_user} ${ivm_ip} "oem_setup_env|prtconf" 2>&1)

vm_sys_info=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F lpar_id,name,lpar_env")
vios_name=$(echo "$vm_sys_info" | awk -F"," '{if($3=="vioserver") print $2}')

if [ "${ssh_out}" != "" ]&&[ "${host_info}" != "" ]
then
	host_name=$(echo "${ssh_out}" | grep "Host Name:" | awk -F":" '{print substr($2,0,length($2)-1)}' | sed 's/ //g')
	cpu_mode=$(echo "${ssh_out}" | grep "Processor Implementation Mode:" | awk -F":" '{print substr($2,0,length($2)-1)}' | sed 's/ //g')
	cpu_speed=$(echo "${ssh_out}" | grep "Processor Clock Speed:" | awk -F":" '{print substr($2,0,length($2)-1)}' | sed 's/ //g' | sed 's/MHz//g')
	cpu_type=$(echo "${ssh_out}" | grep "CPU Type:" | awk -F":" '{print substr($2,0,length($2)-1)}' | sed 's/ //g' | awk -F"-" '{print $1}')
	kernel_type=$(echo "${ssh_out}" | grep "Kernel Type:" | awk -F":" '{print substr($2,0,length($2)-1)}' | sed 's/ //g' | awk -F"-" '{print $1}')
		
	i=0
	echo "$host_info" | while read param
	do
		case $i in
			0)
				i=1;
				prof_info=$param;;
			1)
				i=2;        
				proc_info=$param;;
			2)
				i=3;
				mem_info=$param;;
		esac
	done
	
	if [ "$prof_info" != "" ]&&[ "$proc_info" != "" ]&&[ "$mem_info" != "" ]
	then
		type_model=$(echo "$prof_info" | awk -F"," '{print $1}')
		serial_num=$(echo "$prof_info" | awk -F"," '{print $2}')
		state=$(echo "$prof_info" | awk -F"," '{print $3}')
		max_lpars=$(echo "$prof_info" | awk -F"," '{print $4}')
		viosLparId=$(echo "$prof_info" | awk -F"," '{print $5}')
		avail_proc_units=$(echo "$proc_info" | awk -F"," '{print $1}')
		vios_proc_units=$(ssh ${ivm_user}@${ivm_ip} "lshwres -r proc --level lpar --filter lpar_ids=${viosLparId} -F curr_proc_units")
		configurable_proc_units=$(echo "$proc_info" | awk -F"," '{print $2}')
		installed_proc_units=$(echo "$proc_info" | awk -F"," '{print $3}')
		configurable_mem=$(echo "$mem_info" | awk -F"," '{print $1}')
		avail_mem=$(echo "$mem_info" | awk -F"," '{print $2}')
		vios_mem=$(ssh ${ivm_user}@${ivm_ip} "lshwres -r mem --level lpar --filter lpar_ids=${viosLparId} -F curr_mem")
		installed_mem=$(echo "$mem_info" | awk -F"," '{print $3}')
		sys_firmware_mem=$(echo "$mem_info" | awk -F"," '{print $4}')
	else
		echo "{}"
		exit 1
	fi
else
	echo "{}"
	exit 1
fi

linux_getinfo() {
	echo -e "{\c"
	echo -e "\"host_name\":\"${host_name}\", \c"
	echo -e "\"vios_name\":\"${vios_name}\", \c"
	echo -e "\"serial_num\":\"${serial_num}\", \c"
	echo -e "\"type_model\":\"${type_model}\", \c"
	echo -e "\"kernel_type\":\"${kernel_type}\", \c"
	echo -e "\"state\":\"${state}\", \c"
	#echo -e "\"state\":\"Operating\", \c"
	echo -e "\"max_lpars\":\"${max_lpars}\", \c"
	echo -e "\"cpu_mode\":\"${cpu_mode}\", \c"
	echo -e "\"cpu_speed\":\"${cpu_speed}\", \c"
	echo -e "\"cpu_type\":\"${cpu_type}\", \c"
	echo -e "\"avail_proc_units\":\"${avail_proc_units}\", \c"
	echo -e "\"vios_proc_units\":\"${vios_proc_units}\", \c"
	echo -e "\"configurable_proc_units\":\"${configurable_proc_units}\", \c"
	echo -e "\"installed_proc_units\":\"${installed_proc_units}\", \c"
	echo -e "\"avail_mem\":\"${avail_mem}\", \c"
	echo -e "\"firmware_mem\":\"${sys_firmware_mem}\", \c"
	echo -e "\"vios_mem\":\"${vios_mem}\", \c"
	echo -e "\"configurable_mem\":\"${configurable_mem}\", \c"
	echo -e "\"installed_mem\":\"${installed_mem}\"\c"
	echo -e "}"
}

aix_getinfo() {
	echo "{\c"
	echo "\"host_name\":\"${host_name}\", \c"
	echo "\"vios_name\":\"${vios_name}\", \c"
	echo "\"serial_num\":\"${serial_num}\", \c"
	echo "\"type_model\":\"${type_model}\", \c"
	echo "\"kernel_type\":\"${kernel_type}\", \c"
	echo "\"state\":\"${state}\", \c"
	#echo "\"state\":\"Operating\", \c"
	echo "\"max_lpars\":\"${max_lpars}\", \c"
	echo "\"cpu_mode\":\"${cpu_mode}\", \c"
	echo "\"cpu_speed\":\"${cpu_speed}\", \c"
	echo "\"cpu_type\":\"${cpu_type}\", \c"
	echo "\"avail_proc_units\":\"${avail_proc_units}\", \c"
	echo "\"vios_proc_units\":\"${vios_proc_units}\", \c"
	echo "\"configurable_proc_units\":\"${configurable_proc_units}\", \c"
	echo "\"installed_proc_units\":\"${installed_proc_units}\", \c"
	echo "\"avail_mem\":\"${avail_mem}\", \c"
	echo "\"firmware_mem\":\"${sys_firmware_mem}\", \c"
	echo "\"vios_mem\":\"${vios_mem}\", \c"
	echo "\"configurable_mem\":\"${configurable_mem}\", \c"
	echo "\"installed_mem\":\"${installed_mem}\"\c"
	echo "}"
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