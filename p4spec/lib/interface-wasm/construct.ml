open Wasm_interpreter.Types
open Wasm_interpreter.Value
open Wasm_interpreter.Ast
open Wasm_interpreter.Source
open Wasm_interpreter
open Wrap

let ($) it at = {it; at}
(* il_of_* 함수는 il.value를 반환해야 한다. *)

let default_table_max = 4294967295L
let default_memory_max = 65536L

type layout = { width : int; exponent : int; mantissa : int }
let layout32 = { width = 32; exponent = 8; mantissa = 23 }
let layout64 = { width = 64; exponent = 11; mantissa = 52 }

let mask_sign layout = Z.shift_left Z.one (layout.width - 1)
let mask_mag layout = Z.pred (mask_sign layout)
let mask_mant layout = Z.(pred (shift_left one layout.mantissa))
let mask_exp layout = Z.(mask_mag layout - mask_mant layout)
let bias layout = let em1 = layout.exponent - 1 in Z.((one + one)**em1 - one)

let listV l = Lang.Il.ListV (l)
let optV opt = Lang.Il.OptV (opt)

let il_of_list s f l = (List.map f l) |> wrap_list_v s
let il_of_seq s f seq = List.of_seq seq |> il_of_list s f
let il_of_opt s f opt = Option.map f opt |> wrap_opt_v s

let il_of_final = function
  | NoFinal ->
      [ Term "NoFinal" ] #@ "final"
  | Final ->
      [ Term "Final" ] #@ "final"

let bigint_of_z_nat z =
  assert (z >= Z.zero);
  Bigint.of_zarith_bigint z

let bigint_of_z_int z =
  Bigint.of_zarith_bigint z

let bigint_of_nat32 i32 =
  Z.of_int32_unsigned i32 |> bigint_of_z_nat

let bigint_of_nat64 i64 =
  Z.of_int64_unsigned i64 |> bigint_of_z_nat

let bigint_of_nat i = Z.of_int i |> bigint_of_z_nat

let il_of_fmagN layout i =
  let n = Z.logand i (mask_exp layout) in
  let m = Z.logand i (mask_mant layout) in
  let mag = if layout.width = 32 then "f32mag" else "f64mag" in
  if n = Z.zero then
    [ Term "SUBNORM"; NT (wrap_num_v_nat (bigint_of_z_nat m)) ] #@ mag
  else if n <> mask_exp layout then
    [ Term "NORM"; NT (wrap_num_v_nat (bigint_of_z_nat m)); NT (wrap_num_v_int (bigint_of_z_int Z.(shift_right n layout.mantissa - bias layout))) ] #@ mag
  else if m = Z.zero then
    [ Term "INF" ] #@ mag
  else
    [ Term "NAN"; NT (wrap_num_v_nat (bigint_of_z_nat m)) ] #@ mag

let il_of_floatN layout i =
  let i' = Z.logand i (mask_mag layout) in
  let symbols = [ if i' = i then Term "POS" else Term "NEG"; NT (il_of_fmagN layout i) ] in
  if layout.width = 32 then symbols #@ "f32" else symbols #@ "f64"

let e64 = Z.(shift_left one 64)

let vec128_to_z vec =
  match V128.I64x2.to_lanes vec with
  | [ v1; v2 ] -> Z.(of_int64_unsigned v1 + e64 * of_int64_unsigned v2)
  | _ -> assert false

let il_of_float32 f32 = F32.to_bits f32 |> Z.of_int32_unsigned |> il_of_floatN layout32

let il_of_float64 f64 = F64.to_bits f64 |> Z.of_int64_unsigned |> il_of_floatN layout64

let il_of_vec128 vec = vec128_to_z vec |> bigint_of_z_nat |> wrap_num_v_nat
(*
let bigint_of_byte byte = Char.code byte |> bigint_of_nat

let il_of_bytes bytes_ = String.to_seq bytes_ |> Seq.map bigint_of_byte |> il_of_seq wrap_num_v_nat (Seq.map bigint_of_byte)
*)

let il_of_idx s idx = with_typ (wrap_var_t s) (NumV (`Nat (bigint_of_nat32 idx.it)))

let il_of_name name = wrap_text_v (Utf8.encode name)

let string_of_abs_heap_type = function
  | AnyHT -> "AnyHT"
  | NoneHT -> "NoneHT"
  | EqHT -> "EqHT"
  | I31HT -> "I31HT"
  | StructHT -> "StructHT"
  | ArrayHT -> "ArrayHT"
  | FuncHT -> "FuncHT"
  | NoFuncHT -> "NoFuncHT"
  | ExnHT -> "ExnHT"
  | NoExnHT -> "NoExnHT"
  | ExternHT -> "ExternHT"
  | NoExternHT -> "NoExternHT"
  | BotHT -> "BotHT"
  | _ -> failwith "Not an abstract heap type"

let string_of_int_binop = function
  | IntOp.Add -> "IAdd"
  | IntOp.Sub -> "ISub"
  | IntOp.Mul -> "IMul"
  | IntOp.DivS -> "IDivS"
  | IntOp.DivU -> "IDivU"
  | IntOp.RemS -> "IRemS"
  | IntOp.RemU -> "IRemU"
  | IntOp.And -> "IAnd"
  | IntOp.Or -> "IOr"
  | IntOp.Xor -> "IXor"
  | IntOp.Shl -> "IShl"
  | IntOp.ShrS -> "IShrS"
  | IntOp.ShrU -> "IShrU"
  | IntOp.Rotl -> "IRotl"
  | IntOp.Rotr -> "IRotr"

let string_of_float_binop = function
  | FloatOp.Add -> "FAdd"
  | FloatOp.Sub -> "FSub"
  | FloatOp.Mul -> "FMul"
  | FloatOp.Div -> "FDiv"
  | FloatOp.Min -> "FMin"
  | FloatOp.Max -> "FMax"
| FloatOp.CopySign -> "FCopysign"

(* better name for this function? *)
let rec il_of_typeuse = function
  | StatX i ->
    let symbols = [ Term "StatX"; NT (with_typ (wrap_var_t "typeidx") (NumV (`Nat (bigint_of_nat32 i)))) ] in
    symbols #@ "typevar"
  | RecX i ->
    let symbols = [ Term "RecX"; NT (with_typ (wrap_var_t "typeidx") (NumV (`Nat (bigint_of_nat32 i)))) ] in
    symbols #@ "typevar"

and il_of_def_type = function
  | DefT (rt, i) ->
    let symbols = [ Term "DefT"; NT (il_of_rec_type rt); NT (wrap_num_v_nat (bigint_of_nat32 i)) ] in
    symbols #@ "deftype"

and il_of_heap_type = function
  | VarHT var ->
    let symbols = [ Term "VarHT"; NT (il_of_typeuse var) ] in
    symbols #@ "heaptype"
  | DefHT dt ->
    let symbols = [ Term "DefHT"; NT (il_of_def_type dt) ] in
    symbols #@ "heaptype"
  | ht ->
    [ Term (string_of_abs_heap_type ht) ] #@ "heaptype"

and il_of_mut = function
  | Cons ->
    [ Term "Cons" ] #@ "mut"
  | Var ->
[ Term "Var" ] #@ "mut"

and il_of_num_type = function
  | I32T ->
    [ Term "I32T" ] #@ "numtype"
  | I64T ->
    [ Term "I64T" ] #@ "numtype"
  | F32T ->
    [ Term "F32T" ] #@ "numtype"
  | F64T ->
    [ Term "F64T" ] #@ "numtype"

and il_of_null = function
  | NoNull ->
    [ Term "NoNull" ] #@ "null"
  | Null ->
    [ Term "Null" ] #@ "null"

and il_of_ref_type (null, ht) =
  let symbols =
    [ NT (il_of_null null); NT (il_of_heap_type ht) ] in
  symbols #@ "reftype"

and il_of_vec_type = function
  | V128T ->
    [ Term "V128T" ] #@ "vectype"

and il_of_val_type = function
  | NumT nt ->
    let symbols = [ Term "NumT"; NT (il_of_num_type nt) ] in
    symbols #@ "valtype"
  | RefT rt ->
    let symbols = [ Term "RefT"; NT (il_of_ref_type rt) ] in
    symbols #@ "valtype"
  | VecT vt ->
    let symbols = [ Term "VecT"; NT (il_of_vec_type vt) ] in
    symbols #@ "valtype"
  | BotT ->
    [ Term "BotT" ] #@ "valtype"

and il_of_pack_type = function
  | Pack.Pack8 ->
    [ Term "I8" ] #@ "packtype"
  | Pack.Pack16 ->
    [ Term "I16" ] #@ "packtype"
  | Pack.Pack32 ->
    [ Term "I32" ] #@ "packtype"
  | Pack.Pack64 ->
    [ Term "I64" ] #@ "packtype"

and il_of_storage_type = function
  | ValStorageT vt ->
    let symbols = [ Term "ValStorageT"; NT (il_of_val_type vt) ] in
    symbols #@ "storagetype"
  | PackStorageT pt ->
    let symbols = [ Term "PackStorageT"; NT (il_of_pack_type pt) ] in
    symbols #@ "storagetype"

and il_of_field_type = function
  | FieldT (mut, st) ->
    let symbols = [ Term "FieldT"; NT (il_of_mut mut); NT (il_of_storage_type st) ] in
    symbols #@ "fieldtype"

and il_of_struct_type = function
  | StructT ftl ->
      let symbols = [ Term "StructT"; NT (il_of_list "fieldtype" il_of_field_type ftl) ] in
      symbols #@ "structtype"

and il_of_array_type = function
  | ArrayT ft ->
      let symbols = [ Term "ArrayT"; NT (il_of_field_type ft) ] in
      symbols #@ "arraytype"

and il_of_result_type rt =
  il_of_list "valtype" il_of_val_type rt

and il_of_func_type = function
  | FuncT (rt1, rt2) ->
      let symbols = [ Term "FuncT"; NT (il_of_result_type rt1); NT (il_of_result_type rt2) ] in
      symbols #@ "functype"

and il_of_str_type = function
  | DefStructT st ->
    let symbols = [ Term "DefStructT"; NT (il_of_struct_type st) ] in
    symbols #@ "strtype"
  | DefArrayT arrt ->
    let symbols = [ Term "DefArrayT"; NT (il_of_array_type arrt) ] in
    symbols #@ "strtype"
  | DefFuncT ft ->
    let symbols = [ Term "DefFuncT"; NT (il_of_func_type ft) ] in
    symbols #@ "strtype"

and il_of_sub_type = function
  | SubT (fin, htl, strt) ->
    let symbols = [ Term "SubT"; NT (il_of_final fin); NT (il_of_list "heaptype" il_of_heap_type htl); NT (il_of_str_type strt) ] in
      symbols #@ "subtype"

and il_of_rec_type = function
  | RecT stl ->
    let symbols = [ Term "RecT"; NT (il_of_list "subtype" il_of_sub_type stl) ] in
      symbols #@ "rectype"

and il_of_global_type = function
  | GlobalT (mut, vt) ->
    let symbols = [ Term "GlobalT"; NT (il_of_mut mut); NT (il_of_val_type vt) ] in
    symbols #@ "globaltype"

and il_of_addr_type = function
  | I32AT ->
    [ Term "I32AT" ] #@ "addrtype"
  | I64AT ->
    [ Term "I64AT" ] #@ "addrtype"

and il_of_limits limits =
  wrap_struct_v "limits" [
    (wrap_atom "MIN", with_typ (wrap_var_t "i64") (NumV (`Int (bigint_of_z_int (Z.of_int64_unsigned limits.min)))));
    (wrap_atom "MAX", Option.map (fun i -> with_typ (wrap_var_t "i64") (NumV (`Int ((bigint_of_z_int (Z.of_int64_unsigned i)))))) limits.max |> wrap_opt_v_typed (wrap_iter_t Opt (wrap_var_t "i64")))
  ]

and il_of_table_type = function
  | TableT (at, limits, rt) ->
    let symbols = [ Term "TableT"; NT (il_of_addr_type at); NT (il_of_limits limits); NT (il_of_ref_type rt) ] in
    symbols #@ "tabletype"

and il_of_memory_type = function
  | MemoryT (at, limits) ->
    let symbols = [ Term "MemoryT"; NT (il_of_addr_type at); NT (il_of_limits limits) ] in
    symbols #@ "memtype"

let rename_i_to_f s =
  if String.length s > 0 && s.[0] = 'i' then
    "f" ^ String.sub s 1 (String.length s - 1)
  else
    s

and rename_f_to_i s =
  if String.length s > 0 && s.[0] = 'f' then
    "i" ^ String.sub s 1 (String.length s - 1)
  else
    s

let il_of_op f1 f2 = function
  | I32 op ->
    let open Util.Source in
    let v = f1 op in
    let iid = id_of_case_v v in
    let fid = rename_i_to_f iid in
    let id = wrap_var_t' "op" [ (wrap_var_t iid) $ no_region; (wrap_var_t iid) $ no_region; (wrap_var_t fid) $ no_region; (wrap_var_t fid) $ no_region ] in
    let symbols = [ Term "I32"; NT v ] in
    symbols |> wrap_case_v |> with_typ id
  | I64 op ->
    let open Util.Source in
    let v = f1 op in
    let iid = id_of_case_v v in
    let fid = rename_i_to_f iid in
    let id = wrap_var_t' "op" [ (wrap_var_t iid) $ no_region; (wrap_var_t iid) $ no_region; (wrap_var_t fid) $ no_region; (wrap_var_t fid) $ no_region ] in
    let symbols = [ Term "I64"; NT v ] in
    symbols |> wrap_case_v |> with_typ id
  | F32 op ->
    let open Util.Source in
    let v = f2 op in
    let fid = id_of_case_v v in
    let iid = rename_f_to_i fid in
    let id = wrap_var_t' "op" [ (wrap_var_t iid) $ no_region; (wrap_var_t iid) $ no_region; (wrap_var_t fid) $ no_region; (wrap_var_t fid) $ no_region ] in
    let symbols = [ Term "F32"; NT v ] in
    symbols |> wrap_case_v |> with_typ id
  | F64 op ->
    let open Util.Source in
    let v = f2 op in
    let fid = id_of_case_v v in
    let iid = rename_f_to_i fid in
    let id = wrap_var_t' "op" [ (wrap_var_t iid) $ no_region; (wrap_var_t iid) $ no_region; (wrap_var_t fid) $ no_region; (wrap_var_t fid) $ no_region ] in
    let symbols = [ Term "F64"; NT v ] in
    symbols |> wrap_case_v |> with_typ id

let il_of_int_unop = function
  | IntOp.Clz -> [ Term "Clz" ] #@ "iunop"
  | IntOp.Ctz -> [ Term "Ctz" ] #@ "iunop"
  | IntOp.Popcnt -> [ Term "Popcnt" ] #@ "iunop"
  | IntOp.ExtendS pt -> [ Term "ExtendS"; NT (il_of_pack_type pt) ] #@ "iunop"

let il_of_float_unop = function
  | FloatOp.Neg -> [ Term "Neg" ] #@ "funop"
  | FloatOp.Abs -> [ Term "Abs" ] #@ "funop"
  | FloatOp.Ceil -> [ Term "Ceil" ] #@ "funop"
  | FloatOp.Floor -> [ Term "Floor" ] #@ "funop"
  | FloatOp.Trunc -> [ Term "Trunc" ] #@ "funop"
  | FloatOp.Nearest -> [ Term "Nearest" ] #@ "funop"
  | FloatOp.Sqrt -> [ Term "Sqrt" ] #@ "funop"

let il_of_unop = il_of_op il_of_int_unop il_of_float_unop

let il_of_int_binop ibinop =
  [ Term (string_of_int_binop ibinop) ] #@ "ibinop"

let il_of_float_binop fbinop =
  [ Term (string_of_float_binop fbinop) ] #@ "fbinop"

let il_of_binop = il_of_op il_of_int_binop il_of_float_binop

let il_of_int_testop : IntOp.testop -> Lang.Il.value = function
  | IntOp.Eqz -> [ Term "Eqz" ] #@ "itestop"

let il_of_float_testop : FloatOp.testop -> Lang.Il.value = function
  | _ -> .

let il_of_testop = il_of_op il_of_int_testop il_of_float_testop

let il_of_int_relop = function
  | IntOp.Eq -> [ Term "Eq" ] #@ "irelop"
  | IntOp.Ne -> [ Term "Ne" ] #@ "irelop"
  | IntOp.LtS -> [ Term "LtS" ] #@ "irelop"
  | IntOp.LtU -> [ Term "LtU" ] #@ "irelop"
  | IntOp.GtS -> [ Term "GtS" ] #@ "irelop"
  | IntOp.GtU -> [ Term "GtU" ] #@ "irelop"
  | IntOp.LeS -> [ Term "LeS" ] #@ "irelop"
  | IntOp.LeU -> [ Term "LeU" ] #@ "irelop"
  | IntOp.GeS -> [ Term "GeS" ] #@ "irelop"
  | IntOp.GeU -> [ Term "GeU" ] #@ "irelop"

let il_of_float_relop = function
  | FloatOp.Eq -> [ Term "Eq" ] #@ "frelop"
  | FloatOp.Ne -> [ Term "Ne" ] #@ "frelop"
  | FloatOp.Lt -> [ Term "Lt" ] #@ "frelop"
  | FloatOp.Gt -> [ Term "Gt" ] #@ "frelop"
  | FloatOp.Le -> [ Term "Le" ] #@ "frelop"
  | FloatOp.Ge -> [ Term "Ge" ] #@ "frelop"

let il_of_relop = il_of_op il_of_int_relop il_of_float_relop

let il_of_int_cvtop = function
  | IntOp.ExtendSI32 -> [ Term "ExtendSI32" ] #@ "icvtop"
  | IntOp.ExtendUI32 -> [ Term "ExtendUI32" ] #@ "icvtop"
  | IntOp.WrapI64 -> [ Term "WrapI64" ] #@ "icvtop"
  | IntOp.TruncSF32 -> [ Term "TruncSF32" ] #@ "icvtop"
  | IntOp.TruncUF32 -> [ Term "TruncUF32" ] #@ "icvtop"
  | IntOp.TruncSF64 -> [ Term "TruncSF64" ] #@ "icvtop"
  | IntOp.TruncUF64 -> [ Term "TruncUF64" ] #@ "icvtop"
  | IntOp.TruncSatSF32 -> [ Term "TruncSatSF32" ] #@ "icvtop"
  | IntOp.TruncSatUF32 -> [ Term "TruncSatUF32" ] #@ "icvtop"
  | IntOp.TruncSatSF64 -> [ Term "TruncSatSF64" ] #@ "icvtop"
  | IntOp.TruncSatUF64 -> [ Term "TruncSatUF64" ] #@ "icvtop"
  | IntOp.ReinterpretFloat -> [ Term "ReinterpretFloat" ] #@ "icvtop"

let il_of_float_cvtop = function
  | FloatOp.ConvertSI32 -> [ Term "ConvertSI32" ] #@ "fcvtop"
  | FloatOp.ConvertUI32 -> [ Term "ConvertUI32" ] #@ "fcvtop"
  | FloatOp.ConvertSI64 -> [ Term "ConvertSI64" ] #@ "fcvtop"
  | FloatOp.ConvertUI64 -> [ Term "ConvertUI64" ] #@ "fcvtop"
  | FloatOp.PromoteF32 -> [ Term "PromoteF32" ] #@ "fcvtop"
  | FloatOp.DemoteF64 -> [ Term "DemoteF64" ] #@ "fcvtop"
  | FloatOp.ReinterpretInt -> [ Term "ReinterpretInt" ] #@ "fcvtop"

let il_of_cvtop = il_of_op il_of_int_cvtop il_of_float_cvtop

let il_of_num = function
  | I32 i32 -> [ Term "I32"; NT (wrap_num_v_nat (bigint_of_nat32 i32)) ] #@ "num_"
  | I64 i64 -> [ Term "I64"; NT (wrap_num_v_nat (bigint_of_nat64 i64)) ] #@ "num_"
  | F32 f32 -> [ Term "F32"; NT (il_of_float32 f32) ] #@ "num_"
  | F64 f64 -> [ Term "F64"; NT (il_of_float64 f64) ] #@ "num_"

let vec_rename_i_to_f s =
  if String.length s > 0 && s.[1] = 'i' then
    "vf" ^ String.sub s 2 (String.length s - 2)
  else
    s

let vec_op_name s =
  if String.length s > 0 then
    "v" ^ String.sub s 2 (String.length s - 2)
  else
    s

let il_of_vop ?(vflag=false) f1 f2 = function
  | V128 vop -> (
    let open Util.Source in
    match vop with
    | V128.I8x16 op ->
      let v = f1 op in
      let iid = id_of_case_v v in
      let ftarg = if vflag then (wrap_var_t "void") $ no_region else (wrap_var_t (vec_rename_i_to_f iid)) $ no_region in
      let opname = vec_op_name iid in
      let id = wrap_var_t' opname [ (wrap_var_t iid) $ no_region; (wrap_var_t iid) $ no_region; (wrap_var_t iid) $ no_region; (wrap_var_t iid) $ no_region; ftarg; ftarg ] in
      let v2 = [ Term "I8x16"; NT v ]  |> wrap_case_v |> with_typ id in
      [ Term "V128"; NT v2 ] #@ (opname ^ "_")
    | V128.I16x8 op ->
      let v = f1 op in
      let iid = id_of_case_v v in
      let ftarg = if vflag then (wrap_var_t "void") $ no_region else (wrap_var_t (vec_rename_i_to_f iid)) $ no_region in
      let opname = vec_op_name iid in
      let id = wrap_var_t' opname [ (wrap_var_t iid) $ no_region; (wrap_var_t iid) $ no_region; (wrap_var_t iid) $ no_region; (wrap_var_t iid) $ no_region; ftarg; ftarg ] in
      let v2 = [ Term "I16x8"; NT v ]  |> wrap_case_v |> with_typ id in
      [ Term "V128"; NT v2 ] #@ (opname ^ "_")
    | V128.I32x4 op ->
      let v = f1 op in
      let iid = id_of_case_v v in
      let ftarg = if vflag then (wrap_var_t "void") $ no_region else (wrap_var_t (vec_rename_i_to_f iid)) $ no_region in
      let opname = vec_op_name iid in
      let id = wrap_var_t' opname [ (wrap_var_t iid) $ no_region; (wrap_var_t iid) $ no_region; (wrap_var_t iid) $ no_region; (wrap_var_t iid) $ no_region; ftarg; ftarg ] in
      let v2 = [ Term "I32x4"; NT v ]  |> wrap_case_v |> with_typ id in
      [ Term "V128"; NT v2 ] #@ (opname ^ "_")
    | V128.I64x2 op ->
      let v = f1 op in
      let iid = id_of_case_v v in
      let ftarg = if vflag then (wrap_var_t "void") $ no_region else (wrap_var_t (vec_rename_i_to_f iid)) $ no_region in
      let opname = vec_op_name iid in
      let id = wrap_var_t' opname [ (wrap_var_t iid) $ no_region; (wrap_var_t iid) $ no_region; (wrap_var_t iid) $ no_region; (wrap_var_t iid) $ no_region; ftarg; ftarg ] in
      let v2 = [ Term "I64x2"; NT v ]  |> wrap_case_v |> with_typ id in
      [ Term "V128"; NT v2 ] #@ (opname ^ "_")
    | V128.F32x4 op ->
      let v = f2 op in
      let iid = id_of_case_v v in
      let ftarg = if vflag then (wrap_var_t "void") $ no_region else (wrap_var_t (vec_rename_i_to_f iid)) $ no_region in
      let opname = vec_op_name iid in
      let id = wrap_var_t' opname [ (wrap_var_t iid) $ no_region; (wrap_var_t iid) $ no_region; (wrap_var_t iid) $ no_region; (wrap_var_t iid) $ no_region; ftarg; ftarg ] in
      let v2 = [ Term "F32x4"; NT v ]  |> wrap_case_v |> with_typ id in
      [ Term "V128"; NT v2 ] #@ (opname ^ "_")
    | V128.F64x2 op ->
      let v = f2 op in
      let iid = id_of_case_v v in
      let ftarg = if vflag then (wrap_var_t "void") $ no_region else (wrap_var_t (vec_rename_i_to_f iid)) $ no_region in
      let opname = vec_op_name iid in
      let id = wrap_var_t' opname [ (wrap_var_t iid) $ no_region; (wrap_var_t iid) $ no_region; (wrap_var_t iid) $ no_region; (wrap_var_t iid) $ no_region; ftarg; ftarg ] in
      let v2 = [ Term "F64x2"; NT v ]  |> wrap_case_v |> with_typ id in
      [ Term "V128"; NT v2 ] #@ (opname ^ "_")
  )

let il_of_int_vtestop : V128Op.itestop -> Lang.Il.value = function
  | V128Op.AllTrue -> [ Term "AllTrue" ] #@ "vitestop"

let il_of_float_vtestop : Ast.void -> Lang.Il.value = function
  | _ -> .

let il_of_vtestop = il_of_vop il_of_int_vtestop il_of_float_vtestop

let il_of_int_vrelop : V128Op.irelop -> Lang.Il.value = function
  | V128Op.Eq -> [ Term "Eq" ] #@ "virelop"
  | V128Op.Ne ->  [ Term "Ne" ] #@ "virelop"
  | V128Op.LtS -> [ Term "LtS" ] #@ "virelop"
  | V128Op.LtU -> [ Term "LtU" ] #@ "virelop"
  | V128Op.LeS -> [ Term "LeS" ] #@ "virelop"
  | V128Op.LeU -> [ Term "LeU" ] #@ "virelop"
  | V128Op.GtS -> [ Term "GtS" ] #@ "virelop"
  | V128Op.GtU -> [ Term "GtU" ] #@ "virelop"
  | V128Op.GeS -> [ Term "GeS" ] #@ "virelop"
  | V128Op.GeU -> [ Term "GeU" ] #@ "virelop"

let il_of_float_vrelop : V128Op.frelop -> Lang.Il.value = function
  | V128Op.Eq -> [ Term "Eq" ] #@ "vfrelop"
  | V128Op.Ne -> [ Term "Ne" ] #@ "vfrelop"
  | V128Op.Lt -> [ Term "Lt" ] #@ "vfrelop"
  | V128Op.Le -> [ Term "Le" ] #@ "vfrelop"
  | V128Op.Gt -> [ Term "Gt" ] #@ "vfrelop"
  | V128Op.Ge -> [ Term "Ge" ] #@ "vfrelop"

let il_of_vrelop = il_of_vop il_of_int_vrelop il_of_float_vrelop

let il_of_vec = function
  | V128 v128 ->
    let symbols = [ Term "V128"; NT (il_of_vec128 v128) ] in
    symbols #@ "vec_"

let il_of_int_vunop : V128Op.iunop -> Lang.Il.value = function
  | V128Op.Abs -> [ Term "Abs" ] #@ "viunop"
  | V128Op.Neg -> [ Term "Neg" ] #@ "viunop"
  | V128Op.Popcnt -> [ Term "Popcnt" ] #@ "viunop"

let il_of_float_vunop : V128Op.funop -> Lang.Il.value = function
  | V128Op.Abs -> [ Term "Abs" ] #@ "vfunop"
  | V128Op.Neg -> [ Term "Neg" ] #@ "vfunop"
  | V128Op.Sqrt -> [ Term "Sqrt" ] #@ "vfunop"
  | V128Op.Ceil -> [ Term "Ceil" ] #@ "vfunop"
  | V128Op.Floor -> [ Term "Floor" ] #@ "vfunop"
  | V128Op.Trunc -> [ Term "Trunc" ] #@ "vfunop"
  | V128Op.Nearest -> [ Term "Nearest" ] #@ "vfunop"

let il_of_vunop = il_of_vop il_of_int_vunop il_of_float_vunop

let il_of_int_vbinop : V128Op.ibinop -> Lang.Il.value = function
  | V128Op.Add -> [ Term "Add" ] #@ "vibinop"
  | V128Op.Sub -> [ Term "Sub" ] #@ "vibinop"
  | V128Op.Mul -> [ Term "Mul" ] #@ "vibinop"
  | V128Op.MinS -> [ Term "MinS" ] #@ "vibinop"
  | V128Op.MinU -> [ Term "MinU" ] #@ "vibinop"
  | V128Op.MaxS -> [ Term "MaxS" ] #@ "vibinop"
  | V128Op.MaxU -> [ Term "MaxU" ] #@ "vibinop"
  | V128Op.AvgrU -> [ Term "AvgrU" ] #@ "vibinop"
  | V128Op.AddSatS -> [ Term "AddSatS" ] #@ "vibinop"
  | V128Op.AddSatU -> [ Term "AddSatU" ] #@ "vibinop"
  | V128Op.SubSatS -> [ Term "SubSatS" ] #@ "vibinop"
  | V128Op.SubSatU -> [ Term "SubSatU" ] #@ "vibinop"
  | V128Op.DotS -> [ Term "DotS" ] #@ "vibinop"
  | V128Op.Q15MulRSatS -> [ Term "Q15MulRSatS" ] #@ "vibinop"
  | V128Op.ExtMulLowS -> [ Term "ExtMulLowS" ] #@ "vibinop"
  | V128Op.ExtMulHighS -> [ Term "ExtMulHighS" ] #@ "vibinop"
  | V128Op.ExtMulLowU -> [ Term "ExtMulLowU" ] #@ "vibinop"
  | V128Op.ExtMulHighU -> [ Term "ExtMulHighU" ] #@ "vibinop"
  | V128Op.Swizzle -> [ Term "Swizzle" ] #@ "vibinop"
  | V128Op.Shuffle l ->
    let intv_list = List.map (fun i -> wrap_num_v_nat (bigint_of_nat i)) l in
    let symbols = [ Term "Shuffle"; NT (wrap_list_v_typed (NumT `NatT) intv_list) ] in
    symbols #@ "vibinop"
  | V128Op.NarrowS -> [ Term "NarrowS" ] #@ "vibinop"
  | V128Op.NarrowU -> [ Term "NarrowU" ] #@ "vibinop"
  | V128Op.RelaxedSwizzle -> [ Term "RelaxedSwizzle" ] #@ "vibinop"
  | V128Op.RelaxedQ15MulRS ->  [ Term "RelaxedQ15MulRS" ] #@ "vibinop"
  | V128Op.RelaxedDot -> [ Term "RelaxedDot" ] #@ "vibinop"

let il_of_float_vbinop : V128Op.fbinop -> Lang.Il.value = function
  | V128Op.Add -> [ Term "Add" ] #@ "vfbinop"
  | V128Op.Sub -> [ Term "Sub" ] #@ "vfbinop"
  | V128Op.Mul -> [ Term "Mul" ] #@ "vfbinop"
  | V128Op.Div -> [ Term "Div" ] #@ "vfbinop"
  | V128Op.Min -> [ Term "Min" ] #@ "vfbinop"
  | V128Op.Max -> [ Term "Max" ] #@ "vfbinop"
  | V128Op.Pmin -> [ Term "Pmin" ] #@ "vfbinop"
  | V128Op.Pmax -> [ Term "Pmax" ] #@ "vfbinop"
  | V128Op.RelaxedMin -> [ Term "RelaxedMin" ] #@ "vfbinop"
  | V128Op.RelaxedMax -> [ Term "RelaxedMax" ] #@ "vfbinop"

let il_of_vbinop = il_of_vop il_of_int_vbinop il_of_float_vbinop

let il_of_int i =
  wrap_num_v_int (bigint_of_z_int (Z.of_int i))

let il_of_int64 i64 =
  wrap_num_v_int (bigint_of_z_int (Z.of_int64_unsigned i64))

let il_of_void () =
  wrap_struct_v "void" []

let il_of_extension = function
  | Pack.SX -> [ Term "SX" ] #@ "extension"
  | Pack.ZX -> [ Term "ZX" ] #@ "extension"

let il_of_pack_shape = function
  | Pack.Pack8x8 -> [ Term "Pack8x8" ] #@ "packshape"
  | Pack.Pack16x4 -> [ Term "Pack16x4" ] #@ "packshape"
  | Pack.Pack32x2 -> [ Term "Pack32x2" ] #@ "packshape"

let il_of_vec_extension = function
  | Pack.ExtLane (shape, ext) ->
    let symbols = [ Term "ExtLane"; NT (il_of_pack_shape shape); NT (il_of_extension ext) ] in
    symbols #@ "vextension"
  | Pack.ExtSplat ->
    [ Term "ExtSplat" ] #@ "vextension"
  | Pack.ExtZero ->
    [ Term "ExtZero" ] #@ "vextension"

let il_of_initop = function
  | Explicit -> [ Term "Explicit" ] #@ "initop_"
  | Implicit -> [ Term "Implicit" ] #@ "initop_"

let il_of_externop = function
  | Internalize -> [ Term "Internalize" ] #@ "externop_"
  | Externalize -> [ Term "Externalize" ] #@ "externop_"

let il_of_block_type = function
  | VarBlockType idx ->
    let symbols = [ Term "VarBlockType"; NT (il_of_idx "typeidx" (idx.it $ no_region)) ] in
    symbols #@ "blocktype"
  | ValBlockType vt_opt ->
    let symbols = [ Term "ValBlockType"; NT (il_of_opt "valtype" il_of_val_type vt_opt) ] in
    symbols #@ "blocktype"

let il_of_catch catch =
  match catch.it with
  | Catch (idx1, idx2) ->
    let symbols = [ Term "Catch"; NT (il_of_idx "tagidx" (idx1.it $ no_region)); NT (il_of_idx "labelidx" (idx2.it $ no_region)) ] in
    symbols #@ "catch"
  | CatchRef (idx1, idx2) ->
    let symbols = [ Term "CatchRef"; NT (il_of_idx "tagidx" (idx1.it $ no_region)); NT (il_of_idx "labelidx" (idx2.it $ no_region)) ] in
    symbols #@ "catch"
  | CatchAll idx ->
    let symbols = [ Term "CatchAll"; NT (il_of_idx "labelidx" (idx.it $ no_region)) ] in
    symbols #@ "catch"
  | CatchAllRef idx ->
    let symbols = [ Term "CatchAllRef"; NT (il_of_idx "labelidx" (idx.it $ no_region)) ] in
    symbols #@ "catch"

let il_of_pack_type_memop = function
  | Pack.Pack8 -> [ Term "I8" ] #@ "packtype"
  | Pack.Pack16 -> [ Term "I16" ] #@ "packtype"
  | Pack.Pack32 -> [ Term "I32" ] #@ "packtype"
  | Pack.Pack64 -> [ Term "I64" ] #@ "packtype"

let il_of_loadop op =
  let open Util.Source in
  let vs = [ il_of_pack_type_memop Pack.Pack8; il_of_extension Pack.SX ] in
  let typs = List.map (fun (v: Lang.Il.value) -> v.note.typ $ no_region) vs in
  let default_pack = with_typ (TupleT typs) (TupleV vs) in
  let pack =
    match op.pack with
    | Some (pack, ext) ->
      let vs = [ il_of_pack_type_memop pack; il_of_extension ext ] in
      let typs = List.map (fun (v: Lang.Il.value) -> v.note.typ $ no_region) vs in
      let tuple = with_typ (TupleT typs) (TupleV vs) in
      with_typ (wrap_iter_t Opt tuple.note.typ) (OptV (Some tuple))
    | None ->
     with_typ (wrap_iter_t Opt default_pack.note.typ) (OptV None)
  in
  wrap_struct_v "loadop_" [
    (wrap_atom "TYPE", il_of_num_type op.ty);
    (wrap_atom "ALIGN", il_of_int op.align);
    (wrap_atom "OFFSET", il_of_int64 op.offset);
    (wrap_atom "PACK", pack); ]

let il_of_storeop op =
  let pack = il_of_opt "packtype" il_of_pack_type_memop op.pack in
  wrap_struct_v "storeop_" [
    (wrap_atom "TYPE", il_of_num_type op.ty);
    (wrap_atom "ALIGN", il_of_int op.align);
    (wrap_atom "OFFSET", il_of_int64 op.offset);
    (wrap_atom "PACK", pack); ]

let il_of_vec_loadop op =
  let open Util.Source in
  let vs = [ il_of_pack_type_memop Pack.Pack8; il_of_vec_extension Pack.ExtSplat ] in
  let typs = List.map (fun (v: Lang.Il.value) -> v.note.typ $ no_region) vs in
  let default_pack = with_typ (TupleT typs) (TupleV vs) in
  let pack =
    match op.pack with
    | Some (pack, ext) ->
      let vs = [ il_of_pack_type_memop pack; il_of_vec_extension ext ] in
      let typs = List.map (fun (v: Lang.Il.value) -> v.note.typ $ no_region) vs in
      let tuple = with_typ (TupleT typs) (TupleV vs) in
      with_typ (wrap_iter_t Opt tuple.note.typ) (OptV (Some tuple))
    | None ->
      with_typ (wrap_iter_t Opt default_pack.note.typ) (OptV None)

  in
  wrap_struct_v "vloadop_" [
    (wrap_atom "TYPE", il_of_vec_type op.ty);
    (wrap_atom "ALIGN", il_of_int op.align);
    (wrap_atom "OFFSET", il_of_int64 op.offset);
    (wrap_atom "PACK", pack); ]

let il_of_vec_storeop op =
  wrap_struct_v "vstoreop_" [
    (wrap_atom "TYPE", il_of_vec_type op.ty);
    (wrap_atom "ALIGN", il_of_int op.align);
    (wrap_atom "OFFSET", il_of_int64 op.offset);
    (wrap_atom "PACK", il_of_void ()); ]

let il_of_vec_laneop op =
  wrap_struct_v "vlaneop_" [
    (wrap_atom "TYPE", il_of_vec_type op.ty);
    (wrap_atom "ALIGN", il_of_int op.align);
    (wrap_atom "OFFSET", il_of_int64 op.offset);
    (wrap_atom "PACK", il_of_pack_type_memop op.pack); ]

let il_of_int_vternop : V128Op.iternop -> Lang.Il.value = function
  | V128Op.RelaxedLaneselect -> [ Term "RelaxedLaneselect" ] #@ "viternop"
  | V128Op.RelaxedDotAdd -> [ Term "RelaxedDotAdd" ] #@ "viternop"

let il_of_float_vternop : V128Op.fternop -> Lang.Il.value = function
  | V128Op.RelaxedMadd -> [ Term "RelaxedMadd" ] #@ "vfternop"
  | V128Op.RelaxedNmadd -> [ Term "RelaxedNmadd" ] #@ "vfternop"

let il_of_vternop = il_of_vop il_of_int_vternop il_of_float_vternop

let il_of_int_vcvtop : V128Op.icvtop -> Lang.Il.value = function
  | V128Op.ExtendLowS -> [ Term "ExtendLowS" ] #@ "vicvtop"
  | V128Op.ExtendLowU -> [ Term "ExtendLowU" ] #@ "vicvtop"
  | V128Op.ExtendHighS -> [ Term "ExtendHighS" ] #@ "vicvtop"
  | V128Op.ExtendHighU -> [ Term "ExtendHighU" ] #@ "vicvtop"
  | V128Op.ExtAddPairwiseS -> [ Term "ExtAddPairwiseS" ] #@ "vicvtop"
  | V128Op.ExtAddPairwiseU -> [ Term "ExtAddPairwiseU" ] #@ "vicvtop"
  | V128Op.TruncSatSF32x4 -> [ Term "TruncSatSF32x4" ] #@ "vicvtop"
  | V128Op.TruncSatUF32x4 -> [ Term "TruncSatUF32x4" ] #@ "vicvtop"
  | V128Op.TruncSatSZeroF64x2 -> [ Term "TruncSatSZeroF64x2" ] #@ "vicvtop"
  | V128Op.TruncSatUZeroF64x2 -> [ Term "TruncSatUZeroF64x2" ] #@ "vicvtop"
  | V128Op.RelaxedTruncSF32x4 -> [ Term "RelaxedTruncSF32x4" ] #@ "vicvtop"
  | V128Op.RelaxedTruncUF32x4 -> [ Term "RelaxedTruncUF32x4" ] #@ "vicvtop"
  | V128Op.RelaxedTruncSZeroF64x2 -> [ Term "RelaxedTruncSZeroF64x2" ] #@ "vicvtop"
  | V128Op.RelaxedTruncUZeroF64x2 -> [ Term "RelaxedTruncUZeroF64x2" ] #@ "vicvtop"

let il_of_float_vcvtop : V128Op.fcvtop -> Lang.Il.value = function
  | V128Op.DemoteZeroF64x2 -> [ Term "DemoteZeroF64x2" ] #@ "vfcvtop"
  | V128Op.PromoteLowF32x4 -> [ Term "PromoteLowF32x4" ] #@ "vfcvtop"
  | V128Op.ConvertSI32x4 -> [ Term "ConvertSI32x4" ] #@ "vfcvtop"
  | V128Op.ConvertUI32x4 -> [ Term "ConvertUI32x4" ] #@ "vfcvtop"

let il_of_vcvtop = il_of_vop il_of_int_vcvtop il_of_float_vcvtop

let il_of_int_vshiftop : V128Op.ishiftop -> Lang.Il.value = function
  | V128Op.Shl -> [ Term "Shl" ] #@ "vishiftop"
  | V128Op.ShrS -> [ Term "ShrS" ] #@ "vishiftop"
  | V128Op.ShrU -> [ Term "ShrU" ] #@ "vishiftop"

let il_of_float_vshiftop : Ast.void -> Lang.Il.value = function
  | _ -> .

let il_of_vshiftop = il_of_vop ~vflag:true il_of_int_vshiftop il_of_float_vshiftop

let il_of_int_vbitmaskop : V128Op.ibitmaskop -> Lang.Il.value = function
  | V128Op.Bitmask -> [ Term "Bitmask" ] #@ "vibitmaskop"

let il_of_float_vbitmaskop : Ast.void -> Lang.Il.value = function
  | _ -> .

let il_of_vbitmaskop = il_of_vop ~vflag:true il_of_int_vbitmaskop il_of_float_vbitmaskop

let il_of_vvtestop = function
  | V128 V128Op.AnyTrue ->
    let symbols = [ Term "V128"; NT ([ Term "AnyTrue" ] #@ "vvtestop") ] in
    symbols #@ "vvtestop_"

let il_of_vvunop = function
  | V128 V128Op.Not ->
    let symbols = [ Term "V128"; NT ([ Term "Not" ] #@ "vvunop") ] in
    symbols #@ "vvunop_"

let il_of_vvbinop = function
  | V128 V128Op.And ->
    let symbols = [ Term "V128"; NT ([ Term "And" ] #@ "vvbinop") ] in
    symbols #@ "vvbinop_"
  | V128 V128Op.Or ->
    let symbols = [ Term "V128"; NT ([ Term "Or" ] #@ "vvbinop") ] in
    symbols #@ "vvbinop_"
  | V128 V128Op.Xor ->
    let symbols = [ Term "V128"; NT ([ Term "Xor" ] #@ "vvbinop") ] in
    symbols #@ "vvbinop_"
  | V128 V128Op.AndNot ->
    let symbols = [ Term "V128"; NT ([ Term "AndNot" ] #@ "vvbinop") ] in
    symbols #@ "vvbinop_"

let il_of_vvternop = function
  | V128 V128Op.Bitselect ->
    let symbols = [ Term "V128"; NT ([ Term "Bitselect" ] #@ "vvternop") ] in
    symbols #@ "vvternop_"

let il_of_vnsplatop : V128Op.nsplatop -> Lang.Il.value = function
  | V128Op.Splat -> [ Term "Splat" ] #@ "vnsplatop"

let il_of_vsplatop = il_of_vop il_of_vnsplatop il_of_vnsplatop

let il_of_int_vnextractop : Pack.extension V128Op.nextractop -> Lang.Il.value = function
  | V128Op.Extract (i, ext) ->
    let open Util.Source in
    let vs = [ (il_of_int i); (il_of_extension ext) ] in
    let typs = List.map (fun (v: Lang.Il.value) -> v.note.typ $ no_region) vs in
    let symbols = [ Term "Extract"; NT (with_typ (TupleT typs) (TupleV vs)) ] in
    symbols #@ "vnextractop"

let il_of_float_vnextractop : unit V128Op.nextractop -> Lang.Il.value = function
  | V128Op.Extract (i, _) ->
    let open Util.Source in
    let vs = [ (il_of_int i); (il_of_void ()) ] in
    let typs = List.map (fun (v: Lang.Il.value) -> v.note.typ $ no_region) vs in
    let symbols = [ Term "Extract"; NT (with_typ (TupleT typs) (TupleV vs)) ] in
    symbols #@ "vnextractop"

let il_of_vextractop = function
  | V128 (V128.I8x16 op) ->
    let symbols = [ Term "V128"; NT ([ Term "I8x16"; NT (il_of_int_vnextractop op) ] #@ "vextractop") ] in
    symbols #@ "vextractop_"
  | V128 (V128.I16x8 op) ->
    let symbols = [ Term "V128"; NT ([ Term "I16x8"; NT (il_of_int_vnextractop op) ] #@ "vextractop") ] in
    symbols #@ "vextractop_"
  | V128 (V128.I32x4 op) ->
    let symbols = [ Term "V128"; NT ([ Term "I32x4"; NT (il_of_float_vnextractop op) ] #@ "vextractop") ] in
    symbols #@ "vextractop_"
  | V128 (V128.I64x2 op) ->
    let symbols = [ Term "V128"; NT ([ Term "I64x2"; NT (il_of_float_vnextractop op) ] #@ "vextractop") ] in
    symbols #@ "vextractop_"
  | V128 (V128.F32x4 op) ->
    let symbols = [ Term "V128"; NT ([ Term "F32x4"; NT (il_of_float_vnextractop op) ] #@ "vextractop") ] in
    symbols #@ "vextractop_"
  | V128 (V128.F64x2 op) ->
    let symbols = [ Term "V128"; NT ([ Term "F64x2"; NT (il_of_float_vnextractop op) ] #@ "vextractop") ] in
    symbols #@ "vextractop_"

let il_of_vnreplaceop : V128Op.nreplaceop -> Lang.Il.value = function
  | V128Op.Replace i ->
    let symbols = [ Term "Replace"; NT (il_of_int i) ] in
    symbols #@ "vnreplaceop"

let il_of_vreplaceop = il_of_vop il_of_vnreplaceop il_of_vnreplaceop

let il_of_select_type_opt = function
  | Some vtl ->
    let valtype_list_typ = wrap_iter_t List (wrap_var_t "valtype") in
    let v = il_of_list "valtype" il_of_val_type vtl in
    with_typ (wrap_iter_t Opt valtype_list_typ) (OptV (Some v))
  | None ->
    let valtype_list_typ = wrap_iter_t List (wrap_var_t "valtype") in
    with_typ (wrap_iter_t Opt valtype_list_typ) (OptV (None))

let rec il_of_instr instr =
  match instr.it with
  | Unreachable ->
    [ Term "UNREACHABLE" ] #@ "instr"
  | Nop ->
    [ Term "NOP" ] #@ "instr"
  | Drop ->
    [ Term "DROP" ] #@ "instr"
  | Select vt_opt ->
    let symbols = [ Term "SELECT"; NT (il_of_select_type_opt vt_opt) ] in
    symbols #@ "instr"
  | Block (bt, instrs) ->
    let symbols = [ Term "BLOCK"; NT (il_of_block_type bt); NT (il_of_list "instr" il_of_instr instrs) ] in
    symbols #@ "instr"
  | Loop (bt, instrs) ->
    let symbols = [ Term "LOOP"; NT (il_of_block_type bt); NT (il_of_list "instr" il_of_instr instrs) ] in
    symbols #@ "instr"
  | If (bt, instrs1, instrs2) ->
    let symbols = [ Term "IF"; NT (il_of_block_type bt); NT (il_of_list "instr" il_of_instr instrs1); Term "ELSE"; NT (il_of_list "instr" il_of_instr instrs2) ] in
    symbols #@ "instr"
  | Br idx ->
    let symbols = [ Term "BR"; NT (il_of_idx "labelidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | BrIf idx ->
    let symbols = [ Term "BR_IF"; NT (il_of_idx "labelidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | BrTable (idxl, idx) ->
    let symbols = [ Term "BR_TABLE"; NT (il_of_list "labelidx" (fun i -> il_of_idx "labelidx" (i.it $ no_region)) idxl); NT (il_of_idx "labelidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | BrOnNull idx ->
    let symbols = [ Term "BR_ON_NULL"; NT (il_of_idx "labelidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | BrOnNonNull idx ->
    let symbols = [ Term "BR_ON_NON_NULL"; NT (il_of_idx "labelidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | BrOnCast (idx, rt1, rt2) ->
    let symbols = [ Term "BR_ON_CAST"; NT (il_of_idx "labelidx" (idx.it $ no_region)); NT (il_of_ref_type rt1); NT (il_of_ref_type rt2) ] in
    symbols #@ "instr"
  | BrOnCastFail (idx, rt1, rt2) ->
    let symbols = [ Term "BR_ON_CAST_FAIL"; NT (il_of_idx "labelidx" (idx.it $ no_region)); NT (il_of_ref_type rt1); NT (il_of_ref_type rt2) ] in
    symbols #@ "instr"
  | Return ->
    [ Term "RETURN" ] #@ "instr"
  | Call idx ->
    let symbols = [ Term "CALL"; NT (il_of_idx "funcidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | CallRef idx ->
    let symbols = [ Term "CALL_REF"; NT (il_of_idx "typeidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | CallIndirect (idx1, idx2) ->
    let symbols = [ Term "CALL_INDIRECT"; NT (il_of_idx "tableidx" (idx1.it $ no_region)); NT (il_of_idx "typeidx" (idx2.it $ no_region)) ] in
    symbols #@ "instr"
  | ReturnCall idx ->
    let symbols = [ Term "RETURN_CALL"; NT (il_of_idx "funcidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | ReturnCallRef idx ->
    let symbols = [ Term "RETURN_CALL_REF"; NT (il_of_idx "typeidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | ReturnCallIndirect (idx1, idx2) ->
    let symbols = [ Term "RETURN_CALL_INDIRECT"; NT (il_of_idx "tableidx" (idx1.it $ no_region)); NT (il_of_idx "typeidx" (idx2.it $ no_region)) ] in
    symbols #@ "instr"
  | Throw idx ->
    let symbols = [ Term "THROW"; NT (il_of_idx "tagidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | ThrowRef ->
    [ Term "THROW_REF" ] #@ "instr"
  | TryTable (bt, catches, instrs) ->
    let symbols = [ Term "TRY_TABLE"; NT (il_of_block_type bt); NT (il_of_list "catch" il_of_catch catches); NT (il_of_list "instr" il_of_instr instrs) ] in
    symbols #@ "instr"
  | LocalGet idx ->
    let symbols = [ Term "LOCAL.GET"; NT (il_of_idx "localidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | LocalSet idx ->
    let symbols = [ Term "LOCAL.SET"; NT (il_of_idx "localidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | LocalTee idx ->
    let symbols = [ Term "LOCAL.TEE"; NT (il_of_idx "localidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | GlobalGet idx ->
    let symbols = [ Term "GLOBAL.GET"; NT (il_of_idx "globalidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | GlobalSet idx ->
    let symbols = [ Term "GLOBAL.SET"; NT (il_of_idx "globalidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | TableGet idx ->
    let symbols = [ Term "TABLE.GET"; NT (il_of_idx "tableidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | TableSet idx ->
    let symbols = [ Term "TABLE.SET"; NT (il_of_idx "tableidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | TableSize idx ->
    let symbols = [ Term "TABLE.SIZE"; NT (il_of_idx "tableidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | TableGrow idx ->
    let symbols = [ Term "TABLE.GROW"; NT (il_of_idx "tableidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | TableFill idx ->
    let symbols = [ Term "TABLE.FILL"; NT (il_of_idx "tableidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | TableCopy (idx1, idx2) ->
    let symbols = [ Term "TABLE.COPY"; NT (il_of_idx "tableidx" (idx1.it $ no_region)); NT (il_of_idx "tableidx" (idx2.it $ no_region)) ] in
    symbols #@ "instr"
  | TableInit (idx1, idx2) ->
    let symbols = [ Term "TABLE.INIT"; NT (il_of_idx "tableidx" (idx1.it $ no_region)); NT (il_of_idx "elemidx" (idx2.it $ no_region)) ] in
    symbols #@ "instr"
  | ElemDrop idx ->
    let symbols = [ Term "ELEM.DROP"; NT (il_of_idx "elemidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | Load (idx, loadop) ->
    let symbols = [ Term "LOAD"; NT (il_of_idx "memidx" (idx.it $ no_region)); NT (il_of_loadop loadop) ] in
    symbols #@ "instr"
  | Store (idx, storeop) ->
    let symbols = [ Term "STORE"; NT (il_of_idx "memidx" (idx.it $ no_region)); NT (il_of_storeop storeop) ] in
    symbols #@ "instr"
  | VecLoad (idx, vloadop) ->
    let symbols = [ Term "VEC.LOAD"; NT (il_of_idx "memidx" (idx.it $ no_region)); NT (il_of_vec_loadop vloadop) ] in
    symbols #@ "instr"
  | VecStore (idx, vstoreop) ->
    let symbols = [ Term "VEC.STORE"; NT (il_of_idx "memidx" (idx.it $ no_region)); NT (il_of_vec_storeop vstoreop) ] in
    symbols #@ "instr"
  | VecLoadLane (idx, vlaneop, i) ->
    let symbols = [ Term "VEC.LOAD_LANE"; NT (il_of_idx "memidx" (idx.it $ no_region)); NT (il_of_vec_laneop vlaneop); NT (il_of_int i) ] in
    symbols #@ "instr"
  | VecStoreLane (idx, vlaneop, i) ->
    let symbols = [ Term "VEC.STORE_LANE"; NT (il_of_idx "memidx" (idx.it $ no_region)); NT (il_of_vec_laneop vlaneop); NT (il_of_int i) ] in
    symbols #@ "instr"
  | MemorySize idx ->
    let symbols = [ Term "MEMORY.SIZE"; NT (il_of_idx "memidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | MemoryGrow idx ->
    let symbols = [ Term "MEMORY.GROW"; NT (il_of_idx "memidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | MemoryFill idx ->
    let symbols = [ Term "MEMORY.FILL"; NT (il_of_idx "memidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | MemoryCopy (idx1, idx2) ->
    let symbols = [ Term "MEMORY.COPY"; NT (il_of_idx "memidx" (idx1.it $ no_region)); NT (il_of_idx "memidx" (idx2.it $ no_region)) ] in
    symbols #@ "instr"
  | MemoryInit (idx1, idx2) ->
    let symbols = [ Term "MEMORY.INIT"; NT (il_of_idx "memidx" (idx1.it $ no_region)); NT (il_of_idx "dataidx" (idx2.it $ no_region)) ] in
    symbols #@ "instr"
  | DataDrop idx ->
    let symbols = [ Term "DATA.DROP"; NT (il_of_idx "dataidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | RefNull ht ->
    let symbols = [ Term "REF.NULL"; NT (il_of_heap_type ht) ] in
    symbols #@ "instr"
  | RefFunc idx ->
    let symbols = [ Term "REF.FUNC"; NT (il_of_idx "funcidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | RefIsNull ->
    [ Term "REF.IS_NULL" ] #@ "instr"
  | RefAsNonNull ->
    [ Term "REF.AS_NON_NULL" ] #@ "instr"
  | RefTest rt ->
    let symbols = [ Term "REF.TEST"; NT (il_of_ref_type rt) ] in
    symbols #@ "instr"
  | RefCast rt ->
    let symbols = [ Term "REF.CAST"; NT (il_of_ref_type rt) ] in
    symbols #@ "instr"
  | RefEq ->
    [ Term "REF.EQ" ] #@ "instr"
  | RefI31 ->
    [ Term "REF.I31" ] #@ "instr"
  | I31Get ext ->
    let symbols = [ Term "I31.GET"; NT (il_of_extension ext) ] in
    symbols #@ "instr"
  | StructNew (idx, initop) ->
    let symbols = [ Term "STRUCT.NEW"; NT (il_of_idx "typeidx" (idx.it $ no_region)); NT (il_of_initop initop) ] in
    symbols #@ "instr"
  | StructGet (idx1, idx2, ext_opt) ->
    let symbols = [ Term "STRUCT.GET"; NT (il_of_idx "typeidx" (idx1.it $ no_region)); NT (il_of_idx "typeidx" (idx2.it $ no_region)); NT (il_of_opt "extension" il_of_extension ext_opt) ] in
    symbols #@ "instr"
  | StructSet (idx1, idx2) ->
    let symbols = [ Term "STRUCT.SET"; NT (il_of_idx "typeidx" (idx1.it $ no_region)); NT (il_of_idx "typeidx" (idx2.it $ no_region)) ] in
    symbols #@ "instr"
  | ArrayNew (idx, initop) ->
    let symbols = [ Term "ARRAY.NEW"; NT (il_of_idx "typeidx" (idx.it $ no_region)); NT (il_of_initop initop) ] in
    symbols #@ "instr"
  | ArrayNewFixed (idx, n) ->
    let symbols = [ Term "ARRAY.NEW_FIXED"; NT (il_of_idx "typeidx" (idx.it $ no_region)); NT (wrap_num_v_nat (bigint_of_nat32 n)) ] in
    symbols #@ "instr"
  | ArrayNewElem (idx1, idx2) ->
    let symbols = [ Term "ARRAY.NEW_ELEM"; NT (il_of_idx "typeidx" (idx1.it $ no_region)); NT (il_of_idx "elemidx" (idx2.it $ no_region)) ] in
    symbols #@ "instr"
  | ArrayNewData (idx1, idx2) ->
    let symbols = [ Term "ARRAY.NEW_DATA"; NT (il_of_idx "typeidx" (idx1.it $ no_region)); NT (il_of_idx "dataidx" (idx2.it $ no_region)) ] in
    symbols #@ "instr"
  | ArrayGet (idx, ext_opt) ->
    let symbols = [ Term "ARRAY.GET"; NT (il_of_idx "typeidx" (idx.it $ no_region)); NT (il_of_opt "extension" il_of_extension ext_opt) ] in
    symbols #@ "instr"
  | ArraySet idx ->
    let symbols = [ Term "ARRAY.SET"; NT (il_of_idx "typeidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | ArrayLen ->
    [ Term "ARRAY.LEN" ] #@ "instr"
  | ArrayCopy (idx1, idx2) ->
    let symbols = [ Term "ARRAY.COPY"; NT (il_of_idx "typeidx" (idx1.it $ no_region)); NT (il_of_idx "typeidx" (idx2.it $ no_region)) ] in
    symbols #@ "instr"
  | ArrayFill idx ->
    let symbols = [ Term "ARRAY.FILL"; NT (il_of_idx "typeidx" (idx.it $ no_region)) ] in
    symbols #@ "instr"
  | ArrayInitData (idx1, idx2) ->
    let symbols = [ Term "ARRAY.INIT_DATA"; NT (il_of_idx "typeidx" (idx1.it $ no_region)); NT (il_of_idx "dataidx" (idx2.it $ no_region)) ] in
    symbols #@ "instr"
  | ArrayInitElem (idx1, idx2) ->
    let symbols = [ Term "ARRAY.INIT_ELEM"; NT (il_of_idx "typeidx" (idx1.it $ no_region)); NT (il_of_idx "elemidx" (idx2.it $ no_region)) ] in
    symbols #@ "instr"
  | ExternConvert op ->
    let symbols = [ Term "EXTERN.CONVERT"; NT (il_of_externop op) ] in
    symbols #@ "instr"
  | Const num ->
    let symbols = [ Term "CONST"; NT (il_of_num num.it) ] in
    symbols #@ "instr"
  | Test op ->
    let symbols = [ Term "TEST"; NT (il_of_testop op) ] in
    symbols #@ "instr"
  | Compare op ->
    let symbols = [ Term "COMPARE"; NT (il_of_relop op) ] in
    symbols #@ "instr"
  | Unary op ->
    let symbols = [ Term "UNARY"; NT (il_of_unop op) ] in
    symbols #@ "instr"
  | Binary op ->
    let symbols = [ Term "BINOP"; NT (il_of_binop op) ] in
    symbols #@ "instr"
  | Convert op ->
    let symbols = [ Term "CONVERT"; NT (il_of_cvtop op) ] in
    symbols #@ "instr"
  | VecConst vec ->
    let symbols = [ Term "VEC.CONST"; NT (il_of_vec vec.it) ] in
    symbols #@ "instr"
  | VecTest vop ->
    let symbols = [ Term "VEC.TEST"; NT (il_of_vtestop vop) ] in
    symbols #@ "instr"
  | VecUnary vop ->
    let symbols = [ Term "VEC.UNARY"; NT (il_of_vunop vop) ] in
    symbols #@ "instr"
  | VecBinary vop ->
    let symbols = [ Term "VEC.BINARY"; NT (il_of_vbinop vop) ] in
    symbols #@ "instr"
  | VecCompare vop ->
    let symbols = [ Term "VEC.COMPARE"; NT (il_of_vrelop vop) ] in
    symbols #@ "instr"
  | VecTernary vop ->
    let symbols = [ Term "VEC.TERNARY"; NT (il_of_vternop vop) ] in
    symbols #@ "instr"
  | VecConvert vop ->
    let symbols = [ Term "VEC.CONVERT"; NT (il_of_vcvtop vop) ] in
    symbols #@ "instr"
  | VecShift vop ->
    let symbols = [ Term "VEC.SHIFT"; NT (il_of_vshiftop vop) ] in
    symbols #@ "instr"
  | VecBitmask vop ->
    let symbols = [ Term "VEC.BITMASK"; NT (il_of_vbitmaskop vop) ] in
    symbols #@ "instr"
  | VecTestBits vop ->
    let symbols = [ Term "VEC.TESTBITS"; NT (il_of_vvtestop vop) ] in
    symbols #@ "instr"
  | VecUnaryBits vop ->
    let symbols = [ Term "VEC.UNARYBITS"; NT (il_of_vvunop vop) ] in
    symbols #@ "instr"
  | VecBinaryBits vop ->
    let symbols = [ Term "VEC.BINARYBITS"; NT (il_of_vvbinop vop) ] in
    symbols #@ "instr"
  | VecTernaryBits vop ->
    let symbols = [ Term "VEC.TERNARYBITS"; NT (il_of_vvternop vop) ] in
    symbols #@ "instr"
  | VecSplat vop ->
    let symbols = [ Term "VEC.SPLAT"; NT (il_of_vsplatop vop) ] in
    symbols #@ "instr"
  | VecExtract vop ->
    let symbols = [ Term "VEC.EXTRACT"; NT (il_of_vextractop vop) ] in
    symbols #@ "instr"
  | VecReplace vop ->
    let symbols = [ Term "VEC.REPLACE"; NT (il_of_vreplaceop vop) ] in
    symbols #@ "instr"

let il_of_const const =
    il_of_list "instr" il_of_instr const.it
(* Construct module *)

let il_of_type type_ =
  il_of_rec_type type_.it

let il_of_global global =
  wrap_struct_v "global" [
    (wrap_atom "GTYPE", il_of_global_type global.it.gtype);
    (wrap_atom "GINIT", il_of_const global.it.ginit); ]

let il_of_table table =
  wrap_struct_v "table" [
    (wrap_atom "TTYPE", il_of_table_type table.it.ttype);
    (wrap_atom "TINIT", il_of_const table.it.tinit); ]

let il_of_memory memory =
  wrap_struct_v "memory" [
    (wrap_atom "MTYPE", il_of_memory_type memory.it.mtype) ]

let il_of_tag tag =
  wrap_struct_v "tag" [
    (wrap_atom "TGTYPE", il_of_idx "typeidx" tag.it.tgtype) ]

let il_of_local local =
  wrap_struct_v "local" [
    (wrap_atom "LTYPE", il_of_val_type local.it.ltype) ]

let il_of_func func =
  wrap_struct_v "func" [
    (wrap_atom "FTYPE", il_of_idx "typeidx" func.it.ftype);
    (wrap_atom "LOCALS", il_of_list "local" il_of_local func.it.locals);
    (wrap_atom "BODY", il_of_list "instr" il_of_instr func.it.body); ]

let il_of_start start =
  wrap_struct_v "start" [
    (wrap_atom "SFUNC", il_of_idx "funcidx" start.it.sfunc) ]

let il_of_segment segment =
  match segment.it with
  | Passive ->
    [ Term "Passive" ] #@ "segmentmode"
  | Active { index; offset } ->
    let symbols =
      [ Term "Active"; NT (wrap_struct_v "active" [(wrap_atom "INDEX", wrap_num_v_nat (bigint_of_nat32 index.it)); (wrap_atom "OFFSET", il_of_const offset)]) ] in
    symbols #@ "segmentmode"
  | Declarative ->
    [ Term "Declarative" ] #@ "segmentmode"

let il_of_elem elem =
  wrap_struct_v "elem" [
    (wrap_atom "ETYPE", il_of_ref_type elem.it.etype);
    (wrap_atom "EINIT", il_of_list "const" il_of_const elem.it.einit);
    (wrap_atom "EMODE", il_of_segment elem.it.emode); ]

let il_of_data data =
  wrap_struct_v "data" [
    (wrap_atom "DINIT", wrap_text_v data.it.dinit);
    (wrap_atom "DMODE", il_of_segment data.it.dmode); ]

let il_of_import_desc _ idesc =
  match idesc.it with
  | FuncImport x ->
    let symbols = [ Term "FuncImport"; NT (il_of_idx "typeidx" x) ] in
    symbols #@ "importdesc"
  | TableImport tt ->
    let symbols = [ Term "TableImport"; NT (il_of_table_type tt) ] in
    symbols #@ "importdesc"
  | MemoryImport mt ->
    let symbols = [ Term "MemImport"; NT (il_of_memory_type mt) ] in
    symbols #@ "importdesc"
  | GlobalImport gt ->
    let symbols = [ Term "GlobalImport"; NT (il_of_global_type gt) ] in
    symbols #@ "importdesc"
  | TagImport x ->
    let symbols = [ Term "TagImport"; NT (il_of_idx "typeidx" x) ] in
    symbols #@ "importdesc"

let il_of_import module_ import =
  wrap_struct_v "import" [
    (wrap_atom "MODULENAME", il_of_name import.it.module_name);
    (wrap_atom "ITEMNAME", il_of_name import.it.item_name);
    (wrap_atom "IDESC", il_of_import_desc module_ import.it.idesc); ]

let il_of_export_desc export_desc =
  match export_desc.it with
  | FuncExport idx ->
    let symbols = [ Term "FuncExport"; NT (il_of_idx "funcidx" idx) ] in
    symbols #@ "exportdesc"
  | TableExport idx ->
    let symbols = [ Term "TableExport"; NT (il_of_idx "tableidx" idx) ] in
    symbols #@ "exportdesc"
  | MemoryExport idx ->
    let symbols = [ Term "MemExport"; NT (il_of_idx "memidx" idx) ] in
    symbols #@ "exportdesc"
  | GlobalExport idx ->
    let symbols = [ Term "GlobalExport"; NT (il_of_idx "globalidx" idx) ] in
    symbols #@ "exportdesc"
  | TagExport idx ->
    let symbols = [ Term "TagExport"; NT (il_of_idx "tagidx" idx) ] in
    symbols #@ "exportdesc"

let il_of_export export =
  wrap_struct_v "export" [
    (wrap_atom "NAME", il_of_name export.it.name);
    (wrap_atom "EDESC", il_of_export_desc export.it.edesc); ]

let il_of_module module_ : Lang.Il.value =
  wrap_struct_v "module" [
    (wrap_atom "TYPES", il_of_list "type" il_of_type module_.it.types);
    (wrap_atom "GLOBALS", il_of_list "global" il_of_global module_.it.globals);
    (wrap_atom "TABLES", il_of_list "table" il_of_table module_.it.tables);
    (wrap_atom "MEMS", il_of_list "memory" il_of_memory module_.it.memories);
    (wrap_atom "TAGS", il_of_list "tag" il_of_tag module_.it.tags);
    (wrap_atom "FUNCS", il_of_list "func" il_of_func module_.it.funcs);
    (wrap_atom "START", il_of_opt "start" il_of_start module_.it.start);
    (wrap_atom "ELEMS", il_of_list "elem" il_of_elem module_.it.elems);
    (wrap_atom "DATAS", il_of_list "data" il_of_data module_.it.datas);
    (wrap_atom "IMPORTS", il_of_list "import" (il_of_import module_) module_.it.imports);
    (wrap_atom "EXPORTS", il_of_list "export" il_of_export module_.it.exports);
  ]
