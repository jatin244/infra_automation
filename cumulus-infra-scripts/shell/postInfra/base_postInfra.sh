#!/bin/bash

. $WORKSPACE/infra-scripts/shell/common.sh
#!/bin/bash

. $WORKSPACE/infra-scripts/shell/common.sh
PLAYBOOK_DIR=${WORKSPACE}/infra-scripts/ansible/postInfra

check_var "PRIMARY_SSH_USER"
check_var "PRIMARY_SSH_KEY"
check_var "ANSIBLE_SSH_USER"
check_var "ANSIBLE_SSH_KEY"

PRIMARY_USER="${PRIMARY_SSH_USER}"
PRIMARY_KEY_FILE="${PRIMARY_SSH_KEY}"

ANSIBLE_USER="${ANSIBLE_SSH_USER}"
ANSIBLE_KEY_FILE="${ANSIBLE_SSH_KEY}"

check_var "PRIMARY_USER"
check_var "PRIMARY_KEY_FILE"
check_var "ANSIBLE_USER"
check_var "ANSIBLE_KEY_FILE"


# $1 -> Extra Vars, $2 -> playbook
playBookAsRoot() {
    echo "Extra Vars: $1"
    echo "Running Playbook: $2"
    echo "/usr/bin/ansible-playbook $ANSIBLE_VERBOSITY_LEVEL --private-key ${WORKSPACE}/ansible/keys/$PRIMARY_KEY_FILE --extra-vars "$1 ldap=$LDAP_ENV stack=$STACK_NAME" -u $PRIMARY_USER -b $PLAYBOOK_DIR/$2"
    #echo "/usr/bin/ansible-playbook -v --private-key ${WORKSPACE}/ansible/keys/$PRIMARY_KEY_FILE --extra-vars "$1 ldap=$LDAP_ENV stack=$STACK_NAME" -u $PRIMARY_USER -b $PLAYBOOK_DIR/$2"
    /usr/bin/ansible-playbook $ANSIBLE_VERBOSITY_LEVEL --private-key ${WORKSPACE}/ansible/keys/$PRIMARY_KEY_FILE --extra-vars "$1 ldap=$LDAP_ENV stack=$STACK_NAME" -u $PRIMARY_USER -b $PLAYBOOK_DIR/$2
    #/usr/bin/ansible-playbook -v --private-key ${WORKSPACE}/ansible/keys/$PRIMARY_KEY_FILE --extra-vars "$1 ldap=$LDAP_ENV stack=$STACK_NAME" -u $PRIMARY_USER -b $PLAYBOOK_DIR/$2
    errorCheckWithMessage $? "playBookAsRoot: playbook error, exiting..."
}

playBook() {
    echo "Extra Vars: $1"
    echo "Running Playbook: $2"
    /usr/bin/ansible-playbook $ANSIBLE_VERBOSITY_LEVEL -i ${WORKSPACE}/ansible/ec2.py --private-key ${WORKSPACE}/ansible/keys/$ANSIBLE_KEY_FILE --extra-vars "$1" -u $ANSIBLE_USER -b $PLAYBOOK_DIR/$2
    errorCheckWithMessage $? "playBook: playbook error, exiting..."
}

playBookWithTags() {
    echo "Extra Vars: $1"
    echo "tags: $2"
    echo "Running Playbook: $3"
    /usr/bin/ansible-playbook $ANSIBLE_VERBOSITY_LEVEL --private-key ${WORKSPACE}/ansible/keys/$PRIMARY_KEY_FILE --extra-vars "$1 ldap=$LDAP_ENV product=$LDAP_PRODUCT stack=$STACK_NAME" --tags "$2" -u $PRIMARY_USER -b $PLAYBOOK_DIR/$3
    errorCheckWithMessage $? "playBookWithTags: playbook error, exiting..."
}

playBookAsRootPublic() {
    echo "IP: $1"
    echo "Extra Vars: $2"
    echo "Running Playbook: $3"
    /usr/bin/ansible-playbook $ANSIBLE_VERBOSITY_LEVEL --private-key ${WORKSPACE}/ansible/keys/$PRIMARY_KEY_FILE "$1" --extra-vars "$2" -u $PRIMARY_USER -b $PLAYBOOK_DIR/$3
    errorCheckWithMessage $? "playBookAsRoot: playbook error, exiting..."
}

setHostnames() {
    echo "Setting Hostnames..."
    for ip in "${!IP_MAP[@]}"
    do
        echo "Setting hostname ${IP_MAP[$ip]} [$ip]... "
        playBookAsRoot "host_tag=$ip override=$ALLOW_POST_EC2_SETUP_INSTALL host_name=${IP_MAP[$ip]}" set-host.yml
    done
}

setHostnamesPublic() {
    echo "Setting Hostnames..."
    for ip in "${!IP_MAP[@]}"
    do
        echo "Setting hostname ${IP_MAP[$ip]} [$ip]... "
        playBookAsRootPublic "-i ${ip}," "host_tag=all override=$ALLOW_POST_EC2_SETUP_INSTALL host_name=${IP_MAP[$ip]}" set-host.yml
    done
}

installPackages() {
    echo "install packages..."
    playBookWithTags "host_tag=$HOST_DEPLOY_TAG ldap_server_ip=$LDAP_SERVER_IP override=$ALLOW_POST_EC2_SETUP_INSTALL yml_base=${PLAYBOOK_DIR} papertrail_token=${PAPERTRAIL_TOKEN} jumpcloud_key=${JUMPCLOUD_KEY} site24x7_key=${SITE24X7_KEY} ntp_server_ips=${NTP_SERVER_IPS} alien_vault_key=${ALIEN_VAULT_KEY}" "${EC2_INSTALL_TAGS}" install_apps.yml
}

installPackagesPublic() {
    echo "install packages..."
    echo "IP: $1"
    /usr/bin/ansible-playbook $ANSIBLE_VERBOSITY_LEVEL --private-key ${WORKSPACE}/ansible/keys/$PRIMARY_KEY_FILE "$1" --extra-vars "host_tag=all override=$ALLOW_POST_EC2_SETUP_INSTALL yml_base=${PLAYBOOK_DIR} papertrail_token=${PAPERTRAIL_TOKEN} jumpcloud_key=${JUMPCLOUD_KEY} site24x7_key=${SITE24X7_KEY} ntp_server_ips=${NTP_SERVER_IPS} alien_vault_key=${ALIEN_VAULT_KEY} ldap=$LDAP_ENV stack=$STACK_NAME" --tags "${EC2_INSTALL_TAGS}" -u $PRIMARY_USER -b $PLAYBOOK_DIR/install_apps.yml
    errorCheckWithMessage $? "playBookWithTags: playbook error, exiting..."
}

waitUntilInstancesReachable() {
    echo "*** wait until all instances are reachable..."
    for ip in "${!IP_MAP[@]}"
    do
        echo "connecting to $ip [${IP_MAP[$ip]}]"
        until ssh -o "StrictHostKeyChecking=no" -o "ConnectTimeout=4" -i  ${WORKSPACE}/ansible/keys/$PRIMARY_KEY_FILE $PRIMARY_USER@$ip ls >> /dev/null; do sleep 1; done
    done
    echo "*** all instances were reachable..."
}

setHostnamesAndInstallPackages() {
    echo "***** setHostnamesAndInstallPackages..."
    setHostnames
    # we do not need the next call now that set-host.yml waits for reconnection after reboot, but, it won't hurt
    waitUntilInstancesReachable
    installPackages
}

showIPMap() {
    for ip in "${!IP_MAP[@]}"
    do
        echo "$ip ${IP_MAP[$ip]}"
    done
}

setIpsFromTagWaitForReachable() {
    setIpsByTagDeploy $1
    waitUntilInstancesReachable
}

rebootHost() {
    echo "Rebooting hosts..."
    playBook "host_tag=$HOST_DEPLOY_TAG yml_base=${PLAYBOOK_DIR}" reboot-host.yml

}



