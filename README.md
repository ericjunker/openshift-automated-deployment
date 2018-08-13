# openshift-automated-deployment

This script automatically deploys Openshift in an OpenTLC lab environment.


Prerequisites:

* An existing Openshift cluster setup using OpenTLC
* A bastion host you can SSH to

Run `./setup.sh` as root on your bastion host to start deployment. It may be advisable to send the output to a file as well as `stdout` by running `./setup.sh | tee <logfile>` You should probably run it in `tmux`, since the script will take a long time to run.

