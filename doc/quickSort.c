/*  File: quickSort.c  */
#include "sort_interface.h"

void swap(int *a, int *b) {
  int t = *a; *a = *b; *b = t;
}
void quickSort(int arr[], int beg, int end, int * nb) {
  if (end > beg + 1) {
    int piv = arr[beg], l = beg + 1, r = end;
    while(l < r) {
      if(arr[l] <= piv) l++;
      else {
	if(*nb == 0) return;
        swap(&arr[l], &arr[--r]);
	(*nb) --;
      }
    }
    if(*nb == 0) return;
    swap(&arr[--l], &arr[beg]);
    (*nb) --;
    quickSort(arr, beg, l, nb);
    quickSort(arr, r, end, nb);
  }
}
TYPE_intList IMPORTED_FUNCTION_quickSort(TYPE_intList l, TYPE_int nb) {
  TYPE_intList result = l;
  quickSort(result.items, 0, result.length, &nb);
  return result;
}
