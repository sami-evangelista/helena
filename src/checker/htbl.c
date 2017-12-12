#include "config.h"
#include "htbl.h"
#include "context.h"
#include "bit_stream.h"

/**
 * TODO
 *
 * - for the implementaton of bitstate hashing we assume that 1 char =
 *   8 bits, but we should use 1 char = CHAR_BIT instead
 *
 * - htbl_free is excessively slow (due to cache effects ?) for
 *   dynamic state vectors.  hence we do not free individual vectors
 *   for now
 */

#define NO_ATTRS 12

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

#define BUCKET_EMPTY  0
#define BUCKET_WRITE  1
#define BUCKET_READY  2
#define BUCKET_UPDATE 3

#define MAX_TRIALS 10000

typedef uint8_t bucket_status_t;

typedef hkey_t (* htbl_hash_func_t) (void *);
typedef void (* htbl_serialise_func_t) (void *, char *);
typedef void * (* htbl_unserialise_func_t) (char *, heap_t);
typedef uint16_t (* htbl_char_size_func_t) (void *);
typedef bool_t (* htbl_cmp_func_t) (void *, char *);

struct struct_htbl_t {
  htbl_type_t type;
  uint64_t hash_size;
  uint32_t item_size;
  uint16_t data_size;
  uint32_t attrs_available;
  uint32_t attrs_char_size;
  uint32_t attr_pos[NO_ATTRS];
  uint16_t no_workers;
  heap_t heap;
  char * data;
  htbl_hash_func_t hash_func;
  htbl_serialise_func_t serialise_func;
  htbl_unserialise_func_t unserialise_func;
  htbl_char_size_func_t char_size_func;
  htbl_cmp_func_t cmp_func;
};
typedef struct struct_htbl_t struct_htbl_t;

const struct timespec SLEEP_TIME = { 0, 10 };

#define HTBL_POS_STATE(tbl, id)                 \
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
  (HTBL_POS_DYNAMIC_VECTOR_SIZE(tbl, pos) + sizeof(data_size_t))
#define HTBL_GET_STATUS(tbl, pos, s)            \
  { s = HTBL_POS_STATUS(tbl, pos); }
#define HTBL_GET_STATIC_VECTOR(tbl, pos, v)     \
  { v = HTBL_POS_STATIC_VECTOR(tbl, pos); }
#define HTBL_GET_HASH(tbl, pos, h)                              \
  { memcpy(h, HTBL_POS_HASH(tbl, pos), sizeof(hkey_t)); }
#define HTBL_GET_DYNAMIC_VECTOR(tbl, pos, b)                            \
  { memcpy(b, HTBL_POS_DYNAMIC_VECTOR(tbl, pos), sizeof(char *)); }
#define HTBL_GET_DYNAMIC_VECTOR_SIZE(tbl, pos, s)                       \
  { memcpy(s, HTBL_POS_DYNAMIC_VECTOR_SIZE(tbl, pos), sizeof(data_size_t)); }
#define HTBL_SET_HASH(tbl, pos, h)                              \
  { memcpy(HTBL_POS_HASH(tbl, pos), h, sizeof(hkey_t)); }
#define HTBL_SET_DYNAMIC_VECTOR(tbl, pos, b)                            \
  { memcpy(HTBL_POS_DYNAMIC_VECTOR(tbl, pos), b, sizeof(char *)); }
#define HTBL_SET_DYNAMIC_VECTOR_SIZE(tbl, pos, s)                       \
  { memcpy(HTBL_POS_DYNAMIC_VECTOR_SIZE(tbl, pos), s, sizeof(data_size_t)); } 
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
 uint64_t hash_size,
 uint16_t no_workers,
 htbl_type_t type,
 uint16_t data_size,
 uint32_t attrs_available,
 htbl_hash_func_t hash_func,
 htbl_serialise_func_t serialise_func,
 htbl_unserialise_func_t unserialise_func,
 htbl_char_size_func_t char_size_func,
 htbl_cmp_func_t cmp_func) {
  const heap_t heap = SYSTEM_HEAP;
  uint64_t i;
  htbl_t result;
  uint32_t pos = 0, width, item_size;
  
  result = mem_alloc(SYSTEM_HEAP, sizeof(struct_htbl_t));
  result->type = type;
  result->hash_func = hash_func;
  result->serialise_func = serialise_func;
  result->unserialise_func = unserialise_func;
  result->char_size_func = char_size_func;
  result->cmp_func = cmp_func;
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
  if(pos % 8 != 0) {
    result->attrs_char_size ++;
  }
  result->no_workers = no_workers;
  result->hash_size = hash_size;
  result->data_size = data_size;
  if(type == HTBL_BITSTATE) {
    result->item_size = 1;
  } else {
    result->item_size = 1 + result->attrs_char_size;
    switch(type) {
    case HTBL_HASH_COMPACTION:
      result->item_size += sizeof(hkey_t);
      break;
    case HTBL_FULL_STATIC:
      result->item_size += data_size;
      break;
    case HTBL_FULL_DYNAMIC:
      result->item_size += sizeof(data_size_t) + sizeof(char *);
      result->heap = use_system_heap ? SYSTEM_HEAP : local_heap_new();
      break;
    }
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
    for(id = 0, pos = HTBL_POS_STATE(tbl, id);
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

void htbl_reset
(htbl_t tbl) {
  assert(HTBL_BITSTATE == tbl->type);
  memset(tbl->data, 0, tbl->hash_size * tbl->item_size);
}

bool_t htbl_contains
(htbl_t tbl,
 void * s,
 htbl_id_t * id,
 hkey_t * h) {
  assert(0); /* not implemented */
}

void htbl_insert_real
(htbl_t tbl,
 void ** s,
 bit_vector_t se,
 uint16_t se_size,
 bool_t * is_new,
 htbl_id_t * id,
 hkey_t * h,
 bool_t h_set) {
  htbl_id_t i;
  uint32_t trials = 0;
  bool_t found;
  uint8_t bit;
  hkey_t h_other;
  char * sv, * sv_other, * status, * pos;

  /**
   * compute the hash value if not available
   */
  if(!h_set) {
    assert((*s) != NULL);
    (*h) = tbl->hash_func((void *) (*s));
  }

  if(HTBL_BITSTATE == tbl->type) {
    (*id) = (*h) % (tbl->hash_size << 3);
    i = (*id) >> 3;
    bit = 1 << ((*id) & 7);
    if(tbl->data[i] & bit) {
      (*is_new) = FALSE;
    } else {
      (*is_new) = TRUE;
      tbl->data[i] |= bit;
    }
    return;
  }

  i = (*h) % tbl->hash_size;
  pos = HTBL_POS_STATE(tbl, i);
  while(TRUE) {

    /**
     * we found a bucket where to insert the state => claim it
     */
    HTBL_GET_STATUS(tbl, pos, status);
    if(CAS(status, BUCKET_EMPTY, BUCKET_WRITE)) {

      /**
       * state insertion
       */
      switch(tbl->type) {
      case HTBL_HASH_COMPACTION:
        HTBL_SET_HASH(tbl, pos, h);
        break;
      case HTBL_FULL_DYNAMIC:
        if(NULL == se) {
          se_size = tbl->char_size_func(*s);
        }
        sv = mem_alloc0(tbl->heap, se_size);
        if(NULL == se) {
          tbl->serialise_func(*s, sv);
        } else {
          memcpy(sv, se, se_size);
        }
        HTBL_SET_DYNAMIC_VECTOR(tbl, pos, &sv);
        HTBL_SET_DYNAMIC_VECTOR_SIZE(tbl, pos, &se_size);
        break;
      case HTBL_FULL_STATIC:
        HTBL_GET_STATIC_VECTOR(tbl, pos, sv);
        if(NULL == se) {
          tbl->serialise_func(*s, sv);
        } else {
          memcpy(sv, se, se_size);
        }        
        break;
      default:
        assert(0);
      }
      (*status) = BUCKET_READY;
      (*is_new) = TRUE;
      (*id) = i;
      return;
    }

    /**
     * wait for the bucket to be readable
     */
    while(BUCKET_WRITE == (*status)) {
      context_sleep(SLEEP_TIME);
    }

    /**
     * the bucket is occupied => compare the state in the bucket to
     * the state to insert
     */
    if(HTBL_HASH_COMPACTION == tbl->type) {
      HTBL_GET_HASH(tbl, pos, &h_other);
      found = h_other == *h;
    } else {
      HTBL_GET_VECTOR(tbl, pos, sv_other);
      if(NULL == se) {
        found = tbl->cmp_func(*s, sv_other);
      } else {
        found = 0 == memcmp(se, sv_other, se_size);
      }
    }
    if(found) {
      (*is_new) = FALSE;
      (*id) = i;
      return;
    }

    /**
     * give up if MAX_TRIALS buckets have been checked
     */
    if((++ trials) == MAX_TRIALS) {
      context_error("state table too small (increase --hash-size and rerun)");
      (*is_new) = FALSE;
      return;
    }
    i = (i + 1) % tbl->hash_size;
    pos += tbl->item_size;
  }
}

void htbl_insert
(htbl_t tbl,
 void * data,
 bool_t * is_new,
 htbl_id_t * id,
 hkey_t * h) {
  htbl_insert_real(tbl, &data, NULL, 0, is_new, id, h, FALSE);
}

void htbl_insert_hashed
(htbl_t tbl,
 void * data,
 hkey_t h,
 bool_t * is_new,
 htbl_id_t * id) {
  htbl_insert_real(tbl, &data, NULL, 0, is_new, id, &h, TRUE);
}

void htbl_insert_serialised
(htbl_t tbl,
 char * data,
 uint16_t data_size,
 hkey_t h,
 bool_t * is_new,
 htbl_id_t * id) {
  htbl_insert_real(tbl, NULL, data, data_size, is_new, id, &h, TRUE);
}

void * htbl_get
(htbl_t tbl,
 htbl_id_t id) {
  return htbl_get_mem(tbl, id, SYSTEM_HEAP);
}

void * htbl_get_mem
(htbl_t tbl,
 htbl_id_t id,
 heap_t heap) {
  char * v;
  state_t result;
  char * pos;

  assert(HTBL_HASH_COMPACTION != tbl->type && HTBL_BITSTATE != tbl->type);
  pos = HTBL_POS_STATE(tbl, id);
  HTBL_GET_VECTOR(tbl, pos, v);
  result = tbl->unserialise_func(v, heap);
  return result;
}

hkey_t htbl_get_hash
(htbl_t tbl,
 htbl_id_t id) {
  hkey_t result;
  char * pos;

  assert(HTBL_HASH_COMPACTION == tbl->type);
  pos = HTBL_POS_STATE(tbl, id);
  HTBL_GET_HASH(tbl, pos, &result);
  return result;
}

bool_t htbl_has_attr
(htbl_t tbl,
 attr_state_t attr) {
  if(HTBL_BITSTATE == tbl->type) {
    return FALSE;
  } else {
    return (tbl->attrs_available & ATTR_ID(attr)) ? TRUE : FALSE;
  }
}

#define HTBL_GET_ATTR(shift) {                                          \
    const uint32_t width = ATTR_WIDTH[attr];                            \
    const uint32_t move = tbl->attr_pos[attr] + shift;                  \
    uint64_t result;                                                    \
    bit_stream_t bits;                                                  \
    char * pos;                                                         \
                                                                        \
    pos = HTBL_POS_STATE(tbl, id);                                      \
    HTBL_INIT_BITS_ON_ATTRS(tbl, pos, bits);                            \
    bit_stream_move(bits, move);                                        \
    bit_stream_get(bits, result, width);                                \
    return result;                                                      \
}

uint64_t htbl_get_attr
(htbl_t tbl,
 htbl_id_t id,
 attr_state_t attr) {
  assert(HTBL_BITSTATE != tbl->type && htbl_has_attr(tbl, attr));
  HTBL_GET_ATTR(0);
}

uint64_t htbl_get_worker_attr
(htbl_t tbl,
 htbl_id_t id,
 attr_state_t attr,
 worker_id_t w) {
  assert(HTBL_BITSTATE != tbl->type && htbl_has_attr(tbl, attr));
  HTBL_GET_ATTR(w);
}

#define HTBL_SET_ATTR(shift) {					\
    const uint32_t width = ATTR_WIDTH[attr];			\
    const uint32_t move = tbl->attr_pos[attr] + shift;		\
    bit_stream_t bits;						\
    char * pos, * status;					\
								\
    pos = HTBL_POS_STATE(tbl, id);				\
    HTBL_INIT_BITS_ON_ATTRS(tbl, pos, bits);			\
    bit_stream_move(bits, move);				\
    HTBL_GET_STATUS(tbl, pos, status);				\
    if(tbl->no_workers > 1) {					\
      while(!CAS(status, BUCKET_READY, BUCKET_UPDATE)) {	\
        context_sleep(SLEEP_TIME);				\
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
  assert(HTBL_BITSTATE != tbl->type && htbl_has_attr(tbl, attr));
  HTBL_SET_ATTR(0);
}

void htbl_set_worker_attr
(htbl_t tbl,
 htbl_id_t id,
 attr_state_t attr,
 worker_id_t w,
 uint64_t val) {
  assert(HTBL_BITSTATE != tbl->type && htbl_has_attr(tbl, attr));
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

void htbl_get_serialised
(htbl_t tbl,
 htbl_id_t id,
 bit_vector_t * s,
 uint16_t * size,
 hkey_t * h) {
  char * pos;
  
  assert(HTBL_HASH_COMPACTION != tbl->type &&
         HTBL_BITSTATE != tbl->type);
  pos = HTBL_POS_STATE(tbl, id);
  HTBL_GET_HASH(tbl, pos, h);
  HTBL_GET_VECTOR(tbl, pos, *s);
  if(HTBL_FULL_STATIC == tbl->type) {
    *size = tbl->data_size;
  } else {
    HTBL_GET_DYNAMIC_VECTOR_SIZE(tbl, pos, size);
  }
}

void htbl_fold
(htbl_t tbl,
 htbl_fold_func_t f,
 void * data) {
  char * v, * pos, * status;
  state_t s;
  htbl_id_t id;
  heap_t h = local_heap_new();

  for(id = 0, pos = HTBL_POS_STATE(tbl, id);
      id < tbl->hash_size;
      id ++, pos += tbl->item_size) {
    HTBL_GET_STATUS(tbl, pos, status);
    if((*status) >= BUCKET_READY) {
      HTBL_GET_VECTOR(tbl, pos, v);
      s = tbl->unserialise_func(v, h);
      f(s, id, data);
      state_free(s);
      heap_reset(h);
    }
  }
  heap_free(h);
}
