/**
 * @file mevent_list.h
 * @brief Model event list definition.
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_MEVENT_LIST
#define LIB_MEVENT_LIST

#include "list.h"
#include "model.h"
#include "heap.h"

typedef list_t mevent_list_t;


#define mevent_list_size list_size
#define mevent_list_nth list_nth
#define mevent_list_free list_free
#define mevent_list_append list_append
#define mevent_list_pick_random list_pick_random
#define mevent_list_pick_first list_pick_first
#define mevent_list_is_empty list_is_empty
#define mevent_list_size list_size
#define mevent_list_free list_free
#define mevent_list_unserialise(v) mevent_list_unserialise_mem(v, SYSTEM_HEAP)

mevent_list_t mevent_list_new
(heap_t h);

uint32_t mevent_list_char_width
(mevent_list_t l);

void mevent_list_serialise
(mevent_list_t l,
 bit_vector_t v);

void mevent_list_print
(mevent_list_t l);

mevent_list_t mevent_list_unserialise_mem
(bit_vector_t v,
 heap_t heap);

#endif
