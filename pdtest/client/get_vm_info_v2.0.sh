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
			echo  "], \c"
		
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
								
					num=0
					vm_physloc=""
					# echo "vlan_ids[$num]==${vlan_ids[$num]}"
					while [ $num -lt $sea_length ]
					do
						if [ "$(echo ${vlan_ids[$num]} | awk -F"," '{ for(i=1;i<=NF;i++) { if($i==vlan_id) {print 0; break;} } }' vlan_id=${vethpvid[$j]})" == "0" ]
						then
							vm_physloc[$j]=$(echo "${sea_physloc[$num]}" | sed 's/ //g')
							break
						fi
						num=$(expr $num + 1)
					done
					j=$(expr $j + 1)
				else
					echo $ret|awk -F ',' '{for(i=1;i<=NF;i++) if($i)print $i}'|while read tmp
					do
						vethid[$j]=$(expr $j + 1)
						vethname[$j]="eth$j"
						vethpvid[$j]=$(echo $tmp | awk -F"/" '{print $3}')
						vethslot[$j]=$(echo $tmp | awk -F"/" '{print $1}')
	
						num=0
						vm_physloc=""
						# echo "vlan_ids[$num]==${vlan_ids[$num]}"
						while [ $num -lt $sea_length ]
						do
							if [ "$(echo ${vlan_ids[$num]} | awk -F"," '{ for(i=1;i<=NF;i++) { if($i==vlan_id) {print 0; break;} } }' vlan_id=${vethpvid[$j]})" == "0" ]
							then
								vm_physloc[$j]=$(echo "${sea_physloc[$num]}" | sed 's/ //g')
								break
							fi
							num=$(expr $num + 1)
						done
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
				echo  "\"eth_pvid\":\"${vethpvid[$j]}\", \c"
				echo  "\"eth_physloc\":\"${vm_physloc[$j]}\" \c"
				echo  "} \c"
				j=$(expr $j + 1 ) 
		
				if [ $j -lt $vethnum ]
				then
					echo  ",\c"
				fi
			done
			echo  "], \c"
		fi		
		
		# echo "vm_disk[$i]==${vm_disk[$i]}"
		echo  "\"lv\":[\c"
		j=0
		for lv in ${vm_lv[$i]}
		do
			if [ "$lv" != "" ]
			then
				g=0
				for disk in $(echo "${vm_disk[$i]}" | awk -F":" '{for(i=1;i<=NF;i++) print $i}')
				do
					if [ "$disk" == "$lv" ]
					then
						lv_num=$g
					fi
					g=$(expr $g + 1)
				done
				
				#vm_lv_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lslv $lv -field lvid vgname ppsize pps lvstate -fmt :")
				vm_lv_info=$(echo "$all_vm_lv_info"|awk -F":" '{if($1==lvname) {print $0}}' lvname=$lv)
				if [ "$vm_lv_info" == "" ]
				then
							continue
				fi
				ppsize=$(echo "${vm_lv_info}" | awk -F":" '{print $4}' | awk '{print $1}')
				echo  "{\c"
				echo  "\"serial_num\":\"$lv_num\", \c"
				echo  "\"vios_id\":\"$vios_id\", \c"
				echo  "\"lv_id\":\"$(echo "${vm_lv_info}" | awk -F":" '{print $2}')\", \c"
				echo  "\"lv_name\":\"$lv\", \c"
				echo  "\"lv_vg\":\"$(echo "${vm_lv_info}" | awk -F":" '{print $3}')\", \c"
				lv_state=$(echo "${vm_lv_info}" | awk -F":" '{print $6}')
				case $lv_state in
						"opened/syncd")
							lv_state=1;;
						"closed/syncd")
							lv_state=2;;
						*)
							lv_state=3;;
				esac
				echo  "\"lv_state\":\"${lv_state}\", \c"
				echo  "\"lv_size\":\"$(echo "${vm_lv_info}" | awk -F":" '{print ppsize*$5}' ppsize="$ppsize")\", \c"
				
				#get_pv_uniqueid_info $lv
				len=0
				if [ "$all_lv_pv_uniqueid_info" != "" ]
				then
					echo "$all_lv_pv_uniqueid_info"|awk -F":" '{if($1==lvname) {print $0}}' lvname=$lv|awk -F":" '{for(i=2;i<=NF;i++) print $i}'|while read unique_id
					do
						uniqueid[$len]=$unique_id
						len=$(expr $len + 1)
					done
				fi
				
				echo  "\"pvUniqueIds\":\c"
				echo  "[\c"
				m=0
				while [ $m -lt $len ]
				do
					echo  "\"${uniqueid[$m]}\"\c"
					m=$(expr $m + 1)
					if [ "$m" != "$len" ]
					then
							echo  ", \c"
					fi
				done
				echo  "]\c"
				
				echo  "}\c"
			fi
			j=$(expr $j + 1)
			if [ "$j" != "${vm_lv_num[$i]}" ]
			then
				echo  ",\c"
			fi
		done				
		echo  "], \c"
		
		echo  "\"pv\":[\c"
		
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
				
				vm_pv_info=$(echo "$all_vm_pv_info" | awk -F":" '{if($1==pvname) {print $0}}' pvname=$pv)
				if [ "$vm_pv_info" != "" ]
				then
					pv_size=$(echo "$vm_pv_info" | awk -F":" '{print $2}')
					unique_id=$(echo "$vm_pv_info" | awk -F":" '{print $3}')
					pv_id=$(echo "$vm_pv_info" | awk -F":" '{print $4}')
					pv_status=$(echo "$vm_pv_info" | awk -F":" '{print $5}')
				fi
				
				#pv_size=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -size $pv")
				#unique_id=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev $pv -attr unique_id" | grep -v value | grep -v ^$)
				#pv_id=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev $pv -attr pv_id" | grep -v value | grep -v ^$)
				#pv_status=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev $pv -field status -fmt :")
				
				if [ "${pv_id}" == "none" ]
				then
					pv_id=""
				fi
				if [ "$pv_size" == "" ]||[ "$unique_id" == "" ]||[ "$pv_status" == "" ]
				then
							continue
				fi
				echo  "{\c"
				echo  "\"serial_num\":\"$pv_num\", \c"
				echo  "\"vios_id\":\"$vios_id\", \c"
				echo  "\"unique_id\":\"$unique_id\", \c"
				echo  "\"pv_id\":\"$pv_id\", \c"
				echo  "\"pv_name\":\"$pv\", \c"
				echo  "\"pv_status\":\"$pv_status\", \c"
				echo  "\"pv_size\":\"$pv_size\"\c"
				echo  "}\c"
			fi
			j=$(expr $j + 1)
			if [ "$j" != "${vm_pv_num[$i]}" ]
			then
				echo  ",\c"
			fi
		done				
		echo  "],\c"

		# k=0
		# echo  "\"lu\":[\\c"
		# while [ $k -lt $diskSeqNum ]
		# do
			# luid=$(echo ${lu[$k]}|awk -F ':' '{print $3}')
			# luname=$(echo ${lu[$k]}|awk -F ':' '{print $1}')
			# lusize=$(echo ${lu[$k]}|awk -F ':' '{print $2}')
			# echo  "{\"luid\":\"$luid\",\"luname\":\"$luname\",\"size\":\"$lusize\",\"diskSeqNum\":\"$k\"}\c"
			# if [ $k != $((diskSeqNum-1)) ]
			# then
				# echo  ",\c"
			# fi
			# ((k=k+1))
		# done
		# echo  "]\c"
		echo "\"lu\":[\c"
		j=0
		for lu in ${vm_lu[$i]}
		do
			if [ "$lu" != "" ]
			then
				g=0
				for disk in $(echo "${vm_disk[$i]}" | awk -F":" '{for(i=1;i<=NF;i++) print $i}')
				do
					if [ "$disk" == "$lu" ]
					then
						lu_num=$g
					fi
					g=$(expr $g + 1)
				done
				luudid=$(echo ${lu}|awk -F"." '{print $NF}')
				luname=$(echo "${lu_list_info}"|grep ":${luudid}"|awk -F ':' '{print $1}')
				lusize=$(echo "${lu_list_info}"|grep ":${luudid}"|awk -F ':' '{print $3}')
				luprovisiontype=$(echo "${lu_list_info}"|grep ":${luudid}"|awk -F ':' '{print $4}')
				luunused=$(echo "${lu_list_info}"|grep ":${luudid}"|awk -F ':' '{print $5}')
				echo "{\c"
				echo "\"serial_num\":\"$lu_num\", \c"
				echo "\"luname\":\"$luname\", \c"
				echo "\"luudid\":\"$luudid\", \c"
				echo "\"provisiontype\":\"$luprovisiontype\", \c"
				echo "\"size\":\"$lusize\", \c"
				echo "\"unusedsize\":\"$luunused\" \c"
				echo "}\c"
		
			fi
			j=$(expr $j + 1)
			if [ "$j" != "${vm_lu_num[$i]}" ]
			then
				echo ",\c"
			fi
		done
		echo "]\c"

		
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
			echo -e "], \c"
		
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
								
					num=0
					vm_physloc=""
					# echo "vlan_ids[$num]==${vlan_ids[$num]}"
					while [ $num -lt $sea_length ]
					do
						if [ "$(echo ${vlan_ids[$num]} | awk -F"," '{ for(i=1;i<=NF;i++) { if($i==vlan_id) {print 0; break;} } }' vlan_id=${vethpvid[$j]})" == "0" ]
						then
							vm_physloc[$j]=$(echo "${sea_physloc[$num]}" | sed 's/ //g')
							break
						fi
						num=$(expr $num + 1)
					done
					j=$(expr $j + 1)
				else
					echo $ret|awk -F ',' '{for(i=1;i<=NF;i++) if($i)print $i}'|while read tmp
					do
						vethid[$j]=$(expr $j + 1)
						vethname[$j]="eth$j"
						vethpvid[$j]=$(echo $tmp | awk -F"/" '{print $3}')
						vethslot[$j]=$(echo $tmp | awk -F"/" '{print $1}')
	
						num=0
						vm_physloc=""
						# echo "vlan_ids[$num]==${vlan_ids[$num]}"
						while [ $num -lt $sea_length ]
						do
							if [ "$(echo ${vlan_ids[$num]} | awk -F"," '{ for(i=1;i<=NF;i++) { if($i==vlan_id) {print 0; break;} } }' vlan_id=${vethpvid[$j]})" == "0" ]
							then
								vm_physloc[$j]=$(echo "${sea_physloc[$num]}" | sed 's/ //g')
								break
							fi
							num=$(expr $num + 1)
						done
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
				echo -e "\"eth_pvid\":\"${vethpvid[$j]}\", \c"
				echo -e "\"eth_physloc\":\"${vm_physloc[$j]}\" \c"
				echo -e "} \c"
				j=$(expr $j + 1 ) 
		
				if [ $j -lt $vethnum ]
				then
					echo -e ",\c"
				fi
			done
			echo -e "], \c"
		fi
		echo -e "\"lv\":[\c"
		
		j=0
		for lv in ${vm_lv[$i]}
		do
			if [ "$lv" != "" ]
			then
				g=0
				for disk in $(echo "${vm_disk[$i]}" | awk -F":" '{for(i=1;i<=NF;i++) print $i}')
				do
					if [ "$disk" == "$lv" ]
					then
						lv_num=$g
					fi
					g=$(expr $g + 1)
				done
			
				#vm_lv_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lslv $lv -field lvid vgname ppsize pps lvstate -fmt :")
				vm_lv_info=$(echo "$all_vm_lv_info"|awk -F":" '{if($1==lvname) {print $0}}' lvname=$lv)
				if [ "$vm_lv_info" == "" ]
				then
							continue
				fi
				ppsize=$(echo "${vm_lv_info}" | awk -F":" '{print $4}' | awk '{print $1}')
				echo -e "{\c"
				echo -e "\"serial_num\":\"$lv_num\", \c"
				echo -e "\"vios_id\":\"$vios_id\", \c"
				echo -e "\"lv_id\":\"$(echo "${vm_lv_info}" | awk -F":" '{print $2}')\", \c"
				echo -e "\"lv_name\":\"$lv\", \c"
				echo -e "\"lv_vg\":\"$(echo "${vm_lv_info}" | awk -F":" '{print $3}')\", \c"
				lv_state=$(echo "${vm_lv_info}" | awk -F":" '{print $6}')
				case $lv_state in
						"opened/syncd")
										lv_state=1;;
						"closed/syncd")
										lv_state=2;;
						*)
										lv_state=3;;
				esac
				echo -e "\"lv_state\":\"${lv_state}\", \c"
				echo -e "\"lv_size\":\"$(echo "${vm_lv_info}" | awk -F":" '{print ppsize*$5}' ppsize="$ppsize")\",\c"
				
				#begin add by wansan 20130812
				#get_pv_uniqueid_info $lv
				len=0
				if [ "$all_lv_pv_uniqueid_info" != "" ]
				then
					echo "$all_lv_pv_uniqueid_info"|awk -F":" '{if($1==lvname) {print $0}}' lvname=$lv|awk -F":" '{for(i=2;i<=NF;i++) print $i}'|while read unique_id
					do
						uniqueid[$len]=$unique_id
						len=$(expr $len + 1)
					done
				fi
				
				echo -e "\"pvUniqueIds\":\c"
				echo -e "[\c"
				m=0
				while [ $m -lt $len ]
				do
					echo -e "\"${uniqueid[$m]}\"\c"
					m=$(expr $m + 1)
					if [ "$m" != "$len" ]
					then
							echo -e ", \c"
					fi
				done
				echo -e "]\c"
				#end add by wansan 20130812
				
				echo -e "}\c"
			fi
			j=$(expr $j + 1)
			if [ "$j" != "${vm_lv_num[$i]}" ]
			then
				echo -e ",\c"
			fi
		done
		
		echo -e "], \c"
		
#new add begin
		echo -e "\"pv\":[\c"
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
				
				vm_pv_info=$(echo "$all_vm_pv_info" | awk -F":" '{if($1==pvname) {print $0}}' pvname=$pv)
				if [ "$vm_pv_info" != "" ]
				then
					pv_size=$(echo "$vm_pv_info" | awk -F":" '{print $2}')
					unique_id=$(echo "$vm_pv_info" | awk -F":" '{print $3}')
					pv_id=$(echo "$vm_pv_info" | awk -F":" '{print $4}')
					pv_status=$(echo "$vm_pv_info" | awk -F":" '{print $5}')
				fi
				
				#pv_size=$(ssh ${ivm_user}@${ivm_ip} "ioscli lspv -size $pv")
				#unique_id=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev $pv -attr unique_id" | grep -v value | grep -v ^$)
				#pv_id=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev $pv -attr pvid" | grep -v value | grep -v ^$)
				#pv_status=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev $pv -field status -fmt :")
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
			if [ "$j" != "${vm_pv_num[$i]}" ]
			then
				echo -e ",\c"
			fi
		done
		
		echo -e "],\\c"
		
		# k=0
		# echo -e "\"lu\":[\\c"
		# while [ $k -lt $diskSeqNum ]
		# do
			# luid=$(echo ${lu[$k]}|awk -F ':' '{print $3}')
			# luname=$(echo ${lu[$k]}|awk -F ':' '{print $1}')
			# lusize=$(echo ${lu[$k]}|awk -F ':' '{print $2}')
			# echo -e "{\"luid\":\"$luid\",\"luname\":\"$luname\",\"size\":\"$lusize\",\"diskSeqNum\":\"$k\"}\c"
			# if [ $k != $((diskSeqNum-1)) ]
			# then
				# echo -e ",\c"
			# fi
			# ((k=k+1))
		# done
		# echo -e "]\c"
		echo -e "\"lu\":[\c"
		j=0
		for lu in ${vm_lu[$i]}
		do
			if [ "$lu" != "" ]
			then
				g=0
				for disk in $(echo "${vm_disk[$i]}" | awk -F":" '{for(i=1;i<=NF;i++) print $i}')
				do
					if [ "$disk" == "$lu" ]
					then
						lu_num=$g
					fi
					g=$(expr $g + 1)
				done
				luudid=$(echo ${lu}|awk -F"." '{print $NF}')
				luname=$(echo "${lu_list_info}"|grep ":${luudid}"|awk -F ':' '{print $1}')
				lusize=$(echo "${lu_list_info}"|grep ":${luudid}"|awk -F ':' '{print $3}')
				luprovisiontype=$(echo "${lu_list_info}"|grep ":${luudid}"|awk -F ':' '{print $4}')
				luunused=$(echo "${lu_list_info}"|grep ":${luudid}"|awk -F ':' '{print $5}')
				echo -e "{\c"
				echo -e "\"serial_num\":\"$lu_num\", \c"
				echo -e "\"luname\":\"$luname\", \c"
				echo -e "\"luudid\":\"$luudid\", \c"
				echo -e "\"provisiontype\":\"$luprovisiontype\", \c"
				echo -e "\"size\":\"$lusize\", \c"
				echo -e "\"unusedsize\":\"$luunused\" \c"
				echo -e "}\c"
		
			fi
			j=$(expr $j + 1)
			if [ "$j" != "${vm_lu_num[$i]}" ]
			then
				echo -e ",\c"
			fi
		done
		echo -e "]\c"
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

#begin add by wansan 20130812
# get_pv_uniqueid_info() {
	# lv_name=$1
	# pv_name_list=$(ssh ${ivm_user}@${ivm_ip} "ioscli lslv -pv $lv_name -field PV -fmt :")
	
	# len=0
	# if [ "$pv_name_list" != "" ]
	# then
		# for pv in $(echo ${pv_name_list})
		# do
			# vgpvs[$len]=$pv
			# vgpvsstr=${vgpvsstr}" "${vgpvs[$len]}
			# len=$(expr $len + 1)
		# done
	# fi

	# pv_i=0
	# while [ $pv_i -lt $len ]
	# do
		# uniqueid[$pv_i]=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev ${vgpvs[$pv_i]} -attr unique_id|grep -v value|grep -v ^$" 2>&1)
		# pv_i=$(expr $pv_i + 1)
	# done
# }
#end add by wansan 20130812

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

vios_id=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r lpar -F lpar_id,lpar_env" | awk -F"," '{if($2=="vioserver") print $1}')

sea_name=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -type sea" | grep Available | awk '{print $1}')
sea_map_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -net -field svea physloc bdphysloc -fmt :")

lv_map_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -type lv -field physloc backing -fmt :" | grep -v ^$)

#new add begin
pv_map_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -type disk -field physloc backing -fmt :" | grep -v ^$)

disk_map_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -type lv disk cl_disk -field physloc lun backing -fmt :" | grep -v ^$)

lu_map_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -type cl_disk -field physloc backing -fmt :" | grep -v ^$)

vhost_slot_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsmap -all -field physloc svsa -fmt :" | grep -v ^$)

cluster=$(ssh ${ivm_user}@${ivm_ip} "ioscli cluster -list|grep -E 'CLUSTER_NAME'|awk '{print \$2}'")
sp_name=$(ssh ${ivm_user}@${ivm_ip} 2>/dev/null "ioscli lssp -clustername $cluster|grep -E 'POOL_NAME'|awk '{print \$2}'")
lu_list_info=$(ssh ${ivm_user}@${ivm_ip} 2>/dev/null "ioscli lssp -clustername $cluster -sp $sp_name -bd -field luname luudid size provisiontype unused -fmt :")
#new add end

# echo "vm_sys_info==$vm_sys_info"
# echo "vm_prof_info==$vm_prof_info"
# echo "sea_name==$sea_name"
# echo "sea_map_info==$sea_map_info"
# echo "lv_map_info==$lv_map_info"
# echo "pv_map_info==$pv_map_info"

sea_length=0
for sea in $sea_name
do
	if [ "$sea" != "" ]
	then
		sea_name[$sea_length]=$sea
		sea_info=$(ssh ${ivm_user}@${ivm_ip} "ioscli lsdev -dev $sea -attr")
		# sea_pvid[$sea_length]=$(echo "$sea_info" | awk '{if($1=="pvid") print $2}')
		sea_pvid_ent=$(echo "$sea_info" | awk '{if($1=="pvid_adapter") print $2}')
		sea_virt_adapters=$(echo "$sea_info" | awk '{if($1=="virt_adapters") print $2}')
		# echo "sea_virt_adapters==$sea_virt_adapters"
		echo ${sea_virt_adapters} | awk -F"," '{for(i=1;i<=NF;i++) print $i}' | while read ent
		do
			if [ "$ent" != "" ]
			then
				if [ "$ent" == "$sea_pvid_ent" ]
				then
					echo "${sea_map_info}" | while read map
					do
						if [ "$sea_pvid_ent" == "$(echo "$map" | awk -F":" '{print $1}')" ]
						then
							sea_physloc[$sea_length]=$(echo "$map" | awk -F":" '{print $3}')
							slot_num=$(echo "$map" | awk -F":" '{print $2}' | awk -F"-" '{print $3}' | sed 's/C//g')
							# echo "slot_num==$slot_num"
							vlans=$(ssh ${ivm_user}@${ivm_ip} "lshwres -r virtualio --rsubtype eth --level lpar --filter lpar_ids=$vios_id,slots=$slot_num -F port_vlan_id,addl_vlan_ids" | sed 's/,none//g' | sed 's/"//g')","$vlans
							# echo "vlans==$vlans"
							break
						fi
					done
				else
					echo "${sea_map_info}" | while read map
					do
						if [ "$ent" == "$(echo "$map" | awk -F":" '{print $1}')" ]
						then
							slot_num=$(echo "$map" | awk -F":" '{print $2}' | awk -F"-" '{print $3}' | sed 's/C//g')
							# echo "slot_num==$slot_num"
							vlans=$(ssh ${ivm_user}@${ivm_ip} "lshwres -r virtualio --rsubtype eth --level lpar --filter lpar_ids=$vios_id,slots=$slot_num -F port_vlan_id,addl_vlan_ids"  | sed 's/,none//g' | sed 's/"//g')","$vlans
							# echo "vlans==$vlans"
							break
						fi
					done
				fi
			fi
		done
		vlan_ids[$sea_length]=$(echo "$vlans" | awk -F"," '{for(i=1;i<=NF;i++) { if($i!="") printf $i"," } }' | awk '{print substr($0,0,length($0)-1)}')
		
		# echo "sea_name[$sea_length]==${sea_name[$sea_length]}"
		# echo "vlan_ids[$sea_length]==${vlan_ids[$sea_length]}"
		# echo "sea_physloc[$sea_length]==${sea_physloc[$sea_length]}"
		sea_length=$(expr $sea_length + 1)
	fi
done

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
		
						#backing device
						# lu_bd_info=$(echo "$lu_map_info"|grep "C${vios_scsi_slot}:"|sed 's/\ //g')
						#sequence in mapping
						# diskSeqNum=0
						# echo $lu_bd_info|awk -F ":" '{for (i=2;i<=NF;i++) print $i}'|grep -E "^[a-zA-Z0-9_]+\.[a-zA-Z0-9]{32}$"|while read lu_info
					# do
						# lu_name=$(echo $lu_info|awk -F "." '{print $1}')
						# echo $lu_list|awk '{for (i=1;i<=NF;i++)print $i}'|while read current_lu
					# do
						# find_lu=$(echo $current_lu|grep -E "$lu_name:"|wc -l)
						# if [ $find_lu == 1 ]
						# then
							# lu[$diskSeqNum]=$current_lu
						# fi
					# done
					# ((diskSeqNum=diskSeqNum+1))
					# done
						
						disk_name=$(echo "$disk_map_info" | grep "\-C${vios_scsi_slot[${length}]}:") 
						len=0
						echo "$disk_name" | awk -F":" '{for(i=2;i<=NF;i++) {if(i%2==0) printf $i","; else print $i}}' | while read param
						do
							lun[$len]=$(echo $param | awk -F"," '{print $1}')
							#lun[$len]=$(echo ${lun[$len]#*x} | awk '{num=$0; i=length($0); while(substr(num,i,1)==0) { num=substr(num,0,i-1); i--; } print num}')
							#lun[$len]=$(echo ${lun[$len]} | awk '{num=$0; i=length($0); while(substr(num,i,1)==0) { num=substr(num,0,i-1);i--; } printf "%d",num}')
							if [ $(uname -s) == "AIX" ]
							then
								lun[$len]=$(echo ${lun[$len]} | awk '{num=$0; i=length($0); while(substr(num,i,1)==0) { num=substr(num,0,i-1);i--; } printf "%d",num}')
							fi
							if [ $(uname -s) == "Linux" ]
							then
								lun[$len]=$(echo ${lun[$len]} | awk --posix '{num=$0; i=length($0); while(substr(num,i,1)==0) { num=substr(num,0,i-1);i--; } printf "%d",num}')
							fi

							disk_[$len]=$(echo $param | awk -F"," '{print $2}')
							# echo disk: ${disk_[$j]}
							len=$(expr $len + 1)
						done

						i=0
						while [ $i -lt $len ]
						do
							j=$(expr $i + 1)
							while [ $j -lt $len ]
							do
								if [ ${lun[$i]} -gt ${lun[$j]} ]
								then
									temp=${lun[$j]}
									lun[$j]=${lun[$i]}
									lun[$i]=$temp
									temp=${disk_[$j]}
									disk_[$j]=${disk_[$i]}
									disk_[$i]=$temp
								fi
								j=$(expr $j + 1)
							done
							i=$(expr $i + 1)
						done
						
						i=0
						while [ $i -lt $len ]
						do
							if [ $i -eq 0 ]
							then
								vm_disk[$length]=${disk_[$i]}
							else
								vm_disk[$length]=${vm_disk[$length]}":"${disk_[$i]}
							fi
							i=$(expr $i + 1)
						done
						# vm_disk_num[$length]=$len
						
						if [ "$lv_map_info" != "" ]
						then
							vm_lv_num[${length}]=$(echo "$lv_map_info" | grep "\-C${vios_scsi_slot[${length}]}:" | awk -F":" '{print NF-1}')
							vm_lv[${length}]=$(echo "$lv_map_info" | grep "\-C${vios_scsi_slot[${length}]}:" | awk -F":" '{for(i=2;i<=NF;i++) print $i}')
						fi
						
						if [ "$pv_map_info" != "" ]
						then
							vm_pv_num[${length}]=$(echo "$pv_map_info" | grep "\-C${vios_scsi_slot[${length}]}:" | awk -F":" '{print NF-1}')
							vm_pv[${length}]=$(echo "$pv_map_info" | grep "\-C${vios_scsi_slot[${length}]}:" | awk -F":" '{for(i=2;i<=NF;i++) print $i}')
						fi
						
						if [ "$lu_map_info" != "" ]
						then
							vm_lu_num[${length}]=$(echo "$lu_map_info" | grep "\-C${vios_scsi_slot[${length}]}:" | awk -F":" '{print NF-1}')
							vm_lu[${length}]=$(echo "$lu_map_info" | grep "\-C${vios_scsi_slot[${length}]}:" | awk -F":" '{for(i=2;i<=NF;i++) print $i}')
						fi
												
						# vm_eth[${length}]=$(ssh ${ivm_user}@${ivm_ip} "lssyscfg -r prof -F virtual_eth_adapters --filter lpar_ids=\"${vm_id[${length}]}\"" | sed 's/"//g')
						# if [ "${vm_eth[${length}]}" != "" ]
						# then
							# vm_eth_num[${length}]=$(echo ${vm_eth[${length}]} | awk -F"," '{print NF}')
							# vm_eth[${length}]=$(echo ${vm_eth[${length}]} | awk -F"," '{for(i=1;i<=NF;i++) print $i}')
						# else
							# vm_eth_num[${length}]=0
						# fi
					fi
				fi
			done
			
			length=$(expr $length + 1)
		fi
	done
	if [ "${vm_lv[*]}" != "" ]
	then
		all_vm_lv_info=$(ssh ${ivm_user}@${ivm_ip} "for lv in "${vm_lv[*]}";do lv_info=\$(ioscli lslv \$lv -field lvname lvid vgname ppsize pps lvstate -fmt :);echo \$lv_info;done")
		#echo "$all_vm_lv_info"
	
		#all_lv_pv_uniqueid_info=$(ssh ${ivm_user}@${ivm_ip} "for lv in "${vm_lv[*]}";do pv_list=\$(ioscli lslv -pv \$lv -field PV -fmt :);pv_num=\$(echo \$pv_list|awk -F":" '{print NF}' );echo \"\$lv\\c\";i=1;for pv in "\$pv_list";do pvudid=\$(ioscli lsdev -dev \$pv -attr unique_id|grep -v value|grep -v ^\$);echo \":\$pvudid\\c\";if [ "\$i" == "\$pv_num" ];then echo \"\";fi;((i=i+1));done;done")
		all_lv_pv_uniqueid_info=$(ssh ${ivm_user}@${ivm_ip} "for lv in "${vm_lv[*]}";do pv_list=\$(ioscli lslv -pv \$lv -field PV -fmt :);pv_num=\$(echo \$pv_list|awk -F":" '{print NF}' );echo \"\$lv\\c\";i=1;for pv in "\$pv_list";do pvudid=\$(ioscli chkdev -dev \$pv -field name IDENTIFIER -fmt :|awk -F":" '{print \$2}');echo \":\$pvudid\\c\";if [ "\$i" == "\$pv_num" ];then echo \"\";fi;((i=i+1));done;done")
		#echo "$all_lv_pv_uniqueid_info"
	fi
	
	if [ "${vm_pv[*]}" != "" ]
	then
		#all_vm_pv_info=$(ssh ${ivm_user}@${ivm_ip} "for pv in "${vm_pv[*]}";do pv_size=\$(ioscli lspv -size \$pv);unique_id=\$(ioscli lsdev -dev \$pv -attr unique_id | grep -v value | grep -v ^\$);pv_id=\$(ioscli lsdev -dev \$pv -attr pvid | grep -v value | grep -v ^\$);pv_status=\$(ioscli lsdev -dev \$pv -field status -fmt :);echo \"\$pv:\$pv_size:\$unique_id:\$pv_id:\$pv_status\";done") 
		all_vm_pv_info=$(ssh ${ivm_user}@${ivm_ip} "for pv in "${vm_pv[*]}";do pv_size=\$(ioscli lspv -size \$pv);unique_id=\$(ioscli chkdev -dev \$pv -field name IDENTIFIER -fmt :|awk -F":" '{print \$2}');pv_id=\$(ioscli lsdev -dev \$pv -attr pvid | grep -v value | grep -v ^\$);pv_status=\$(ioscli lsdev -dev \$pv -field status -fmt :);echo \"\$pv:\$pv_size:\$unique_id:\$pv_id:\$pv_status\";done") 
	fi
	
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