#!/bin/sh

#
# Overview
# ~~~~~~~~
#
# This script demonstrates a problem with P4 when integrating a
# file which has been moved and then re-added.
#
# Step 1:
#
# Create a directory "dev" in P4. Add a plain file "mdev.conf"
#
# Step 2:
#
# Integrate "dev" to "branched_dev". After this, branched_dev
# contains a copy of the file mdev.conf.
#
# Step 3:
#
# Rename mdev.conf.
# In a separate commit, add a new file, also called mdev.conf.
#
# After this, we have 2 files, mdev.conf and mdev_initial.conf.
#
# Step 4:
#
# Integrate again from dev to branched_dev. We would expect that
# branched_dev is then identical to dev. But instead, the file
# mdev.conf is missing from branched_dev.
#
# Usage
# ~~~~~
#
# Ensure p4 and p4d are in your path. Run the script.
#
# After it finishes, it will kill p4d.
#
# Version:
#
# p4d:
#   Server date: 2015/12/04 17:46:52 +0000 GMT
# p4:
#   Rev. P4/LINUX26X86_64/2015.1/1024208 (2015/03/16).

export P4PORT=:1666

create_client() {
        name=$1 &&
        depot=$2 &&
        root=$(pwd) &&
        printf "Client: $name\nRoot: $root\nView://depot/$depot/... //$name/...\n" | p4 client -i
        p4 clients
}

error() {
    printf "\033[1;31;40merror: $*\n\033[0m\n"
}

expect_file() {
    f=$1
    test -f "$f" || error "file $f not found"
}

expect_symlink() {
    link=$1
    test -h "$link" || error "symlink $link not found"
}

banner() {
    printf "\033[1;32;40m$*\033[0m\n"
}

p4cmd() {
    printf "\033[1;34;40mp4 -c $P4CLIENT $*\033[0m"
    p4 -c $P4CLIENT "$@"
}

start_p4d() {
    mkdir db &&
    (cd db &&
        p4d -q --pid-file=../p4.pid -d
    )
}

stop_p4d() {
    p4 admin stop &&
    wait $p4pid
}

rm -fr trashdir &&
mkdir trashdir &&
cd trashdir &&
start_p4d &&
p4pid=$(cat p4.pid) &&
echo "started p4d at pid $p4pid" &&
trap stop_p4d 0 &&

banner create initial state &&

mkdir cli &&
(cd cli &&
    create_client dev dev &&
    echo "mdev configuration" >mdev.conf &&
    export P4CLIENT=dev &&
    p4cmd add mdev.conf &&
    p4cmd submit -d 'initial' &&
    expect_file mdev.conf
) &&

banner integrate to a branch &&

mkdir branched &&
(cd branched &&
    create_client branched_dev branched_dev &&
    export P4CLIENT=branched_dev &&
    p4cmd integrate -3 //depot/dev/... ... &&
    p4cmd resolve -am ... &&
    p4cmd submit -d 'integrate from dev' &&
    expect_file mdev.conf
) &&

banner move mdev.conf &&

(cd cli &&
    export P4CLIENT=dev &&
    p4cmd edit mdev.conf &&
    p4cmd move mdev.conf mdev_initial.conf &&
    p4cmd submit -d 'move mdev.conf to mdev_initial.conf' &&
    echo "new mdev configuration" >mdev.conf &&
    p4cmd add mdev.conf &&
    p4cmd submit -d 'add symlink' &&
    expect_file mdev_initial.conf &&
    expect_file mdev.conf
) &&

banner now integrate this &&

(cd branched &&
    export P4CLIENT=branched_dev &&
    p4cmd integrate -3 //depot/dev/... ... &&
    p4cmd resolve -am ... &&
    p4cmd submit -d 'second integrate from dev' &&
    (p4 filelog //depot/dev/mdev.conf | tee mdev.conf.filelog) &&
    (p4 filelog //depot/branched_dev/mdev.conf | tee mdev.conf.branched.filelog) &&
    expect_file mdev_initial.conf &&
    expect_file mdev.conf
)
