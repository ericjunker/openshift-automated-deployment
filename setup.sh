#!/bin/bash

#Required command line argument  ($1) is your GUID

if [ $# -eq 0 ]; then
    echo "No arguments provided"
    exit 1
fi

echo $1