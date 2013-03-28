/*  File: initList.c  */
#include "sort_interface.h"

TYPE_intList IMPORTED_FUNCTION_initList() {
  TYPE_intList result;
  result.length = 5;
  result.items[0] = 4;
  result.items[1] = 1;
  result.items[2] = 3;
  result.items[3] = 0;
  result.items[4] = 2;
  return result;
}
