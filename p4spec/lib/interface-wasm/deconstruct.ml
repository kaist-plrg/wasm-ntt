module Value = Runtime.Value
module Ast = Wasm_interpreter.Ast
module Types = Wasm_interpreter.Types
module Wasm_Value = Wasm_interpreter.Value
module Pack = Wasm_interpreter.Pack
module I32 = Wasm_interpreter.I32
module I64 = Wasm_interpreter.I64
module F32 = Wasm_interpreter.F32
module F64 = Wasm_interpreter.F64
module V128 = Wasm_interpreter.V128

module Unwrap = struct
  let unwrap_list_v = Value.Get.list
  let unwrap_opt_v = Value.Get.opt
  let unwrap_num_v value = Value.Get.num value |> Lang.Xl.Num.to_int
  let unwrap_tuple_v_two value = value |> Value.Get.tuple |> Value.Get.two
  let unwrap_text_v = Value.Get.text
end

let sl_case (value : Value.t) =
  match value.it with
  | CaseV valuecase ->
      Some (Domain.Mixfix.atoms_matrix valuecase, Domain.Mixfix.args valuecase)
  | _ -> None

let sl_to_phrase (f : Value.t -> 'a) (v : Value.t) : 'a Wasm_interpreter.Source.phrase =
  Wasm_interpreter.Source.((f v) @@ no_region)

let sl_to_list (f: Value.t -> 'a) (v: Value.t) : 'a list =
  Unwrap.unwrap_list_v v |> List.map f

let sl_to_opt (f: Value.t -> 'a) (v: Value.t) : 'a option =
  Unwrap.unwrap_opt_v v |> Option.map f

let is_heap_type_tag (tag: string) : bool =
  match tag with
  | "AnyHT" | "NoneHT" | "EqHT" | "I31HT"
  | "StructHT" | "ArrayHT" | "FuncHT" | "NoFuncHT"
  | "ExnHT" | "NoExnHT" | "ExternHT" | "NoExternHT" | "BotHT" -> true
  | _ -> false

let heap_type_of_tag (tag: string) : Types.heap_type =
  match tag with
  | "AnyHT" -> AnyHT
  | "NoneHT" -> NoneHT
  | "EqHT" -> EqHT
  | "I31HT" -> I31HT
  | "StructHT" -> StructHT
  | "ArrayHT" -> ArrayHT
  | "FuncHT" -> FuncHT
  | "NoFuncHT" -> NoFuncHT
  | "ExnHT" -> ExnHT
  | "NoExnHT" -> NoExnHT
  | "ExternHT" -> ExternHT
  | "NoExternHT" -> NoExternHT
  | "BotHT" -> BotHT
  | _ -> failwith "unknown heap type tag"

let sl_to_z_nat (value: Value.t) : Z.t =  Unwrap.unwrap_num_v value |> Bigint.to_zarith_bigint

let sl_to_z_int (value: Value.t) : Z.t = Unwrap.unwrap_num_v value |> Bigint.to_zarith_bigint

let z_to_intN signed unsigned z = if z < Z.zero then signed z else unsigned z

let sl_to_nat (value: Value.t) : int = sl_to_z_nat value |> Z.to_int
let sl_to_nat32 (value: Value.t) : I32.t = sl_to_z_nat value |> z_to_intN Z.to_int32 Z.to_int32_unsigned
let sl_to_nat64 (value: Value.t) : I64.t = sl_to_z_nat value |> z_to_intN Z.to_int64 Z.to_int64_unsigned

type layout = { width : int; exponent : int; mantissa : int }
let layout32 = { width = 32; exponent = 8; mantissa = 23 }
let layout64 = { width = 64; exponent = 11; mantissa = 52 }

let mask_sign (layout: layout) : Z.t =
  Z.shift_left Z.one (layout.width - 1)

let mask_mag (layout: layout) : Z.t = Z.pred (mask_sign layout)

let mask_mant (layout: layout) : Z.t = Z.(pred (shift_left one layout.mantissa))

let mask_exp (layout: layout) : Z.t = Z.(mask_mag layout - mask_mant layout)
let bias (layout: layout) : Z.t = let em1 = layout.exponent - 1 in Z.((one + one)**em1 - one)

let sl_to_fmagN (layout: layout) (value: Value.t) : Z.t =
  match sl_case value with
  | Some (([{ it = Atom "SUBNORM"; _ }] :: _), [m]) -> sl_to_z_nat m
  | Some (([{ it = Atom "NORM"; _ }] :: _), [m; exp]) -> Z.(shift_left (sl_to_z_int exp + bias layout) layout.mantissa + sl_to_z_nat m)
  | Some ([[{ it = Atom "INF"; _ }]], []) -> mask_exp layout
  | Some (([{ it = Atom "NAN"; _ }] :: _), [m]) -> Z.(mask_exp layout + sl_to_z_nat m)
  | _ -> failwith "Expected f32mag/f64mag"

let sl_to_floatN (layout: layout) (value: Value.t) : Z.t =
  match sl_case value with
  | Some (([{ it = Atom "POS"; _ }] :: _), [mag]) -> sl_to_fmagN layout mag
  | Some (([{ it = Atom "NEG"; _ }] :: _), [mag]) -> Z.(mask_sign layout + sl_to_fmagN layout mag)
  | _ -> failwith "Expected f32/f64"

let sl_to_float32 (value: Value.t) : F32.t =
  sl_to_floatN layout32 value |> Z.to_int32_unsigned |> F32.of_bits

let sl_to_float64 (value: Value.t) : F64.t =
  sl_to_floatN layout64 value |> Z.to_int64_unsigned |> F64.of_bits

let sl_to_idx (value: Value.t) : Ast.idx = sl_to_phrase sl_to_nat32 value

let sl_to_num (value: Value.t) : Wasm_Value.num =
  match sl_case value with
  | Some (([{ it = Atom "I32"; _ }] :: _), [i32]) ->
    Wasm_Value.I32 (sl_to_nat32 i32)
  | Some (([{ it = Atom "I64"; _ }] :: _), [i64]) ->
    Wasm_Value.I64 (sl_to_nat64 i64)
  | Some (([{ it = Atom "F32"; _ }] :: _), [f32]) ->
    Wasm_Value.F32 (sl_to_float32 f32)
  | Some (([{ it = Atom "F64"; _ }] :: _), [f64]) ->
    Wasm_Value.F64 (sl_to_float64 f64)
  | _ -> failwith "Expected num_"

let sl_to_vec (value: Value.t) : Wasm_Value.vec =
  let e64 = Z.shift_left Z.one 64 in
  match sl_case value with
  | Some (([{ it = Atom "V128"; _ }] :: _), [v]) ->
    let z = sl_to_z_nat v in
    let low = Z.(erem z e64) |> Z.to_int64_unsigned in
    let high = Z.(shift_right z 64) |> Z.to_int64_unsigned in
    Wasm_Value.V128 (V128.I64x2.of_lanes [ low; high ])
  | _ -> failwith "Expected vec_"

let rec sl_to_final (value: Value.t) : Types.final =
  match sl_case value with
  | Some ([[{ it = Atom "NoFinal"; _ }]], []) -> NoFinal
  | Some ([[{ it = Atom "Final"; _ }]], []) -> Final
  | _ -> failwith "Expected final"

and sl_to_typeuse (value: Value.t) : Types.var =
  match sl_case value with
  | Some (([{ it = Atom "StatX"; _ }] :: _), [ i32 ]) -> StatX (sl_to_nat32 i32)
  | Some (([{ it = Atom "RecX"; _ }] :: _), [ i32 ]) -> RecX (sl_to_nat32 i32)
  | _ -> failwith "Expected var"

and sl_to_def_type (value: Value.t) : Types.def_type =
  match sl_case value with
  | Some (([{ it = Atom "DefT"; _ }] :: _), [rt; i32]) -> DefT (sl_to_rec_type rt, sl_to_nat32 i32)
  | _ -> failwith "Expected final"

and sl_to_heap_type (value: Value.t) : Types.heap_type =
  match sl_case value with
  | Some (([{ it = Atom "VarHT"; _ }] :: _), [value]) -> VarHT (sl_to_typeuse value)
  | Some (([{ it = Atom "DefHT"; _ }] :: _), [value]) -> DefHT (sl_to_def_type value)
  | Some ([[{ it = Atom tag; _ }]], []) when is_heap_type_tag tag -> heap_type_of_tag tag
  | _ -> failwith "Expected heaptype"

and sl_to_mut (value: Value.t) : Types.mut =
  match sl_case value with
  | Some ([[{ it = Atom "Cons"; _ }]], []) -> Cons
  | Some ([[{ it = Atom "Var"; _ }]], []) -> Var
  | _ -> failwith "Excpected mut"

and sl_to_num_type (value: Value.t) : Types.num_type =
  match sl_case value with
  | Some ([[{ it = Atom "I32T"; _ }]], []) -> I32T
  | Some ([[{ it = Atom "I64T"; _ }]], []) -> I64T
  | Some ([[{ it = Atom "F32T"; _ }]], []) -> F32T
  | Some ([[{ it = Atom "F64T"; _ }]], []) -> F64T
  | _ -> failwith "Excpected numtype"

and sl_to_null (value: Value.t) : Types.null =
  match sl_case value with
  | Some ([[{ it = Atom "Null"; _ }]], []) -> Null
  | Some ([[{ it = Atom "NoNull"; _ }]], []) -> NoNull
  | _ -> failwith "Excpected null"

and sl_to_ref_type (value: Value.t) : Types.ref_type =
  match sl_case value with
  | Some ([[]; []; []], [null; ht]) -> (sl_to_null null, sl_to_heap_type ht)
  | _ -> failwith "Excpected reftype"

and sl_to_vec_type (value: Value.t) : Types.vec_type =
  match sl_case value with
  | Some ([[{ it = Atom "V128T"; _ }]], []) -> V128T
  | _ -> failwith "Excpected vectype"

and sl_to_val_type (value: Value.t) : Types.val_type =
  match sl_case value with
  | Some (([{ it = Atom "NumT"; _ }] :: _), [nt]) -> NumT (sl_to_num_type nt)
  | Some (([{ it = Atom "RefT"; _ }] :: _), [rt]) -> RefT (sl_to_ref_type rt)
  | Some (([{ it = Atom "VecT"; _ }] :: _), [vt]) -> VecT (sl_to_vec_type vt)
  | _ -> failwith "Excpected valtype"

and sl_to_pack_type (value: Value.t) : Pack.pack_size =
  match sl_case value with
  | Some ([[{ it = Atom "I8"; _ }]], []) -> Pack8
  | Some ([[{ it = Atom "I16"; _ }]], []) -> Pack16
  | Some ([[{ it = Atom "I32"; _ }]], []) -> Pack32
  | Some ([[{ it = Atom "I64"; _ }]], []) -> Pack64
  | _ -> failwith "Excpected packtype"

and sl_to_storage_type (value: Value.t) : Types.storage_type =
  match sl_case value with
  | Some (([{ it = Atom "ValStorageT"; _ }] :: _), [vt]) -> ValStorageT (sl_to_val_type vt)
  | Some (([{ it = Atom "PackStorageT"; _ }] :: _), [pt]) -> PackStorageT (sl_to_pack_type pt)
  | _ -> failwith "Excpected storagetype"

and sl_to_field_type (value: Value.t) : Types.field_type =
  match sl_case value with
  | Some (([{ it = Atom "FieldT"; _ }] :: _), [mut; st]) -> FieldT (sl_to_mut mut, sl_to_storage_type st)
  | _ -> failwith "Excpected fieldtype"

and sl_to_struct_type (value: Value.t) : Types.struct_type =
  match sl_case value with
  | Some (([{ it = Atom "StructT"; _ }] :: _), [ftl]) -> StructT (sl_to_list sl_to_field_type ftl)
  | _ -> failwith "Excpected structtype"

and sl_to_array_type (value: Value.t) : Types.array_type =
  match sl_case value with
  | Some (([{ it = Atom "ArrayT"; _ }] :: _), [ft]) -> ArrayT (sl_to_field_type ft)
  | _ -> failwith "Excpected arraytype"

and sl_to_result_type (value: Value.t) : Types.result_type = sl_to_list sl_to_val_type value

and sl_to_func_type (value: Value.t) : Types.func_type =
  match sl_case value with
  | Some (([{ it = Atom "FuncT"; _ }] :: _), [rt1; rt2]) -> FuncT (sl_to_result_type rt1, sl_to_result_type rt2)
  | _ -> failwith "Excpected functype"

and sl_to_str_type (value: Value.t) : Types.str_type =
  match sl_case value with
  | Some (([{ it = Atom "DefStructT"; _ }] :: _), [st]) -> DefStructT (sl_to_struct_type st)
  | Some (([{ it = Atom "DefArrayT"; _ }] :: _), [arrt]) -> DefArrayT (sl_to_array_type arrt)
  | Some (([{ it = Atom "DefFuncT"; _ }] :: _), [ft]) -> DefFuncT (sl_to_func_type ft)
  | _ -> failwith "Excpected strtype"

and sl_to_sub_type (value: Value.t) : Types.sub_type =
  match sl_case value with
  | Some (([{ it = Atom "SubT"; _ }] :: _), [fin; htl; st]) -> SubT (sl_to_final fin, sl_to_list sl_to_heap_type htl, sl_to_str_type st)
  | _ -> failwith "Excpected subtype"

and sl_to_rec_type (value: Value.t) : Types.rec_type =
  match sl_case value with
  | Some (([{ it = Atom "RecT"; _ }] :: _), [stl]) -> RecT (sl_to_list sl_to_sub_type stl)
  | _ -> failwith "Expected rectype"

and sl_to_int (value: Value.t) : int = sl_to_z_int value |> Z.to_int

and sl_to_int64 (value: Value.t) : int64 = sl_to_z_int value |> z_to_intN Z.to_int64 Z.to_int64_unsigned

and sl_to_void (value: Value.t) : unit =
  match value.it with
  | StructV [] -> ()
  | _ -> failwith "Expected void"

and sl_to_select_type_opt (value: Value.t) : Types.val_type list option = sl_to_opt (sl_to_list sl_to_val_type) value

and sl_to_extension (value: Value.t) : Pack.extension =
  match sl_case value with
  | Some ([[{ it = Atom "SX"; _ }]], []) -> SX
  | Some ([[{ it = Atom "ZX"; _ }]], []) -> ZX
  | _ -> failwith "Expected extension"

and sl_to_pack_shape (value: Value.t) : Pack.pack_shape =
  match sl_case value with
  | Some ([[{ it = Atom "Pack8x8"; _ }]], []) -> Pack.Pack8x8
  | Some ([[{ it = Atom "Pack16x4"; _ }]], []) -> Pack.Pack16x4
  | Some ([[{ it = Atom "Pack32x2"; _ }]], []) -> Pack.Pack32x2
  | _ -> failwith "Expected packshape"

and sl_to_vec_extension (value: Value.t) : Pack.vec_extension =
  match sl_case value with
  | Some (([{ it = Atom "ExtLane"; _ }] :: _), [shape; ext]) -> Pack.ExtLane (sl_to_pack_shape shape, sl_to_extension ext)
  | Some ([[{ it = Atom "ExtSplat"; _ }]], []) -> Pack.ExtSplat
  | Some ([[{ it = Atom "ExtZero"; _ }]], []) -> Pack.ExtZero
  | _ -> failwith "Expected vextension"

and sl_to_initop (value: Value.t) : Ast.initop =
  match sl_case value with
  | Some ([[{ it = Atom "Explicit"; _ }]], []) -> Explicit
  | Some ([[{ it = Atom "Implicit"; _ }]], []) -> Implicit
  | _ -> failwith "Expected initop"

and sl_to_externop (value: Value.t) : Ast.externop =
  match sl_case value with
  | Some ([[{ it = Atom "Internalize"; _ }]], []) -> Internalize
  | Some ([[{ it = Atom "Externalize"; _ }]], []) -> Externalize
  | _ -> failwith "Expected externop"

and sl_to_block_type (value: Value.t) : Ast.block_type =
  match sl_case value with
  | Some (([{ it = Atom "VarBlockType"; _ }] :: _), [idx]) -> VarBlockType (sl_to_idx idx)
  | Some (([{ it = Atom "ValBlockType"; _ }] :: _), [vt_opt]) -> ValBlockType (sl_to_opt sl_to_val_type vt_opt)
  | _ -> failwith "Expected blocktype"

and sl_to_catch' (value: Value.t) : Ast.catch' =
  match sl_case value with
  | Some (([{ it = Atom "Catch"; _ }] :: _), [idx1; idx2]) -> Catch (sl_to_idx idx1, sl_to_idx idx2)
  | Some (([{ it = Atom "CatchRef"; _ }] :: _), [idx1; idx2]) -> CatchRef (sl_to_idx idx1, sl_to_idx idx2)
  | Some (([{ it = Atom "CatchAll"; _ }] :: _), [idx]) -> CatchAll (sl_to_idx idx)
  | Some (([{ it = Atom "CatchAllRef"; _ }] :: _), [idx]) -> CatchAllRef (sl_to_idx idx)
  | _ -> failwith "Expected catch"

and sl_to_catch (value: Value.t) : Ast.catch = sl_to_phrase sl_to_catch' value

and sl_to_pack_type_extension (value: Value.t) : Pack.pack_size * Pack.extension =
  let pt, ext = Unwrap.unwrap_tuple_v_two value in
  (sl_to_pack_type pt, sl_to_extension ext)

and sl_to_pack_type_vec_extension (value: Value.t) : Pack.pack_size * Pack.vec_extension =
  let pt, ext = Unwrap.unwrap_tuple_v_two value in
  (sl_to_pack_type pt, sl_to_vec_extension ext)

and sl_to_loadop (value: Value.t) : Ast.loadop =
  match value.it with
  | StructV valuefields ->
    let _atoms, values = List.split valuefields in
    (match values with
    | [ty; align; offset; pack] -> { ty = sl_to_num_type ty; align = sl_to_int align; offset = sl_to_int64 offset; pack = sl_to_opt sl_to_pack_type_extension pack }
    | _ -> failwith "Expected loadop_ with 4 fields")
  | _ -> failwith "Expected loadop_"

and sl_to_storeop (value: Value.t) : Ast.storeop =
  match value.it with
  | StructV valuefields ->
    let _atoms, values = List.split valuefields in
    (match values with
    | [ty; align; offset; pack] -> { ty = sl_to_num_type ty; align = sl_to_int align; offset = sl_to_int64 offset; pack = sl_to_opt sl_to_pack_type pack }
    | _ -> failwith "Expected storeop_ with 4 fields")
  | _ -> failwith "Expected storeop_"

and sl_to_vec_loadop (value: Value.t) : Ast.vec_loadop =
  match value.it with
  | StructV valuefields ->
    let _atoms, values = List.split valuefields in
    (match values with
    | [ty; align; offset; pack] -> { ty = sl_to_vec_type ty; align = sl_to_int align; offset = sl_to_int64 offset; pack = sl_to_opt sl_to_pack_type_vec_extension pack }
    | _ -> failwith "Expected vloadop_ with 4 fields")
  | _ -> failwith "Expected vloadop_"

and sl_to_vec_storeop (value: Value.t) : Ast.vec_storeop =
  match value.it with
  | StructV valuefields ->
    let _atoms, values = List.split valuefields in
    (match values with
    | [ty; align; offset; pack] -> sl_to_void pack; { ty = sl_to_vec_type ty; align = sl_to_int align; offset = sl_to_int64 offset; pack = () }
    | _ -> failwith "Expected vstoreop_ with 4 fields")
  | _ -> failwith "Expected vstoreop_"

and sl_to_vec_laneop (value: Value.t) : Ast.vec_laneop =
  match value.it with
  | StructV valuefields ->
    let _atoms, values = List.split valuefields in
    (match values with
    | [ty; align; offset; pack] -> { ty = sl_to_vec_type ty; align = sl_to_int align; offset = sl_to_int64 offset; pack = sl_to_pack_type pack }
    | _ -> failwith "Expected vlaneop_ with 4 fields")
  | _ -> failwith "Expected vlaneop_"

and sl_to_op : type a b. (Value.t -> a) -> (Value.t -> b) -> Value.t -> (a, a, b, b) Wasm_Value.op =
  fun f_int f_float value ->
    match sl_case value with
    | Some (([{ it = Atom "I32"; _ }] :: _), [op]) -> Wasm_Value.I32 (f_int op)
    | Some (([{ it = Atom "I64"; _ }] :: _), [op]) -> Wasm_Value.I64 (f_int op)
    | Some (([{ it = Atom "F32"; _ }] :: _), [op]) -> Wasm_Value.F32 (f_float op)
    | Some (([{ it = Atom "F64"; _ }] :: _), [op]) -> Wasm_Value.F64 (f_float op)
    | _ -> failwith "Expected op"

and sl_to_int_unop (value: Value.t) : Ast.IntOp.unop =
  match sl_case value with
  | Some ([[{ it = Atom "Clz"; _ }]], []) -> Clz
  | Some ([[{ it = Atom "Ctz"; _ }]], []) -> Ctz
  | Some ([[{ it = Atom "Popcnt"; _ }]], []) -> Popcnt
  | Some (([{ it = Atom "ExtendS"; _ }] :: _), [pt]) -> ExtendS (sl_to_pack_type pt)
  | _ -> failwith "Expected iunop"

and sl_to_float_unop (value: Value.t) : Ast.FloatOp.unop =
  match sl_case value with
  | Some ([[{ it = Atom "Neg"; _ }]], []) -> Neg
  | Some ([[{ it = Atom "Abs"; _ }]], []) -> Abs
  | Some ([[{ it = Atom "Ceil"; _ }]], []) -> Ceil
  | Some ([[{ it = Atom "Floor"; _ }]], []) -> Floor
  | Some ([[{ it = Atom "Trunc"; _ }]], []) -> Trunc
  | Some ([[{ it = Atom "Nearest"; _ }]], []) -> Nearest
  | Some ([[{ it = Atom "Sqrt"; _ }]], []) -> Sqrt
  | _ -> failwith "Expected funop"

and sl_to_unop (value: Value.t) : Ast.unop = sl_to_op sl_to_int_unop sl_to_float_unop value

and sl_to_int_binop (value: Value.t) : Ast.IntOp.binop =
  match sl_case value with
  | Some ([[{ it = Atom "IAdd"; _ }]], []) -> Add
  | Some ([[{ it = Atom "ISub"; _ }]], []) -> Sub
  | Some ([[{ it = Atom "IMul"; _ }]], []) -> Mul
  | Some ([[{ it = Atom "IDivS"; _ }]], []) -> DivS
  | Some ([[{ it = Atom "IDivU"; _ }]], []) -> DivU
  | Some ([[{ it = Atom "IRemS"; _ }]], []) -> RemS
  | Some ([[{ it = Atom "IRemU"; _ }]], []) -> RemU
  | Some ([[{ it = Atom "IAnd"; _ }]], []) -> And
  | Some ([[{ it = Atom "IOr"; _ }]], []) -> Or
  | Some ([[{ it = Atom "IXor"; _ }]], []) -> Xor
  | Some ([[{ it = Atom "IShl"; _ }]], []) -> Shl
  | Some ([[{ it = Atom "IShrS"; _ }]], []) -> ShrS
  | Some ([[{ it = Atom "IShrU"; _ }]], []) -> ShrU
  | Some ([[{ it = Atom "IRotl"; _ }]], []) -> Rotl
  | Some ([[{ it = Atom "IRotr"; _ }]], []) -> Rotr
  | _ -> failwith "Expected ibinop"

and sl_to_float_binop (value: Value.t) : Ast.FloatOp.binop =
  match sl_case value with
  | Some ([[{ it = Atom "FAdd"; _ }]], []) -> Add
  | Some ([[{ it = Atom "FSub"; _ }]], []) -> Sub
  | Some ([[{ it = Atom "FMul"; _ }]], []) -> Mul
  | Some ([[{ it = Atom "FDiv"; _ }]], []) -> Div
  | Some ([[{ it = Atom "FMin"; _ }]], []) -> Min
  | Some ([[{ it = Atom "FMax"; _ }]], []) -> Max
  | Some ([[{ it = Atom "FCopysign"; _ }]], []) -> CopySign
  | _ -> failwith "Expected fbinop"

and sl_to_binop (value: Value.t) : Ast.binop = sl_to_op sl_to_int_binop sl_to_float_binop value

and sl_to_int_testop (value: Value.t) : Ast.IntOp.testop =
  match sl_case value with
  | Some ([[{ it = Atom "Eqz"; _ }]], []) -> Eqz
  | _ -> failwith "Expected itestop"

and sl_to_testop (value: Value.t) : Ast.testop =
  match sl_case value with
  | Some (([{ it = Atom "I32"; _ }] :: _), [op]) -> Wasm_Value.I32 (sl_to_int_testop op)
  | Some (([{ it = Atom "I64"; _ }] :: _), [op]) -> Wasm_Value.I64 (sl_to_int_testop op)
  | _ -> failwith "Expected testop"

and sl_to_int_relop (value: Value.t) : Ast.IntOp.relop =
  match sl_case value with
  | Some ([[{ it = Atom "Eq"; _ }]], []) -> Eq
  | Some ([[{ it = Atom "Ne"; _ }]], []) -> Ne
  | Some ([[{ it = Atom "LtS"; _ }]], []) -> LtS
  | Some ([[{ it = Atom "LtU"; _ }]], []) -> LtU
  | Some ([[{ it = Atom "GtS"; _ }]], []) -> GtS
  | Some ([[{ it = Atom "GtU"; _ }]], []) -> GtU
  | Some ([[{ it = Atom "LeS"; _ }]], []) -> LeS
  | Some ([[{ it = Atom "LeU"; _ }]], []) -> LeU
  | Some ([[{ it = Atom "GeS"; _ }]], []) -> GeS
  | Some ([[{ it = Atom "GeU"; _ }]], []) -> GeU
  | _ -> failwith "Expected irelop"

and sl_to_float_relop (value: Value.t) : Ast.FloatOp.relop =
  match sl_case value with
  | Some ([[{ it = Atom "Eq"; _ }]], []) -> Eq
  | Some ([[{ it = Atom "Ne"; _ }]], []) -> Ne
  | Some ([[{ it = Atom "Lt"; _ }]], []) -> Lt
  | Some ([[{ it = Atom "Gt"; _ }]], []) -> Gt
  | Some ([[{ it = Atom "Le"; _ }]], []) -> Le
  | Some ([[{ it = Atom "Ge"; _ }]], []) -> Ge
  | _ -> failwith "Expected frelop"

and sl_to_relop (value: Value.t) : Ast.relop = sl_to_op sl_to_int_relop sl_to_float_relop value

and sl_to_int_cvtop (value: Value.t) : Ast.IntOp.cvtop =
  match sl_case value with
  | Some ([[{ it = Atom "ExtendSI32"; _ }]], []) -> ExtendSI32
  | Some ([[{ it = Atom "ExtendUI32"; _ }]], []) -> ExtendUI32
  | Some ([[{ it = Atom "WrapI64"; _ }]], []) -> WrapI64
  | Some ([[{ it = Atom "TruncSF32"; _ }]], []) -> TruncSF32
  | Some ([[{ it = Atom "TruncUF32"; _ }]], []) -> TruncUF32
  | Some ([[{ it = Atom "TruncSF64"; _ }]], []) -> TruncSF64
  | Some ([[{ it = Atom "TruncUF64"; _ }]], []) -> TruncUF64
  | Some ([[{ it = Atom "TruncSatSF32"; _ }]], []) -> TruncSatSF32
  | Some ([[{ it = Atom "TruncSatUF32"; _ }]], []) -> TruncSatUF32
  | Some ([[{ it = Atom "TruncSatSF64"; _ }]], []) -> TruncSatSF64
  | Some ([[{ it = Atom "TruncSatUF64"; _ }]], []) -> TruncSatUF64
  | Some ([[{ it = Atom "ReinterpretFloat"; _ }]], []) -> ReinterpretFloat
  | _ -> failwith "Expected icvtop"

and sl_to_float_cvtop (value: Value.t) : Ast.FloatOp.cvtop =
  match sl_case value with
  | Some ([[{ it = Atom "ConvertSI32"; _ }]], []) -> ConvertSI32
  | Some ([[{ it = Atom "ConvertUI32"; _ }]], []) -> ConvertUI32
  | Some ([[{ it = Atom "ConvertSI64"; _ }]], []) -> ConvertSI64
  | Some ([[{ it = Atom "ConvertUI64"; _ }]], []) -> ConvertUI64
  | Some ([[{ it = Atom "PromoteF32"; _ }]], []) -> PromoteF32
  | Some ([[{ it = Atom "DemoteF64"; _ }]], []) -> DemoteF64
  | Some ([[{ it = Atom "ReinterpretInt"; _ }]], []) -> ReinterpretInt
  | _ -> failwith "Expected fcvtop"

and sl_to_cvtop (value: Value.t) : Ast.cvtop = sl_to_op sl_to_int_cvtop sl_to_float_cvtop value

and sl_to_vop : type a b. (Value.t -> a) -> (Value.t -> b) -> Value.t -> ((a, a, a, a, b, b) V128.laneop) Wasm_Value.vecop =
  fun f_int f_float value ->
    match sl_case value with
    | Some (([{ it = Atom "V128"; _ }] :: _), [vop]) ->
      (match sl_case vop with
      | Some (([{ it = Atom "I8x16"; _ }] :: _), [op]) -> Wasm_Value.V128 (V128.I8x16 (f_int op))
      | Some (([{ it = Atom "I16x8"; _ }] :: _), [op]) -> Wasm_Value.V128 (V128.I16x8 (f_int op))
      | Some (([{ it = Atom "I32x4"; _ }] :: _), [op]) -> Wasm_Value.V128 (V128.I32x4 (f_int op))
      | Some (([{ it = Atom "I64x2"; _ }] :: _), [op]) -> Wasm_Value.V128 (V128.I64x2 (f_int op))
      | Some (([{ it = Atom "F32x4"; _ }] :: _), [op]) -> Wasm_Value.V128 (V128.F32x4 (f_float op))
      | Some (([{ it = Atom "F64x2"; _ }] :: _), [op]) -> Wasm_Value.V128 (V128.F64x2 (f_float op))
      | _ -> failwith "Expected vop lane")
    | _ -> failwith "Expected vop"

and sl_to_int_vtestop (value: Value.t) : Ast.V128Op.itestop =
  match sl_case value with
  | Some ([[{ it = Atom "AllTrue"; _ }]], []) -> AllTrue
  | _ -> failwith "Expected vitestop"

and sl_to_vtestop (value: Value.t) : Ast.vec_testop = sl_to_vop sl_to_int_vtestop (fun _ -> failwith "Expected integer vtestop lane") value

and sl_to_int_vrelop (value: Value.t) : Ast.V128Op.irelop =
  match sl_case value with
  | Some ([[{ it = Atom "Eq"; _ }]], []) -> Eq
  | Some ([[{ it = Atom "Ne"; _ }]], []) -> Ne
  | Some ([[{ it = Atom "LtS"; _ }]], []) -> LtS
  | Some ([[{ it = Atom "LtU"; _ }]], []) -> LtU
  | Some ([[{ it = Atom "LeS"; _ }]], []) -> LeS
  | Some ([[{ it = Atom "LeU"; _ }]], []) -> LeU
  | Some ([[{ it = Atom "GtS"; _ }]], []) -> GtS
  | Some ([[{ it = Atom "GtU"; _ }]], []) -> GtU
  | Some ([[{ it = Atom "GeS"; _ }]], []) -> GeS
  | Some ([[{ it = Atom "GeU"; _ }]], []) -> GeU
  | _ -> failwith "Expected virelop"

and sl_to_float_vrelop (value: Value.t) : Ast.V128Op.frelop =
  match sl_case value with
  | Some ([[{ it = Atom "Eq"; _ }]], []) -> Eq
  | Some ([[{ it = Atom "Ne"; _ }]], []) -> Ne
  | Some ([[{ it = Atom "Lt"; _ }]], []) -> Lt
  | Some ([[{ it = Atom "Le"; _ }]], []) -> Le
  | Some ([[{ it = Atom "Gt"; _ }]], []) -> Gt
  | Some ([[{ it = Atom "Ge"; _ }]], []) -> Ge
  | _ -> failwith "Expected vfrelop"

and sl_to_vrelop (value: Value.t) : Ast.vec_relop = sl_to_vop sl_to_int_vrelop sl_to_float_vrelop value

and sl_to_int_vunop (value: Value.t) : Ast.V128Op.iunop =
  match sl_case value with
  | Some ([[{ it = Atom "Abs"; _ }]], []) -> Abs
  | Some ([[{ it = Atom "Neg"; _ }]], []) -> Neg
  | Some ([[{ it = Atom "Popcnt"; _ }]], []) -> Popcnt
  | _ -> failwith "Expected viunop"

and sl_to_float_vunop (value: Value.t) : Ast.V128Op.funop =
  match sl_case value with
  | Some ([[{ it = Atom "Abs"; _ }]], []) -> Abs
  | Some ([[{ it = Atom "Neg"; _ }]], []) -> Neg
  | Some ([[{ it = Atom "Sqrt"; _ }]], []) -> Sqrt
  | Some ([[{ it = Atom "Ceil"; _ }]], []) -> Ceil
  | Some ([[{ it = Atom "Floor"; _ }]], []) -> Floor
  | Some ([[{ it = Atom "Trunc"; _ }]], []) -> Trunc
  | Some ([[{ it = Atom "Nearest"; _ }]], []) -> Nearest
  | _ -> failwith "Expected vfunop"

and sl_to_vunop (value: Value.t) : Ast.vec_unop = sl_to_vop sl_to_int_vunop sl_to_float_vunop value

and sl_to_int_vbinop (value: Value.t) : Ast.V128Op.ibinop =
  match sl_case value with
  | Some ([[{ it = Atom "Add"; _ }]], []) -> Add
  | Some ([[{ it = Atom "Sub"; _ }]], []) -> Sub
  | Some ([[{ it = Atom "Mul"; _ }]], []) -> Mul
  | Some ([[{ it = Atom "MinS"; _ }]], []) -> MinS
  | Some ([[{ it = Atom "MinU"; _ }]], []) -> MinU
  | Some ([[{ it = Atom "MaxS"; _ }]], []) -> MaxS
  | Some ([[{ it = Atom "MaxU"; _ }]], []) -> MaxU
  | Some ([[{ it = Atom "AvgrU"; _ }]], []) -> AvgrU
  | Some ([[{ it = Atom "AddSatS"; _ }]], []) -> AddSatS
  | Some ([[{ it = Atom "AddSatU"; _ }]], []) -> AddSatU
  | Some ([[{ it = Atom "SubSatS"; _ }]], []) -> SubSatS
  | Some ([[{ it = Atom "SubSatU"; _ }]], []) -> SubSatU
  | Some ([[{ it = Atom "DotS"; _ }]], []) -> DotS
  | Some ([[{ it = Atom "Q15MulRSatS"; _ }]], []) -> Q15MulRSatS
  | Some ([[{ it = Atom "ExtMulLowS"; _ }]], []) -> ExtMulLowS
  | Some ([[{ it = Atom "ExtMulHighS"; _ }]], []) -> ExtMulHighS
  | Some ([[{ it = Atom "ExtMulLowU"; _ }]], []) -> ExtMulLowU
  | Some ([[{ it = Atom "ExtMulHighU"; _ }]], []) -> ExtMulHighU
  | Some ([[{ it = Atom "Swizzle"; _ }]], []) -> Swizzle
  | Some (([{ it = Atom "Shuffle"; _ }] :: _), [l]) -> Shuffle (sl_to_list sl_to_int l)
  | Some ([[{ it = Atom "NarrowS"; _ }]], []) -> NarrowS
  | Some ([[{ it = Atom "NarrowU"; _ }]], []) -> NarrowU
  | Some ([[{ it = Atom "RelaxedSwizzle"; _ }]], []) -> RelaxedSwizzle
  | Some ([[{ it = Atom "RelaxedQ15MulRS"; _ }]], []) -> RelaxedQ15MulRS
  | Some ([[{ it = Atom "RelaxedDot"; _ }]], []) -> RelaxedDot
  | _ -> failwith "Expected vibinop"

and sl_to_float_vbinop (value: Value.t) : Ast.V128Op.fbinop =
  match sl_case value with
  | Some ([[{ it = Atom "Add"; _ }]], []) -> Add
  | Some ([[{ it = Atom "Sub"; _ }]], []) -> Sub
  | Some ([[{ it = Atom "Mul"; _ }]], []) -> Mul
  | Some ([[{ it = Atom "Div"; _ }]], []) -> Div
  | Some ([[{ it = Atom "Min"; _ }]], []) -> Min
  | Some ([[{ it = Atom "Max"; _ }]], []) -> Max
  | Some ([[{ it = Atom "Pmin"; _ }]], []) -> Pmin
  | Some ([[{ it = Atom "Pmax"; _ }]], []) -> Pmax
  | Some ([[{ it = Atom "RelaxedMin"; _ }]], []) -> RelaxedMin
  | Some ([[{ it = Atom "RelaxedMax"; _ }]], []) -> RelaxedMax
  | _ -> failwith "Expected vfbinop"

and sl_to_vbinop (value: Value.t) : Ast.vec_binop = sl_to_vop sl_to_int_vbinop sl_to_float_vbinop value

and sl_to_int_vternop (value: Value.t) : Ast.V128Op.iternop =
  match sl_case value with
  | Some ([[{ it = Atom "RelaxedLaneselect"; _ }]], []) -> RelaxedLaneselect
  | Some ([[{ it = Atom "RelaxedDotAdd"; _ }]], []) -> RelaxedDotAdd
  | _ -> failwith "Expected viternop"

and sl_to_float_vternop (value: Value.t) : Ast.V128Op.fternop =
  match sl_case value with
  | Some ([[{ it = Atom "RelaxedMadd"; _ }]], []) -> RelaxedMadd
  | Some ([[{ it = Atom "RelaxedNmadd"; _ }]], []) -> RelaxedNmadd
  | _ -> failwith "Expected vfternop"

and sl_to_vternop (value: Value.t) : Ast.vec_ternop = sl_to_vop sl_to_int_vternop sl_to_float_vternop value

and sl_to_int_vcvtop (value: Value.t) : Ast.V128Op.icvtop =
  match sl_case value with
  | Some ([[{ it = Atom "ExtendLowS"; _ }]], []) -> ExtendLowS
  | Some ([[{ it = Atom "ExtendLowU"; _ }]], []) -> ExtendLowU
  | Some ([[{ it = Atom "ExtendHighS"; _ }]], []) -> ExtendHighS
  | Some ([[{ it = Atom "ExtendHighU"; _ }]], []) -> ExtendHighU
  | Some ([[{ it = Atom "ExtAddPairwiseS"; _ }]], []) -> ExtAddPairwiseS
  | Some ([[{ it = Atom "ExtAddPairwiseU"; _ }]], []) -> ExtAddPairwiseU
  | Some ([[{ it = Atom "TruncSatSF32x4"; _ }]], []) -> TruncSatSF32x4
  | Some ([[{ it = Atom "TruncSatUF32x4"; _ }]], []) -> TruncSatUF32x4
  | Some ([[{ it = Atom "TruncSatSZeroF64x2"; _ }]], []) -> TruncSatSZeroF64x2
  | Some ([[{ it = Atom "TruncSatUZeroF64x2"; _ }]], []) -> TruncSatUZeroF64x2
  | Some ([[{ it = Atom "RelaxedTruncSF32x4"; _ }]], []) -> RelaxedTruncSF32x4
  | Some ([[{ it = Atom "RelaxedTruncUF32x4"; _ }]], []) -> RelaxedTruncUF32x4
  | Some ([[{ it = Atom "RelaxedTruncSZeroF64x2"; _ }]], []) -> RelaxedTruncSZeroF64x2
  | Some ([[{ it = Atom "RelaxedTruncUZeroF64x2"; _ }]], []) -> RelaxedTruncUZeroF64x2
  | _ -> failwith "Expected vicvtop"

and sl_to_float_vcvtop (value: Value.t) : Ast.V128Op.fcvtop =
  match sl_case value with
  | Some ([[{ it = Atom "DemoteZeroF64x2"; _ }]], []) -> DemoteZeroF64x2
  | Some ([[{ it = Atom "PromoteLowF32x4"; _ }]], []) -> PromoteLowF32x4
  | Some ([[{ it = Atom "ConvertSI32x4"; _ }]], []) -> ConvertSI32x4
  | Some ([[{ it = Atom "ConvertUI32x4"; _ }]], []) -> ConvertUI32x4
  | _ -> failwith "Expected vfcvtop"

and sl_to_vcvtop (value: Value.t) : Ast.vec_cvtop = sl_to_vop sl_to_int_vcvtop sl_to_float_vcvtop value

and sl_to_int_vshiftop (value: Value.t) : Ast.V128Op.ishiftop =
  match sl_case value with
  | Some ([[{ it = Atom "Shl"; _ }]], []) -> Shl
  | Some ([[{ it = Atom "ShrS"; _ }]], []) -> ShrS
  | Some ([[{ it = Atom "ShrU"; _ }]], []) -> ShrU
  | _ -> failwith "Expected vishiftop"

and sl_to_vshiftop (value: Value.t) : Ast.vec_shiftop = sl_to_vop sl_to_int_vshiftop (fun _ -> failwith "Expected integer vshiftop lane") value

and sl_to_int_vbitmaskop (value: Value.t) : Ast.V128Op.ibitmaskop =
  match sl_case value with
  | Some ([[{ it = Atom "Bitmask"; _ }]], []) -> Bitmask
  | _ -> failwith "Expected vibitmaskop"

and sl_to_vbitmaskop (value: Value.t) : Ast.vec_bitmaskop = sl_to_vop sl_to_int_vbitmaskop (fun _ -> failwith "Expected integer vbitmaskop lane") value

and sl_to_vvtestop (value: Value.t) : Ast.vec_vtestop =
  match sl_case value with
  | Some (([{ it = Atom "V128"; _ }] :: _), [op]) ->
    (match sl_case op with
    | Some ([[{ it = Atom "AnyTrue"; _ }]], []) -> Wasm_Value.V128 AnyTrue
    | _ -> failwith "Expected vvtestop")
  | _ -> failwith "Expected vvtestop_"

and sl_to_vvunop (value: Value.t) : Ast.vec_vunop =
  match sl_case value with
  | Some (([{ it = Atom "V128"; _ }] :: _), [op]) ->
    (match sl_case op with
    | Some ([[{ it = Atom "Not"; _ }]], []) -> Wasm_Value.V128 Not
    | _ -> failwith "Expected vvunop")
  | _ -> failwith "Expected vvunop_"

and sl_to_vvbinop (value: Value.t) : Ast.vec_vbinop =
  match sl_case value with
  | Some (([{ it = Atom "V128"; _ }] :: _), [op]) ->
    (match sl_case op with
    | Some ([[{ it = Atom "And"; _ }]], []) -> Wasm_Value.V128 And
    | Some ([[{ it = Atom "Or"; _ }]], []) -> Wasm_Value.V128 Or
    | Some ([[{ it = Atom "Xor"; _ }]], []) -> Wasm_Value.V128 Xor
    | Some ([[{ it = Atom "AndNot"; _ }]], []) -> Wasm_Value.V128 AndNot
    | _ -> failwith "Expected vvbinop")
  | _ -> failwith "Expected vvbinop_"

and sl_to_vvternop (value: Value.t) : Ast.vec_vternop =
  match sl_case value with
  | Some (([{ it = Atom "V128"; _ }] :: _), [op]) ->
    (match sl_case op with
    | Some ([[{ it = Atom "Bitselect"; _ }]], []) -> Wasm_Value.V128 Bitselect
    | _ -> failwith "Expected vvternop")
  | _ -> failwith "Expected vvternop_"

and sl_to_vnsplatop (value: Value.t) : Ast.V128Op.nsplatop =
  match sl_case value with
  | Some ([[{ it = Atom "Splat"; _ }]], []) -> Splat
  | _ -> failwith "Expected vnsplatop"

and sl_to_vsplatop (value: Value.t) : Ast.vec_splatop = sl_to_vop sl_to_vnsplatop sl_to_vnsplatop value

and sl_to_vnextractop (value: Value.t) : Pack.extension Ast.V128Op.nextractop =
  match sl_case value with
  | Some (([{ it = Atom "Extract"; _ }] :: _), [tuple]) ->
    let i, ext = Unwrap.unwrap_tuple_v_two tuple in
    Extract (sl_to_nat i, sl_to_extension ext)
  | _ -> failwith "Expected int vnextractop"

and sl_to_vnextractop' (value: Value.t) : unit Ast.V128Op.nextractop =
  match sl_case value with
  | Some (([{ it = Atom "Extract"; _ }] :: _), [tuple]) ->
    let i, void = Unwrap.unwrap_tuple_v_two tuple in
    sl_to_void void;
    Extract (sl_to_nat i, ())
  | _ -> failwith "Expected float vnextractop"

and sl_to_vextractop (value: Value.t) : Ast.vec_extractop =
  match sl_case value with
  | Some (([{ it = Atom "V128"; _ }] :: _), [vop]) ->
    (match sl_case vop with
    | Some (([{ it = Atom "I8x16"; _ }] :: _), [op]) -> Wasm_Value.V128 (V128.I8x16 (sl_to_vnextractop op))
    | Some (([{ it = Atom "I16x8"; _ }] :: _), [op]) -> Wasm_Value.V128 (V128.I16x8 (sl_to_vnextractop op))
    | Some (([{ it = Atom "I32x4"; _ }] :: _), [op]) -> Wasm_Value.V128 (V128.I32x4 (sl_to_vnextractop' op))
    | Some (([{ it = Atom "I64x2"; _ }] :: _), [op]) -> Wasm_Value.V128 (V128.I64x2 (sl_to_vnextractop' op))
    | Some (([{ it = Atom "F32x4"; _ }] :: _), [op]) -> Wasm_Value.V128 (V128.F32x4 (sl_to_vnextractop' op))
    | Some (([{ it = Atom "F64x2"; _ }] :: _), [op]) -> Wasm_Value.V128 (V128.F64x2 (sl_to_vnextractop' op))
    | _ -> failwith "Expected vextractop lane")
  | _ -> failwith "Expected vextractop_"

and sl_to_vnreplaceop (value: Value.t) : Ast.V128Op.nreplaceop =
  match sl_case value with
  | Some (([{ it = Atom "Replace"; _ }] :: _), [i]) -> Replace (sl_to_nat i)
  | _ -> failwith "Expected vnreplaceop"

and sl_to_vreplaceop (value: Value.t) : Ast.vec_replaceop = sl_to_vop sl_to_vnreplaceop sl_to_vnreplaceop value

and sl_to_instr' (value: Value.t) : Ast.instr' =
  match sl_case value with
  | Some ([[{ it = Atom "UNREACHABLE"; _ }]], []) -> Unreachable
  | Some ([[{ it = Atom "NOP"; _ }]], []) -> Nop
  | Some ([[{ it = Atom "DROP"; _ }]], []) -> Drop
  | Some (([{ it = Atom "SELECT"; _ }] :: _), [vt_opt]) -> Select (sl_to_select_type_opt vt_opt)
  | Some (([{ it = Atom "BLOCK"; _ }] :: _), [bt; instrs]) -> Block (sl_to_block_type bt, sl_to_list sl_to_instr instrs)
  | Some (([{ it = Atom "LOOP"; _ }] :: _), [bt; instrs]) -> Loop (sl_to_block_type bt, sl_to_list sl_to_instr instrs)
  | Some ([[{ it = Atom "IF"; _ }]; _; [{ it = Atom "ELSE"; _ }]; _], [bt; instrs1; instrs2]) -> If (sl_to_block_type bt, sl_to_list sl_to_instr instrs1, sl_to_list sl_to_instr instrs2)
  | Some (([{ it = Atom "BR"; _ }] :: _), [idx]) -> Br (sl_to_idx idx)
  | Some (([{ it = Atom "BR_IF"; _ }] :: _), [idx]) -> BrIf (sl_to_idx idx)
  | Some (([{ it = Atom "BR_TABLE"; _ }] :: _), [idxl; idx]) -> BrTable (sl_to_list sl_to_idx idxl, sl_to_idx idx)
  | Some (([{ it = Atom "BR_ON_NULL"; _ }] :: _), [idx]) -> BrOnNull (sl_to_idx idx)
  | Some (([{ it = Atom "BR_ON_NON_NULL"; _ }] :: _), [idx]) -> BrOnNonNull (sl_to_idx idx)
  | Some (([{ it = Atom "BR_ON_CAST"; _ }] :: _), [idx; rt1; rt2]) -> BrOnCast (sl_to_idx idx, sl_to_ref_type rt1, sl_to_ref_type rt2)
  | Some (([{ it = Atom "BR_ON_CAST_FAIL"; _ }] :: _), [idx; rt1; rt2]) -> BrOnCastFail (sl_to_idx idx, sl_to_ref_type rt1, sl_to_ref_type rt2)
  | Some ([[{ it = Atom "RETURN"; _ }]], []) -> Return
  | Some (([{ it = Atom "CALL"; _ }] :: _), [idx]) -> Call (sl_to_idx idx)
  | Some (([{ it = Atom "CALL_REF"; _ }] :: _), [idx]) -> CallRef (sl_to_idx idx)
  | Some (([{ it = Atom "CALL_INDIRECT"; _ }] :: _), [idx1; idx2]) -> CallIndirect (sl_to_idx idx1, sl_to_idx idx2)
  | Some (([{ it = Atom "RETURN_CALL"; _ }] :: _), [idx]) -> ReturnCall (sl_to_idx idx)
  | Some (([{ it = Atom "RETURN_CALL_REF"; _ }] :: _), [idx]) -> ReturnCallRef (sl_to_idx idx)
  | Some (([{ it = Atom "RETURN_CALL_INDIRECT"; _ }] :: _), [idx1; idx2]) -> ReturnCallIndirect (sl_to_idx idx1, sl_to_idx idx2)
  | Some (([{ it = Atom "THROW"; _ }] :: _), [idx]) -> Throw (sl_to_idx idx)
  | Some ([[{ it = Atom "THROW_REF"; _ }]], []) -> ThrowRef
  | Some (([{ it = Atom "TRY_TABLE"; _ }] :: _), [bt; catches; instrs]) -> TryTable (sl_to_block_type bt, sl_to_list sl_to_catch catches, sl_to_list sl_to_instr instrs)
  | Some (([{ it = Atom "LOCAL.GET"; _ }] :: _), [idx]) -> LocalGet (sl_to_idx idx)
  | Some (([{ it = Atom "LOCAL.SET"; _ }] :: _), [idx]) -> LocalSet (sl_to_idx idx)
  | Some (([{ it = Atom "LOCAL.TEE"; _ }] :: _), [idx]) -> LocalTee (sl_to_idx idx)
  | Some (([{ it = Atom "GLOBAL.GET"; _ }] :: _), [idx]) -> GlobalGet (sl_to_idx idx)
  | Some (([{ it = Atom "GLOBAL.SET"; _ }] :: _), [idx]) -> GlobalSet (sl_to_idx idx)
  | Some (([{ it = Atom "TABLE.GET"; _ }] :: _), [idx]) -> TableGet (sl_to_idx idx)
  | Some (([{ it = Atom "TABLE.SET"; _ }] :: _), [idx]) -> TableSet (sl_to_idx idx)
  | Some (([{ it = Atom "TABLE.SIZE"; _ }] :: _), [idx]) -> TableSize (sl_to_idx idx)
  | Some (([{ it = Atom "TABLE.GROW"; _ }] :: _), [idx]) -> TableGrow (sl_to_idx idx)
  | Some (([{ it = Atom "TABLE.FILL"; _ }] :: _), [idx]) -> TableFill (sl_to_idx idx)
  | Some (([{ it = Atom "TABLE.COPY"; _ }] :: _), [idx1; idx2]) -> TableCopy (sl_to_idx idx1, sl_to_idx idx2)
  | Some (([{ it = Atom "TABLE.INIT"; _ }] :: _), [idx1; idx2]) -> TableInit (sl_to_idx idx1, sl_to_idx idx2)
  | Some (([{ it = Atom "ELEM.DROP"; _ }] :: _), [idx]) -> ElemDrop (sl_to_idx idx)
  | Some (([{ it = Atom "LOAD"; _ }] :: _), [idx; op]) -> Load (sl_to_idx idx, sl_to_loadop op)
  | Some (([{ it = Atom "STORE"; _ }] :: _), [idx; op]) -> Store (sl_to_idx idx, sl_to_storeop op)
  | Some (([{ it = Atom "VEC.LOAD"; _ }] :: _), [idx; op]) -> VecLoad (sl_to_idx idx, sl_to_vec_loadop op)
  | Some (([{ it = Atom "VEC.STORE"; _ }] :: _), [idx; op]) -> VecStore (sl_to_idx idx, sl_to_vec_storeop op)
  | Some (([{ it = Atom "VEC.LOAD_LANE"; _ }] :: _), [idx; op; i]) -> VecLoadLane (sl_to_idx idx, sl_to_vec_laneop op, sl_to_int i)
  | Some (([{ it = Atom "VEC.STORE_LANE"; _ }] :: _), [idx; op; i]) -> VecStoreLane (sl_to_idx idx, sl_to_vec_laneop op, sl_to_int i)
  | Some (([{ it = Atom "MEMORY.SIZE"; _ }] :: _), [idx]) -> MemorySize (sl_to_idx idx)
  | Some (([{ it = Atom "MEMORY.GROW"; _ }] :: _), [idx]) -> MemoryGrow (sl_to_idx idx)
  | Some (([{ it = Atom "MEMORY.FILL"; _ }] :: _), [idx]) -> MemoryFill (sl_to_idx idx)
  | Some (([{ it = Atom "MEMORY.COPY"; _ }] :: _), [idx1; idx2]) -> MemoryCopy (sl_to_idx idx1, sl_to_idx idx2)
  | Some (([{ it = Atom "MEMORY.INIT"; _ }] :: _), [idx1; idx2]) -> MemoryInit (sl_to_idx idx1, sl_to_idx idx2)
  | Some (([{ it = Atom "DATA.DROP"; _ }] :: _), [idx]) -> DataDrop (sl_to_idx idx)
  | Some (([{ it = Atom "REF.NULL"; _ }] :: _), [ht]) -> RefNull (sl_to_heap_type ht)
  | Some (([{ it = Atom "REF.FUNC"; _ }] :: _), [idx]) -> RefFunc (sl_to_idx idx)
  | Some ([[{ it = Atom "REF.IS_NULL"; _ }]], []) -> RefIsNull
  | Some ([[{ it = Atom "REF.AS_NON_NULL"; _ }]], []) -> RefAsNonNull
  | Some (([{ it = Atom "REF.TEST"; _ }] :: _), [rt]) -> RefTest (sl_to_ref_type rt)
  | Some (([{ it = Atom "REF.CAST"; _ }] :: _), [rt]) -> RefCast (sl_to_ref_type rt)
  | Some ([[{ it = Atom "REF.EQ"; _ }]], []) -> RefEq
  | Some ([[{ it = Atom "REF.I31"; _ }]], []) -> RefI31
  | Some (([{ it = Atom "I31.GET"; _ }] :: _), [ext]) -> I31Get (sl_to_extension ext)
  | Some (([{ it = Atom "STRUCT.NEW"; _ }] :: _), [idx; initop]) -> StructNew (sl_to_idx idx, sl_to_initop initop)
  | Some (([{ it = Atom "STRUCT.GET"; _ }] :: _), [idx1; idx2; ext_opt]) -> StructGet (sl_to_idx idx1, sl_to_idx idx2, sl_to_opt sl_to_extension ext_opt)
  | Some (([{ it = Atom "STRUCT.SET"; _ }] :: _), [idx1; idx2]) -> StructSet (sl_to_idx idx1, sl_to_idx idx2)
  | Some (([{ it = Atom "ARRAY.NEW"; _ }] :: _), [idx; initop]) -> ArrayNew (sl_to_idx idx, sl_to_initop initop)
  | Some (([{ it = Atom "ARRAY.NEW_FIXED"; _ }] :: _), [idx; n]) -> ArrayNewFixed (sl_to_idx idx, sl_to_nat32 n)
  | Some (([{ it = Atom "ARRAY.NEW_ELEM"; _ }] :: _), [idx1; idx2]) -> ArrayNewElem (sl_to_idx idx1, sl_to_idx idx2)
  | Some (([{ it = Atom "ARRAY.NEW_DATA"; _ }] :: _), [idx1; idx2]) -> ArrayNewData (sl_to_idx idx1, sl_to_idx idx2)
  | Some (([{ it = Atom "ARRAY.GET"; _ }] :: _), [idx; ext_opt]) -> ArrayGet (sl_to_idx idx, sl_to_opt sl_to_extension ext_opt)
  | Some (([{ it = Atom "ARRAY.SET"; _ }] :: _), [idx]) -> ArraySet (sl_to_idx idx)
  | Some ([[{ it = Atom "ARRAY.LEN"; _ }]], []) -> ArrayLen
  | Some (([{ it = Atom "ARRAY.COPY"; _ }] :: _), [idx1; idx2]) -> ArrayCopy (sl_to_idx idx1, sl_to_idx idx2)
  | Some (([{ it = Atom "ARRAY.FILL"; _ }] :: _), [idx]) -> ArrayFill (sl_to_idx idx)
  | Some (([{ it = Atom "ARRAY.INIT_DATA"; _ }] :: _), [idx1; idx2]) -> ArrayInitData (sl_to_idx idx1, sl_to_idx idx2)
  | Some (([{ it = Atom "ARRAY.INIT_ELEM"; _ }] :: _), [idx1; idx2]) -> ArrayInitElem (sl_to_idx idx1, sl_to_idx idx2)
  | Some (([{ it = Atom "EXTERN.CONVERT"; _ }] :: _), [op]) -> ExternConvert (sl_to_externop op)
  | Some (([{ it = Atom "CONST"; _ }] :: _), [num]) -> Const (sl_to_phrase sl_to_num num)
  | Some (([{ it = Atom "TEST"; _ }] :: _), [op]) -> Test (sl_to_testop op)
  | Some (([{ it = Atom "COMPARE"; _ }] :: _), [op]) -> Compare (sl_to_relop op)
  | Some (([{ it = Atom "UNARY"; _ }] :: _), [op]) -> Unary (sl_to_unop op)
  | Some (([{ it = Atom "BINOP"; _ }] :: _), [op]) -> Binary (sl_to_binop op)
  | Some (([{ it = Atom "CONVERT"; _ }] :: _), [op]) -> Convert (sl_to_cvtop op)
  | Some (([{ it = Atom "VEC.CONST"; _ }] :: _), [vec]) -> VecConst (sl_to_phrase sl_to_vec vec)
  | Some (([{ it = Atom "VEC.TEST"; _ }] :: _), [op]) -> VecTest (sl_to_vtestop op)
  | Some (([{ it = Atom "VEC.UNARY"; _ }] :: _), [op]) -> VecUnary (sl_to_vunop op)
  | Some (([{ it = Atom "VEC.BINARY"; _ }] :: _), [op]) -> VecBinary (sl_to_vbinop op)
  | Some (([{ it = Atom "VEC.COMPARE"; _ }] :: _), [op]) -> VecCompare (sl_to_vrelop op)
  | Some (([{ it = Atom "VEC.TERNARY"; _ }] :: _), [op]) -> VecTernary (sl_to_vternop op)
  | Some (([{ it = Atom "VEC.CONVERT"; _ }] :: _), [op]) -> VecConvert (sl_to_vcvtop op)
  | Some (([{ it = Atom "VEC.SHIFT"; _ }] :: _), [op]) -> VecShift (sl_to_vshiftop op)
  | Some (([{ it = Atom "VEC.BITMASK"; _ }] :: _), [op]) -> VecBitmask (sl_to_vbitmaskop op)
  | Some (([{ it = Atom "VEC.TESTBITS"; _ }] :: _), [op]) -> VecTestBits (sl_to_vvtestop op)
  | Some (([{ it = Atom "VEC.UNARYBITS"; _ }] :: _), [op]) -> VecUnaryBits (sl_to_vvunop op)
  | Some (([{ it = Atom "VEC.BINARYBITS"; _ }] :: _), [op]) -> VecBinaryBits (sl_to_vvbinop op)
  | Some (([{ it = Atom "VEC.TERNARYBITS"; _ }] :: _), [op]) -> VecTernaryBits (sl_to_vvternop op)
  | Some (([{ it = Atom "VEC.SPLAT"; _ }] :: _), [op]) -> VecSplat (sl_to_vsplatop op)
  | Some (([{ it = Atom "VEC.EXTRACT"; _ }] :: _), [op]) -> VecExtract (sl_to_vextractop op)
  | Some (([{ it = Atom "VEC.REPLACE"; _ }] :: _), [op]) -> VecReplace (sl_to_vreplaceop op)
  | _ -> failwith "Unsupported instr in sl_to_instr"

and sl_to_instr (value: Value.t) : Ast.instr = sl_to_phrase sl_to_instr' value

and sl_to_const (value: Value.t) : Ast.const =
  Wasm_interpreter.Source.((sl_to_list sl_to_instr value) @@ no_region)

and sl_to_global_type (value: Value.t) : Types.global_type =
  match sl_case value with
  | Some (([{ it = Atom "GlobalT"; _ }] :: _), [mut; vt]) ->
    GlobalT (sl_to_mut mut, sl_to_val_type vt)
  | _ -> failwith "Expected globaltype"

and sl_to_global' (value: Value.t) : Ast.global' =
  match (value.note.typ, value.it) with
  | VarT ({ it = "global"; _ }, _), StructV valuefields ->
    let _atoms, values = List.split valuefields in
    (match values with
    | [ gtype; ginit ] ->
      {
        gtype = sl_to_global_type gtype;
        ginit = sl_to_const ginit;
      }
    | _ -> failwith "Expect 2 global fields")
  | _ -> failwith "Expect global with StructV, but different value is given."

and sl_to_global (value: Value.t) : Ast.global = sl_to_phrase sl_to_global' value

and sl_to_name (value: Value.t) : Ast.name = Unwrap.unwrap_text_v value |> Wasm_interpreter.Utf8.decode

and sl_to_addr_type (value: Value.t) : Types.addr_type =
  match sl_case value with
  | Some ([[{ it = Atom "I32AT"; _ }]], []) -> I32AT
  | Some ([[{ it = Atom "I64AT"; _ }]], []) -> I64AT
  | _ -> failwith "Expected addrtype"

and sl_to_limits (value: Value.t) : Types.limits =
  match value.it with
  | StructV valuefields ->
    let _atoms, values = List.split valuefields in
    (match values with
    | [min; max] -> { min = sl_to_int64 min; max = sl_to_opt sl_to_int64 max }
    | _ -> failwith "Expect 2 limits fields")
  | _ -> failwith "Expected limits"

and sl_to_table_type (value: Value.t) : Types.table_type =
  match sl_case value with
  | Some (([{ it = Atom "TableT"; _ }] :: _), [at; limits; rt]) -> TableT (sl_to_addr_type at, sl_to_limits limits, sl_to_ref_type rt)
  | _ -> failwith "Expected tabletype"

and sl_to_memory_type (value: Value.t) : Types.memory_type =
  match sl_case value with
  | Some (([{ it = Atom "MemoryT"; _ }] :: _), [at; limits]) -> MemoryT (sl_to_addr_type at, sl_to_limits limits)
  | _ -> failwith "Expected memtype"

and sl_to_table' (value: Value.t) : Ast.table' =
  match (value.note.typ, value.it) with
  | VarT ({ it = "table"; _ }, _), StructV valuefields ->
    let _atoms, values = List.split valuefields in
    (match values with
    | [ttype; tinit] -> { ttype = sl_to_table_type ttype; tinit = sl_to_const tinit }
    | _ -> failwith "Expect 2 table fields")
  | _ -> failwith "Expect table with StructV, but different value is given."

and sl_to_table (value: Value.t) : Ast.table = sl_to_phrase sl_to_table' value

and sl_to_memory' (value: Value.t) : Ast.memory' =
  match (value.note.typ, value.it) with
  | VarT ({ it = "memory"; _ }, _), StructV valuefields ->
    let _atoms, values = List.split valuefields in
    (match values with
    | [mtype] -> { mtype = sl_to_memory_type mtype }
    | _ -> failwith "Expect 1 memory field")
  | _ -> failwith "Expect memory with StructV, but different value is given."

and sl_to_memory (value: Value.t) : Ast.memory = sl_to_phrase sl_to_memory' value

and sl_to_tag' (value: Value.t) : Ast.tag' =
  match (value.note.typ, value.it) with
  | VarT ({ it = "tag"; _ }, _), StructV valuefields ->
    let _atoms, values = List.split valuefields in
    (match values with
    | [tgtype] -> { tgtype = sl_to_idx tgtype }
    | _ -> failwith "Expect 1 tag field")
  | _ -> failwith "Expect tag with StructV, but different value is given."

and sl_to_tag (value: Value.t) : Ast.tag = sl_to_phrase sl_to_tag' value

and sl_to_local' (value: Value.t) : Ast.local' =
  match (value.note.typ, value.it) with
  | VarT ({ it = "local"; _ }, _), StructV valuefields ->
    let _atoms, values = List.split valuefields in
    (match values with
    | [ltype] -> { ltype = sl_to_val_type ltype }
    | _ -> failwith "Expect 1 local field")
  | _ -> failwith "Expect local with StructV, but different value is given."

and sl_to_local (value: Value.t) : Ast.local = sl_to_phrase sl_to_local' value

and sl_to_func' (value: Value.t) : Ast.func' =
  match (value.note.typ, value.it) with
  | VarT ({ it = "func"; _ }, _), StructV valuefields ->
    let _atoms, values = List.split valuefields in
    (match values with
    | [ftype; locals; body] ->
      {
        ftype = sl_to_idx ftype;
        locals = sl_to_list sl_to_local locals;
        body = sl_to_list sl_to_instr body;
      }
    | _ -> failwith "Expect 3 func fields")
  | _ -> failwith "Expect func with StructV, but different value is given."

and sl_to_func (value: Value.t) : Ast.func = sl_to_phrase sl_to_func' value

and sl_to_start' (value: Value.t) : Ast.start' =
  match (value.note.typ, value.it) with
  | VarT ({ it = "start"; _ }, _), StructV valuefields ->
    let _atoms, values = List.split valuefields in
    (match values with
    | [sfunc] -> { sfunc = sl_to_idx sfunc }
    | _ -> failwith "Expect 1 start field")
  | _ -> failwith "Expect start with StructV, but different value is given."

and sl_to_start (value: Value.t) : Ast.start = sl_to_phrase sl_to_start' value

and sl_to_elemmode' (value: Value.t) : Ast.segment_mode' =
  match sl_case value with
  | Some ([[{ it = Atom "Passive"; _ }]], []) -> Passive
  | Some (([{ it = Atom "Active"; _ }] :: _), [active]) ->
    (match active.it with
    | StructV valuefields ->
      let _atoms, values = List.split valuefields in
      (match values with
      | [index; offset] -> Active { index = sl_to_idx index; offset = sl_to_const offset }
      | _ -> failwith "Expect 2 active fields")
    | _ -> failwith "Expect active struct")
  | Some ([[{ it = Atom "Declarative"; _ }]], []) -> Declarative
  | _ -> failwith "Expected elemmode"

and sl_to_elemmode (value: Value.t) : Ast.segment_mode = sl_to_phrase sl_to_elemmode' value

and sl_to_elem' (value: Value.t) : Ast.elem_segment' =
  match (value.note.typ, value.it) with
  | VarT ({ it = "elem"; _ }, _), StructV valuefields ->
    let _atoms, values = List.split valuefields in
    (match values with
    | [etype; einit; emode] ->
      {
        etype = sl_to_ref_type etype;
        einit = sl_to_list sl_to_const einit;
        emode = sl_to_elemmode emode;
      }
    | _ -> failwith "Expect 3 elem fields")
  | _ -> failwith "Expect elem with StructV, but different value is given."

and sl_to_elem (value: Value.t) : Ast.elem_segment = sl_to_phrase sl_to_elem' value

and sl_to_datamode' (value: Value.t) : Ast.segment_mode' =
  match sl_case value with
  | Some ([[{ it = Atom "Passive"; _ }]], []) -> Passive
  | Some (([{ it = Atom "Active"; _ }] :: _), [active]) ->
    (match active.it with
    | StructV valuefields ->
      let _atoms, values = List.split valuefields in
      (match values with
      | [index; offset] -> Active { index = sl_to_idx index; offset = sl_to_const offset }
      | _ -> failwith "Expect 2 active fields")
    | _ -> failwith "Expect active struct")
  | _ -> failwith "Expected datamode"

and sl_to_datamode (value: Value.t) : Ast.segment_mode = sl_to_phrase sl_to_datamode' value

and sl_to_data' (value: Value.t) : Ast.data_segment' =
  match (value.note.typ, value.it) with
  | VarT ({ it = "data"; _ }, _), StructV valuefields ->
    let _atoms, values = List.split valuefields in
    (match values with
    | [dinit; dmode] ->
      {
        dinit = Unwrap.unwrap_text_v dinit;
        dmode = sl_to_datamode dmode;
      }
    | _ -> failwith "Expect 2 data fields")
  | _ -> failwith "Expect data with StructV, but different value is given."

and sl_to_data (value: Value.t) : Ast.data_segment = sl_to_phrase sl_to_data' value

and sl_to_import_desc' (value: Value.t) : Ast.import_desc' =
  match sl_case value with
  | Some (([{ it = Atom "FuncImport"; _ }] :: _), [idx]) -> FuncImport (sl_to_idx idx)
  | Some (([{ it = Atom "TableImport"; _ }] :: _), [ttype]) -> TableImport (sl_to_table_type ttype)
  | Some (([{ it = Atom "MemImport"; _ }] :: _), [mtype]) -> MemoryImport (sl_to_memory_type mtype)
  | Some (([{ it = Atom "GlobalImport"; _ }] :: _), [gtype]) -> GlobalImport (sl_to_global_type gtype)
  | Some (([{ it = Atom "TagImport"; _ }] :: _), [idx]) -> TagImport (sl_to_idx idx)
  | _ -> failwith "Expected importdesc"

and sl_to_import_desc (value: Value.t) : Ast.import_desc = sl_to_phrase sl_to_import_desc' value

and sl_to_import' (value: Value.t) : Ast.import' =
  match (value.note.typ, value.it) with
  | VarT ({ it = "import"; _ }, _), StructV valuefields ->
    let _atoms, values = List.split valuefields in
    (match values with
    | [module_name; item_name; idesc] ->
      {
        module_name = sl_to_name module_name;
        item_name = sl_to_name item_name;
        idesc = sl_to_import_desc idesc;
      }
    | _ -> failwith "Expect 3 import fields")
  | _ -> failwith "Expect import with StructV, but different value is given."

and sl_to_import (value: Value.t) : Ast.import = sl_to_phrase sl_to_import' value

and sl_to_export_desc' (value: Value.t) : Ast.export_desc' =
  match sl_case value with
  | Some (([{ it = Atom "FuncExport"; _ }] :: _), [idx]) -> FuncExport (sl_to_idx idx)
  | Some (([{ it = Atom "TableExport"; _ }] :: _), [idx]) -> TableExport (sl_to_idx idx)
  | Some (([{ it = Atom "MemExport"; _ }] :: _), [idx]) -> MemoryExport (sl_to_idx idx)
  | Some (([{ it = Atom "GlobalExport"; _ }] :: _), [idx]) -> GlobalExport (sl_to_idx idx)
  | Some (([{ it = Atom "TagExport"; _ }] :: _), [idx]) -> TagExport (sl_to_idx idx)
  | _ -> failwith "Expected exportdesc"

and sl_to_export_desc (value: Value.t) : Ast.export_desc = sl_to_phrase sl_to_export_desc' value

and sl_to_export' (value: Value.t) : Ast.export' =
  match (value.note.typ, value.it) with
  | VarT ({ it = "export"; _ }, _), StructV valuefields ->
    let _atoms, values = List.split valuefields in
    (match values with
    | [name; edesc] ->
      {
        name = sl_to_name name;
        edesc = sl_to_export_desc edesc;
      }
    | _ -> failwith "Expect 2 export fields")
  | _ -> failwith "Expect export with StructV, but different value is given."

and sl_to_export (value: Value.t) : Ast.export = sl_to_phrase sl_to_export' value

and sl_to_type (value : Value.t) : Ast.type_ = sl_to_phrase sl_to_rec_type value

let sl_to_module' (value: Value.t) : Ast.module_' =
  match (value.note.typ, value.it) with
  | VarT ({ it = "module"; _ }, _), StructV valuefields ->
    let _atoms, values = List.split valuefields in
    (match values with
    | [
     types;
     globals;
     tables;
     memories;
     tags;
     funcs;
     start;
     elems;
     datas;
     imports;
     exports;
    ] ->
      {
        types = sl_to_list sl_to_type types;
        globals = sl_to_list sl_to_global globals;
        tables = sl_to_list sl_to_table tables;
        memories = sl_to_list sl_to_memory memories;
        tags = sl_to_list sl_to_tag tags;
        funcs = sl_to_list sl_to_func funcs;
        start = sl_to_opt sl_to_start start;
        elems = sl_to_list sl_to_elem elems;
        datas = sl_to_list sl_to_data datas;
        imports = sl_to_list sl_to_import imports;
        exports = sl_to_list sl_to_export exports;
      }
    | _ -> failwith "Expect 11 module fields")
  | _ -> failwith "Expect module with StructV, but different value is given."

let sl_to_module (value : Value.t) : Ast.module_ = sl_to_phrase sl_to_module' value
