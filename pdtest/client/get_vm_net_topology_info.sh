#!/usr/bin/ksh

aix_getinfo() {
	i=0
	echo  "[\c"
	while [ $i -lt $length ]
	do
		echo  "{\c"
		echo  "\"lpar_id\":\"${vm_id[$i]}\", \c"
		echo  "\"lpar_name\":\"${vm_name[$i]}\", \c"
		echo  "\"lpar_env\":\"${vm_env[$i]}\", \c"
		echo  "\"lpar_state\":\"${vm_state[$i]}\", \c"
		echo  "\"lpar_ostype\":\"${vm_os_type[$i]}\", \c"
		echo  "\"lpar_osversion\":\"${vm_osversion[$i]}\", \c"
		echo  "\"lpar_profile\":\"${vm_profile[$i]}\", \c"
		echo  "\"lpar_bootmode\":\"${vm_bootmode[$i]}\", \c"
		echo  "\"lpar_autostart\":\"${vm_autostart[$i]}\", \c"
		echo  "\"lpar_uptime\":\"${vm_uptime[$i]}\", \c"
		echo  "\"lpar_rmcstate\":\"${vm_rmcstate[$i]}\", \c"
		echo  "\"lpar_proc_mode\":\"${vm_proc_mode[$i]}\", \c"
		echo  "\"lpar_mem\":{\c"
		echo  "\"min_mem\":\"${vm_min_mem[$i]}\", \c"
		echo  "\"desired_mem\":\"${vm_desired_mem[$i]}\", \c"
		echo  "\"max_mem\":\"${vm_max_mem[$i]}\"\c"
		echo  "}, \c"
		
		if [ "${vm_id[$i]}" == "1" ]
		then
			echo  "\"scsi_adapter\":\c"
			echo "{}, \c"
		else
			echo  "\"scsi_adapter\":{\c"
			#echo "\"vios_scsi_slot\":\"${vios_scsi_slot[$i]}\", \c"
			echo "\"vios_scsi_adapter\":\"${vios_scsi_adapter[$i]}\", \c"
			#echo "\"client_scsi_slot\":\"${client_scsi_slot[$i]}\", \c"
			echo "\"slot_num\":\"${slot_num[$i]}\", \c"
			echo "\"adapter_type\":\"${adapter_type[$i]}\", \c"
			echo "\"remote_lpar_id\":\"${remote_lpar_id[$i]}\", \c"
			echo "\"remote_lpar_name\":\"${remote_lpar_name[$i]}\", \c"
			echo "\"remote_slot_num\":\"${remote_slot_num[$i]}\", \c"
			echo "\"is_required\":\"${is_required[$i]}\" \c"
			echo  "}, \c"
		fi
		
		echo  "\"lpar_proc\":{\c"
		echo  "\"proc_mode\":\"${vm_proc_mode[$i]}\", \c"
		echo  "\"min_proc_units\":\"${vm_min_proc_units[$i]}\", \c"
		echo  "\"desired_proc_units\":\"${vm_desired_proc_units[$i]}\", \c"
		echo  "\"max_proc_units\":\"${vm_max_proc_units[$i]}\", \c"
		echo  "\"min_procs\":\"${vm_min_procs[$i]}\", \c" 
		echo  "\"desired_procs\":\"${vm_desired_procs[$i]}\", \c"
		echo  "\"max_procs\":\"${vm_max_procs[$i]}\", \c"
		echo  "\"sharing_mode\":\"${vm_sharing_mode[$i]}\", \c"
		echo  "\"uncap_weight\":\"${vm_uncap_weight[$i]}\"\c"
		echo  "}, \c"
		echo  "\"network\":[\c"
		#slot_number/is_ieee/port_vlan_id/additional_vlan_ids/ is_trunk/is_required
		vm_eth_info=$(echo "$all_vm_eth_info"|awk -F":" '{if($1==vmid) {print $2}}' vmid="${vm_id[$i]}")
		
		j=0
		m=1
		if [ "$vm_eth_info" == "none" ]
		then
			echo  "] \c"
		
		else
			echo "$vm_eth_info" | awk -F'""' '{for(i=1;i<=NF;i++) print $i}' | while read eth
			do
				eth=$(echo $eth|sed 's/"//g')
				ret=${eth}
		
				if [ $((m%2)) == 0 ]
				then
					vethid[$j]=$(expr $j + 1)
					vethname[$j]="eth$j"
					vethpvid[$j]=$(echo $ret | awk -F"/" '{print $3}')
					vethslot[$j]=$(echo $ret | awk -F"/" '{print $1}')
					j=$(expr $j + 1)
				else
					echo $ret|awk -F ',' '{for(i=1;i<=NF;i++) if($i)print $i}'|while read tmp
					do
						vethid[$j]=$(expr $j + 1)
						vethname[$j]="eth$j"
						vethpvid[$j]=$(echo $tmp | awk -F"/" '{print $3}')
						vethslot[$j]=$(echo $tmp | awk -F"/" '{print $1}')
						j=$(expr $j + 1)
					done
				fi
				m=$(expr $m + 1)		
			done
			vethnum=$(expr $j - 0)
			
			j=0
			while [ $j -lt $vethnum ]
			do
				echo  "{\c"
				echo  "\"eth_slot\":\"${vethslot[$j]}\", \c"
				echo  "\"eth_id\":\"${vethid[$j]}\", \c"
				echo  "\"eth_name\":\"${vethname[$j]}\", \c"
				echo  "\"eth_pvid\":\"${vethpvid[$j]}\" \c"
				echo  "} \c"
				j=$(expr $j + 1 ) 
		
				if [ $j -lt $vethnum ]
				then
					echo  ",\c"
				fi
			done
			echo  "] \c"
		fi
		i=$(expr $i + 1)
		if [ "$i" == "$length" ]
		then
			echo  "}]"
		else
			echo  "}, \c"
		fi
	done
}

linux_getinfo() {
	i=0
	echo -e "[\c"
	while [ $i -lt $length ]
	do
		echo -e "{\c"
		echo -e "\"lpar_id\":\"${vm_id[$i]}\", \c"
		echo -e "\"lpar_name\":\"${vm_name[$i]}\", \c"
		echo -e "\"lpar_env\":\"${vm_env[$i]}\", \c"
		echo -e "\"lpar_state\":\"${vm_state[$i]}\", \c"
		echo -e "\"lpar_ostype\":\"${vm_os_type[$i]}\", \c"
		echo -e "\"lpar_osversion\":\"${vm_osversion[$i]}\", \c"
		echo -e "\"lpar_profile\":\"${vm_profile[$i]}\", \c"
		echo -e "\"lpar_bootmode\":\"${vm_bootmode[$i]}\", \c"
		echo -e "\"lpar_autostart\":\"${vm_autostart[$i]}\", \c"
		echo -e "\"lpar_uptime\":\"${vm_uptime[$i]}\", \c"
		echo -e "\"lpar_rmcstate\":\"${vm_rmcstate[$i]}\", \c"
		echo -e "\"lpar_proc_mode\":\"${vm_proc_mode[$i]}\", \c"
		echo -e "\"lpar_mem\":{\c"
		echo -e "\"min_mem\":\"${vm_min_mem[$i]}\", \c"
		echo -e "\"desired_mem\":\"${vm_desired_mem[$i]}\", \c"
		echo -e "\"max_mem\":\"${vm_max_mem[$i]}\"\c"
		echo -e "}, \c"
		
		if [ "${vm_id[$i]}" == "1" ]
		then
			echo -e "\"scsi_adapter\":\c"
			echo -e "{}, \c"
		else
			echo -e "\"scsi_adapter\":{\c"
			#echo "\"vios_scsi_slot\":\"${vios_scsi_slot[$i]}\", \c"
			echo -e "\"vios_scsi_adapter\":\"${vios_scsi_adapter[$i]}\", \c"
			#echo "\"client_scsi_slot\":\"${client_scsi_slot[$i]}\", \c"
			echo -e "\"slot_num\":\"${slot_num[$i]}\", \c"
			echo -e "\"adapter_type\":\"${adapter_type[$i]}\", \c"
			echo -e "\"remote_lpar_id\":\"${remote_lpar_id[$i]}\", \c"
			echo -e "\"remote_lpar_name\":\"${remote_lpar_name[$i]}\", \c"
			echo -e "\"remote_slot_num\":\"${remote_slot_num[$i]}\", \c"
			echo -e "\"is_required\":\"${is_required[$i]}\" \c"
			echo -e "}, \c"
		fi
		
		echo -e "\"lpar_proc\":{\c"
		echo -e "\"proc_mode\":\"${vm_proc_mode[$i]}\", \c"
		echo -e "\"min_proc_units\":\"${vm_min_proc_units[$i]}\", \c"
		echo -e "\"desired_proc_units\":\"${vm_desired_proc_units[$i]}\", \c"
		echo -e "\"max_proc_units\":\"${vm_max_proc_units[$i]}\", \c"
		echo -e "\"min_procs\":\"${vm_min_procs[$i]}\", \c" 
		echo -e "\"desired_procs\":\"${vm_desired_procs[$i]}\", \c"
		echo -e "\"max_procs\":\"${vm_max_procs[$i]}\", \c"
		echo -e "\"sharing_mode\":\"${vm_sharing_mode[$i]}\", \c"
		echo -e "\"uncap_weight\":\"${vm_uncap_weight[$i]}\"\c"
		echo -e "}, \c"
		echo -e "\"network\":[\c"
				
		vm_eth_info=$(echo "$all_vm_eth_info"|awk -F":" '{if($1==vmid) {print $2}}' vmid="${vm_id[$i]}")
		
		j=0
		m=1
		if [ "$vm_eth_info" == "none" ]
		then
			echo -e "] \c"
		
		else
			echo "$vm_eth_info" | awk -F'""' '{for(i=1;i<=NF;i++) print $i}' | while read eth
			do
				eth=$(echo $eth|sed 's/"//g')
				ret=${eth}
				
				if [ $((m%2)) == 0 ]
				then
					vethid[$j]=$(expr $j + 1)
					vethname[$j]="eth$j"
					vethpvid[$j]=$(echo $ret | awk -F"/" '{print $3}')
					vethslot[$j]=$(echo $ret | awk -F"/" '{print $1}')
	
					j=$(expr $j + 1)
				else
					echo $ret|awk -F ',' '{for(i=1;i<=NF;i++) if($i)print $i}'|while read tmp
					do
						vethid[$j]=$(expr $j + 1)
						vethname[$j]="eth$j"
						vethpvid[$j]=$(echo $tmp | awk -F"/" '{print $3}')
						vethslot[$j]=$(echo $tmp | awk -F"/" '{print $1}')
	
						j=$(expr $j + 1)
					done
				fi
				m=$(expr $m + 1)		
			done
			vethnum=$(expr $j - 0)
			
			j=0
			while [ $j -lt $vethnum ]
			do
				echo -e "{\c"
				echo -e "\"eth_slot\":\"${vethslot[$j]}\", \c"
				echo -e "\"eth_id\":\"${vethid[$j]}\", \c"
				echo -e "\"eth_name\":\"${vethname[$j]}\", \c"
				echo -e "\"eth_pvid\":\"${vethpvid[$j]}\" \c"
				echo -e "} \c"
				j=$(expr $j + 1 ) 
		
				if [ $j -lt $vethnum ]
				then
					echo -e ",\c"
				fi
			done
			echo -e "] \c"
		fi
#new add end
		
		i=$(expr $i + 1)
		if [ "$i" == "$length" ]
		then
			echo -e "}]"
		else
			echo -e "}, \c"
		fi
	done
}

ivm_ip=$1
ivm_user=$2
lpar_name=$3

DateNow=$(date +%Y%m%d%H%M%S)
out_log="out_startup_${DateNow}.log"
error_log="error_startup_${DateNow}.log"

if [ "${lpar_name}" != "" ]
then
	info=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar --filter lpar_names=\"${lpar_name}\"" 2> /dev/null)
	if [ "$info" == "" ]
	then
		echo "No results were found." >&2
		exit 1
	fi
fi

if [ "${lpar_name}" == "" ]
then
	vm_sys_info=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F name,lpar_id,lpar_env,state,os_version,default_profile,boot_mode,auto_start,uptime,rmc_state,auto_start")
	vm_prof_info=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof -F lpar_id,os_type,min_mem,desired_mem,max_mem,proc_mode,min_proc_units,desired_proc_units,max_proc_units,min_procs,desired_procs,max_procs,sharing_mode,uncap_weight,virtual_scsi_adapters,virtual_eth_adapters")
else
	vm_sys_info=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F name,lpar_id,lpar_env,state,os_version,default_profile,boot_mode,auto_start,uptime,rmc_state,auto_start --filter lpar_names=\"${lpar_name}\"")
	vm_prof_info=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof -F lpar_id,os_type,min_mem,desired_mem,max_mem,proc_mode,min_proc_units,desired_proc_units,max_proc_units,min_procs,desired_procs,max_procs,sharing_mode,uncap_weight,virtual_scsi_adapters,virtual_eth_adapters --filter lpar_names=\"${lpar_name}\"")
fi

vhost_slot_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -field physloc svsa -fmt :" | grep -v ^$)

#new add end

# echo "vm_sys_info==$vm_sys_info"
# echo "vm_prof_info==$vm_prof_info"
# echo "sea_name==$sea_name"
# echo "sea_map_info==$sea_map_info"
# echo "lv_map_info==$lv_map_info"
# echo "pv_map_info==$pv_map_info"

length=0
if [ "${vm_sys_info}" != "" ]
then
	echo "${vm_sys_info}" | while read sys_info
	do
		if [ "$sys_info" != "" ]
		then
			vm_name[${length}]=$(echo "${sys_info}" | awk -F"," '{print $1}')
			vm_id[${length}]=$(echo "${sys_info}" | awk -F"," '{print $2}')
			vm_env[${length}]=$(echo "${sys_info}" | awk -F"," '{print $3}')
			vm_state[${length}]=$(echo "${sys_info}" | awk -F"," '{print $4}')
			vm_osversion[${length}]=$(echo "${sys_info}" | awk -F"," '{print $5}')
			vm_profile[${length}]=$(echo "${sys_info}" | awk -F"," '{print $6}')
			vm_bootmode[${length}]=$(echo "${sys_info}" | awk -F"," '{print $7}')
			vm_autostart[${length}]=$(echo "${sys_info}" | awk -F"," '{print $8}')
			vm_uptime[${length}]=$(echo "${sys_info}" | awk -F"," '{print $9}')
			vm_rmcstate[${length}]=$(echo "${sys_info}" | awk -F"," '{print $10}')
			
			echo "${vm_prof_info}" | while read prof_info
			do
				if [ "${prof_info}" != "" ]
				then
					vid=$(echo "${prof_info}" | awk -F"," '{print $1}')
					if [ "${vm_id[${length}]}" ==  "${vid}" ]
					then
						vm_os_type[${length}]=$(echo "${prof_info}" | awk -F"," '{print $2}' | awk '{if($0!="null") print $0}')
						vm_min_mem[${length}]=$(echo "${prof_info}" | awk -F"," '{print $3}' | awk '{if($0!="null") print $0}')
						vm_desired_mem[${length}]=$(echo "${prof_info}" | awk -F"," '{print $4}' | awk '{if($0!="null") print $0}')
						vm_max_mem[${length}]=$(echo "${prof_info}" | awk -F"," '{print $5}' | awk '{if($0!="null") print $0}')
						vm_proc_mode[${length}]=$(echo "${prof_info}" | awk -F"," '{print $6}' | awk '{if($0!="null") print $0}')
						vm_min_proc_units[${length}]=$(echo "${prof_info}" | awk -F"," '{print $7}' | awk '{if($0!="null") print $0}')
						vm_desired_proc_units[${length}]=$(echo "${prof_info}" | awk -F"," '{print $8}' | awk '{if($0!="null") print $0}')
						vm_max_proc_units[${length}]=$(echo "${prof_info}" | awk -F"," '{print $9}' | awk '{if($0!="null") print $0}')
						vm_min_procs[${length}]=$(echo "${prof_info}" | awk -F"," '{print $10}' | awk '{if($0!="null") print $0}')
						vm_desired_procs[${length}]=$(echo "${prof_info}" | awk -F"," '{print $11}' | awk '{if($0!="null") print $0}')
						vm_max_procs[${length}]=$(echo "${prof_info}" | awk -F"," '{print $12}' | awk '{if($0!="null") print $0}')
						vm_sharing_mode[${length}]=$(echo "${prof_info}" | awk -F"," '{print $13}' | awk '{if($0!="null") print $0}')
						vm_uncap_weight[${length}]=$(echo "${prof_info}" | awk -F"," '{print $14}' | awk '{if($0!="null") print $0}')
						
						if [ "${vm_id[$length]}" != "1" ]
						then
							#slot_num/adapter_type/remote_lpar_id/remote_lpar_name/remote_slot_num/is_required
							vios_scsi_slot[${length}]=$(echo "${prof_info}" | awk -F"," '{print $15}' | awk -F"/" '{print $5}' | awk '{if($0!="null") print $0}')
							vios_scsi_adapter[${length}]=$(echo "${vhost_slot_info}" | grep "\-C${vios_scsi_slot[${length}]}:" | awk -F":" '{print $2}' )
							client_scsi_slot[${length}]=$(echo "${prof_info}" | awk -F"," '{print $15}' | awk -F"/" '{print $1}' | awk '{if($0!="null") print $0}')
							slot_num[${length}]=$(echo "${prof_info}" | awk -F"," '{print $15}' | awk -F"/" '{print $1}' | awk '{if($0!="null") print $0}')
							adapter_type[${length}]=$(echo "${prof_info}" | awk -F"," '{print $15}' | awk -F"/" '{print $2}' | awk '{if($0!="null") print $0}')
							remote_lpar_id[${length}]=$(echo "${prof_info}" | awk -F"," '{print $15}' | awk -F"/" '{print $3}' | awk '{if($0!="null") print $0}')
							remote_lpar_name[${length}]=$(echo "${prof_info}" | awk -F"," '{print $15}' | awk -F"/" '{print $4}' | awk '{if($0!="null") print $0}')
							remote_slot_num[${length}]=$(echo "${prof_info}" | awk -F"," '{print $15}' | awk -F"/" '{print $5}' | awk '{if($0!="null") print $0}')
							is_required[${length}]=$(echo "${prof_info}" | awk -F"," '{print $15}' | awk -F"/" '{print $6}' | awk '{if($0!="null") print $0}')
							
						fi
		
					fi
				fi
			done
			
			length=$(expr $length + 1)
		fi
	done
	
	if [ "${vm_id[*]}" != "" ]
	then
		all_vm_eth_info=$(ssh ${ivm_user}@${ivm_ip} "for vmid in "${vm_id[*]}";do vm_eth=\$(lssyscfg -r prof -F virtual_eth_adapters --filter lpar_ids=\$vmid );echo \"\$vmid:\$vm_eth\";done")
		#echo "$all_vm_eth_info"
	fi
else
	echo "[]"
	exit 1
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
