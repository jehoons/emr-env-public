#!/bin/bash -eu
cmd="$1"
if [ "${cmd}" == "emr" ]; then
    export _pwd=`pwd`
    export SHELL=/bin/bash
    mkdir -p share/logs
    # jupyter lab --port=8888 --no-browser --ip=0.0.0.0 --allow-root \
    jupyter notebook --port=8888 --no-browser --ip=0.0.0.0 --allow-root \
        --notebook-dir=`pwd` >& share/logs/jupyterlab.log &

    tail -f share/logs/jupyterlab.log
else
    exec "$@"
fi
