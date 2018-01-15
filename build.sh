#! /bin/bash -x

usage(){
   echo ""
   echo "Description:"
   echo "   Builds Ensight Docker image"
   echo ""
   echo "Usage:"
   echo "   build.sh [ <option> ] ... ]"
   echo ""
   echo "Options:"
   echo ""
   echo "-t <tag>                 tag to use (default is branch-release)"
   echo ""
   echo "-f <dockerfile>          name of docker file (default is \"Dockerfile\")"
   echo ""
   echo "-i <dockerimage>         name of docker image (default is hifimagnet)"
   echo ""
   echo "-r <release>             target OS (NB shall be consistent with docker image and Salome platform. Default is yakkety)"
   echo ""
   echo "-v <version>             compiler version (defaut is 4.0 for clang)"
   echo ""
   echo "-d                       Activate debug (means only start Docker)"
   echo ""
   echo "-h                       Prints this help information"
   echo ""
   exit 1
}

DEBUG=0
TESTSUITE=0

#########################################################
## parse parameters
##########################################################
while getopts "hb:t:i:f:dr:v:" option ; do
   case $option in
       h ) usage ;;
       b ) BRANCH=$OPTARG ;;
       t ) DOCKERTAG=$OPTARG ;;
       i ) DOCKERIMAGE=$OPTARG ;;
       f ) DOCKERFILE=$OPTARG ;;
       d ) DEBUG=1 ;;
       r ) RELEASE=$OPTARG ;;
       v ) VERSION=$OPTARG ;;
       ? ) usage ;;
   esac
done
# shift to have the good number of other args
shift $((OPTIND - 1))

# Optionally set VERSION and others if none is defined. 
: ${BRANCH:="develop"}
: ${RELEASE:="xenial"}
: ${VERSION:="10.2.2a"}
: ${DOCKERFILE="Dockerfile"}
: ${DOCKERTAG=${BRANCH}-${RELEASE}}
: ${DOCKERIMAGE="hifimagnet"}

URL="git@github.com:feelpp/hifimagnet.git"

NJOBS_MAX=$(getconf _NPROCESSORS_ONLN)
NJOBS=$(($NJOBS<$NJOBS_MAX?$NJOBS:$NJOBS_MAX))

# echo "!! Be sure to get latest feelpp/feelpp-toolboxes !!"
# docker pull feelpp/feelpp-toolboxes:develop
# #check feelpp/feelpp-toolboxes:develop osname
# osname=$(docker run -it --rm feelpp/feelpp-toolboxes:develop lsb_release -a)
# compiler=$(docker run -it --rm feelpp/feelpp-toolboxes:develop clang --version)

echo "Building ${DOCKERIMAGE}:${DOCKERTAG} : HiFiMagnet branch=$BRANCH"

# Append values with version
DOCKERIMAGE=$DOCKERIMAGE
DOCKERFILE=$DOCKERFILE

# Should verify if Dockerfile exist and if DockerImage already exist or not
if [ ! -f ${DOCKERFILE} ]; then
    echo "$DOCKERFILE does not exist"
    echo "you should create $DOCKERFILE before running this script"
    exit 1 
fi

mkdir -p tmp
cd tmp

# Get Hifimagnet
git clone --branch $BRANCH ${URL} hifimagnet
VERSION=$(git ls-remote --tags ${URL} | awk '{print $2}' | grep -v '{}' | awk -F"/" '{print $3}' | sort -n -t. -k1,1 -k2,2 -k3,3 | tail -n 1 | tr -d v )
if [ "$BRANCH" = "develop" ] ; then
       OLDVERSION="${VERSION%.*}.$((${VERSION##*.}+1))"
       COMMITID=$(git log --format="%h" -n 1)
       VERSION=$(echo $OLDVERSION"+git"$COMMITID)
fi
    
tar --exclude-vcs -cvf ../hifimagnet.tar hifimagnet > /dev/null || {
    echo "failed to create ../hifimagnet.tar"
    exit 1
}

cd ..
rm -rf tmp

# check for Graphics card
if [ -f /usr/bin/lshw ]; then
    GRAPHICS=$(sudo lshw -c video | grep configuration | awk  '{print $2}' | perl -pe 's|driver=||')
    echo "GRAPHICS=$GRAPHICS"
else
    echo "To determine Graphics card install lshw"
fi

echo "Building Ensight ${VERSION} for $DOCKERFILE:$DOCKERTAG"

docker build  \
       --build-arg DEBUG=${DEBUG} \
       --build-arg GRAPHICS=$GRAPHICS \
   --no-cache \
   -q \
   -t $DOCKERIMAGE:$DOCKERTAG -f ./$DOCKERFILE . > docker-build.log 2>&1
isOK=$?

if [ "$isOK" != "0" ]; then
    echo "docker build failed (see docker-build.log)"
    for image in $(docker images --filter "dangling=true"  --format "{{.ID}}" ); do
        for container in $(docker ps -a --filter "ancestor=${image}"  --format "{{.ID}}" ); do
            echo "Remove container ${container}"
            docker rm ${container}
        done;
        echo "Remove image ${image}"
        docker rmi ${image}
    done
    #tail -30 docker-build.log
    exit 1
fi

# Clean up
rm -f hifimagnet.tar
rm lncmi.list
#rm docker-build.log
