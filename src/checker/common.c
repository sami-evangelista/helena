#include "common.h"
#include "report.h"

void init_common
() {
  unsigned int i = 0;
  glob_error_msg = NULL;
  crc32_tab[i++] = 0x00000000;
  crc32_tab[i++] = 0x77073096;
  crc32_tab[i++] = 0xee0e612c;
  crc32_tab[i++] = 0x990951ba;
  crc32_tab[i++] = 0x076dc419;
  crc32_tab[i++] = 0x706af48f;
  crc32_tab[i++] = 0xe963a535;
  crc32_tab[i++] = 0x9e6495a3;
  crc32_tab[i++] = 0x0edb8832;
  crc32_tab[i++] = 0x79dcb8a4;
  crc32_tab[i++] = 0xe0d5e91e;
  crc32_tab[i++] = 0x97d2d988;
  crc32_tab[i++] = 0x09b64c2b;
  crc32_tab[i++] = 0x7eb17cbd;
  crc32_tab[i++] = 0xe7b82d07;
  crc32_tab[i++] = 0x90bf1d91;
  crc32_tab[i++] = 0x1db71064;
  crc32_tab[i++] = 0x6ab020f2;
  crc32_tab[i++] = 0xf3b97148;
  crc32_tab[i++] = 0x84be41de;
  crc32_tab[i++] = 0x1adad47d;
  crc32_tab[i++] = 0x6ddde4eb;
  crc32_tab[i++] = 0xf4d4b551;
  crc32_tab[i++] = 0x83d385c7;
  crc32_tab[i++] = 0x136c9856;
  crc32_tab[i++] = 0x646ba8c0;
  crc32_tab[i++] = 0xfd62f97a;
  crc32_tab[i++] = 0x8a65c9ec;
  crc32_tab[i++] = 0x14015c4f;
  crc32_tab[i++] = 0x63066cd9;
  crc32_tab[i++] = 0xfa0f3d63;
  crc32_tab[i++] = 0x8d080df5;
  crc32_tab[i++] = 0x3b6e20c8;
  crc32_tab[i++] = 0x4c69105e;
  crc32_tab[i++] = 0xd56041e4;
  crc32_tab[i++] = 0xa2677172;
  crc32_tab[i++] = 0x3c03e4d1;
  crc32_tab[i++] = 0x4b04d447;
  crc32_tab[i++] = 0xd20d85fd;
  crc32_tab[i++] = 0xa50ab56b;
  crc32_tab[i++] = 0x35b5a8fa;
  crc32_tab[i++] = 0x42b2986c;
  crc32_tab[i++] = 0xdbbbc9d6;
  crc32_tab[i++] = 0xacbcf940;
  crc32_tab[i++] = 0x32d86ce3;
  crc32_tab[i++] = 0x45df5c75;
  crc32_tab[i++] = 0xdcd60dcf;
  crc32_tab[i++] = 0xabd13d59;
  crc32_tab[i++] = 0x26d930ac;
  crc32_tab[i++] = 0x51de003a;
  crc32_tab[i++] = 0xc8d75180;
  crc32_tab[i++] = 0xbfd06116;
  crc32_tab[i++] = 0x21b4f4b5;
  crc32_tab[i++] = 0x56b3c423;
  crc32_tab[i++] = 0xcfba9599;
  crc32_tab[i++] = 0xb8bda50f;
  crc32_tab[i++] = 0x2802b89e;
  crc32_tab[i++] = 0x5f058808;
  crc32_tab[i++] = 0xc60cd9b2;
  crc32_tab[i++] = 0xb10be924;
  crc32_tab[i++] = 0x2f6f7c87;
  crc32_tab[i++] = 0x58684c11;
  crc32_tab[i++] = 0xc1611dab;
  crc32_tab[i++] = 0xb6662d3d;
  crc32_tab[i++] = 0x76dc4190;
  crc32_tab[i++] = 0x01db7106;
  crc32_tab[i++] = 0x98d220bc;
  crc32_tab[i++] = 0xefd5102a;
  crc32_tab[i++] = 0x71b18589;
  crc32_tab[i++] = 0x06b6b51f;
  crc32_tab[i++] = 0x9fbfe4a5;
  crc32_tab[i++] = 0xe8b8d433;
  crc32_tab[i++] = 0x7807c9a2;
  crc32_tab[i++] = 0x0f00f934;
  crc32_tab[i++] = 0x9609a88e;
  crc32_tab[i++] = 0xe10e9818;
  crc32_tab[i++] = 0x7f6a0dbb;
  crc32_tab[i++] = 0x086d3d2d;
  crc32_tab[i++] = 0x91646c97;
  crc32_tab[i++] = 0xe6635c01;
  crc32_tab[i++] = 0x6b6b51f4;
  crc32_tab[i++] = 0x1c6c6162;
  crc32_tab[i++] = 0x856530d8;
  crc32_tab[i++] = 0xf262004e;
  crc32_tab[i++] = 0x6c0695ed;
  crc32_tab[i++] = 0x1b01a57b;
  crc32_tab[i++] = 0x8208f4c1;
  crc32_tab[i++] = 0xf50fc457;
  crc32_tab[i++] = 0x65b0d9c6;
  crc32_tab[i++] = 0x12b7e950;
  crc32_tab[i++] = 0x8bbeb8ea;
  crc32_tab[i++] = 0xfcb9887c;
  crc32_tab[i++] = 0x62dd1ddf;
  crc32_tab[i++] = 0x15da2d49;
  crc32_tab[i++] = 0x8cd37cf3;
  crc32_tab[i++] = 0xfbd44c65;
  crc32_tab[i++] = 0x4db26158;
  crc32_tab[i++] = 0x3ab551ce;
  crc32_tab[i++] = 0xa3bc0074;
  crc32_tab[i++] = 0xd4bb30e2;
  crc32_tab[i++] = 0x4adfa541;
  crc32_tab[i++] = 0x3dd895d7;
  crc32_tab[i++] = 0xa4d1c46d;
  crc32_tab[i++] = 0xd3d6f4fb;
  crc32_tab[i++] = 0x4369e96a;
  crc32_tab[i++] = 0x346ed9fc;
  crc32_tab[i++] = 0xad678846;
  crc32_tab[i++] = 0xda60b8d0;
  crc32_tab[i++] = 0x44042d73;
  crc32_tab[i++] = 0x33031de5;
  crc32_tab[i++] = 0xaa0a4c5f;
  crc32_tab[i++] = 0xdd0d7cc9;
  crc32_tab[i++] = 0x5005713c;
  crc32_tab[i++] = 0x270241aa;
  crc32_tab[i++] = 0xbe0b1010;
  crc32_tab[i++] = 0xc90c2086;
  crc32_tab[i++] = 0x5768b525;
  crc32_tab[i++] = 0x206f85b3;
  crc32_tab[i++] = 0xb966d409;
  crc32_tab[i++] = 0xce61e49f;
  crc32_tab[i++] = 0x5edef90e;
  crc32_tab[i++] = 0x29d9c998;
  crc32_tab[i++] = 0xb0d09822;
  crc32_tab[i++] = 0xc7d7a8b4;
  crc32_tab[i++] = 0x59b33d17;
  crc32_tab[i++] = 0x2eb40d81;
  crc32_tab[i++] = 0xb7bd5c3b;
  crc32_tab[i++] = 0xc0ba6cad;
  crc32_tab[i++] = 0xedb88320;
  crc32_tab[i++] = 0x9abfb3b6;
  crc32_tab[i++] = 0x03b6e20c;
  crc32_tab[i++] = 0x74b1d29a;
  crc32_tab[i++] = 0xead54739;
  crc32_tab[i++] = 0x9dd277af;
  crc32_tab[i++] = 0x04db2615;
  crc32_tab[i++] = 0x73dc1683;
  crc32_tab[i++] = 0xe3630b12;
  crc32_tab[i++] = 0x94643b84;
  crc32_tab[i++] = 0x0d6d6a3e;
  crc32_tab[i++] = 0x7a6a5aa8;
  crc32_tab[i++] = 0xe40ecf0b;
  crc32_tab[i++] = 0x9309ff9d;
  crc32_tab[i++] = 0x0a00ae27;
  crc32_tab[i++] = 0x7d079eb1;
  crc32_tab[i++] = 0xf00f9344;
  crc32_tab[i++] = 0x8708a3d2;
  crc32_tab[i++] = 0x1e01f268;
  crc32_tab[i++] = 0x6906c2fe;
  crc32_tab[i++] = 0xf762575d;
  crc32_tab[i++] = 0x806567cb;
  crc32_tab[i++] = 0x196c3671;
  crc32_tab[i++] = 0x6e6b06e7;
  crc32_tab[i++] = 0xfed41b76;
  crc32_tab[i++] = 0x89d32be0;
  crc32_tab[i++] = 0x10da7a5a;
  crc32_tab[i++] = 0x67dd4acc;
  crc32_tab[i++] = 0xf9b9df6f;
  crc32_tab[i++] = 0x8ebeeff9;
  crc32_tab[i++] = 0x17b7be43;
  crc32_tab[i++] = 0x60b08ed5;
  crc32_tab[i++] = 0xd6d6a3e8;
  crc32_tab[i++] = 0xa1d1937e;
  crc32_tab[i++] = 0x38d8c2c4;
  crc32_tab[i++] = 0x4fdff252;
  crc32_tab[i++] = 0xd1bb67f1;
  crc32_tab[i++] = 0xa6bc5767;
  crc32_tab[i++] = 0x3fb506dd;
  crc32_tab[i++] = 0x48b2364b;
  crc32_tab[i++] = 0xd80d2bda;
  crc32_tab[i++] = 0xaf0a1b4c;
  crc32_tab[i++] = 0x36034af6;
  crc32_tab[i++] = 0x41047a60;
  crc32_tab[i++] = 0xdf60efc3;
  crc32_tab[i++] = 0xa867df55;
  crc32_tab[i++] = 0x316e8eef;
  crc32_tab[i++] = 0x4669be79;
  crc32_tab[i++] = 0xcb61b38c;
  crc32_tab[i++] = 0xbc66831a;
  crc32_tab[i++] = 0x256fd2a0;
  crc32_tab[i++] = 0x5268e236;
  crc32_tab[i++] = 0xcc0c7795;
  crc32_tab[i++] = 0xbb0b4703;
  crc32_tab[i++] = 0x220216b9;
  crc32_tab[i++] = 0x5505262f;
  crc32_tab[i++] = 0xc5ba3bbe;
  crc32_tab[i++] = 0xb2bd0b28;
  crc32_tab[i++] = 0x2bb45a92;
  crc32_tab[i++] = 0x5cb36a04;
  crc32_tab[i++] = 0xc2d7ffa7;
  crc32_tab[i++] = 0xb5d0cf31;
  crc32_tab[i++] = 0x2cd99e8b;
  crc32_tab[i++] = 0x5bdeae1d;
  crc32_tab[i++] = 0x9b64c2b0;
  crc32_tab[i++] = 0xec63f226;
  crc32_tab[i++] = 0x756aa39c;
  crc32_tab[i++] = 0x026d930a;
  crc32_tab[i++] = 0x9c0906a9;
  crc32_tab[i++] = 0xeb0e363f;
  crc32_tab[i++] = 0x72076785;
  crc32_tab[i++] = 0x05005713;
  crc32_tab[i++] = 0x95bf4a82;
  crc32_tab[i++] = 0xe2b87a14;
  crc32_tab[i++] = 0x7bb12bae;
  crc32_tab[i++] = 0x0cb61b38;
  crc32_tab[i++] = 0x92d28e9b;
  crc32_tab[i++] = 0xe5d5be0d;
  crc32_tab[i++] = 0x7cdcefb7;
  crc32_tab[i++] = 0x0bdbdf21;
  crc32_tab[i++] = 0x86d3d2d4;
  crc32_tab[i++] = 0xf1d4e242;
  crc32_tab[i++] = 0x68ddb3f8;
  crc32_tab[i++] = 0x1fda836e;
  crc32_tab[i++] = 0x81be16cd;
  crc32_tab[i++] = 0xf6b9265b;
  crc32_tab[i++] = 0x6fb077e1;
  crc32_tab[i++] = 0x18b74777;
  crc32_tab[i++] = 0x88085ae6;
  crc32_tab[i++] = 0xff0f6a70;
  crc32_tab[i++] = 0x66063bca;
  crc32_tab[i++] = 0x11010b5c;
  crc32_tab[i++] = 0x8f659eff;
  crc32_tab[i++] = 0xf862ae69;
  crc32_tab[i++] = 0x616bffd3;
  crc32_tab[i++] = 0x166ccf45;
  crc32_tab[i++] = 0xa00ae278;
  crc32_tab[i++] = 0xd70dd2ee;
  crc32_tab[i++] = 0x4e048354;
  crc32_tab[i++] = 0x3903b3c2;
  crc32_tab[i++] = 0xa7672661;
  crc32_tab[i++] = 0xd06016f7;
  crc32_tab[i++] = 0x4969474d;
  crc32_tab[i++] = 0x3e6e77db;
  crc32_tab[i++] = 0xaed16a4a;
  crc32_tab[i++] = 0xd9d65adc;
  crc32_tab[i++] = 0x40df0b66;
  crc32_tab[i++] = 0x37d83bf0;
  crc32_tab[i++] = 0xa9bcae53;
  crc32_tab[i++] = 0xdebb9ec5;
  crc32_tab[i++] = 0x47b2cf7f;
  crc32_tab[i++] = 0x30b5ffe9;
  crc32_tab[i++] = 0xbdbdf21c;
  crc32_tab[i++] = 0xcabac28a;
  crc32_tab[i++] = 0x53b39330;
  crc32_tab[i++] = 0x24b4a3a6;
  crc32_tab[i++] = 0xbad03605;
  crc32_tab[i++] = 0xcdd70693;
  crc32_tab[i++] = 0x54de5729;
  crc32_tab[i++] = 0x23d967bf;
  crc32_tab[i++] = 0xb3667a2e;
  crc32_tab[i++] = 0xc4614ab8;
  crc32_tab[i++] = 0x5d681b02;
  crc32_tab[i++] = 0x2a6f2b94;
  crc32_tab[i++] = 0xb40bbe37;
  crc32_tab[i++] = 0xc30c8ea1;
  crc32_tab[i++] = 0x5a05df1b;
  crc32_tab[i++] = 0x2d02ef8d;
}
void free_common
() {
}

hash_key_t bit_vector_hash
(bit_vector_t v,
 unsigned int len) {
  unsigned int i;
  hash_key_t result = 0;
  for(i = 0; i < len; i++)
    result = crc32_tab[(result ^ v[i]) & 0xff] ^ (result >> 8);
  return result;
}

void lna_timer_init
(lna_timer_t * t) {
  t->value = 0;
}

void lna_timer_start
(lna_timer_t * t) {
  gettimeofday(&t->start, NULL);
}

void lna_timer_stop
(lna_timer_t * t) {
  struct timeval end;
  gettimeofday(&end, NULL);
  t->value += (uint64_t)
    (end.tv_sec * 1000000 + end.tv_usec) -
    (t->start.tv_sec * 1000000 + t->start.tv_usec);
}

uint64_t lna_timer_value
(lna_timer_t t) {
  return t.value;
}

uint64_t duration
(struct timeval t0,
 struct timeval t1) {
  uint64_t t0_time = t0.tv_sec * 1000000 + t0.tv_usec;
  uint64_t t1_time = t1.tv_sec * 1000000 + t1.tv_usec;
  return (uint64_t) t1_time - t0_time;
}

uint32_t random_seed
(worker_id_t w) {
  struct timeval t;
  
  gettimeofday(&t, NULL);
  return t.tv_sec * 1000000 + t.tv_usec + w;
}

#define RANDOM_MULT 1664525
#define RANDOM_CONS 1
#define RANDOM_MASK 0xFFFF
#define RANDOM_LOW(X) (X&RANDOM_MASK)
#define RANDOM_HIGH(X) ((X>>16)&RANDOM_MASK)

uint32_t random_int
(uint32_t * seed) {
  uint32_t lo, hi;
  uint32_t s = *seed;
  lo = RANDOM_LOW(RANDOM_LOW(s) * RANDOM_LOW(RANDOM_MULT) + RANDOM_CONS);
  hi = RANDOM_LOW(RANDOM_HIGH(s) * RANDOM_LOW(RANDOM_MULT))
    + RANDOM_LOW(RANDOM_HIGH(RANDOM_MULT) * RANDOM_LOW(s))
    + RANDOM_HIGH(RANDOM_LOW(s) * RANDOM_LOW(RANDOM_MULT) + RANDOM_CONS);
  *seed = (hi << 16 | lo);
  return *seed;
}

bool_t raise_error
(char * msg) {
#ifdef ACTION_SIMULATE
  if(!glob_error_msg) {
    glob_error_msg = mem_alloc(SYSTEM_HEAP, sizeof(char) * strlen(msg) + 1);
    strcpy(glob_error_msg, msg);
  }
  return TRUE;
#else
  return report_error(msg);
#endif
}

void flush_error
() {
#ifdef ACTION_SIMULATE
  if(glob_error_msg) {
    mem_free(SYSTEM_HEAP, glob_error_msg);
    glob_error_msg = NULL;
  }
#endif
}

void stop_search
(termination_state_t state) {
  report_stop_search(state);
}

FILE * open_graph_file
() {
  FILE * result = NULL;
#ifdef ACTION_BUILD_RG
  result = fopen(GRAPH_FILE, "w");
#endif
  return result;
}

uint64_t do_large_sum
(uint64_t * array,
 unsigned int nb) {
  uint64_t result = 0;
  unsigned int i = 0;
  for(i = 0; i < nb; i ++) {
    result += array[i];
  }
  return result;
}

uint32_t worker_global_id
(worker_id_t w) {
  return proc_id() * NO_WORKERS + w;
}

uint32_t proc_id
() {
  uint32_t result;
  
#ifdef DISTRIBUTED
  result = shmem_my_pe();
#else
  result = 0;
#endif
  return result;
}
