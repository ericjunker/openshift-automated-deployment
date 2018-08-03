#!/bin/bash

#Required command line argument  ($1) is your GUID

# if [ $# -eq 0 ]; then
#     echo "No arguments provided"
#     exit 1
# fi
# echo $1

#set environment variables on bastion host and all nodes, in this case GUID
ansible localhost,all -m shell -a 'export GUID=`hostname | cut -d"." -f2`; echo "export GUID=$GUID" >> $HOME/.bashrc'

#ok, we have the GUID

#copy hosts file to new name for editing
cp /inventory/original_hosts /inventory/hosts
#swap the actual GUID for '$GUID'
sed -i "s/\$GUID/${GUID}/g" /inventory/hosts

#Run the setup!
ansible-playbook -f 20 -i inventory/hosts /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml