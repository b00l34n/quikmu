#!/bin/sh

##
# quikmu is a helper script for using Qemu to create, edit and delet Qemu-VMs
#

scriptHeader() {
  cat << HeadPart
##########################
#                        #
#    quikmu generated    #
#    Qemu Start Skript   #
#                        #
##########################
#!/bin/sh

export QEMU_AUDIO_DRV=none
clear
echo "starting $1..."

qemu-system-x86_64 -boot menu=on \\
HeadPart
}
scriptCore(){
cat << Core
-enable-kvm \\
  -accel accel=kvm,thread=multi \\
  -smp cores=$1,threads=1,sockets=1 \\
Core
}
scriptMemory() {
  echo "-m $1 \\"
}
scriptCD() {
  echo "-cdrom \"$1\" \\"
}
scriptDrive() {
  qemu-img create -f qcow2 disk.qcow2 "$1" 1> /dev/null 2> /dev/null
  echo "-hda ./disk.qcow2 \\"
}
scriptNetwrok() {
  NET=$(echo $1 | grep -o "[1-9]\{1,3\}\.[1-9]\{1,3\}\.[1-9]\{1,3\}")
  cat << Network
-nic none \\
-netdev user,id=eth0,net=$NET.0/24,dhcpstart=$NET.67,ipv6=off,restrict=off,dns=$NET.53,smb=/home/monday/.qemu/smb_share,smbserver=$NET.7 \\
-device e1000,netdev=eth0 \\
Network
}
scriptTail() {
  echo "-daemonize && echo \"SUCCES!\""
}
#==============================================================================
printUsage() {
  cat << usage
quikmu [OPTION] NAME

  quikmu is a helper script to create, edit and delte qemu VM's in the 
  directory the script lives in

OPTION:

    -c <NAME>    Create a new VM
                  -k|--Cores <INT>        give number of Cores(at least one)
                  -M|--Memmory <INT>[M|G] give size of RAM
                                          M for Megabyte and G for Gigabyte
                  -i|--CDRom <PATH>       give path of Instalation-Images        
                  -D|--Drive <INT>[M|G]   make the Instalation Drive             
                  -n|--Network            give the Networkaddress for the
                                          Machien and its periferils
                
    --create    The same as -c

    -d <NAME>   Delete a VM
    
    --delete    The same as -d

    -e <NAME>   Edit an existing VM

    --edit      The same as -e

usage
}

vmExist() {
  if [ -e $1 ]; then
    return 0
  else 
    throwErorr "5" # VM not exist
  fi
}

throwErorr()  {
  case $1 in
    1) ERORR="ERORR: To few arguments" ;;
    2) ERORR="ERORR: Bad number of arguments" ;;
    3) ERORR="ERORR: Unknown/Wrong arguments" ;;
    4) ERORR="ERORR: To many arguments" ;;
    5) ERORR="ERORR: VM dose not exist" ;;
  esac
  echo $ERORR >&2
  case $1 in 
    [1-4])printUsage >&2 ;;
  esac
  exit $1
}
#==============================================================================
delete() {
  if [ $# -eq 1 ] && vmExist "$1"; then 
    echo "WARNING! Are you sure about that? [Y/n]"
    read CHOIS
    if [ $CHOIS = "y" -o $CHOIS = "Y" ]; then
      rm -fr "./$1" && echo "$1 is no more..."
    fi
  else
    throwErorr "4" # to many Args
  fi
}

create() {
  if [ $# -lt 6 ]; then
    throwErorr "1"
  fi
  NEWDIR=$1  
  mkdir "$NEWDIR"
  scriptHeader $1 > _start
  shift
  while [ $# -ne 0 ]; do
    case $1 in
      "-k"|"--Cores") scriptCore $2 >> _start ;;
      "-M"|"--Memmory") scriptMemory $2 >> _start ;;
      "-i"|"--CDRom") scriptCD $2 >> _start ;;
      "-D"|"--Drive") scriptDrive $2 >> _start ;;
      "-n"|"--Network") scriptNetwrok $2 >> _start ;;
      *) throwErorr "3" ;;
    esac
    shift; shift
  done
  scriptTail >> _start
  chmod 744 _start
  mv _start "$NEWDIR"
  mv disk.qcow2 "$NEWDIR"
}

edit() {
  if [ $# -ge 2 ] && vmExist "$1"; then 
    echo "== DB editing $1 =="
  else
    throwErorr "1" # to few Args
  fi
}
#==============================================================================

case $# in 
  0) throwErorr "1" ;; # to few Args
  1) if [ $1 = "-h" ]; then
       printUsage; exit 0
     else
       throwErorr "2" # Bad number Args
     fi
  ;;
  *) 
    case $1 in
      "-c"|"--create") shift; create $@ ;;
      "-d"|"--delete") shift; delete $@ ;;
      "-e"|"--edit") shift; edit $@ ;;
      *)  throwErorr "3" ;; # Wrong Args
    esac
  ;;
esac