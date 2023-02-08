#!/bin/bash

chmod -R +x *
cd ./Grammar
fpc -B -O3 -Mobjfpc -FcUTF-8 ./Grammar.lpr
cp ./libGrammar.so ../
cd ..
cd ./xpathInduct.dir
fpc -B -O3 -Mobjfpc -FcUTF-8 -fPIC ./xpathInduct.lpr
cp ./libxpathInduct.so ../
cd ..
cd ./Params
fpc -B -O3 -Mobjfpc -FcUTF-8 ./lparams.pas
cp ./lparams ../
cd ..
export CPPFLAGS="$PWD/link-grammar-5.3.0"
cd ./link-grammar-5.3.0
sudo ./configure
sudo make
sudo make install
sudo ldconfig
cd ..
cp /usr/local/lib/liblink-grammar.so.5.3.0 ./liblink-grammar.so
cd ./NeuroNet.dir
g++ -o NeuroNet ./NeuroNet.cpp -D__LINUX__ -O3 -fopenmp -fpermissive -std=c++0x
cp ./NeuroNet ../
cd ..
cd ./Predicates
g++ -o main.o -c ./main.cpp -fPIC -O3
g++ -shared -o libPredicates.so main.o
cp ./libPredicates.so ../
cd ..
rm -f ./induct.log
