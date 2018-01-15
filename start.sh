#!/bin/bash

USER_ID=${LOCAL_USER_ID:-9001}

echo "Starting with UID : $USER_ID"
if [ "$USER_ID" != "9001" ]; then
    useradd -m -s /bin/bash -d /home/user -u $USER_ID -G sudo,video user
    echo "user ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/user

    # cp /home/feelpp/WELCOME /home/user
    cp -f /home/feelpp/.bash_aliases /home/user
    cp -f /home/feelpp/.bashrc /home/user

    # check for mounted directories in /home/user
    declare -a MountedDir
    declare -a MountedDirUid
    declare -a MountedDirGid

    for dir in $(find /home/user -type d); do
        status=$(mount -f | grep $dir); 
        if [ "x$status" != "x" ]; then 
            dir_uid=$(ls -gn $dir | awk  '{print $3}')
            dir_gid=$(ls -gn $dir | awk  '{print $3}')
            MountedDir=("${MountedDir[@]}" "$dir")
            MountedDirUid=("${MountedDirUid[@]}" "$dir_uid")      
            MountedDirGid=("${MountedDirGid[@]}" "$dir_gid")
            echo "!!! $dir(user=${dir_uid}, group=${dir_gid}  is mounted !!!" 
        fi
    done

    # Note this may be problematic if there are directories mounted in /home/user
    chown -R user.user /home/user

    # restore permissions on mounted directories if any
    for i in "${MountedDir[@]}"; do
        echo "Restore permissions on $MountedDir[$i]: $MountedUidDir[$i]:$MountedGidDir[$i]"
        echo "chown $MountedUidDir[$i]:$MountedGidDir[$i] $MountedDir[$i]/*"
        echo "chown $MountedUidDir[$i]:$MountedGidDir[$i] $MountedDir[$i]/."
    done

    export HOME=/home/user

    exec /usr/sbin/gosu user bash
else
    export HOME=/home/user
    exec /usr/sbin/gosu feelpp bash
fi    
