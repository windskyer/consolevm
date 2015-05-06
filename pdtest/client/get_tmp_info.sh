#!/usr/bin/ksh

tmp_path=$1
tmp_name=$2


if [ "$tmp_name" == "" ]
then
	ls -1 ${tmp_path}/*.cfg | while read line
	do
		tmp_info_list=${line}"|"$tmp_info_list
	done
	tmp_info_list=$(echo $tmp_info_list | awk '{print substr($0,0,length($0)-1)}') 
else
	tmp_info_list=$(ls -1 ${tmp_path}/${tmp_name}.cfg)
fi


tmp_length=0
if [ "$tmp_info_list" != "" ]
then
	echo $tmp_info_list | awk -F"|" '{for(i=1;i<=NF;i++) print $i}' | while read tmp
	do
		name=${tmp##*/}
		name=${name%.*}
		tmp_name[$tmp_length]=$name
		tmp_length=$(expr $tmp_length + 1)
	done
else
	echo "[]"
	exit 1
fi

i=0
length=0
if [ "$tmp_length" != "0" ]
then
	while [ $i -lt $tmp_length ]
	do
		check_tmp=$(ls ${tmp_path}/${tmp_name[$i]} 2> /dev/null)
		if [ "$check_tmp" == "" ]
		then
			i=$(expr $i + 1)
			continue
		else
			tmp_name[$length]=${tmp_name[$i]}
			length=$(expr $length + 1)
		fi
		i=$(expr $i + 1)
	done
fi

aix_getinfo() {
	i=0
	echo  "[\c"
	if [ "$length" != "0" ]
	then
		while [ $i -lt $length ]
		do
			tmp_info=$(cat ${tmp_path}/${tmp_name[$i]}.cfg)
			id=$(echo "$tmp_info" | grep "id=" | awk -F"=" '{print $2}')
			filename=$(echo "$tmp_info" | grep "filename=" | awk -F"=" '{print $2}')
			type=$(echo "$tmp_info" | grep "type=" | awk -F"=" '{print $2}')
			size=$(echo "$tmp_info" | grep "size=" | awk -F"=" '{print $2}')
			desc=$(echo "$tmp_info" | grep "desc=" | awk -F"=" '{print $2}')
			echo  "{\c"
			echo  "\"name\":\"${tmp_name[$i]}\", \c"
			echo  "\"id\":\"${id}\", \c"
			echo  "\"filename\":\"${filename}\", \c"
			echo  "\"type\":\"${type}\", \c"
			echo  "\"size\":\"${size}\", \c"
			echo  "\"desc\":\"${desc}\"\c"
			echo  "}\c"
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
			tmp_info=$(cat ${tmp_path}/${tmp_name[$i]}.cfg)
			id=$(echo "$tmp_info" | grep "id=" | awk -F"=" '{print $2}')
			filename=$(echo "$tmp_info" | grep "filename=" | awk -F"=" '{print $2}')
			type=$(echo "$tmp_info" | grep "type=" | awk -F"=" '{print $2}')
			size=$(echo "$tmp_info" | grep "size=" | awk -F"=" '{print $2}')
			desc=$(echo "$tmp_info" | grep "desc=" | awk -F"=" '{print $2}')
			echo -e "{\c"
			echo -e "\"name\":\"${tmp_name[$i]}\", \c"
			echo -e "\"id\":\"${id}\", \c"
			echo -e "\"filename\":\"${filename}\", \c"
			echo -e "\"type\":\"${type}\", \c"
			echo -e "\"size\":\"${size}\", \c"
			echo -e "\"desc\":\"${desc}\"\c"
			echo -e "}\c"
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