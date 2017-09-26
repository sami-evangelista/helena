#include "mevent_list.h"

void mevent_list_free_item
(void * ptr) {
  mevent_t e = * ((mevent_t *) ptr);
  
  mevent_free(e);
}

mevent_list_t mevent_list_new
(heap_t h) {
  return list_new(h, sizeof(mevent_t), mevent_list_free_item);
}

uint32_t mevent_list_char_width
(mevent_list_t l) {
  uint32_t result = sizeof(list_size_t);
  list_iter_t it;
  mevent_t e;
  
  for(it = list_get_iterator(l);
      !list_iterator_at_end(it);
      it = list_iterator_next(it)) {
    e = * ((mevent_t *) list_iterator_item(it));
    result += mevent_char_width(e);
  }
  return result;
}

void mevent_list_serialise
(mevent_list_t l,
 bit_vector_t v) {
  mevent_t e;
  list_iter_t it;
  list_size_t size = list_size(l);
  uint32_t pos = 0;

  memcpy(v, &size, sizeof(list_size_t));
  pos = sizeof(list_size_t);
  for(it = list_get_iterator(l);
      !list_iterator_at_end(it);
      it = list_iterator_next(it)) {
    e = * ((mevent_t *) list_iterator_item(it));
    mevent_serialise(e, v + pos);
    pos += mevent_char_width(e);
  }
}

mevent_list_t mevent_list_unserialise_mem
(bit_vector_t v,
 heap_t heap) {
  mevent_list_t result;
  uint32_t size, pos;
  mevent_t e;

  memcpy(&size, v, sizeof(list_size_t));
  result = mevent_list_new(heap);
  pos = sizeof(list_size_t);
  while(size) {
    e = mevent_unserialise_mem(v + pos, heap);
    pos += mevent_char_width(e);
    list_append(result, &e);
    size --;
  }
  return result;
}

void mevent_list_print_app
(void * item,
 void * data) {
  mevent_t e = * ((mevent_t *) item);

  mevent_print(e, stdout);
}

void mevent_list_print
(mevent_list_t l) {
  list_app(l, &mevent_list_print_app, NULL);
}
