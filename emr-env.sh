#!/bin/bash 
IMAGE=jhsong/emrenv
CONTAINER=emrenv_$(whoami)
DOCKER_HOME=/root
HOST_SCRATCH_DIR=${HOME}/.scratch
DOCKER_SCRATCH_DIR=${DOCKER_HOME}/.scratch
VOLUMNE_MAPS="-v ${HOST_SCRATCH_DIR}:${DOCKER_SCRATCH_DIR} -v `pwd`/share:${DOCKER_HOME}/share -v ${HOME}:${DOCKER_HOME}/home"
# PORT_MAPS=--publish=8888:8888
PORT_MAPS=-P 

# ------------- main ------------
shell(){
	docker exec -it ${container} su root
}

push(){
	docker push 
}

pull(){
	docker pull ${IMAGE}
}

ps(){
	docker ps | grep --color ${CONTAINER}
}

jup(){
    if [ -e "host.txt" ]
    then # for server setting 
        hostipaddr=$(cat host.txt)
    else 
        hostipaddr="localhost"
    fi 
    jupaddr=$(cat share/logs/jupyterlab.log | grep -o http://0.0.0.0:8888/.*$ | head -1 | sed "s/0.0.0.0/${hostipaddr}/g")
    jupport=$(docker ps | grep --color ${CONTAINER} | grep -o --color "[0-9]\+->8888\+" | sed "s/->8888//g")
    echo "Jupyter connection address is :"
    echo ${jupaddr} | sed "s/8888/${jupport}/g"
}

build(){
    docker build . -t ${IMAGE}
}

start(){
	mkdir -p ${HOST_SCRATCH_DIR}

    if [ "$1" = "yes" ]
    then 
        echo "run with nvidia/cuda ..."
        docker run --runtime=nvidia --rm -d --name ${CONTAINER} ${PORT_MAPS} ${VOLUMNE_MAPS} ${IMAGE} 
    else 
        docker run --rm -d --name ${CONTAINER} ${PORT_MAPS} ${VOLUMNE_MAPS} ${IMAGE} 
    fi 
}

stop(){
	docker stop ${CONTAINER}
}

source $(dirname $0)/argparse.bash || exit 1
argparse "$@" <<EOF || exit 1
parser.description = 'This is a Docker environment for EMR project.'
parser.add_argument('exec_mode', type=str, 
    help='build|start|stop|shell|update'
    )

parser.add_argument('-f', '--foreground', 
    action='store_true',
    help='run with foreground mode? [default %(default)s]', 
    default=False
    )

parser.add_argument('-n', '--nvidia', 
    action='store_true',
    help='run with foreground mode? [default %(default)s]', 
    default=False
    )

EOF

case "${EXEC_MODE}" in
    shell)
        shell 
        ;; 
    ps) 
        ps
        ;; 
    jup) 
        jup 
        ;; 

    build)
        build 
        ;;
    start)
        start $NVIDIA
        ;;
    stop)
        stop
        ;;
    update)
        echo "wait stoping ..."
        stop 
        wait 
        build 
        start $NVIDIA
        ;; 
    push)
        push  
        ;;
    pull)
        pull  
        ;;
    *)
        echo 
esac


