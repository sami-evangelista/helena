/*  File: isSorted.c  */
#include "sort_interface.h"

TYPE_bool IMPORTED_FUNCTION_isSorted(TYPE_intList l) {
  int i = 0;
  for(i=0; i<l.length-1; i++)
    if(l.items[i] > l.items[i+1])
      return TYPE__ENUM_CONST_bool__false;
  return TYPE__ENUM_CONST_bool__true;
}
