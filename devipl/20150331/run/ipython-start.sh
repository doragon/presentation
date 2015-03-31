#!/bin/bash

export PORT=8080
export WORK_DIR=${HOME}/workspace/github/presentation/devipl/20150331/notebook
export LOG_DIR=${HOME}/workspace/github/presentation/devipl/20150331/log
export PYTHON_DIR=${HOME}/.pyenv/versions/2.7/bin/python2.7
export IPYTHON_DIR=${HOME}/.pyenv/versions/2.7/bin/ipython

nohup ${PYTHON_DIR} ${IPYTHON_DIR} notebook --no-browser --ip=0.0.0.0 --port=${PORT} --notebook-dir=${WORK_DIR} > ${LOG_DIR}/stdout.log 2> ${LOG_DIR}/error.log &
echo started pid $!

