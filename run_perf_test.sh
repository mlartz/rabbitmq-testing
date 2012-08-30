#!/bin/bash

for MSG_SIZE in 1 100 1000 100000 1000000 10000000; do
    for MSG_COUNT in 1000 10000 100000; do 
        echo $MSG_COUNT $MSG_SIZE
        bundle exec ruby publish.rb -n $MSG_COUNT -b $MSG_SIZE
    done
done
