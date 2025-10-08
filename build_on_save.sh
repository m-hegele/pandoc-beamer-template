#!/bin/bash

if [ "$1" = "" ]; then
	echo Pass path to presentation as first argument
	exit 1
fi

find . -name '*.md' | entr sh -c "./build_on_save.sh $1"
