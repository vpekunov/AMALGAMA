#!/bin/bash

echo 'Content-type: text/html'>$2
echo 'X-Powered-By: NNET_SIMPLIFY'>>$2
echo ''>>$2
./nnets_simplify $1 Y 4 1000 >>$2
echo $? >_.err
