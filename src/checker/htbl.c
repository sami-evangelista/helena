#include "htbl.h"
#include "bit_stream.h"
#include "state.h"
#include "event.h"


/**
 * TODO
 *
 * - htbl_free is excessively slow (due to cache effects ?) for
 *   dynamic state vectors.  hence we do not free individual vectors
 *   for now
 */

#define NO_ATTRS 12

#define BUCKET_EMPTY  0
#define BUCKET_WRITE  1
#define BUCKET_READY  2
#define BUCKET_UPDATE 3

#define HTBL_INSERT_MAX_TRIALS 10000

const uint16_t ATTR_WIDTH[] = {
  1, /* cyan */
  1, /* blue */
  1, /* pink */
  1,  /* red */
  CHAR_BIT * sizeof(htbl_id_t), /* pred */
  CHAR_BIT * sizeof(mevent_id_t), /* evt*/
  32, /* index */
  32, /* lowlink */
  1, /* live */
  1, /* safe */
  1, /* unsafe successor */
  1  /* to revisit */
};

const bool_t ATTR_OF_WORKER[] = {
  1, /*  cyan  */
  0,
  1, /*  pink  */
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0,
  0
};

typedef uint8_t bucket_status_t;

struct struct_htbl_t {
  htbl_type_t type;
  uint8_t hash_bits;
  uint64_t hash_size;
  uint64_t hash_size_m;
  uint32_t item_size;
  uint16_t data_size;
  uint32_t attrs_available;
  uint32_t attrs_char_size;
  uint32_t attr_pos[NO_ATTRS];
  uint16_t no_workers;
  heap_t heap;
  char * data;
  htbl_compress_func_t compress_func;
  htbl_uncompress_func_t uncompress_func;
};
typedef struct struct_htbl_t struct_htbl_t;

const struct timespec SLEEP_TIME = { 0, 10 };

#define HTBL_POS_ITEM(tbl, id)                  \
  (tbl->data + id * tbl->item_size)
#define HTBL_POS_STATUS(tbl, pos)               \
  (pos)
#define HTBL_POS_ATTRS(tbl, pos)                \
  (HTBL_POS_STATUS(tbl, pos) + 1)
#define HTBL_POS_HASH(tbl, pos)                         \
  (HTBL_POS_ATTRS(tbl, pos) + tbl->attrs_char_size)
#define HTBL_POS_STATIC_VECTOR(tbl, pos)                \
  (HTBL_POS_ATTRS(tbl, pos) + tbl->attrs_char_size)
#define HTBL_POS_DYNAMIC_VECTOR_SIZE(tbl, pos)          \
  (HTBL_POS_ATTRS(tbl, pos) + tbl->attrs_char_size)
#define HTBL_POS_DYNAMIC_VECTOR(tbl, pos)                               \
  (HTBL_POS_DYNAMIC_VECTOR_SIZE(tbl, pos) + sizeof(htbl_data_size_t))
#define HTBL_GET_STATUS(tbl, pos, s)            \
  { s = HTBL_POS_STATUS(tbl, pos); }
#define HTBL_GET_STATIC_VECTOR(tbl, pos, v)     \
  { v = HTBL_POS_STATIC_VECTOR(tbl, pos); }
#define HTBL_GET_HASH(tbl, pos, h)                              \
  { memcpy(h, HTBL_POS_HASH(tbl, pos), sizeof(hkey_t)); }
#define HTBL_GET_DYNAMIC_VECTOR(tbl, pos, b)                            \
  { memcpy(b, HTBL_POS_DYNAMIC_VECTOR(tbl, pos), sizeof(char *)); }
#define HTBL_GET_DYNAMIC_VECTOR_SIZE(tbl, pos, s)       \
  { memcpy(s, HTBL_POS_DYNAMIC_VECTOR_SIZE(tbl, pos),   \
           sizeof(htbl_data_size_t)); }
#define HTBL_SET_HASH(tbl, pos, h)                              \
  { memcpy(HTBL_POS_HASH(tbl, pos), h, sizeof(hkey_t)); }
#define HTBL_SET_DYNAMIC_VECTOR(tbl, pos, b)                            \
  { memcpy(HTBL_POS_DYNAMIC_VECTOR(tbl, pos), b, sizeof(char *)); }
#define HTBL_SET_DYNAMIC_VECTOR_SIZE(tbl, pos, s)       \
  { memcpy(HTBL_POS_DYNAMIC_VECTOR_SIZE(tbl, pos), s,   \
           sizeof(htbl_data_size_t)); } 
#define HTBL_INIT_BITS_ON_ATTRS(tbl, pos, bits)         \
  { bit_stream_init(bits, HTBL_POS_ATTRS(tbl, pos)); }
#define HTBL_GET_VECTOR(tbl, pos, v) {          \
    if(HTBL_FULL_STATIC == tbl->type) {         \
      HTBL_GET_STATIC_VECTOR(tbl, pos, v);      \
    } else {                                    \
      HTBL_GET_DYNAMIC_VECTOR(tbl, pos, &v);    \
    }                                           \
  }

htbl_t htbl_new
(bool_t use_system_heap,
 uint64_t hash_bits,
 uint16_t no_workers,
 htbl_type_t type,
 uint16_t data_size,
 uint32_t attrs_available,
 htbl_compress_func_t compress_func,
 htbl_uncompress_func_t uncompress_func) {
  const heap_t heap = SYSTEM_HEAP;
  uint64_t i;
  htbl_t result;
  uint32_t pos = 0, width;
  
  result = mem_alloc(SYSTEM_HEAP, sizeof(struct_htbl_t));
  result->type = type;
  result->compress_func = compress_func;
  result->uncompress_func = uncompress_func;
  result->attrs_available = attrs_available;
  for(i = 0; i < NO_ATTRS; i ++) {
    if(htbl_has_attr(result, i)) {
      width = ATTR_WIDTH[i];
      if(ATTR_OF_WORKER[i]) {
        width *= no_workers;
      }
      result->attr_pos[i] = pos;
      pos += width;
    }
  }
  result->attrs_char_size = pos / 8;
  if(pos & 7) {
    result->attrs_char_size ++;
  }
  result->no_workers = no_workers;
  result->hash_bits = hash_bits;
  result->hash_size = 1 << hash_bits;
  result->hash_size_m = result->hash_size - 1;
  result->data_size = data_size;
  result->heap = NULL;
  result->item_size = 1 + result->attrs_char_size;
  switch(type) {
  case HTBL_HASH_COMPACTION:
    result->item_size += sizeof(hkey_t);
    break;
  case HTBL_FULL_STATIC:
    result->item_size += data_size;
    break;
  case HTBL_FULL_DYNAMIC:
    result->item_size += sizeof(htbl_data_size_t) + sizeof(char *);
    result->heap = use_system_heap ? SYSTEM_HEAP : local_heap_new();
    break;
  }
  result->data = mem_alloc0(heap, result->hash_size * result->item_size);
  return result;
}

void htbl_free
(htbl_t tbl) {
  htbl_id_t id = 0;
  char * b, * status, * pos;

  /*  disabled for now (see TODO)  */
  if(0 && HTBL_FULL_DYNAMIC == tbl->type) {
    for(id = 0, pos = HTBL_POS_ITEM(tbl, id);
        id < tbl->hash_size;
        id ++, pos += tbl->item_size) {
      HTBL_GET_STATUS(tbl, pos, status);
      if(*status != BUCKET_EMPTY) {
        HTBL_GET_DYNAMIC_VECTOR(tbl, pos, &b);
        mem_free(tbl->heap, b);
      }
    }
  }
  if(tbl->heap) {
    heap_free(tbl->heap);
  }
  mem_free(SYSTEM_HEAP, tbl->data);
  mem_free(SYSTEM_HEAP, tbl);
}

bool_t htbl_contains
(htbl_t tbl,
 void * s,
 htbl_id_t * id,
 hkey_t * h) {
  assert(0); /* not implemented */
}

htbl_insert_code_t htbl_insert
(htbl_t tbl,
 void * s,
 htbl_id_t * id,
 hkey_t * h) {
  htbl_id_t i;
  uint32_t trials = HTBL_INSERT_MAX_TRIALS;
  bool_t found;
  uint16_t size;
  hkey_t h_other;
  char * sv, * sv_other, * pos, buffer[65536];
  
  /**
   * compress the data and compute its hash value
   */
  tbl->compress_func(s, buffer, &size);
  (*h) = string_hash(buffer, size);
  i = (*h) & tbl->hash_size_m;
  pos = HTBL_POS_ITEM(tbl, i);
  while(TRUE) {

    /**
     * we found a bucket where to insert the data => claim it
     */
    if(CAS(HTBL_POS_STATUS(tbl, pos), BUCKET_EMPTY, BUCKET_WRITE)) {

      /**
       * data insertion
       */
      switch(tbl->type) {
      case HTBL_HASH_COMPACTION:
        HTBL_SET_HASH(tbl, pos, h);
        break;
      case HTBL_FULL_DYNAMIC:
        sv = mem_alloc0(tbl->heap, size);
        memcpy(sv, buffer, size);
        HTBL_SET_DYNAMIC_VECTOR(tbl, pos, &sv);
        HTBL_SET_DYNAMIC_VECTOR_SIZE(tbl, pos, &size);
        break;
      case HTBL_FULL_STATIC:
        memcpy(HTBL_POS_STATIC_VECTOR(tbl, pos), buffer, size);
        break;
      default:
        assert(0);
      }
      (*(HTBL_POS_STATUS(tbl, pos))) = BUCKET_READY;
      (*id) = i;
      return HTBL_INSERT_OK;
    }

    /**
     * wait for the bucket to be readable
     */
    while(BUCKET_WRITE == (*(HTBL_POS_STATUS(tbl, pos)))) {
      nanosleep(&SLEEP_TIME, NULL);
    }

    /**
     * the bucket is occupied => compare the data in the bucket to the
     * data to insert
     */
    if(HTBL_HASH_COMPACTION == tbl->type) {
      HTBL_GET_HASH(tbl, pos, &h_other);
      found = h_other == *h;
    } else {
      HTBL_GET_VECTOR(tbl, pos, sv_other);
      found = 0 == memcmp(sv_other, buffer, size);
    }
    if(found) {
      (*id) = i;
      return HTBL_INSERT_FOUND;
    }
    
    /**
     * give up if HTBL_INSERT_MAX_TRIALS buckets have been checked
     */
    if(!(-- trials)) {
      return HTBL_INSERT_FULL;
    }
    i = (i + 1) & tbl->hash_size_m;
    pos = i ? (pos + tbl->item_size) : HTBL_POS_ITEM(tbl, 0);
  }
}

void * htbl_get
(htbl_t tbl,
 htbl_id_t id,
 heap_t heap) {
  char * v, * pos;
  void * result;

  assert(HTBL_HASH_COMPACTION != tbl->type);
  pos = HTBL_POS_ITEM(tbl, id);
  HTBL_GET_VECTOR(tbl, pos, v);
  result = tbl->uncompress_func(v, heap);
  return result;
}

bool_t htbl_has_attr
(htbl_t tbl,
 attr_state_t attr) {
  return (tbl->attrs_available & ATTR_ID(attr)) ? TRUE : FALSE;
}

#define HTBL_GET_ATTR(shift) {                          \
    const uint32_t width = ATTR_WIDTH[attr];            \
    const uint32_t move = tbl->attr_pos[attr] + shift;  \
    uint64_t result;                                    \
    bit_stream_t bits;                                  \
    char * pos;                                         \
                                                        \
    pos = HTBL_POS_ITEM(tbl, id);                       \
    HTBL_INIT_BITS_ON_ATTRS(tbl, pos, bits);            \
    bit_stream_move(bits, move);                        \
    bit_stream_get(bits, result, width);                \
    return result;                                      \
  }

uint64_t htbl_get_attr
(htbl_t tbl,
 htbl_id_t id,
 attr_state_t attr) {
  assert(htbl_has_attr(tbl, attr));
  HTBL_GET_ATTR(0);
}

uint64_t htbl_get_worker_attr
(htbl_t tbl,
 htbl_id_t id,
 attr_state_t attr,
 worker_id_t w) {
  assert(htbl_has_attr(tbl, attr));
  HTBL_GET_ATTR(w);
}

#define HTBL_SET_ATTR(shift) {					\
    const uint32_t width = ATTR_WIDTH[attr];			\
    const uint32_t move = tbl->attr_pos[attr] + shift;		\
    bit_stream_t bits;						\
    char * pos, * status;					\
								\
    pos = HTBL_POS_ITEM(tbl, id);				\
    HTBL_INIT_BITS_ON_ATTRS(tbl, pos, bits);			\
    bit_stream_move(bits, move);				\
    HTBL_GET_STATUS(tbl, pos, status);				\
    if(tbl->no_workers > 1) {					\
      while(!CAS(status, BUCKET_READY, BUCKET_UPDATE)) {	\
        nanosleep(&SLEEP_TIME, NULL);				\
      }								\
    }								\
    bit_stream_set(bits, val, width);				\
    *status = BUCKET_READY;					\
  }

void htbl_set_attr
(htbl_t tbl,
 htbl_id_t id,
 attr_state_t attr,
 uint64_t val) {
  assert(htbl_has_attr(tbl, attr));
  HTBL_SET_ATTR(0);
}

void htbl_set_worker_attr
(htbl_t tbl,
 htbl_id_t id,
 attr_state_t attr,
 worker_id_t w,
 uint64_t val) {
  assert(htbl_has_attr(tbl, attr));
  HTBL_SET_ATTR(w);
}

bool_t htbl_get_any_cyan
(htbl_t tbl,
 htbl_id_t id) {
  worker_id_t w;

  for(w = 0; w < tbl->no_workers; w ++) {
    if(htbl_get_worker_attr(tbl, id, ATTR_CYAN, w)) {
      return TRUE;
    }
  }
  return FALSE;
}

void htbl_fold
(htbl_t tbl,
 htbl_fold_func_t f,
 void * data) {
  char * v, * pos, * status;
  state_t s;
  htbl_id_t id;
  heap_t h = local_heap_new();

  for(id = 0, pos = HTBL_POS_ITEM(tbl, id);
      id < tbl->hash_size;
      id ++, pos += tbl->item_size) {
    HTBL_GET_STATUS(tbl, pos, status);
    if((*status) >= BUCKET_READY) {
      HTBL_GET_VECTOR(tbl, pos, v);
      s = tbl->uncompress_func(v, h);
      f(s, id, data);
      state_free(s);
      heap_reset(h);
    }
  }
  heap_free(h);
}
