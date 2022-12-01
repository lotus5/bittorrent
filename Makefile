CC=gcc
CFLAGS=-Wall -Iincludes -Wextra -std=c99 -ggdb
VPATH=src

all: bittorrent

bittorrent: bittorrent.c 

hash.o: hash.c

clean:
	rm -rf bittorrent *.o


.PHONY : clean all
