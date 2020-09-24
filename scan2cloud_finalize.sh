#!/bin/bash
###############################################################################
# Domain toevoegen

  

#################################
##########  variables ##############
#################################
DISABLE_RESET_BUTTON="no"
INSTALL_RECONNECT_SCRIPT="no"

# old samples
# TEMP_USER_ANSWER="no"
# SUBDOMAIN="customer-name"
# CHECK_INVALID_STRING=""
# CHECK_INVALID_CHAR_RESULT="NOT OK"
# DOMAINS_FILE="/etc/letsencrypt/configs/domains.conf"
# NGINX_FILE="/etc/nginx/includes/fusionpbx-domains"
# ADD_NEW_SUB_DOMAIN="no"
  


#################################
####  general functions #########
#################################

# sample 
ask_to_user_yes_or_no () 
{
		# default answer = no
		TEMP_USER_ANSWER="no"
		clear
		echo ""
		echo -e ${1}
		read -n 1 -p "(y/n)? :"
		if [ "${REPLY}" = "y" ]; then
			TEMP_USER_ANSWER="yes"
		else
			TEMP_USER_ANSWER="no"
			echo ""
		fi
}


# check invalid car script
check_invalid_char (){
if [[ "${1}" =~ [^0-9a-z\-]+ ]] ; then
	# echo "string $CHECK_INVALID_STRING has characters which are not alphanumeric"
	CHECK_INVALID_CHAR_RESULT="NOT OK"
else
	#echo "string $CHECK_INVALID_STRING has alphabets which are only alpha numeric"
	CHECK_INVALID_CHAR_RESULT="OK"
fi
}




#################################
########  ASK SCRIPTS ###########
#################################

ask_disable_reset_button ()
{
 read -n 1 -p "Do you want disable reset button ? (y/n) "
	if [ "$REPLY"   = "y" ]; then
	DISABLE_RESET_BUTTON="Yes"
	fi   
}			
ask_disable_reset_button	


ask_install_reconnect_script ()
{
 read -n 1 -p "Do you want install reconnect button ? (y/n) "
	if [ "$REPLY"   = "y" ]; then
	INSTALL_RECONNECT_SCRIPT="Yes"
	fi   
}				
ask_install_reconnect_script


test_script ()
{
		echo ""
		# read user data
		read -p "Enter subdomainname in (i.e ${SUBDOMAIN}): "
		# set user data to variables
		SUBDOMAIN=${REPLY}
		# check invalied chars
		check_invalid_char ${SUBDOMAIN}

		if [ "${CHECK_INVALID_CHAR_RESULT}" = "OK" ]; then
			echo "Your entered subdomainname is : ${SUBDOMAIN} "
			echo "Your FQDN is : ${SUBDOMAIN}.${DOMAIN_NAME} "
		else
			echo "Enter subdomainname NOT OK you can use only a-z, 0-9 and only - character"
			echo "Your INVALID entered subdomainname is : ${SUBDOMAIN} "
			echo "Please run this script again"
			echo ""	
			DISABLE_RESET_BUTTON="no"
		fi
}



#################################
####  INSTALL SCRIPTS ###########
#################################

disable_reset_button()
{
# remove reset command script
rm -rf /usr/bin/reset
}
if [ "${DISABLE_RESET_BUTTON}" = "Yes" ]; then
	disable_reset_button
fi


install_reconnect_script()
{

#make script file
touch /usr/bin/vpn_reconnect

#make file executable
chmod +x /usr/bin/vpn_reconnect

# write content in script file
cat > /usr/bin/vpn_reconnect <<EOF
#!/bin/sh

#wait for the openvpn to connect for the first time
sleep 120

while [ true ]; do

#check if openvpn is enabled, if not, go to next loop
vpn_enabled=$(uci get glconfig.openvpn.enable)
if [ “$vpn_enabled” != “1” ]; then
echo "VPN not enabled, check 20 seconds later"
sleep 20
continue
fi

vpn_pid=$(pidof openvpn)
tun0_ifname=$(ifconfig tun0)

if [ -z “$tun0_ifname” ] && [ -z “$vpn_pid” ]; then
echo “VPN enabled but not running, restarting it”
/etc/init.d/startvpn restart
else
echo "VPN is connected and connecting, check 20 seconds later"
fi

sleep 20

done

EOF



# add command to start script on boot (at the end of /etc/rc.local, before exit)
cat >> /etc/rc.local <<EOF
# reconnect script
/usr/bin/vpn_reconnect &

EOF


}
if [ "${INSTALL_RECONNECT_SCRIPT}" = "yes" ]; then
	install_reconnect_script
fi
 
