#include <stdio.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>

#include "hash.h"
//#include "parse_torrent.c"

int main(int argc, char *argv[]) {
	//parse_torrent(argv[1]);

	int sock;
	if ((sock = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)) < 0) {
		exit(-1);
    }

	struct sockaddr_in trackerAddr;
    memset(&trackerAddr, 0, sizeof(trackerAddr));
    trackerAddr.sin_family = AF_INET;
	
    //int rtnVal = inet_pton(AF_INET, tracker's_ip, &trackerAddr.sin_addr.s_addr);
    /*if (rtnVal <= 0) {
        printf("fail to get address.\n");
        exit(1);
    }*/
    //trackerAddr.sin_port = htons(tracker's port);
}