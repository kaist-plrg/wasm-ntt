module Fresh_ = Fresh
open Lang
open Il
module Typ = Runtime.Type.Typ
module Value = Runtime.Value
module Run = Runtime.Dynamic_Runner.Signature
open Error
open Util.Source

(* Extensibility point: extra or override builtins per interface *)

type impl = (Value.t -> unit) -> region -> Typ.t list -> Value.t list -> Value.t

module type EXT = sig
  val entries : (string * impl) list
end

module No_ext : EXT = struct
  let entries = []
end

(* Create a BUILTIN from an EXT module containing extensions *)

module Make (Ext : EXT) () = struct
  (* States for builtins *)

  let ctr : int ref = ref 0

  (* Initializer *)

  let init () : unit = ctr := 0

  (* State management *)

  let checkpoint () : int = !ctr
  let seff (before : int) (after : int) : bool = before <> after

  (* Builtin calls *)

  module Funcs = Map.Make (String)

  let funcs =
    Funcs.empty
    (* Nats *)
    |> Funcs.add "sum_nat" Nats.sum_nat
    |> Funcs.add "max_nat" Nats.max_nat
    |> Funcs.add "min_nat" Nats.min_nat
    |> Funcs.add "byte_of_i32" Nats.byte_of_i32
    |> Funcs.add "i31_of_i32" Nats.i31_of_i32
    |> Funcs.add "i32_add" Nats.i32_add
    |> Funcs.add "i32_sub" Nats.i32_sub
    |> Funcs.add "i32_mul" Nats.i32_mul
    |> Funcs.add "i64_add" Nats.i64_add
    |> Funcs.add "i64_sub" Nats.i64_sub
    |> Funcs.add "i64_mul" Nats.i64_mul
    |> Funcs.add "f32_add" Nats.f32_add
    |> Funcs.add "f32_sub" Nats.f32_sub
    |> Funcs.add "f32_mul" Nats.f32_mul
    |> Funcs.add "f64_add" Nats.f64_add
    |> Funcs.add "f64_sub" Nats.f64_sub
    |> Funcs.add "f64_mul" Nats.f64_mul
    |> Funcs.add "i32_eqz" Nats.i32_eqz
    |> Funcs.add "i64_eqz" Nats.i64_eqz
    |> Funcs.add "i32_gt_u" Nats.i32_gt_u
    |> Funcs.add "i32_le_s" Nats.i32_le_s
    |> Funcs.add "i32_le_u" Nats.i32_le_u
    |> Funcs.add "i64_le_u" Nats.i64_le_u
    |> Funcs.add "i32_ne" Nats.i32_ne
    |> Funcs.add "i32_wrap_i64" Nats.i32_wrap_i64
    |> Funcs.add "f32_eq" Nats.f32_eq
    |> Funcs.add "f32_ne" Nats.f32_ne
    |> Funcs.add "f32_le" Nats.f32_le
    |> Funcs.add "f64_eq" Nats.f64_eq
    |> Funcs.add "f64_ne" Nats.f64_ne
    |> Funcs.add "f64_le" Nats.f64_le
    |> Funcs.add "i32_extend_i8_s" Nats.i32_extend_i8_s
    |> Funcs.add "i32_extend_i16_s" Nats.i32_extend_i16_s
    |> Funcs.add "i31_get_s" Nats.i31_get_s
    |> Funcs.add "bytes_of_i32" Nats.bytes_of_i32
    |> Funcs.add "i32_of_bytes" Nats.i32_of_bytes
    |> Funcs.add "i64_of_bytes" Nats.i64_of_bytes
    |> Funcs.add "f32_of_bytes" Nats.f32_of_bytes
    |> Funcs.add "f64_of_bytes" Nats.f64_of_bytes
    |> Funcs.add "v128_of_bytes" Nats.v128_of_bytes
    |> Funcs.add "zero_bytes" Nats.zero_bytes
    |> Funcs.add "repeat_byte" Nats.repeat_byte
    |> Funcs.add "slice_bytes" Nats.slice_bytes
    |> Funcs.add "replace_bytes" Nats.replace_bytes
    |> Funcs.add "eval_testop" Nats.eval_testop
    |> Funcs.add "eval_relop" Nats.eval_relop
    |> Funcs.add "eval_unop" Nats.eval_unop
    |> Funcs.add "eval_binop" Nats.eval_binop
    |> Funcs.add "eval_cvtop" Nats.eval_cvtop
    |> Funcs.add "eval_vtestop" Nats.eval_vtestop
    |> Funcs.add "eval_vrelop" Nats.eval_vrelop
    |> Funcs.add "eval_vunop" Nats.eval_vunop
    |> Funcs.add "eval_vbinop" Nats.eval_vbinop
    |> Funcs.add "eval_vternop" Nats.eval_vternop
    |> Funcs.add "eval_vcvtop" Nats.eval_vcvtop
    |> Funcs.add "eval_vshiftop" Nats.eval_vshiftop
    |> Funcs.add "eval_vbitmaskop" Nats.eval_vbitmaskop
    |> Funcs.add "eval_vvtestop" Nats.eval_vvtestop
    |> Funcs.add "eval_vvunop" Nats.eval_vvunop
    |> Funcs.add "eval_vvbinop" Nats.eval_vvbinop
    |> Funcs.add "eval_vvternop" Nats.eval_vvternop
    |> Funcs.add "eval_vsplatop" Nats.eval_vsplatop
    |> Funcs.add "eval_vextractop" Nats.eval_vextractop
    |> Funcs.add "eval_vreplaceop" Nats.eval_vreplaceop
    |> Funcs.add "loadop_size" Nats.loadop_size
    |> Funcs.add "storeop_size" Nats.storeop_size
    |> Funcs.add "eval_load_num" Nats.eval_load_num
    |> Funcs.add "eval_store_num" Nats.eval_store_num
    |> Funcs.add "vloadop_size" Nats.vloadop_size
    |> Funcs.add "vstoreop_size" Nats.vstoreop_size
    |> Funcs.add "vlaneop_size" Nats.vlaneop_size
    |> Funcs.add "eval_load_vec" Nats.eval_load_vec
    |> Funcs.add "eval_store_vec" Nats.eval_store_vec
    |> Funcs.add "eval_load_vec_lane" Nats.eval_load_vec_lane
    |> Funcs.add "eval_store_vec_lane" Nats.eval_store_vec_lane
    (* Ints *)
    |> Funcs.add "sum_int" Ints.sum_int
    |> Funcs.add "max_int" Ints.max_int
    |> Funcs.add "min_int" Ints.min_int
    (* Texts *)
    |> Funcs.add "text_to_int" Texts.text_to_int
    |> Funcs.add "int_to_text" Texts.int_to_text
    |> Funcs.add "split_text" Texts.split_text
    |> Funcs.add "strip_prefix" Texts.strip_prefix
    |> Funcs.add "strip_suffix" Texts.strip_suffix
    |> Funcs.add "strip_all_whitespace" Texts.strip_all_whitespace
    |> Funcs.add "bytes_of_text" Texts.bytes_of_text
    (* Lists *)
    |> Funcs.add "rev_" Lists.rev_
    |> Funcs.add "concat_" Lists.concat_
    |> Funcs.add "distinct_" Lists.distinct_
    |> Funcs.add "partition_" Lists.partition_
    |> Funcs.add "assoc_" Lists.assoc_
    |> Funcs.add "sort_" Lists.sort_
    |> Funcs.add "transpose_" Lists.transpose_
    (* Sets *)
    |> Funcs.add "intersect_set" Sets.intersect_set
    |> Funcs.add "union_set" Sets.union_set
    |> Funcs.add "unions_set" Sets.unions_set
    |> Funcs.add "diff_set" Sets.diff_set
    |> Funcs.add "sub_set" Sets.sub_set
    |> Funcs.add "eq_set" Sets.eq_set
    (* Maps *)
    |> Funcs.add "find_map" Maps.find_map
    |> Funcs.add "find_maps" Maps.find_maps
    |> Funcs.add "add_map" Maps.add_map
    |> Funcs.add "adds_map" Maps.adds_map
    |> Funcs.add "update_map" Maps.update_map
    (* Fresh type id *)
    |> Funcs.add "fresh_typeId" (Fresh_.fresh_typeId ctr)
    (* Numerics *)
    |> Funcs.add "shl" Numerics.shl
    |> Funcs.add "shr" Numerics.shr
    |> Funcs.add "shr_arith" Numerics.shr_arith
    |> Funcs.add "pow2" Numerics.pow2
    |> Funcs.add "bitstr_to_int" Numerics.bitstr_to_int
    |> Funcs.add "int_to_bitstr" Numerics.int_to_bitstr
    |> Funcs.add "bits_to_int_unsigned" Numerics.bits_to_int_unsigned
    |> Funcs.add "bits_to_int_signed" Numerics.bits_to_int_signed
    |> Funcs.add "int_to_bits_unsigned" Numerics.int_to_bits_unsigned
    |> Funcs.add "int_to_bits_signed" Numerics.int_to_bits_signed
    |> Funcs.add "bneg" Numerics.bneg
    |> Funcs.add "band" Numerics.band
    |> Funcs.add "bxor" Numerics.bxor
    |> Funcs.add "bor" Numerics.bor
    |> Funcs.add "bitacc" Numerics.bitacc
    |> Funcs.add "bitacc_replace" Numerics.bitacc_replace
    (* Ext entries merged last — allow interface-specific overrides *)
    |> fun m ->
    List.fold_left (fun acc (k, v) -> Funcs.add k v acc) m Ext.entries

  let invoke (add : value -> unit) (id : id) (targs : targ list)
      (args : value list) : value =
    let func = Funcs.find_opt id.it funcs in
    check (Option.is_some func) id.at
      (Format.asprintf "implementation for builtin %s is missing" id.it);
    let func = Option.get func in
    func add id.at targs args
end
