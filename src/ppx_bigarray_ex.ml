(* ppx_bigarray --- A PPX extension for providing big array literals in OCaml

   Copyright (C) 2015 Akinori ABE
   This software is distributed under MIT License
   See LICENSE.txt for details. *)

open Format
open Ast_helper
open Ast_mapper
open Asttypes
open Parsetree
open Longident

let ( >> ) f g x = g (f x)

let rec split chr offset str =
  try
    let i = String.index_from str offset chr in
    (String.sub str offset (i - offset)) :: (split chr (i + 1) str)
  with _ ->
    [String.sub str offset (String.length str - offset)]

let bigarray_kind_of_string = function
  | "float32" -> NestedMatrix.Float32
  | "float64" -> NestedMatrix.Float64
  | "int8_signed" | "sint8" -> NestedMatrix.Int8_signed
  | "int8_unsigned" | "uint8" -> NestedMatrix.Int8_unsigned
  | "int16_signed" | "sint16" -> NestedMatrix.Int16_signed
  | "int16_unsigned" | "uint16" -> NestedMatrix.Int16_unsigned
  | "int32" -> NestedMatrix.Int32
  | "int64" -> NestedMatrix.Int64
  | "int" -> NestedMatrix.Int
  | "nativeint" -> NestedMatrix.Nativeint
  | "complex32" -> NestedMatrix.Complex32
  | "complex64" -> NestedMatrix.Complex64
  | "char" -> NestedMatrix.Char
  | s -> NestedMatrix.Dynamic s

let bigarray_layout_of_string ?loc = function
  | "c" | "c_layout" -> NestedMatrix.C_layout
  | "fortran" | "fortran_layout" -> NestedMatrix.Fortran_layout
  | layout -> Error.exnf ?loc "Unknown big array layout `%s'" layout ()

let check_nested_matrix mat =
  let size = NestedMatrix.size mat in
  let msg_head =
    sprintf "This %d-dimensional big array literal expects size %s"
      (List.length size) (NestedMatrix.string_of_size size) in
  let gather_warnings acc = function
    | (n, NestedMatrix.Leaf (loc, _)) ->
      Error.exnf ~loc "Syntax Error: @[%s@\n\
                       This expression should be a list or an array@ \
                       of length %d@ syntactically@]" msg_head n ()
    | (-1, NestedMatrix.Node (loc, _)) ->
      Error.exnf ~loc "Syntax Error: @[%s@\n\
                       This expression should be an element of a big array@\n\
                       but a list or an array is given@]" msg_head ()
    | (n, NestedMatrix.Node (loc, children)) ->
      let msg = sprintf "@[%s@\nThis row should have %d element(s),@ \
                         but %d element(s) are given@]"
          msg_head n (List.length children) in
      (attribute_of_warning loc msg) :: acc
  in
  let errors = NestedMatrix.check_rect size mat in
  let warnings = List.fold_left gather_warnings [] errors in
  (size, warnings)

let convert loc ba_type kind layout = function
  | PStr [{ pstr_desc = Pstr_eval (expr, _); _ }] -> (* [%ext expression] *)
    let mat = NestedMatrix.of_expression expr in
    let (size, warnings) = check_nested_matrix mat in
    NestedMatrix.to_expression ~loc ~attrs:warnings
      ba_type (bigarray_kind_of_string kind)
      (bigarray_layout_of_string ~loc layout) size mat
  | _ -> Error.exnf ~loc
           "Syntax Error: @[This expression should be a list or an array@ \
            syntactically@]" ()

let bigarray_mapper =
  let super = default_mapper in
  let expr self e = match e with
    | { pexp_desc = Pexp_extension ({txt; _}, payload); _ } ->
      begin
        try
          match split '.' 0 txt with
          | ["bigarray1"; kind; layout] ->
            convert e.pexp_loc NestedMatrix.Array1 kind layout payload
          | ["bigarray2"; kind; layout] ->
            convert e.pexp_loc NestedMatrix.Array2 kind layout payload
          | ["bigarray3"; kind; layout] ->
            convert e.pexp_loc NestedMatrix.Array3 kind layout payload
          | ["bigarray"; kind; layout] ->
            convert e.pexp_loc NestedMatrix.Genarray kind layout payload
          | _ -> super.expr self e
        with
        | Location.Error error -> Exp.extension (extension_of_error error)
      end
    | _ -> super.expr self e
  in
  { super with expr }

let () =
  match Sys.argv with
  | [|_; infile; outfile|] ->
    Ast_mapper.apply ~source:infile ~target:outfile bigarray_mapper
  | _ -> eprintf "ppx_bigarray infile outfile"