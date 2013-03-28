/*
 *
 * File: interfaces.h
 * Date: 03/03/2010 at 14:41
 *
 * This file has been created by Helena. It is useless to modify it.
 *
 * Description:
 *    Interface file that contain all type definitions, net constant
 * declarations and function prototypes.
 *
 */


#ifndef INTERFACES_H
#   define INTERFACES_H


/***
 *  type int
 ***/
typedef int TYPE_int;

/***
 *  type nat
 ***/
typedef TYPE_int TYPE_nat;

/***
 *  type short
 ***/
typedef TYPE_int TYPE_short;

/***
 *  type ushort
 ***/
typedef TYPE_int TYPE_ushort;

/***
 *  type bool
 ***/
typedef char TYPE_bool;
#define TYPE__ENUM_CONST_bool__false 0
#define TYPE__ENUM_CONST_bool__true 1

/***
 *  type intList
 ***/
typedef struct {
   TYPE_int items[1000];
   unsigned int length;
} TYPE_intList;

/*****
 * net constant toSort
 *****/
TYPE_intList CONSTANT_toSort;

/*****
 * function initList
 *****/
TYPE_intList FUNCTION_initList
();
TYPE_intList IMPORTED_FUNCTION_initList
();

/*****
 * function quickSort
 *****/
TYPE_intList FUNCTION_quickSort
(TYPE_intList V2,
 TYPE_int V3);
TYPE_intList IMPORTED_FUNCTION_quickSort
(TYPE_intList V2,
 TYPE_int V3);

/*****
 * function isSorted
 *****/
TYPE_bool FUNCTION_isSorted
(TYPE_intList V4);
TYPE_bool IMPORTED_FUNCTION_isSorted
(TYPE_intList V4);

#endif /*  INTERFACES_H  */
