ppx_bigarray
============

[![Build Status](https://travis-ci.org/akabe/ppx_bigarray.svg?branch=master)](https://travis-ci.org/akabe/ppx_bigarray)

This PPX extension provides
[big array](http://caml.inria.fr/pub/docs/manual-ocaml/libref/Bigarray.html)
literals in [OCaml](http://ocaml.org).

Install
-------

```
./configure
make
make install
```

Usage
-----

### Example

`x` is a two-dimensional big array that has size 3-by-4, kind `Bigarray.int`,
and layout `Bigarray.c_layout`.

```OCaml
let x = [%bigarray2.int.c
          [
            [11; 12; 13; 14];
            [21; 22; 23; 24];
            [31; 32; 33; 34];
          ]
        ] in
print_int x.{1,2} (* print "23" *)
```

In this code, elements of a big array are given as a list of lists, but
you can use an array of arrays.

### Syntax

- `[%bigarray1.KIND.LAYOUT ELEMENTS]` is a one-dimensional big array
  (that has type `Bigarray.Array1.t`). `ELEMENTS` is a list or an array.
- `[%bigarray2.KIND.LAYOUT ELEMENTS]` is a two-dimensional big array
  (that has type `Bigarray.Array2.t`). `ELEMENTS` is a list of lists or
  an array of arrays.
- `[%bigarray3.KIND.LAYOUT ELEMENTS]` is a three-dimensional big array
  (that has type `Bigarray.Array3.t`). `ELEMENTS` is a list of lists of lists or
  an array of arrays of arrays.
- `[%bigarray.KIND.LAYOUT ELEMENTS]` is a multi-dimensional big array
  (that has type `Bigarray.Genarray.t`). `ELEMENTS` is a nested list or
  a nested array.

| `KIND`                       | Corresponding variable                                  |
|------------------------------|---------------------------------------------------------|
| `int8_signed` or `sint8`     | `Bigarray.int8_signed`                                  |
| `int8_unsigned` or `uint8`   | `Bigarray.int8_unsigned`                                |
| `int16_signed` or `sint16`   | `Bigarray.int16_signed`                                 |
| `int16_unsigned` or `uint16` | `Bigarray.int16_unsigned`                               |
| `int32`                      | `Bigarray.int32`                                        |
| `int64`                      | `Bigarray.int64`                                        |
| `int`                        | `Bigarray.int`                                          |
| `nativeint`                  | `Bigarray.nativeint`                                    |
| `float32`                    | `Bigarray.float32`                                      |
| `float64`                    | `Bigarray.float64`                                      |
| `complex32`                  | `Bigarray.complex32`                                    |
| `complex64`                  | `Bigarray.complex64`                                    |
| `char`                       | `Bigarray.char`                                         |
| otherwise                    | (to refer the variable that has a given name as a kind) |

| `LAYOUT`                      | Corresponding variable    |
|-------------------------------|---------------------------|
| `c` or `c_layout`             | `Bigarray.c_layout`       |
| `fortran` or `fortran_layout` | `Bigarray.fortran_layout` |