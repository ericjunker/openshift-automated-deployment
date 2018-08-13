#!/bin/bash

#Required command line argument  ($1) is your GUID

# if [ $# -eq 0 ]; then
#     echo "No arguments provided"
#     exit 1
# fi
# echo $1

#set environment variables on bastion host and all nodes, in this case GUID
ansible localhost,all -m shell -a 'export GUID=`hostname | cut -d"." -f2`; echo "export GUID=$GUID" >> $HOME/.bashrc'

echo "GUID is ${GUID}"

#copy hosts file to new name for editing
cp /inventory/original_hosts /inventory/hosts
#swap the actual GUID for '$GUID'
sed -i "s/\$GUID/${GUID}/g" /inventory/hosts

#Run the setup!
ansible-playbook -f 20 -i inventory/hosts /usr/share/ansible/openshift-ansible/playbooks/deploy_cluster.yml

#bring over .kube/config so that bastion can run oc commands as system:admin
ansible masters[0] -b -m fetch -a "src=/root/.kube/config dest=/root/.kube/config flat=yes"

#log in as system:admin
oc login -u system:admin

#add PVs to support node 1
ssh support1.$GUID.internal 'sudo bash -s'< scripts/create_pvs.sh

#now make PV files locally
export volsize="5Gi"
mkdir /root/pvs
for volume in pv{1..25} ; do
cat << EOF > /root/pvs/${volume}
{
  "apiVersion": "v1",
  "kind": "PersistentVolume",
  "metadata": {
    "name": "${volume}"
  },
  "spec": {
    "capacity": {
        "storage": "${volsize}"
    },
    "accessModes": [ "ReadWriteOnce" ],
    "nfs": {
        "path": "/srv/nfs/user-vols/${volume}",
        "server": "support1.${GUID}.internal"
    },
    "persistentVolumeReclaimPolicy": "Recycle"
  }
}
EOF
echo "Created def file for ${volume}";
done;

export GUID=`hostname|awk -F. '{print $2}'`

export volsize="10Gi"
for volume in pv{26..50} ; do
cat << EOF > /root/pvs/${volume}
{
  "apiVersion": "v1",
  "kind": "PersistentVolume",
  "metadata": {
    "name": "${volume}"
  },
  "spec": {
    "capacity": {
        "storage": "${volsize}"
    },
    "accessModes": [ "ReadWriteMany" ],
    "nfs": {
        "path": "/srv/nfs/user-vols/${volume}",
        "server": "support1.${GUID}.internal"
    },
    "persistentVolumeReclaimPolicy": "Retain"
  }
}
EOF
echo "Created def file for ${volume}";
done;

#add these PVs to Openshift
cat /root/pvs/* | oc create -f -

#fix NFS persistent volume recycling
ansible nodes -m shell -a "docker pull registry.access.redhat.com/openshift3/ose-recycler:latest"
ansible nodes -m shell -a "docker tag registry.access.redhat.com/openshift3/ose-recycler:latest registry.access.redhat.com/openshift3/ose-recycler:v3.9.30"

#NetworkPolicy time!

#We start in multitenant mode. Switch over like so: 
sed -i -e 's/openshift-ovs-multitenant/openshift-ovs-networkpolicy/g' /inventory/hosts
ansible masters -m shell -a "sed -i -e 's/openshift-ovs-multitenant/openshift-ovs-networkpolicy/g' /etc/origin/master/master-config.yaml"
ansible nodes -m shell -a "sed -i -e 's/openshift-ovs-multitenant/openshift-ovs-networkpolicy/g' /etc/origin/node/node-config.yaml"

# stop openshift
ansible masters -m shell  -a"systemctl stop atomic-openshift-master-api"
ansible masters -m shell -a"systemctl stop atomic-openshift-master-controllers"
ansible nodes -m shell -a"systemctl stop atomic-openshift-node"
ansible nodes -m shell -a"systemctl stop docker"

ansible nodes -m shell -a"systemctl restart openvswitch"

ansible nodes -m shell -a"systemctl start docker"
ansible masters -m shell -a"systemctl start atomic-openshift-master-api"
ansible masters -m shell -a"systemctl start atomic-openshift-master-controllers"

ansible masters -m shell -a"systemctl start atomic-openshift-node" # (make sure masters are up before nodes)

ansible nodes -m shell -a"systemctl start atomic-openshift-node"

#default deny all traffic
oc create templates/network-policy/default-deny.yaml -f -


#allow traffic between pods in the same namespace
oc create templates/network-policy/allow-same-namespace.yaml -f -

#allow traffic from default (for routers, etc)
oc create templates/network-policy/allow-default-namespace.yaml -f -

#test out app creation
oc new-project smoke-test
oc new-app nodejs-mongo-persistent