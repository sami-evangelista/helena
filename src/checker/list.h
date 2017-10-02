/**
 * @file list.h
 * @brief Implementation of lists.
 * @date 12 sep 2017
 * @author Sami Evangelista
 */

#ifndef LIB_LIST
#define LIB_LIST

#include "includes.h"
#include "heap.h"

typedef uint32_t list_index_t;

typedef uint32_t list_size_t;

typedef struct struct_list_t * list_t;

typedef struct struct_list_node_t * list_iter_t;

typedef void (* list_free_func_t) (void *);
typedef char (* list_pred_func_t) (void *, void *);
typedef void (* list_app_func_t) (void *, void *);
typedef uint32_t (* list_char_size_func_t) (void *);
typedef void (* list_serialise_func_t) (void *, char *);
typedef void (* list_unserialise_func_t) (char *, heap_t, void *);


/**
 * @brief list_new
 */
list_t list_new
(heap_t heap,
 uint32_t sizeof_item,
 list_free_func_t free_func);


/**
 * @brief list_is_empty
 */
char list_is_empty
(list_t list);


/**
 * @brief list_size
 */
list_size_t list_size
(list_t list);


/**
 * @brief list_free
 */
void list_free
(list_t list);


/**
 * @brief list_first
 */
void list_first
(list_t list,
 void * item);


/**
 * @brief list_last
 */
void list_last
(list_t list,
 void * item);


/**
 * @brief list_nth
 */
void list_nth
(list_t list,
 list_index_t n,
 void * item);


/**
 * @brief list_app
 */
void list_app
(list_t list,
 list_app_func_t app_func,
 void * data);


/**
 *  @brief list_prepend
 */
void list_prepend
(list_t list,
 void * item);


/**
 *  @brief list_append
 */
void list_append
(list_t list,
 void * item);


/**
 *  @brief list_pick_last
 */
void list_pick_last
(list_t list,
 void * item);


/**
 *  @brief list_pick_first
 */
void list_pick_first
(list_t list,
 void * item);


/**
 *  @brief list_pick_random
 */
void list_pick_random
(list_t list,
 void * item,
 rseed_t * seed);


/**
 *  @brief list_find
 */
void * list_find
(list_t list,
 list_pred_func_t pred_func,
 void * find_data);


/**
 *  @brief list_filter
 */
void list_filter
(list_t list,
 list_pred_func_t pred_func,
 void * filter_data);


/**
 *  @brief list_char_size
 */
uint32_t list_char_size
(list_t list,
 list_char_size_func_t char_size_func);


/**
 *  @brief list_serialise
 */
void list_serialise
(list_t list,
 char * data,
 list_char_size_func_t char_size_func,
 list_serialise_func_t serialise_func);


/**
 *  @brief list_unserialise
 */

list_t list_unserialise
(heap_t heap,
 uint32_t sizeof_item,
 list_free_func_t free_func,
 char * data,
 list_char_size_func_t char_size_func,
 list_unserialise_func_t unserialise_func);


/**
 * @brief list_get_iter
 */
list_iter_t list_get_iter
(list_t list);


/**
 * @brief list_iter_next
 */
list_iter_t list_iter_next
(list_iter_t it);


/**
 * @brief list_iter_at_end
 */
char list_iter_at_end
(list_iter_t it);


/**
 * @brief list_iter_item
 */
void * list_iter_item
(list_iter_t it);

#endif
