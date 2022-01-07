#!/bin/bash

MAXSZ=16384; export MAXSZ

gprolog --query-goal "change_directory('"$1"')" --query-goal "consult('"$2"')" --query-goal "asserta(global_id("$7"))" --query-goal "tell('"$3"')" --query-goal $4 --query-goal "told" --query-goal $6 --query-goal "end_of_file" >$5
