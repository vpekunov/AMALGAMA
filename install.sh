#!/bin/bash

chmod -R +x *
cd ./Grammar
fpc -B -O3 -Mobjfpc -FcUTF-8 ./Grammar.lpr
cp ./libGrammar.so ../
cd ..
cd ./prolog_micro_brain.dir
g++ -o prolog_micro_brain tinyxml2.cpp elements.cpp prolog_micro_brain.cpp -std=c++11 -O4 -lm -lboost_system -lboost_filesystem -ldl
g++ -c tinyxml2.cpp elements.cpp prolog_micro_brain.cpp -std=c++11 -O4 -lm -lboost_system -lboost_filesystem -ldl -fPIC
cp ./prolog_micro_brain ../
cd ..
cd ./PrologIntrf
g++ -o main.o -c main.cpp -fPIC -O4 -std=c++11
g++ -shared -o libPrologIntrf.so main.o ../prolog_micro_brain.dir/*.o -lm -lboost_system -lboost_filesystem -ldl -Wl,--allow-multiple-definition
cp libPrologIntrf.so ../
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
unzip ./link-grammar-5.3.0.zip
sudo sh ./configure
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
