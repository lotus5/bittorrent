CC=gcc
CFLAG_INCLUDE=-I. -Iinclude -Iprotobuf
CFLAGS=-Wall $(CFLAG_INCLUDE) -Wextra -std=gnu99 -ggdb
LDLIBS=-lprotobuf-c -lcrypto
SRC=src
VPATH= $(SRC) include protobuf

all: bittorent_protobuf

bittorent_protobuf:
	protoc-c --c_out=. protobuf/bittorent.proto

bittorent: protobuf/bittorent.pb-c.c bittorent.c

clean:
	rm -rf protobuf/*.pb-c.* *~ 

.PHONY : clean all
