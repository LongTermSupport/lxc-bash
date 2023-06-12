#!/usr/bin/env bash
set -euo pipefail
readonly DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
cd $DIR

if [[ "$(whoami)" != "root" ]]
then
    echo "Please run this as root"
    exit 1
fi

if [[ $# -lt 2 ]]
then
    echo "

Copy a container from another desktop machine to your desktop machine

NOTE:

* the machine we are copying from must have passwordless SUDO set up

Usage:

$0 [other host IP or configured hostname] [container name] (optional: other host SSH port)


"
    exit 1
fi

otherHost="$1"
containerName="$2"
otherHostPort="${3:-22}"

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
ssh "$otherHost" -p "$otherHostPort" -o StrictHostKeyChecking=no exit
canSshExitCode=$?
set -e
if (( canSshExitCode != 0 ))
then
    echo "Failed to SSH as root to $otherHost"
    exit 1
fi

echo "Making sure we have pv installed"
if [[ "" = "$(command -v pv)" ]]
then
    dnf -y install pv
fi

echo "
Making sure the container is not running on $otherHost
"
ssh -p "$otherHostPort" "$otherHost" -- "sudo \lxc-stop -n $containerName || true"

echo "

Piping the container tar over SSH

please wait ...
"
ssh "$otherHost" -p "$otherHostPort" --  "sudo bash -xc 'tar --numeric-owner -czf - $containerPath'" | pv | sudo tar -C / --numeric-owner -xzf -

echo "

The files for $containerName are now copied,

however you may need to do further configuration to allow the container to run

"



