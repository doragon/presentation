#!/bin/bash

pid=$(ps -ef | egrep "[${HOME}]/.pyenv/versions/2.7/bin/python2.7 ${HOME}/.pyenv/versions/2.7/bin/ipython notebook" | awk '{print $2}')
echo killing $pid...
kill $pid
