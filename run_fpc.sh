#!/bin/bash

fpc -B -O3 -Mobjfpc -FcUTF-8 $1.pas > $2
