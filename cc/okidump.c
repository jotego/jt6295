#include <stdio.h>
#include <stdlib.h>

void dump(FILE *f);

int main(int argc, char *argv[]) {
    FILE *f;
    if( argc != 2 ) {
        printf("ERROR: expecting a file name as the one and only argument\n");
        return 1;
    }
    f=fopen(argv[1],"rb");
    if( !f ) {
        printf("Cannot open file %s", argv[1]);
        return 1;
    }
    dump(f);
    return 0;
}

void dump(FILE *f) {
    char *rom;
    size_t rdcnt;
    int k;

    rom = malloc( 4*64*1024 );
    rdcnt = fread( rom, 4*64*1024, 1, f );
    if( rdcnt < 8*128 ) {
        printf("Could not read the full header. Expecting 1024 bytes. Only %d bytes read\n", rdcnt);
        goto dump_end;
    }
    for( k=1; k<128; k++ ) {
        char fname[32];
        int start, end;
        FILE *fout;
        int aux=k<<3;
        start = ((((rom[k+0] & 3) << 8) | rom[k+1])<<8) << rom[k+2];
        end   = ((((rom[k+3] & 3) << 8) | rom[k+4])<<8) << rom[k+5];
        if( start > end ) {
            printf("Warning: reverse order for sample %d", k );
            continue;
        }
        if( start == end ) continue;
        sprintf(fname,"dump_%d.oki",k);
        fout = fopen(fname,"wb");
        if( !fout ) {
            printf("Cannot create file %s\n", fname );
            goto dump_end;
        }
        fwrite( rom+start, end-start, 1, fout );
        fclose(fout);
    }
    dump_end:
    free( rom );
}