CC=gcc
CFLAG_INCLUDE=-I. -Iinclude -Iprotobuf
CFLAGS=-Wall $(CFLAG_INCLUDE) -Wextra -std=gnu99 -ggdb
LDLIBS=-lprotobuf-c -lcrypto
SRC=src
VPATH= $(SRC) include protobuf

all: bittorent_protobuf

bittorent_protobuf:
	protoc-c --c_out=. protobuf/bittorent.proto

chord: hash.o chord_arg_parser.o protobuf/bittorent.pb-c.c chord.c

clean:
	rm -rf protobuf/*.pb-c.* *~ chord *.o example_hash

.PHONY : clean all
