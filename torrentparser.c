#include <string.h>
#include <stdlib.h>
#include "bencode.h"

// reads a binary file with the flag 'rb' on fopen
// return -1 if fail or the number of bytes read
int readbinaryfile(unsigned char * buffer, char * filename) {
  FILE * h;
	int i = 0;
	char tmp;

	h = fopen(filename, "rb");
	if (!h) {
		return -1;
	}

	while (!feof(h)) {
		fread(&tmp,1,1,h);
		buffer[i] = tmp;
		i++;
	}
	fclose(h);

	return i-1;
}

// read a torrent file. Support torrent with size less than 12k
// 0 = read or parser error
// 1 = file read ok
int parse_torrent(char *torrent_filename) {
  struct bencode *torrent;
	struct bencode *info;
	struct bencode_list *files;
	struct bencode_str *filename;
	int piece_length = 0;	
	unsigned char buf[12 * 1024];
	unsigned char *sha1_pieces;
	int sha1_pieces_len;
	int len = 0;
	int file_length = 0;

	// read a torrent file
	memset(buf, 0, sizeof(buf));
	len = readbinaryfile(buf, torrent_filename);
	// read fail
	if (len <= 0) {
		return 0;
	}

	// decode the bencode buffer
	torrent = (struct bencode*)ben_decode(buf,len);
	// decode fail
	if(!torrent) {
	  printf ("fail\n");
		return 0;
	}

	// pull out the .info part, which has stuff about the file we're downloading
	info = (struct bencode*)ben_dict_get_by_str((struct bencode*)torrent,"info");
	// decode fail
	if(!info) {
		// clean memory and return
		ben_free(torrent);
		return 0;
	}

	// get the piece length
	piece_length = ((struct bencode_int*)ben_dict_get_by_str(info,"piece length"))->ll;
	printf("parse_torrent piece_length=%d\n", piece_length);

	// get the concatened SHA1 from all pieces
	sha1_pieces = ((struct bencode_str*)ben_dict_get_by_str(info,"pieces"))->s;
	sha1_pieces_len = ((struct bencode_str*)ben_dict_get_by_str(info,"pieces"))->len;
	//hexdump(sha1_pieces, sha1_pieces_len, "sha1_pieces");

	// get the files dict from multiple file torrent. otherwise is a single file torrent
	files = (struct bencode_list*)ben_dict_get_by_str(info,"files");
	if (files) {
		printf( "parse_torrent multiple files\n");
	}
	else {
		filename = (struct bencode_str*)ben_dict_get_by_str(info,"name");
		file_length = ((struct bencode_int*)ben_dict_get_by_str(info,"length"))->ll;
		printf( "parse_torrent filename=%s\n", filename->s);
		printf( "parse_torrent file_length=%d\n", file_length);
		//		printf( "parse_torrent check_next_piece=%d\n", check_next_piece(filename->s, file_length, piece_length));
	}

	// clean memory and return
	ben_free(torrent);
	return 1;
}

int main() {
  parse_torrent("flatland.torrent");
}
