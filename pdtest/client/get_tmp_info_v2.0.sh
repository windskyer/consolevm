#!/usr/bin/ksh

tmp_nm=$1

j=0
for nfs_info in $(echo $2 |awk -F"|" '{for(i=1;i<=NF;i++) print $i}')
do
		case $j in
			0)
					j=1;
					nfs_ip=$nfs_info;;
			1)
					j=2;        
					nfs_name=$nfs_info;;
			2)
					j=3;
					nfs_passwd=$nfs_info;;
			3)
					j=4;
					nfs_path=$nfs_info;;
		esac
done

#####################################################################################
#####                                                                           #####
#####                          		 mount nfs	                                #####
#####                                                                           #####
#####################################################################################
result=$(./ivm_mount_nfs.sh "$2" 2>&1)
if [ $? -ne 0 ]
then
	echo "$result" >&2
	exit 1
fi
tmp_path=$(echo "$result" | sed -e 's/"//g' -e 's/\[//g' -e 's/\]//g' -e 's/{//g' -e 's/}//g' | awk -F":" '{print $2}')

length=0
if [ "$tmp_nm" == "" ]
then
	ls -l $tmp_path | awk '{if(substr($1,0,1)=="d") print $0}' | while read line
	do
		tmp_name[$length]=$(echo $line | awk '{print $9}')
		tmp_info=$(cat $tmp_path"/"${tmp_name[$length]}"/"${tmp_name[$length]}".cfg" 2>&1)
		if [ "$(echo $?)" != "0" ]
		then
			continue
		fi
		tmp_id[$length]=$(echo "$tmp_info" | awk -F"=" '{if($1=="id") print $2}')
		tmp_files[$length]=$(echo "$tmp_info" | awk -F"=" '{if($1=="files") print $2}')
		echo ${tmp_files[$length]} | awk -F"," '{for(i=1;i<=NF;i++) print $i}' | while read file
		do
			tmp_file=$(echo $line | awk -F"|" '{print $1}')
			ls $tmp_file > /dev/null 2>&1
			if [ "$(echo $?)" != "0" ]
			then
				continue
			fi
		done
		file_num[$length]=$(echo "${tmp_files[$length]}" | awk -F"," '{print NF}')
		tmp_type[$length]=$(echo "$tmp_info" | awk -F"=" '{if($1=="type") print $2}')
		tmp_desc[$length]=$(echo "$tmp_info" | awk -F"=" '{if($1=="desc") print $2}')
		if [ "${tmp_id[$length]}" == "" ]||[ "${tmp_files[$length]}" == "" ]||[ "${tmp_type[$length]}" == "" ]||[ "${file_num[$length]}" == "0" ]
		then
			continue
		fi
		length=$(expr $length + 1)
	done
else
	tmp_name[$length]=${tmp_nm}
	
	tmp_info=$(cat $tmp_path"/"${tmp_name[$length]}"/"${tmp_name[$length]}".cfg" 2>&1)
	if [ "$(echo $?)" != "0" ]
	then
		./ivm_unmount_nfs.sh "${nfs_ip}|${nfs_path}|${tmp_path}" > /dev/null 2>&1
		echo "The template ${tmp_name[$length]} is not found." >&2
		exit 1
	fi
	if [ "$(echo $?)" == "0" ]
	then
		tmp_id[$length]=$(echo "$tmp_info" | awk -F"=" '{if($1=="id") print $2}')
		img_files=$(echo "$tmp_info" | awk -F"=" '{if($1=="files") print $2}')
		i=0
		echo $img_files | awk -F"," '{for(i=1;i<=NF;i++) print $i}' | while read file
		do
			tmp_file=$(echo $file | awk -F"|" '{print $1}' | awk -F"/" '{print $NF}')
			tmp_file=$tmp_path"/"$tmp_nm"/"$tmp_file
			file_type=$(echo $file | awk -F"|" '{print $2}')
			result=$(ls $tmp_file 2>&1)
			if [ $? -ne 0 ]
			then
				./ivm_unmount_nfs.sh "${nfs_ip}|${nfs_path}|${tmp_path}" > /dev/null 2>&1
				echo "$result" >&2
				exit 1
			fi
			if [ $i -eq 0 ]
			then
				tmp_files[$length]=$tmp_file"|"$file_type
			else
				tmp_files[$length]=${tmp_files[$length]}","$tmp_file"|"$file_type
			fi
			i=$(expr $i + 1)
		done
		file_num[$length]=$(echo "${tmp_files[$length]}" | awk -F"," '{print NF}')
		tmp_type[$length]=$(echo "$tmp_info" | awk -F"=" '{if($1=="type") print $2}')
		tmp_desc[$length]=$(echo "$tmp_info" | awk -F"=" '{if($1=="desc") print $2}')
		if [ "${tmp_id[$length]}" != "" ]&&[ "${tmp_files[$length]}" != "" ]&&[ "${tmp_type[$length]}" != "" ]&&[ "${file_num[$length]}" != "0" ]
		then
			length=$(expr $length + 1)
		fi
	fi
fi



aix_getinfo() {
	i=0
	echo  "[\c"
	if [ "$length" != "0" ]
	then
		while [ $i -lt $length ]
		do
			echo  "{\c"
			echo  "\"tmp_name\":\"${tmp_name[$i]}\", \c"
			echo  "\"tmp_id\":\"${tmp_id[$i]}\", \c"
			echo  "\"tmp_type\":\"${tmp_type[$i]}\", \c"
			echo  "\"tmp_desc\":\"${tmp_desc[$i]}\", \c"
			echo  "\"tmp_file\":[\c"
			j=0
			echo ${tmp_files[$i]} | awk -F"," '{for(i=1;i<=NF;i++) print $i}' | while read file
			do
				file_info=$(echo $file | awk -F"|" '{print $1}')
				file_type=$(echo $file | awk -F"|" '{print $2}')
				file_number=$(expr $j + 1)
				file_name=${file_info##*/}
				file_size=$(ls -l $file_info | awk '{print $5/1024}')
				echo "{\c"
				echo "\"file_num\":\"$file_number\", \c"
				echo "\"file_name\":\"$file_name\", \c"
				echo "\"file_size\":\"$file_size\", \c"
				echo "\"file_type\":\"$file_type\"\c"
				echo "}\c"
				j=$(expr $j + 1)
				if [ "$j" != "${file_num[$i]}" ]
				then
					echo  ", \c"
				fi
			done
			
			echo  "]}\c"
			i=$(expr $i + 1)
			if [ "$i" != "$length" ]
			then
				echo  ", \c"
			fi
		done
	fi
	echo  "]"
}



linux_getinfo() {
	i=0
	echo -e "[\c"
	if [ "$length" != "0" ]
	then
		while [ $i -lt $length ]
		do
			echo -e "{\c"
			echo -e "\"tmp_name\":\"${tmp_name[$i]}\", \c"
			echo -e "\"tmp_id\":\"${tmp_id[$i]}\", \c"
			echo -e "\"tmp_type\":\"${tmp_type[$i]}\", \c"
			echo -e "\"tmp_desc\":\"${tmp_desc[$i]}\", \c"
			echo -e "\"tmp_file\":[\c"
			j=0
			
			echo ${tmp_files[$i]} | awk -F"," '{for(i=1;i<=NF;i++) print $i}' | while read file
			do
				file_info=$(echo $file | awk -F"|" '{print $1}')
				file_type=$(echo $file | awk -F"|" '{print $2}')
				file_number=$(expr $j + 1)
				file_name=${file_info##*/}
				file_size=$(ls -l $file_info | awk '{print $5/1024}')
				echo -e "{\c"
				echo -e "\"file_num\":\"$file_number\", \c"
				echo -e "\"file_name\":\"$file_name\", \c"
				echo -e "\"file_size\":\"$file_size\", \c"
				echo -e "\"file_type\":\"$file_type\"\c"
				echo -e "}\c"
				j=$(expr $j + 1)
				if [ "$j" != "${file_num[$i]}" ]
				then
					echo -e ", \c"
				fi
			done
			
			echo -e "]}\c"
			i=$(expr $i + 1)
			if [ "$i" != "$length" ]
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
	*) echo "Unknown operating system" >&2 ;;
esac

#####################################################################################
#####                                                                           #####
#####                          		unmount nfs	                                #####
#####                                                                           #####
#####################################################################################
result=$(./ivm_unmount_nfs.sh "${nfs_ip}|${nfs_path}|${tmp_path}" 2>&1)
