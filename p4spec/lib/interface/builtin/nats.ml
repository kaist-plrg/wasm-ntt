open Lang
open Xl
open Il
open Domain.Atom
module Value = struct
  include Runtime.Value

  let make typ value = Make.mk Util.Source.no_region typ value
  let get_list = Get.list
  let get_text = Get.text
end
module F32 = Wasm_interpreter.F32
module F64 = Wasm_interpreter.F64
module Ast = Wasm_interpreter.Ast
module Eval_num = Wasm_interpreter.Eval_num
module Eval_vec = Wasm_interpreter.Eval_vec
module Pack = Wasm_interpreter.Pack
module Types = Wasm_interpreter.Types
module V128 = Wasm_interpreter.V128
module WasmValue = Wasm_interpreter.Value
open Util.Source
open Error

type symbol = NT of value | Term of string

let wrap_atom (s : string) : atom = Atom s $ no_region

let wrap_var_t (s : string) : typ' = VarT (s $ no_region, [])

let with_typ (typ : typ') (v : value') : value =
  Runtime.Value.Make.mk no_region typ v

let wrap_num_v_nat (n : Bigint.t) : value =
  NumV (`Nat n) |> with_typ (NumT `NatT)

let wrap_num_v_int (i : Bigint.t) : value =
  NumV (`Int i) |> with_typ (NumT `IntT)

let wrap_case_v (vs : symbol list) : value' =
  let rec build_mixop acc_mixop acc_terms = function
    | [] -> acc_mixop @ [ acc_terms ]
    | Term s :: rest -> build_mixop acc_mixop (acc_terms @ [ wrap_atom s ]) rest
    | NT _ :: rest ->
        let new_mixop = acc_mixop @ [ acc_terms ] in
        build_mixop new_mixop [] rest
  in
  let mixop = build_mixop [] [] vs in
  let values =
    vs
    |> List.filter (function NT _ -> true | Term _ -> false)
    |> List.map (function NT v -> v | Term _ -> assert false)
  in
  let mixop =
    mixop
    |> List.map (List.map (fun atom -> atom.it))
    |> Runtime.Value.Mixops.of_atoms_matrix
  in
  CaseV (Domain.Mixfix.fill mixop values)

let ( #@ ) (symbols : symbol list) (typ : string) : value =
  symbols |> wrap_case_v |> with_typ (wrap_var_t typ)

let wasm_hook_missing name =
  error no_region ("wasm builtin hook " ^ name ^ " is not initialized")

let il_of_num_hook : (WasmValue.num -> value) ref =
  ref (fun _ -> wasm_hook_missing "il_of_num")

let il_of_vec_hook : (WasmValue.vec -> value) ref =
  ref (fun _ -> wasm_hook_missing "il_of_vec")

let sl_to_num_hook : (value -> WasmValue.num) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_num")

let sl_to_vec_hook : (value -> WasmValue.vec) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_vec")

let sl_to_testop_hook : (value -> Ast.testop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_testop")

let sl_to_relop_hook : (value -> Ast.relop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_relop")

let sl_to_unop_hook : (value -> Ast.unop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_unop")

let sl_to_binop_hook : (value -> Ast.binop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_binop")

let sl_to_cvtop_hook : (value -> Ast.cvtop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_cvtop")

let sl_to_vtestop_hook : (value -> Ast.vec_testop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_vtestop")

let sl_to_vrelop_hook : (value -> Ast.vec_relop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_vrelop")

let sl_to_vunop_hook : (value -> Ast.vec_unop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_vunop")

let sl_to_vbinop_hook : (value -> Ast.vec_binop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_vbinop")

let sl_to_vternop_hook : (value -> Ast.vec_ternop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_vternop")

let sl_to_vcvtop_hook : (value -> Ast.vec_cvtop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_vcvtop")

let sl_to_vshiftop_hook : (value -> Ast.vec_shiftop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_vshiftop")

let sl_to_vbitmaskop_hook : (value -> Ast.vec_bitmaskop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_vbitmaskop")

let sl_to_vvtestop_hook : (value -> Ast.vec_vtestop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_vvtestop")

let sl_to_vvunop_hook : (value -> Ast.vec_vunop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_vvunop")

let sl_to_vvbinop_hook : (value -> Ast.vec_vbinop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_vvbinop")

let sl_to_vvternop_hook : (value -> Ast.vec_vternop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_vvternop")

let sl_to_vsplatop_hook : (value -> Ast.vec_splatop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_vsplatop")

let sl_to_vextractop_hook : (value -> Ast.vec_extractop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_vextractop")

let sl_to_vreplaceop_hook : (value -> Ast.vec_replaceop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_vreplaceop")

let sl_to_loadop_hook : (value -> Ast.loadop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_loadop")

let sl_to_storeop_hook : (value -> Ast.storeop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_storeop")

let sl_to_vec_loadop_hook : (value -> Ast.vec_loadop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_vec_loadop")

let sl_to_vec_storeop_hook : (value -> Ast.vec_storeop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_vec_storeop")

let sl_to_vec_laneop_hook : (value -> Ast.vec_laneop) ref =
  ref (fun _ -> wasm_hook_missing "sl_to_vec_laneop")

let set_wasm_hooks ~il_of_num ~il_of_vec ~sl_to_num ~sl_to_vec ~sl_to_testop
    ~sl_to_relop ~sl_to_unop ~sl_to_binop ~sl_to_cvtop ~sl_to_vtestop
    ~sl_to_vrelop ~sl_to_vunop ~sl_to_vbinop ~sl_to_vternop ~sl_to_vcvtop
    ~sl_to_vshiftop ~sl_to_vbitmaskop ~sl_to_vvtestop ~sl_to_vvunop
    ~sl_to_vvbinop ~sl_to_vvternop ~sl_to_vsplatop ~sl_to_vextractop
    ~sl_to_vreplaceop ~sl_to_loadop ~sl_to_storeop ~sl_to_vec_loadop
    ~sl_to_vec_storeop ~sl_to_vec_laneop =
  il_of_num_hook := il_of_num;
  il_of_vec_hook := il_of_vec;
  sl_to_num_hook := sl_to_num;
  sl_to_vec_hook := sl_to_vec;
  sl_to_testop_hook := sl_to_testop;
  sl_to_relop_hook := sl_to_relop;
  sl_to_unop_hook := sl_to_unop;
  sl_to_binop_hook := sl_to_binop;
  sl_to_cvtop_hook := sl_to_cvtop;
  sl_to_vtestop_hook := sl_to_vtestop;
  sl_to_vrelop_hook := sl_to_vrelop;
  sl_to_vunop_hook := sl_to_vunop;
  sl_to_vbinop_hook := sl_to_vbinop;
  sl_to_vternop_hook := sl_to_vternop;
  sl_to_vcvtop_hook := sl_to_vcvtop;
  sl_to_vshiftop_hook := sl_to_vshiftop;
  sl_to_vbitmaskop_hook := sl_to_vbitmaskop;
  sl_to_vvtestop_hook := sl_to_vvtestop;
  sl_to_vvunop_hook := sl_to_vvunop;
  sl_to_vvbinop_hook := sl_to_vvbinop;
  sl_to_vvternop_hook := sl_to_vvternop;
  sl_to_vsplatop_hook := sl_to_vsplatop;
  sl_to_vextractop_hook := sl_to_vextractop;
  sl_to_vreplaceop_hook := sl_to_vreplaceop;
  sl_to_loadop_hook := sl_to_loadop;
  sl_to_storeop_hook := sl_to_storeop;
  sl_to_vec_loadop_hook := sl_to_vec_loadop;
  sl_to_vec_storeop_hook := sl_to_vec_storeop;
  sl_to_vec_laneop_hook := sl_to_vec_laneop

let il_of_num num = !il_of_num_hook num
let il_of_vec vec = !il_of_vec_hook vec
let sl_to_num value = !sl_to_num_hook value
let sl_to_vec value = !sl_to_vec_hook value
let sl_to_testop value = !sl_to_testop_hook value
let sl_to_relop value = !sl_to_relop_hook value
let sl_to_unop value = !sl_to_unop_hook value
let sl_to_binop value = !sl_to_binop_hook value
let sl_to_cvtop value = !sl_to_cvtop_hook value
let sl_to_vtestop value = !sl_to_vtestop_hook value
let sl_to_vrelop value = !sl_to_vrelop_hook value
let sl_to_vunop value = !sl_to_vunop_hook value
let sl_to_vbinop value = !sl_to_vbinop_hook value
let sl_to_vternop value = !sl_to_vternop_hook value
let sl_to_vcvtop value = !sl_to_vcvtop_hook value
let sl_to_vshiftop value = !sl_to_vshiftop_hook value
let sl_to_vbitmaskop value = !sl_to_vbitmaskop_hook value
let sl_to_vvtestop value = !sl_to_vvtestop_hook value
let sl_to_vvunop value = !sl_to_vvunop_hook value
let sl_to_vvbinop value = !sl_to_vvbinop_hook value
let sl_to_vvternop value = !sl_to_vvternop_hook value
let sl_to_vsplatop value = !sl_to_vsplatop_hook value
let sl_to_vextractop value = !sl_to_vextractop_hook value
let sl_to_vreplaceop value = !sl_to_vreplaceop_hook value
let sl_to_loadop value = !sl_to_loadop_hook value
let sl_to_storeop value = !sl_to_storeop_hook value
let sl_to_vec_loadop value = !sl_to_vec_loadop_hook value
let sl_to_vec_storeop value = !sl_to_vec_storeop_hook value
let sl_to_vec_laneop value = !sl_to_vec_laneop_hook value

(* Conversion between meta-numerics and OCaml numerics *)

let bigint_of_value (value : value) : Bigint.t =
  value |> Value.Get.num |> Num.to_int

let value_of_bigint (add : value -> unit) (n : Bigint.t) : value =
  let value = Value.Make.nat n in
  add value;
  value

let two32 = Bigint.(one lsl 32)
let two64 = Bigint.(one lsl 64)

let wrap modulo n =
  let r = Bigint.rem n modulo in
  if Bigint.(r < zero) then Bigint.(r + modulo) else r

let two31 = Bigint.(one lsl 31)

let signed32 n =
  let n = wrap two32 n in
  if Bigint.(n >= two31) then Bigint.(n - two32) else n

let one_nat at values_input = Extract.one at values_input |> bigint_of_value

let two_nats at values_input =
  let a, b = Extract.two at values_input in
  (bigint_of_value a, bigint_of_value b)

type float_layout = { width : int; exponent : int; mantissa : int }

let layout32 = { width = 32; exponent = 8; mantissa = 23 }
let layout64 = { width = 64; exponent = 11; mantissa = 52 }

let z_of_value value =
  value |> Value.Get.num |> Num.to_int |> Bigint.to_zarith_bigint

let sl_case value =
  match value.it with
  | CaseV valuecase ->
      Some (Domain.Mixfix.atoms_matrix valuecase, Domain.Mixfix.args valuecase)
  | _ -> None

let bigint_of_z z = Bigint.of_zarith_bigint z

let mask_sign layout = Z.shift_left Z.one (layout.width - 1)

let mask_mag layout = Z.pred (mask_sign layout)

let mask_mant layout = Z.(pred (shift_left one layout.mantissa))

let mask_exp layout = Z.(mask_mag layout - mask_mant layout)

let bias layout =
  let em1 = layout.exponent - 1 in
  Z.((one + one) ** em1 - one)

let fmag_bits at layout value =
  match sl_case value with
  | Some (([{ it = Atom "SUBNORM"; _ }] :: _), [ m ]) -> z_of_value m
  | Some (([{ it = Atom "NORM"; _ }] :: _), [ m; exp ]) ->
    Z.(shift_left (z_of_value exp + bias layout) layout.mantissa + z_of_value m)
  | Some ([[{ it = Atom "INF"; _ }]], []) -> mask_exp layout
  | Some (([{ it = Atom "NAN"; _ }] :: _), [ m ]) ->
    Z.(mask_exp layout + z_of_value m)
  | _ -> error at "expected f32mag/f64mag"

let float_bits at layout value =
  match sl_case value with
  | Some (([{ it = Atom "POS"; _ }] :: _), [ mag ]) ->
    fmag_bits at layout mag
  | Some (([{ it = Atom "NEG"; _ }] :: _), [ mag ]) ->
    Z.(mask_sign layout + fmag_bits at layout mag)
  | _ -> error at "expected f32/f64"

let f32_of_value at value = float_bits at layout32 value |> Z.to_int32_unsigned |> F32.of_bits

let f64_of_value at value = float_bits at layout64 value |> Z.to_int64_unsigned |> F64.of_bits

let add_value add value =
  add value;
  value

let nat_value add z = wrap_num_v_nat (bigint_of_z z) |> add_value add

let int_value add z = wrap_num_v_int (bigint_of_z z) |> add_value add

let float_mag_value add layout bits =
  let mag_typ = if layout.width = 32 then "f32mag" else "f64mag" in
  let n = Z.logand bits (mask_exp layout) in
  let m = Z.logand bits (mask_mant layout) in
  let value =
    if Z.equal n Z.zero then [ Term "SUBNORM"; NT (nat_value add m) ] #@ mag_typ
    else if not (Z.equal n (mask_exp layout)) then
      [
        Term "NORM";
        NT (nat_value add m);
        NT (int_value add Z.(shift_right n layout.mantissa - bias layout));
      ]
      #@ mag_typ
    else if Z.equal m Z.zero then [ Term "INF" ] #@ mag_typ
    else [ Term "NAN"; NT (nat_value add m) ] #@ mag_typ
  in
  add_value add value

let float_value add layout bits =
  let typ = if layout.width = 32 then "f32" else "f64" in
  let mag_bits = Z.logand bits (mask_mag layout) in
  let mag = float_mag_value add layout bits in
  let value =
    [ (if Z.equal mag_bits bits then Term "POS" else Term "NEG"); NT mag ] #@ typ
  in
  add_value add value

let f32_value add f = F32.to_bits f |> Z.of_int32_unsigned |> float_value add layout32

let f64_value add f = F64.to_bits f |> Z.of_int64_unsigned |> float_value add layout64

(* dec $sum_nat(nat* ) : nat *)

let sum_nat (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let values =
    Extract.one at values_input |> Value.Get.list |> List.map bigint_of_value
  in
  let sum = List.fold_left Bigint.( + ) Bigint.zero values in
  value_of_bigint add sum

(* dec $max_nat(nat* ) : nat *)

let max_nat (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let values =
    Extract.one at values_input |> Value.Get.list |> List.map bigint_of_value
  in
  let max =
    match values with
    | [] -> error at "max of empty list"
    | hd :: tl -> List.fold_left Bigint.max hd tl
  in
  value_of_bigint add max

(* dec $min_nat(nat* ) : nat *)

let min_nat (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let values =
    Extract.one at values_input |> Value.Get.list |> List.map bigint_of_value
  in
  let min =
    match values with
    | [] -> error at "min of empty list"
    | hd :: tl -> List.fold_left Bigint.min hd tl
  in
  value_of_bigint add min

(* dec $byte_of_i32(nat) : byte *)

let byte_of_i32 (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let n = Extract.one at values_input |> bigint_of_value in
  value_of_bigint add Bigint.(rem n (of_int 256))

(* dec $i31_of_i32(nat) : nat *)

let i31_of_i32 (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let n = one_nat at values_input in
  value_of_bigint add Bigint.(rem n (of_int 0x80000000))

(* dec $i32_add(nat, nat) : nat *)

let i32_add (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let a, b = two_nats at values_input in
  let result = wrap two32 Bigint.(a + b) in
  value_of_bigint add result

(* dec $i32_sub(nat, nat) : nat *)

let i32_sub (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let a, b = two_nats at values_input in
  let result = wrap two32 Bigint.(a - b) in
  value_of_bigint add result

(* dec $i32_mul(nat, nat) : nat *)

let i32_mul (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let a, b = two_nats at values_input in
  let result = wrap two32 Bigint.(a * b) in
  value_of_bigint add result

(* dec $i64_add(nat, nat) : nat *)

let i64_add (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let a, b = two_nats at values_input in
  value_of_bigint add (wrap two64 Bigint.(a + b))

(* dec $i64_sub(nat, nat) : nat *)

let i64_sub (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let a, b = two_nats at values_input in
  value_of_bigint add (wrap two64 Bigint.(a - b))

(* dec $i64_mul(nat, nat) : nat *)

let i64_mul (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let a, b = two_nats at values_input in
  value_of_bigint add (wrap two64 Bigint.(a * b))

let two_f32s at values_input =
  let a, b = Extract.two at values_input in
  (f32_of_value at a, f32_of_value at b)

let two_f64s at values_input =
  let a, b = Extract.two at values_input in
  (f64_of_value at a, f64_of_value at b)

let f32_binop op add at targs values_input =
  Extract.zero at targs;
  let a, b = two_f32s at values_input in
  f32_value add (op a b)

let f64_binop op add at targs values_input =
  Extract.zero at targs;
  let a, b = two_f64s at values_input in
  f64_value add (op a b)

let f32_cmp op add at targs values_input =
  Extract.zero at targs;
  let a, b = two_f32s at values_input in
  value_of_bigint add (if op a b then Bigint.one else Bigint.zero)

let f64_cmp op add at targs values_input =
  Extract.zero at targs;
  let a, b = two_f64s at values_input in
  value_of_bigint add (if op a b then Bigint.one else Bigint.zero)

(* dec $f32_add(f32, f32) : f32 *)

let f32_add add at targs values_input = f32_binop F32.add add at targs values_input

(* dec $f32_sub(f32, f32) : f32 *)

let f32_sub add at targs values_input = f32_binop F32.sub add at targs values_input

(* dec $f32_mul(f32, f32) : f32 *)

let f32_mul add at targs values_input = f32_binop F32.mul add at targs values_input

(* dec $f64_add(f64, f64) : f64 *)

let f64_add add at targs values_input = f64_binop F64.add add at targs values_input

(* dec $f64_sub(f64, f64) : f64 *)

let f64_sub add at targs values_input = f64_binop F64.sub add at targs values_input

(* dec $f64_mul(f64, f64) : f64 *)

let f64_mul add at targs values_input = f64_binop F64.mul add at targs values_input

(* dec $f32_eq(f32, f32) : nat *)

let f32_eq add at targs values_input = f32_cmp F32.eq add at targs values_input

(* dec $f32_ne(f32, f32) : nat *)

let f32_ne add at targs values_input = f32_cmp F32.ne add at targs values_input

(* dec $f32_le(f32, f32) : nat *)

let f32_le add at targs values_input = f32_cmp F32.le add at targs values_input

(* dec $f64_eq(f64, f64) : nat *)

let f64_eq add at targs values_input = f64_cmp F64.eq add at targs values_input

(* dec $f64_ne(f64, f64) : nat *)

let f64_ne add at targs values_input = f64_cmp F64.ne add at targs values_input

(* dec $f64_le(f64, f64) : nat *)

let f64_le add at targs values_input = f64_cmp F64.le add at targs values_input

(* dec $i32_eqz(nat) : nat *)

let i32_eqz (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let n = one_nat at values_input in
  value_of_bigint add (if Bigint.(n = zero) then Bigint.one else Bigint.zero)

(* dec $i64_eqz(nat) : nat *)

let i64_eqz (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let n = one_nat at values_input in
  value_of_bigint add (if Bigint.(n = zero) then Bigint.one else Bigint.zero)

(* dec $i32_gt_u(nat, nat) : nat *)

let i32_gt_u (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let a, b = two_nats at values_input in
  value_of_bigint add (if Bigint.(a > b) then Bigint.one else Bigint.zero)

(* dec $i32_le_s(nat, nat) : nat *)

let i32_le_s (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let a, b = two_nats at values_input in
  value_of_bigint add
    (if Bigint.(signed32 a <= signed32 b) then Bigint.one else Bigint.zero)

(* dec $i32_le_u(nat, nat) : nat *)

let i32_le_u (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let a, b = two_nats at values_input in
  value_of_bigint add (if Bigint.(a <= b) then Bigint.one else Bigint.zero)

(* dec $i64_le_u(nat, nat) : nat *)

let i64_le_u (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let a, b = two_nats at values_input in
  value_of_bigint add (if Bigint.(a <= b) then Bigint.one else Bigint.zero)

(* dec $i32_ne(nat, nat) : nat *)

let i32_ne (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let a, b = two_nats at values_input in
  value_of_bigint add (if Bigint.(a <> b) then Bigint.one else Bigint.zero)

(* dec $i32_wrap_i64(nat) : nat *)

let i32_wrap_i64 (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let n = one_nat at values_input in
  value_of_bigint add (wrap two32 n)

(* dec $i32_extend_i8_s(nat) : nat *)

let i32_extend_i8_s (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let n = one_nat at values_input |> wrap Bigint.(of_int 256) in
  let result =
    if Bigint.(n >= of_int 128) then Bigint.(n + (two32 - of_int 256)) else n
  in
  value_of_bigint add result

(* dec $i32_extend_i16_s(nat) : nat *)

let i32_extend_i16_s (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let n = one_nat at values_input |> wrap Bigint.(of_int 65536) in
  let result =
    if Bigint.(n >= of_int 32768) then Bigint.(n + (two32 - of_int 65536))
    else n
  in
  value_of_bigint add result

(* dec $i31_get_s(nat) : nat *)

let i31_get_s (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let two31 = Bigint.(one lsl 31) in
  let two30 = Bigint.(one lsl 30) in
  let n = one_nat at values_input |> wrap two31 in
  let result = if Bigint.(n >= two30) then Bigint.(n + (two32 - two31)) else n in
  value_of_bigint add result

(* dec $bytes_of_i32(nat) : list of byte *)

let bytes_of_i32 (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let n = one_nat at values_input |> wrap two32 in
  let byte_typ = Il.VarT ("byte" $ no_region, []) in
  let byte shift =
    let divisor = Bigint.(one lsl shift) in
    let b = Bigint.((n / divisor) % of_int 256) in
    Value.make byte_typ (NumV (`Nat b))
  in
  let bytes = [ byte 0; byte 8; byte 16; byte 24 ] in
  let value =
    Value.make (Il.IterT (byte_typ $ no_region, Il.List)) (ListV bytes)
  in
  add value;
  value

(* dec $i32_of_bytes(list of byte) : nat *)

let i32_of_bytes (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let bytes = Extract.one at values_input |> Value.get_list in
  let rec loop shift acc = function
    | [] -> acc
    | byte :: bytes ->
      let b = bigint_of_value byte in
      let factor = Bigint.(one lsl shift) in
      loop (shift + 8) Bigint.(acc + (b * factor)) bytes
  in
  value_of_bigint add (wrap two32 (loop 0 Bigint.zero bytes))

(* dec $i64_of_bytes(list of byte) : nat *)

let i64_of_bytes (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let bytes = Extract.one at values_input |> Value.get_list in
  let rec loop shift acc = function
    | [] -> acc
    | byte :: bytes ->
      let b = bigint_of_value byte in
      let factor = Bigint.(one lsl shift) in
      loop (shift + 8) Bigint.(acc + (b * factor)) bytes
  in
  value_of_bigint add (wrap two64 (loop 0 Bigint.zero bytes))

(* dec $zero_bytes(nat) : list of byte *)

let zero_bytes (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let n = Extract.one at values_input |> bigint_of_value |> Bigint.to_int_exn in
  let byte_typ = Il.VarT ("byte" $ no_region, []) in
  let zero = Value.make byte_typ (NumV (`Nat Bigint.zero)) in
  let value =
    Value.make (Il.IterT (byte_typ $ no_region, Il.List))
      (ListV (List.init n (fun _ -> zero)))
  in
  add value;
  value

(* dec $repeat_byte(byte, nat) : list of byte *)

let repeat_byte (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let byte_value, count_value = Extract.two at values_input in
  let count = bigint_of_value count_value |> Bigint.to_int_exn in
  if count < 0 then error at "repeat_byte negative count";
  let byte_typ = Il.VarT ("byte" $ no_region, []) in
  let value =
    Value.make (Il.IterT (byte_typ $ no_region, Il.List))
      (ListV (List.init count (fun _ -> byte_value)))
  in
  add value;
  value

let rec take_values n xs =
  match (n, xs) with
  | 0, _ -> []
  | _, [] -> []
  | n, x :: xs -> x :: take_values (n - 1) xs

let rec drop_values n xs =
  match (n, xs) with
  | 0, xs -> xs
  | _, [] -> []
  | n, _ :: xs -> drop_values (n - 1) xs

(* dec $slice_bytes(list of byte, nat, nat) : list of byte *)

let slice_bytes (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let bytes_value, offset_value, count_value = Extract.three at values_input in
  let bytes = Value.get_list bytes_value in
  let offset = bigint_of_value offset_value |> Bigint.to_int_exn in
  let count = bigint_of_value count_value |> Bigint.to_int_exn in
  if offset < 0 || count < 0 || offset + count > List.length bytes then
    error at "slice_bytes out of bounds";
  let byte_typ = Il.VarT ("byte" $ no_region, []) in
  let bytes' = bytes |> drop_values offset |> take_values count in
  let value =
    Value.make (Il.IterT (byte_typ $ no_region, Il.List)) (ListV bytes')
  in
  add value;
  value

(* dec $replace_bytes(list of byte, nat, list of byte) : list of byte *)

let replace_bytes (add : value -> unit) (at : region) (targs : targ list)
    (values_input : value list) : value =
  Extract.zero at targs;
  let bytes_value, offset_value, replacement_value =
    Extract.three at values_input
  in
  let bytes = Value.get_list bytes_value in
  let offset = bigint_of_value offset_value |> Bigint.to_int_exn in
  let replacement = Value.get_list replacement_value in
  let replacement_len = List.length replacement in
  if offset < 0 || offset + replacement_len > List.length bytes then
    error at "replace_bytes out of bounds";
  let byte_typ = Il.VarT ("byte" $ no_region, []) in
  let bytes' =
    take_values offset bytes @ replacement @ drop_values (offset + replacement_len) bytes
  in
  let value =
    Value.make (Il.IterT (byte_typ $ no_region, Il.List)) (ListV bytes')
  in
  add value;
  value

let bool_value add b =
  value_of_bigint add (if b then Bigint.one else Bigint.zero)

let num_value add num = il_of_num num |> add_value add

let vec_value add vec = il_of_vec vec |> add_value add

let trap_as_unmatch at thunk =
  try thunk () with exn -> error at (Printexc.to_string exn)

let byte_list_typ = Il.IterT (Il.VarT ("byte" $ no_region, []) $ no_region, Il.List)

let byte_value n =
  Value.make (Il.VarT ("byte" $ no_region, [])) (NumV (`Nat (Bigint.of_int n)))

let bytes_string_of_value value =
  value |> Value.get_list
  |> List.map (fun byte ->
         byte |> bigint_of_value |> Bigint.to_int_exn |> Char.chr)
  |> List.to_seq |> String.of_seq

let bytes_value add bytes =
  let values =
    String.to_seq bytes |> Seq.map Char.code |> Seq.map byte_value |> List.of_seq
  in
  let value = Value.make byte_list_typ (ListV values) in
  add_value add value

let nat_of_int add n = value_of_bigint add (Bigint.of_int n)

(* dec $eval_testop(testop_, num_) : nat *)

let eval_testop add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op, num = Extract.two at values_input in
      bool_value add
        (Eval_num.eval_testop (sl_to_testop op)
           (sl_to_num num)))

(* dec $eval_relop(relop_, num_, num_) : nat *)

let eval_relop add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op, lhs, rhs = Extract.three at values_input in
      bool_value add
        (Eval_num.eval_relop (sl_to_relop op)
           (sl_to_num lhs)
           (sl_to_num rhs)))

(* dec $eval_unop(unop_, num_) : num_ *)

let eval_unop add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op, num = Extract.two at values_input in
      num_value add
        (Eval_num.eval_unop (sl_to_unop op)
           (sl_to_num num)))

(* dec $eval_binop(binop_, num_, num_) : num_ *)

let eval_binop add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op, lhs, rhs = Extract.three at values_input in
      num_value add
        (Eval_num.eval_binop (sl_to_binop op)
           (sl_to_num lhs)
           (sl_to_num rhs)))

(* dec $eval_cvtop(cvtop_, num_) : num_ *)

let eval_cvtop add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op, num = Extract.two at values_input in
      num_value add
        (Eval_num.eval_cvtop (sl_to_cvtop op)
           (sl_to_num num)))

(* dec $eval_vtestop(vtestop_, vec_) : nat *)

let eval_vtestop add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op, vec = Extract.two at values_input in
      bool_value add
        (Eval_vec.eval_testop (sl_to_vtestop op)
           (sl_to_vec vec)))

(* dec $eval_vrelop(vrelop_, vec_, vec_) : vec_ *)

let eval_vrelop add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op, lhs, rhs = Extract.three at values_input in
      vec_value add
        (Eval_vec.eval_relop (sl_to_vrelop op)
           (sl_to_vec lhs)
           (sl_to_vec rhs)))

(* dec $eval_vunop(vunop_, vec_) : vec_ *)

let eval_vunop add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op, vec = Extract.two at values_input in
      vec_value add
        (Eval_vec.eval_unop (sl_to_vunop op)
           (sl_to_vec vec)))

(* dec $eval_vbinop(vbinop_, vec_, vec_) : vec_ *)

let eval_vbinop add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op, lhs, rhs = Extract.three at values_input in
      vec_value add
        (Eval_vec.eval_binop (sl_to_vbinop op)
           (sl_to_vec lhs)
           (sl_to_vec rhs)))

(* dec $eval_vternop(vternop_, vec_, vec_, vec_) : vec_ *)

let eval_vternop add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op, v1, v2, v3 = Extract.four at values_input in
      vec_value add
        (Eval_vec.eval_ternop (sl_to_vternop op)
           (sl_to_vec v1)
           (sl_to_vec v2)
           (sl_to_vec v3)))

(* dec $eval_vcvtop(vcvtop_, vec_) : vec_ *)

let eval_vcvtop add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op, vec = Extract.two at values_input in
      vec_value add
        (Eval_vec.eval_cvtop (sl_to_vcvtop op)
           (sl_to_vec vec)))

(* dec $eval_vshiftop(vshiftop_, vec_, num_) : vec_ *)

let eval_vshiftop add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op, vec, num = Extract.three at values_input in
      vec_value add
        (Eval_vec.eval_shiftop (sl_to_vshiftop op)
           (sl_to_vec vec)
           (sl_to_num num)))

(* dec $eval_vbitmaskop(vbitmaskop_, vec_) : num_ *)

let eval_vbitmaskop add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op, vec = Extract.two at values_input in
      num_value add
        (Eval_vec.eval_bitmaskop
           (sl_to_vbitmaskop op)
           (sl_to_vec vec)))

(* dec $eval_vvtestop(vvtestop_, vec_) : nat *)

let eval_vvtestop add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op, vec = Extract.two at values_input in
      bool_value add
        (Eval_vec.eval_vtestop (sl_to_vvtestop op)
           (sl_to_vec vec)))

(* dec $eval_vvunop(vvunop_, vec_) : vec_ *)

let eval_vvunop add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op, vec = Extract.two at values_input in
      vec_value add
        (Eval_vec.eval_vunop (sl_to_vvunop op)
           (sl_to_vec vec)))

(* dec $eval_vvbinop(vvbinop_, vec_, vec_) : vec_ *)

let eval_vvbinop add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op, lhs, rhs = Extract.three at values_input in
      vec_value add
        (Eval_vec.eval_vbinop (sl_to_vvbinop op)
           (sl_to_vec lhs)
           (sl_to_vec rhs)))

(* dec $eval_vvternop(vvternop_, vec_, vec_, vec_) : vec_ *)

let eval_vvternop add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op, v1, v2, v3 = Extract.four at values_input in
      vec_value add
        (Eval_vec.eval_vternop (sl_to_vvternop op)
           (sl_to_vec v1)
           (sl_to_vec v2)
           (sl_to_vec v3)))

(* dec $eval_vsplatop(vsplatop_, num_) : vec_ *)

let eval_vsplatop add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op, num = Extract.two at values_input in
      vec_value add
        (Eval_vec.eval_splatop (sl_to_vsplatop op)
           (sl_to_num num)))

(* dec $eval_vextractop(vextractop_, vec_) : num_ *)

let eval_vextractop add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op, vec = Extract.two at values_input in
      num_value add
        (Eval_vec.eval_extractop (sl_to_vextractop op)
           (sl_to_vec vec)))

(* dec $eval_vreplaceop(vreplaceop_, vec_, num_) : vec_ *)

let eval_vreplaceop add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op, vec, num = Extract.three at values_input in
      vec_value add
        (Eval_vec.eval_replaceop
           (sl_to_vreplaceop op)
           (sl_to_vec vec)
           (sl_to_num num)))

(* dec $loadop_size(loadop_) : nat *)

let loadop_size add at targs values_input =
  Extract.zero at targs;
  let op = Extract.one at values_input |> sl_to_loadop in
  let size =
    match op.pack with
    | None -> Types.num_size op.ty
    | Some (pack, _) -> Pack.packed_size pack
  in
  nat_of_int add size

(* dec $storeop_size(storeop_) : nat *)

let storeop_size add at targs values_input =
  Extract.zero at targs;
  let op = Extract.one at values_input |> sl_to_storeop in
  let size =
    match op.pack with
    | None -> Types.num_size op.ty
    | Some pack -> Pack.packed_size pack
  in
  nat_of_int add size

(* dec $eval_load_num(loadop_, byte list) : num_ *)

let eval_load_num add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op_value, bytes_value = Extract.two at values_input in
      let op = sl_to_loadop op_value in
      let bytes = bytes_string_of_value bytes_value in
      let num =
        match op.pack with
        | None -> WasmValue.num_of_bits op.ty bytes
        | Some (pack, ext) -> WasmValue.num_of_packed_bits op.ty pack ext bytes
      in
      num_value add num)

(* dec $eval_store_num(storeop_, num_) : byte* *)

let eval_store_num add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op_value, num_value = Extract.two at values_input in
      let op = sl_to_storeop op_value in
      let num = sl_to_num num_value in
      let bytes =
        match op.pack with
        | None -> WasmValue.bits_of_num num
        | Some pack -> WasmValue.packed_bits_of_num pack num
      in
      bytes_value add bytes)

(* dec $vloadop_size(vloadop_) : nat *)

let vloadop_size add at targs values_input =
  Extract.zero at targs;
  let op =
    Extract.one at values_input |> sl_to_vec_loadop
  in
  let size =
    match op.pack with
    | None -> Types.vec_size op.ty
    | Some (pack, _) -> Pack.packed_size pack
  in
  nat_of_int add size

(* dec $vstoreop_size(vstoreop_) : nat *)

let vstoreop_size add at targs values_input =
  Extract.zero at targs;
  let op =
    Extract.one at values_input |> sl_to_vec_storeop
  in
  nat_of_int add (Types.vec_size op.ty)

(* dec $vlaneop_size(vlaneop_) : nat *)

let vlaneop_size add at targs values_input =
  Extract.zero at targs;
  let op =
    Extract.one at values_input |> sl_to_vec_laneop
  in
  nat_of_int add (Pack.packed_size op.pack)

(* dec $eval_load_vec(vloadop_, byte list) : vec_ *)

let eval_load_vec add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op_value, bytes_value = Extract.two at values_input in
      let op = sl_to_vec_loadop op_value in
      let bytes = bytes_string_of_value bytes_value in
      let vec =
        match op.pack with
        | None -> WasmValue.vec_of_bits op.ty bytes
        | Some (pack, ext) -> WasmValue.vec_of_packed_bits op.ty pack ext bytes
      in
      vec_value add vec)

(* dec $eval_store_vec(vstoreop_, vec_) : byte* *)

let eval_store_vec add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op_value, vec_input = Extract.two at values_input in
      let _op = sl_to_vec_storeop op_value in
      let vec = sl_to_vec vec_input in
      bytes_value add (WasmValue.bits_of_vec vec))

(* dec $eval_load_vec_lane(vlaneop_, int, byte*, vec_) : vec_ *)

let eval_load_vec_lane add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op_value, lane_value, bytes_input, vec_input =
        Extract.four at values_input
      in
      let op = sl_to_vec_laneop op_value in
      let lane = bigint_of_value lane_value |> Bigint.to_int_exn in
      let bytes = bytes_string_of_value bytes_input in
      let vec = sl_to_vec vec_input in
      match vec with
      | WasmValue.V128 vec128 ->
        let vec128' =
          match op.pack with
          | Pack.Pack8 ->
            V128.I8x16.replace_lane lane vec128
              (WasmValue.I32Num.of_num 0
                 (WasmValue.num_of_packed_bits Types.I32T Pack.Pack8 Pack.SX
                    bytes))
          | Pack.Pack16 ->
            V128.I16x8.replace_lane lane vec128
              (WasmValue.I32Num.of_num 0
                 (WasmValue.num_of_packed_bits Types.I32T Pack.Pack16 Pack.SX
                    bytes))
          | Pack.Pack32 ->
            V128.I32x4.replace_lane lane vec128
              (WasmValue.I32Num.of_num 0
                 (WasmValue.num_of_bits Types.I32T bytes))
          | Pack.Pack64 ->
            V128.I64x2.replace_lane lane vec128
              (WasmValue.I64Num.of_num 0
                 (WasmValue.num_of_bits Types.I64T bytes))
        in
        vec_value add (WasmValue.V128 vec128'))

(* dec $eval_store_vec_lane(vlaneop_, int, vec_) : byte* *)

let eval_store_vec_lane add at targs values_input =
  Extract.zero at targs;
  trap_as_unmatch at (fun () ->
      let op_value, lane_value, vec_input = Extract.three at values_input in
      let op = sl_to_vec_laneop op_value in
      let lane = bigint_of_value lane_value |> Bigint.to_int_exn in
      let vec = sl_to_vec vec_input in
      match vec with
      | WasmValue.V128 vec128 ->
        let num =
          match op.pack with
          | Pack.Pack8 ->
            WasmValue.I32 (V128.I8x16.extract_lane_s lane vec128)
          | Pack.Pack16 ->
            WasmValue.I32 (V128.I16x8.extract_lane_s lane vec128)
          | Pack.Pack32 ->
            WasmValue.I32 (V128.I32x4.extract_lane_s lane vec128)
          | Pack.Pack64 ->
            WasmValue.I64 (V128.I64x2.extract_lane_s lane vec128)
        in
        let bytes =
          match op.pack with
          | Pack.Pack8 | Pack.Pack16 -> WasmValue.packed_bits_of_num op.pack num
          | Pack.Pack32 | Pack.Pack64 -> WasmValue.bits_of_num num
        in
        bytes_value add bytes)
