#include "bit_stream.h"
#include "compression.h"
#include "config.h"
#include "context.h"
#include "htbl.h"

#if CFG_STATE_COMPRESSION == 1 && defined(MODEL_HAS_STATE_COMPRESSION)
#define COMPRESSION_ENABLED
#endif

htbl_t * compression_htbls;
char * compression_tbl_full_msg =
  "compression table too small (increase --compression-bits and rerun)";
uint16_t compression_compressed_char_size;

void * compression_get_compressed_comp
(char * v,
 heap_t heap) {
  return v;
}

void init_compression
() {
#if defined(COMPRESSION_ENABLED)
  int i;
  htbl_data_size_t size;
  htbl_type_t t;
  
  compression_htbls =
    mem_alloc(SYSTEM_HEAP, sizeof(htbl_t *) * MODEL_NO_COMPONENTS);
  for(i = 0; i < MODEL_NO_COMPONENTS; i ++) {
    size = model_component_size(i);
    if(size == 0) {
      t = HTBL_FULL_DYNAMIC;
    } else {
      t = HTBL_FULL_STATIC;
    }
    compression_htbls[i] =
      htbl_new(TRUE, CFG_STATE_COMPRESSION_BITS, 2, t, size, 0,
               HTBL_LINEAR_PROBING,
               model_component_compress_func(i),
               compression_get_compressed_comp);
  }
  compression_compressed_char_size = compression_char_size();
#endif
}

void finalise_compression
() {
#if defined(COMPRESSION_ENABLED)
  int i;

  for(i = 0; i < MODEL_NO_COMPONENTS; i ++) {
    htbl_free(compression_htbls[i]);
  }
  free(compression_htbls);
#endif
}

void compression_output_statistics
(FILE * f) {
#if defined(COMPRESSION_ENABLED)
  int i;

  if(0 == context_proc_id()) {
    fprintf(f, "<compressionTemplates><list>");
    for(i = 0; i < MODEL_NO_COMPONENTS; i ++) {
      fprintf(f, "<item>%llu</item>", htbl_no_items(compression_htbls[i]));
    }
    fprintf(f, "</list></compressionTemplates>");
  }
#endif
}

void compression_compress
(mstate_t s,
 char * v,
 uint16_t * size) {
#if defined(COMPRESSION_ENABLED)
  int i;
  bit_stream_t bits;
  htbl_id_t id;
  hkey_t h;
  htbl_meta_data_t mdata;

  *size = compression_compressed_char_size;
  memset(v, 0, *size);
  bit_stream_init(bits, v);
  for(i = 0; i < MODEL_NO_COMPONENTS; i ++) {
    htbl_meta_data_init(mdata, s);
    if(HTBL_INSERT_FULL == htbl_insert(compression_htbls[i], &mdata)) {
      context_error(compression_tbl_full_msg);
    } else {
      bit_stream_set(bits, mdata.id, CFG_STATE_COMPRESSION_BITS);
    }
  }
  return;
#endif
  assert(0);
}

void * compression_uncompress
(char * v,
 heap_t heap) {
#if defined(COMPRESSION_ENABLED)
  bit_stream_t bits;
  htbl_id_t id;
  int i = 0;
  void * data[MODEL_NO_COMPONENTS];

  bit_stream_init(bits, v);
  for(i = 0; i < MODEL_NO_COMPONENTS; i ++) {
    bit_stream_get(bits, id, CFG_STATE_COMPRESSION_BITS);
    data[i] = htbl_get(compression_htbls[i], id, heap);
  }
  return mstate_reconstruct_from_components(data, heap);
#endif
  assert(0);
}

uint16_t compression_char_size
() {
#if defined(COMPRESSION_ENABLED)
  uint32_t bits = CFG_STATE_COMPRESSION_BITS * MODEL_NO_COMPONENTS;
  uint16_t result = bits / CHAR_BIT;

  if(bits % CHAR_BIT) {
    result ++;
  }
  return result;
#else
#if defined(MODEL_STATE_SIZE)
  return MODEL_STATE_SIZE;
#else
  return 0;
#endif  
#endif
  assert(0);
}
