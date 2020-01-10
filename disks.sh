#!/bin/bash

SIZE=20
NAME=data.img
FORMAT=raw

sudo qemu-img create -f $FORMAT $NAME ${SIZE}G
