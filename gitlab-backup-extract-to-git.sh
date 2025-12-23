#!/bin/bash

if [ -z "$1" ]; then
    echo "gitlab-backup-extract-to-git <archive.tar.gz> <git folder>"
    exit 1
fi

echo "extracting from archive $1 into $2"

mkdir tmp
tar xvfz $1 -C tmp --strip-components=1

mkdir $2
git clone --mirror tmp/project.bundle $2/.git
cd $2
git init
git checkout

git status
ls

cd ..
rm -r tmp
