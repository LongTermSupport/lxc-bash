#!/usr/bin/env bash
set -euo pipefail
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
cd $DIR

if [[ "$(whoami)" != "root" ]]
then
    echo "Please run this as root"
    exit 1
fi

if [[ "$#" != "2" ]]
then
    echo "

Copy a container from another desktop machine to your desktop machine

NOTE:

* the machine we are copying from must have passwordless SUDO set up

Usage:

$0 [container name] [other host IP or configured hostname] (optional: other host SSH port)


"
    exit 1
fi

readonly otherHost="$1"

readonly containerName="$2"

readonly containerPath=/var/lib/lxc/$containerName


if [[ -d $containerPath ]]
then
    echo "

ERROR - this container already exists on your machine

You need to remove it before running this script

"
    exit 1
fi
echo "

Testing we can SSH as root to $otherHost

"

set +e
ssh -p $otherHost -oBatchMode=yes exit
canSshExitCode=$?
set -e
if (( $canSshExitCode != 0 ))
then
    ssh-copy-id $otherHost -p $otherHostPort
fi

echo "Making sure we have pv installed"
if [[ "" = "$(command -v pv)" ]]
then
    dnf -y install pv
fi

echo "
Making sure the container is not running on $otherHost
"
ssh -p $otherHostPort root@$otherHost -- "\lxc-stop -n $containerName || true"

echo "

Piping the container tar over SSH

please wait ...
"
ssh $otherHost -p $otherHostPort --  "sudo bash -xc 'tar --numeric-owner -czf - $containerPath'" | pv | sudo tar -C / --numeric-owner -xzf -

echo "

The files for $containerName are now copied,

however you may need to do further configuration to allow the container to run

"



