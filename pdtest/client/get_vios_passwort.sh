#!/bin/ksh

vios_ip=$1

get_password(){
	java -Djava.ext.dirs="/powerdirector/tomcat/webapps/ROOT/WEB-INF/lib:/usr/java7_64/jre/lib/ext" -cp /powerdirector/tomcat/webapps/ROOT/WEB-INF/classes com.teamsun.pc.web.common.utils.MutualTrustSupport "$vios_ip"
}

get_password "$vios_ip";
