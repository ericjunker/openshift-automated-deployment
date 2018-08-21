# openshift-automated-deployment

This script automatically deploys Openshift in an OpenTLC lab environment. The cluster contains a CICD pipeline deploying the [Openshift Tasks](https://github.com/ericjunker/openshift-tasks) application, a full metrics and logging setup, and multitenancy support.


Prerequisites:

* An existing Openshift cluster setup using OpenTLC
* A bastion host you can SSH to

Run `./setup.sh` as root on your bastion host to start deployment. You should probably run it in `tmux`, since the script will take a long time to run.

Logs will automatically be written to `logfile` located in this folder.

