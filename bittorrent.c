#include <stdio.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <unistd.h>
#include <argp.h>

#include "hash.h"
//#include "parse_torrent.c"

struct client_arguments {
	FILE *file; 
};

error_t client_parser(int key, char *arg, struct argp_state *state) {
	struct client_arguments *args = state->input;
	error_t ret = 0;
	switch(key) {
	case 'f':
		
		args->file = fopen(arg, "r");
		break;
	default:
		ret = ARGP_ERR_UNKNOWN;
		break;
	}
	return ret;
}


struct client_arguments client_parseopt(int argc, char *argv[]) {
	struct argp_option options[] = {
		{ "file", 'f', "file", 0, "The file that the client reads data from for all hash requests", 0},
		{0}
	};

	struct argp argp_settings = { options, client_parser, 0, 0, 0, 0, 0 };

	struct client_arguments args;
	bzero(&args, sizeof(args));

	if (argp_parse(&argp_settings, argc, argv, 0, NULL, &args) != 0) {
		printf("Got error in parse\n");
	}

	if (args.file == NULL) {
		printf("need a bittorent file\n");
		exit(-1);
	}

	printf("file opened\n");
	return args;
}

int main(int argc, char *argv[]) {
	//parsing the file from command line
	struct client_arguments args = client_parseopt(argc, argv);
	
	//read in the file contents
	fseek(args.file, 0, SEEK_END); // seek to end of file
	int size = ftell(args.file); // get current file pointer
	fseek(args.file, 0, SEEK_SET);
	char* bitFile = malloc(size);
	fread(bitFile, 1, size, args.file);

	printf("size: %d\n\n", size);
	printf("%s\n", bitFile);

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