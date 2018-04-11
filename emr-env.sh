#!/bin/bash 
if [ -e "base.txt" ] 
then 
    BASE_IMAGE=$(cat base.txt | awk -v line=1 'NR==line')
    CUDA_ROOT=$(cat base.txt | awk -v line=2 'NR==line')
else
    # default is cuda-9.0
    BASE_IMAGE="9.0-cudnn7-devel-ubuntu16.04"
    CUDA_ROOT="/usr/local/cuda-9.0"
fi

IMAGE=jhsong/emrenv:${BASE_IMAGE} 
IMAGE_FILE=emrenv-${BASE_IMAGE}.tar
CONTAINER=emrenv-${BASE_IMAGE}-$(basename ${HOME})
DOCKER_HOME=/root
HOST_SCRATCH_DIR=${HOME}/.scratch
DOCKER_SCRATCH_DIR=${DOCKER_HOME}/.scratch
VOLUMNE_MAPS="-v ${HOST_SCRATCH_DIR}:${DOCKER_SCRATCH_DIR} -v `pwd`/share:${DOCKER_HOME}/share -v ${HOME}:${DOCKER_HOME}/home"
PORT_MAPS=-P 

THEANORC="[global]\n
device=cuda0\n
floatX=float32\n
optimizer_including=cudnn\n
\n
[lib]\n
cnmem = 1\n
\n
[nvcc]\n
flags=-D_FORCE_INLINES\n
fastmath = True\n
\n
[blas]\n
ldflags = -lopenblas\n
\n
[cuda]\n
root = ${CUDA_ROOT}\n
\n
[dnn]\n
library_path = ${CUDA_ROOT}/lib64\n
include_path = ${CUDA_ROOT}/include"

echo -e $THEANORC > .theanorc

# ------------- main ------------
shell(){ 
    docker exec -it ${CONTAINER} su root 
}

check(){ 
    echo "test theano ..."
    docker exec -it ${CONTAINER} python -c "import theano"
    echo "test tensorflow ..."
    docker exec -it ${CONTAINER} python -c "import tensorflow"
    echo "ok"
}

push(){ 
    docker push ${IMAGE} 
}

pull(){ 
    docker pull ${IMAGE} 
}

save(){ 
    echo "save image to file ${IMAGE_FILE} ..."
    docker save ${IMAGE} > ${IMAGE_FILE} 
}

ps(){ 
    docker ps | grep --color ${CONTAINER} 
}

build(){ 
    echo "*****************************************"
    echo "base image: ${BASE_IMAGE}"
    echo "*****************************************"
    docker build . -t ${IMAGE} --build-arg BASE_IMAGE=${BASE_IMAGE} 
}

jupyter_address(){
    if [ -e "host.txt" ]
    then # for server setting 
        hostipaddr=$(cat host.txt)
    else 
        hostipaddr="localhost"
    fi 
    jupaddr=$(cat share/logs/jupyterlab.log | grep -o http://0.0.0.0:8888/.*$ | head -1 | sed "s/0.0.0.0/${hostipaddr}/g")
    jupport=$(docker ps | grep --color ${CONTAINER} | grep -o --color "[0-9]\+->8888\+" | sed "s/->8888//g")
    conn_jupyter=$(echo ${jupaddr} | sed "s/8888/${jupport}/g")
    conn_jupyterlab=$(echo ${conn_jupyter} | sed "s/?/lab?/g")
    echo "Your Jupyter addressis is ${conn_jupyter}"
    echo "Your JupyterLab address is ${conn_jupyterlab}"
    echo "enjoy!"
}

start(){
    mkdir -p ${HOST_SCRATCH_DIR}
    echo "start ${IMAGE}"
    if [ "$1" = "yes" ]
    then 
        echo "run with nvidia/cuda ..."
        docker run --runtime=nvidia --rm -d --name ${CONTAINER} ${PORT_MAPS} ${VOLUMNE_MAPS} ${IMAGE} 
    else 
        docker run --rm -d --name ${CONTAINER} ${PORT_MAPS} ${VOLUMNE_MAPS} ${IMAGE} 
    fi 
    if [ $? -eq 0 ]
    then 
        sleep 5
        jupyter_address
    else 
        echo "docker run failed"
    fi 
}

stop(){
	docker stop ${CONTAINER}
}

source $(dirname $0)/argparse.bash || exit 1
argparse "$@" <<EOF || exit 1
parser.description = 'This is a Docker environment for EMR project.'
parser.add_argument('exec_mode', type=str, 
    help='shell|check|push|pull|pload|save|build|jup|start|update'
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
    save)
        save
        ;; 
    load)
        load 
        ;; 
    shell)
        shell 
        ;; 
    jup) 
        jupyter_address 
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
        build 
        if [ $? -eq 0 ] 
        then 
            echo "wait stoping ..."
            stop 
            wait 
            start $NVIDIA
        else 
            echo "build failed"
        fi 
        ;; 
    push)
        push  
        ;;
    check)
        check  
        ;;
    pull)
        pull  
        ;;
    *)
        echo 
esac


