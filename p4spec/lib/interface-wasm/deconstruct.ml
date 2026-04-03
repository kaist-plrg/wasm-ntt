module Value = Runtime.Dynamic_Il.Value
module Ast = Wasm_interpreter.Ast
module Types = Wasm_interpreter.Types
module Wasm_Value = Wasm_interpreter.Value
module Pack = Wasm_interpreter.Pack
module I32 = Wasm_interpreter.I32
module I64 = Wasm_interpreter.I64
module F32 = Wasm_interpreter.F32
module F64 = Wasm_interpreter.F64
module V128 = Wasm_interpreter.V128

let sl_to_phrase (f : Value.t -> 'a) (v : Value.t) : 'a Wasm_interpreter.Source.phrase =
  Wasm_interpreter.Source.((f v) @@ no_region)

let sl_to_list (f: Value.t -> 'a) (v: Value.t) : 'a list =
  Interface.Unwrap.unwrap_list_v v |> List.map f

let sl_to_opt (f: Value.t -> 'a) (v: Value.t) : 'a option =
  Interface.Unwrap.unwrap_opt_v v |> Option.map f

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

let sl_to_z_nat (value: Value.t) : Z.t =  Interface.Unwrap.unwrap_num_v value |> Bigint.to_zarith_bigint

let sl_to_z_int (value: Value.t) : Z.t = Interface.Unwrap.unwrap_num_v value |> Bigint.to_zarith_bigint

let z_to_intN signed unsigned z = if z < Z.zero then signed z else unsigned z

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
  match value.it with
  | CaseV ([[{ it = Atom "SUBNORM"; _ }]; _], [m]) -> sl_to_z_nat m
  | CaseV ([[{ it = Atom "NORM"; _ }]; _; _], [m; exp]) -> Z.(shift_left (sl_to_z_int exp + bias layout) layout.mantissa + sl_to_z_nat m)
  | CaseV ([[{ it = Atom "INF"; _ }]], []) -> mask_exp layout
  | CaseV ([[{ it = Atom "NAN"; _ }]; _], [m]) -> Z.(mask_exp layout + sl_to_z_nat m)
  | _ -> failwith "Expected f32mag/f64mag"

let sl_to_floatN (layout: layout) (value: Value.t) : Z.t =
  match value.it with
  | CaseV ([[{ it = Atom "POS"; _ }]; _], [mag]) -> sl_to_fmagN layout mag
  | CaseV ([[{ it = Atom "NEG"; _ }]; _], [mag]) -> Z.(mask_sign layout + sl_to_fmagN layout mag)
  | _ -> failwith "Expected f32/f64"

let sl_to_float32 (value: Value.t) : F32.t =
  sl_to_floatN layout32 value |> Z.to_int32_unsigned |> F32.of_bits

let sl_to_float64 (value: Value.t) : F64.t =
  sl_to_floatN layout64 value |> Z.to_int64_unsigned |> F64.of_bits

let sl_to_idx (value: Value.t) : Ast.idx = sl_to_phrase sl_to_nat32 value

let sl_to_num (value: Value.t) : Wasm_Value.num =
  match value.it with
  | CaseV ([[{ it = Atom "I32"; _ }]; _], [i32]) ->
    Wasm_Value.I32 (sl_to_nat32 i32)
  | CaseV ([[{ it = Atom "I64"; _ }]; _], [i64]) ->
    Wasm_Value.I64 (sl_to_nat64 i64)
  | CaseV ([[{ it = Atom "F32"; _ }]; _], [f32]) ->
    Wasm_Value.F32 (sl_to_float32 f32)
  | CaseV ([[{ it = Atom "F64"; _ }]; _], [f64]) ->
    Wasm_Value.F64 (sl_to_float64 f64)
  | _ -> failwith "Expected num_"

let sl_to_vec (value: Value.t) : Wasm_Value.vec =
  let e64 = Z.shift_left Z.one 64 in
  match value.it with
  | CaseV ([[{ it = Atom "V128"; _ }]; _], [v]) ->
    let z = sl_to_z_nat v in
    let low = Z.(erem z e64) |> Z.to_int64_unsigned in
    let high = Z.(shift_right z 64) |> Z.to_int64_unsigned in
    Wasm_Value.V128 (V128.I64x2.of_lanes [ low; high ])
  | _ -> failwith "Expected vec_"

let rec sl_to_final (value: Value.t) : Types.final =
  match value.it with
  | CaseV ([[{ it = Atom "NoFinal"; _ }]], []) -> NoFinal
  | CaseV ([[{ it = Atom "Final"; _ }]], []) -> Final
  | _ -> failwith "Expected final"

and sl_to_typeuse (value: Value.t) : Types.var =
  match value.it with
  | CaseV ([[{ it = Atom "StatX"; _ }]; _], [ i32 ]) -> StatX (sl_to_nat32 i32)
  | CaseV ([[{ it = Atom "RecX"; _ }]; _], [ i32 ]) -> RecX (sl_to_nat32 i32)
  | _ -> failwith "Expected var"

and sl_to_def_type (value: Value.t) : Types.def_type =
  match value.it with
  | CaseV ([[{ it = Atom "DefT"; _ }]; _], [rt; i32]) -> DefT (sl_to_rec_type rt, sl_to_nat32 i32)
  | _ -> failwith "Expected final"

and sl_to_heap_type (value: Value.t) : Types.heap_type =
  match value.it with
  | CaseV ([[{ it = Atom "VarHT"; _ }]; _], [value]) -> VarHT (sl_to_typeuse value)
  | CaseV ([[{ it = Atom "DefHT"; _ }]; _], [value]) -> DefHT (sl_to_def_type value)
  | CaseV ([[{ it = Atom tag; _ }]], []) when is_heap_type_tag tag -> heap_type_of_tag tag
  | _ -> failwith "Expected heaptype"

and sl_to_mut (value: Value.t) : Types.mut =
  match value.it with
  | CaseV ([[{ it = Atom "Cons"; _ }]], []) -> Cons
  | CaseV ([[{ it = Atom "Var"; _ }]], []) -> Var
  | _ -> failwith "Excpected mut"

and sl_to_num_type (value: Value.t) : Types.num_type =
  match value.it with
  | CaseV ([[{ it = Atom "I32T"; _ }]], []) -> I32T
  | CaseV ([[{ it = Atom "I64T"; _ }]], []) -> I64T
  | CaseV ([[{ it = Atom "F32T"; _ }]], []) -> F32T
  | CaseV ([[{ it = Atom "F64T"; _ }]], []) -> F64T
  | _ -> failwith "Excpected numtype"

and sl_to_null (value: Value.t) : Types.null =
  match value.it with
  | CaseV ([[{ it = Atom "Null"; _ }]], []) -> Null
  | CaseV ([[{ it = Atom "NoNull"; _ }]], []) -> NoNull
  | _ -> failwith "Excpected null"

and sl_to_ref_type (value: Value.t) : Types.ref_type =
  match value.it with
  | CaseV ([[]; []; []], [null; ht]) -> (sl_to_null null, sl_to_heap_type ht)
  | _ -> failwith "Excpected reftype"

and sl_to_vec_type (value: Value.t) : Types.vec_type =
  match value.it with
  | CaseV ([[{ it = Atom "V128T"; _ }]], []) -> V128T
  | _ -> failwith "Excpected vectype"

and sl_to_val_type (value: Value.t) : Types.val_type =
  match value.it with
  | CaseV ([[{ it = Atom "NumT"; _ }]; _], [nt]) -> NumT (sl_to_num_type nt)
  | CaseV ([[{ it = Atom "RefT"; _ }]; _], [rt]) -> RefT (sl_to_ref_type rt)
  | CaseV ([[{ it = Atom "VecT"; _ }]; _], [vt]) -> VecT (sl_to_vec_type vt)
  | _ -> failwith "Excpected valtype"

and sl_to_pack_type (value: Value.t) : Pack.pack_size =
  match value.it with
  | CaseV ([[{ it = Atom "I8"; _ }]], []) -> Pack8
  | CaseV ([[{ it = Atom "I16"; _ }]], []) -> Pack16
  | CaseV ([[{ it = Atom "I32"; _ }]], []) -> Pack32
  | CaseV ([[{ it = Atom "I64"; _ }]], []) -> Pack64
  | _ -> failwith "Excpected packtype"

and sl_to_storage_type (value: Value.t) : Types.storage_type =
  match value.it with
  | CaseV ([[{ it = Atom "ValStorageT"; _ }]; _], [vt]) -> ValStorageT (sl_to_val_type vt)
  | CaseV ([[{ it = Atom "PackStorageT"; _ }]; _], [pt]) -> PackStorageT (sl_to_pack_type pt)
  | _ -> failwith "Excpected storagetype"

and sl_to_field_type (value: Value.t) : Types.field_type =
  match value.it with
  | CaseV ([[{ it = Atom "FieldT"; _ }]; _], [mut; st]) -> FieldT (sl_to_mut mut, sl_to_storage_type st)
  | _ -> failwith "Excpected fieldtype"

and sl_to_struct_type (value: Value.t) : Types.struct_type =
  match value.it with
  | CaseV ([[{ it = Atom "StructT"; _ }]; _], [ftl]) -> StructT (sl_to_list sl_to_field_type ftl)
  | _ -> failwith "Excpected structtype"

and sl_to_array_type (value: Value.t) : Types.array_type =
  match value.it with
  | CaseV ([[{ it = Atom "ArrayT"; _ }]; _], [ft]) -> ArrayT (sl_to_field_type ft)
  | _ -> failwith "Excpected arraytype"

and sl_to_result_type (value: Value.t) : Types.result_type = sl_to_list sl_to_val_type value

and sl_to_func_type (value: Value.t) : Types.func_type =
  match value.it with
  | CaseV ([[{ it = Atom "FuncT"; _ }]; _], [rt1; rt2]) -> FuncT (sl_to_result_type rt1, sl_to_result_type rt2)
  | _ -> failwith "Excpected functype"

and sl_to_str_type (value: Value.t) : Types.str_type =
  match value.it with
  | CaseV ([[{ it = Atom "DefStructT"; _ }]; _], [st]) -> DefStructT (sl_to_struct_type st)
  | CaseV ([[{ it = Atom "DefArrayT"; _ }]; _], [arrt]) -> DefArrayT (sl_to_array_type arrt)
  | CaseV ([[{ it = Atom "DefFuncT"; _ }]; _], [ft]) -> DefFuncT (sl_to_func_type ft)
  | _ -> failwith "Excpected strtype"

and sl_to_sub_type (value: Value.t) : Types.sub_type =
  match value.it with
  | CaseV ([[{ it = Atom "SubT"; _ }]; _], [fin; htl; st]) -> SubT (sl_to_final fin, sl_to_list sl_to_heap_type htl, sl_to_str_type st)
  | _ -> failwith "Excpected subtype"

and sl_to_rec_type (value: Value.t) : Types.rec_type =
  match value.it with
  | CaseV ([[{ it = Atom "RecT"; _ }]; _], [stl]) -> RecT (sl_to_list sl_to_sub_type stl)
  | _ -> failwith "Expected rectype"

and sl_to_int (value: Value.t) : int = sl_to_z_int value |> Z.to_int

and sl_to_int64 (value: Value.t) : int64 = sl_to_z_int value |> z_to_intN Z.to_int64 Z.to_int64_unsigned

and sl_to_void (value: Value.t) : unit =
  match value.it with
  | StructV [] -> ()
  | _ -> failwith "Expected void"

and sl_to_select_type_opt (value: Value.t) : Types.val_type list option = sl_to_opt (sl_to_list sl_to_val_type) value

and sl_to_extension (value: Value.t) : Pack.extension =
  match value.it with
  | CaseV ([[{ it = Atom "SX"; _ }]], []) -> SX
  | CaseV ([[{ it = Atom "ZX"; _ }]], []) -> ZX
  | _ -> failwith "Expected extension"

and sl_to_pack_shape (value: Value.t) : Pack.pack_shape =
  match value.it with
  | CaseV ([[{ it = Atom "Pack8x8"; _ }]], []) -> Pack.Pack8x8
  | CaseV ([[{ it = Atom "Pack16x4"; _ }]], []) -> Pack.Pack16x4
  | CaseV ([[{ it = Atom "Pack32x2"; _ }]], []) -> Pack.Pack32x2
  | _ -> failwith "Expected packshape"

and sl_to_vec_extension (value: Value.t) : Pack.vec_extension =
  match value.it with
  | CaseV ([[{ it = Atom "ExtLane"; _ }]; _; _], [shape; ext]) -> Pack.ExtLane (sl_to_pack_shape shape, sl_to_extension ext)
  | CaseV ([[{ it = Atom "ExtSplat"; _ }]], []) -> Pack.ExtSplat
  | CaseV ([[{ it = Atom "ExtZero"; _ }]], []) -> Pack.ExtZero
  | _ -> failwith "Expected vextension"

and sl_to_initop (value: Value.t) : Ast.initop =
  match value.it with
  | CaseV ([[{ it = Atom "Explicit"; _ }]], []) -> Explicit
  | CaseV ([[{ it = Atom "Implicit"; _ }]], []) -> Implicit
  | _ -> failwith "Expected initop"

and sl_to_externop (value: Value.t) : Ast.externop =
  match value.it with
  | CaseV ([[{ it = Atom "Internalize"; _ }]], []) -> Internalize
  | CaseV ([[{ it = Atom "Externalize"; _ }]], []) -> Externalize
  | _ -> failwith "Expected externop"

and sl_to_block_type (value: Value.t) : Ast.block_type =
  match value.it with
  | CaseV ([[{ it = Atom "VarBlockType"; _ }]; _], [idx]) -> VarBlockType (sl_to_idx idx)
  | CaseV ([[{ it = Atom "ValBlockType"; _ }]; _], [vt_opt]) -> ValBlockType (sl_to_opt sl_to_val_type vt_opt)
  | _ -> failwith "Expected blocktype"

and sl_to_catch' (value: Value.t) : Ast.catch' =
  match value.it with
  | CaseV ([[{ it = Atom "Catch"; _ }]; _; _], [idx1; idx2]) -> Catch (sl_to_idx idx1, sl_to_idx idx2)
  | CaseV ([[{ it = Atom "CatchRef"; _ }]; _; _], [idx1; idx2]) -> CatchRef (sl_to_idx idx1, sl_to_idx idx2)
  | CaseV ([[{ it = Atom "CatchAll"; _ }]; _], [idx]) -> CatchAll (sl_to_idx idx)
  | CaseV ([[{ it = Atom "CatchAllRef"; _ }]; _], [idx]) -> CatchAllRef (sl_to_idx idx)
  | _ -> failwith "Expected catch"

and sl_to_catch (value: Value.t) : Ast.catch = sl_to_phrase sl_to_catch' value

and sl_to_pack_type_extension (value: Value.t) : Pack.pack_size * Pack.extension =
  let pt, ext = Interface.Unwrap.unwrap_tuple_v_two value in
  (sl_to_pack_type pt, sl_to_extension ext)

and sl_to_pack_type_vec_extension (value: Value.t) : Pack.pack_size * Pack.vec_extension =
  let pt, ext = Interface.Unwrap.unwrap_tuple_v_two value in
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
    match value.it with
    | CaseV ([[{ it = Atom "I32"; _ }]; _], [op]) -> Wasm_Value.I32 (f_int op)
    | CaseV ([[{ it = Atom "I64"; _ }]; _], [op]) -> Wasm_Value.I64 (f_int op)
    | CaseV ([[{ it = Atom "F32"; _ }]; _], [op]) -> Wasm_Value.F32 (f_float op)
    | CaseV ([[{ it = Atom "F64"; _ }]; _], [op]) -> Wasm_Value.F64 (f_float op)
    | _ -> failwith "Expected op"

and sl_to_int_unop (value: Value.t) : Ast.IntOp.unop =
  match value.it with
  | CaseV ([[{ it = Atom "Clz"; _ }]], []) -> Clz
  | CaseV ([[{ it = Atom "Ctz"; _ }]], []) -> Ctz
  | CaseV ([[{ it = Atom "Popcnt"; _ }]], []) -> Popcnt
  | CaseV ([[{ it = Atom "ExtendS"; _ }]; _], [pt]) -> ExtendS (sl_to_pack_type pt)
  | _ -> failwith "Expected iunop"

and sl_to_float_unop (value: Value.t) : Ast.FloatOp.unop =
  match value.it with
  | CaseV ([[{ it = Atom "Neg"; _ }]], []) -> Neg
  | CaseV ([[{ it = Atom "Abs"; _ }]], []) -> Abs
  | CaseV ([[{ it = Atom "Ceil"; _ }]], []) -> Ceil
  | CaseV ([[{ it = Atom "Floor"; _ }]], []) -> Floor
  | CaseV ([[{ it = Atom "Trunc"; _ }]], []) -> Trunc
  | CaseV ([[{ it = Atom "Nearest"; _ }]], []) -> Nearest
  | CaseV ([[{ it = Atom "Sqrt"; _ }]], []) -> Sqrt
  | _ -> failwith "Expected funop"

and sl_to_unop (value: Value.t) : Ast.unop = sl_to_op sl_to_int_unop sl_to_float_unop value

and sl_to_int_binop (value: Value.t) : Ast.IntOp.binop =
  match value.it with
  | CaseV ([[{ it = Atom "IAdd"; _ }]], []) -> Add
  | CaseV ([[{ it = Atom "ISub"; _ }]], []) -> Sub
  | CaseV ([[{ it = Atom "IMul"; _ }]], []) -> Mul
  | CaseV ([[{ it = Atom "IDivS"; _ }]], []) -> DivS
  | CaseV ([[{ it = Atom "IDivU"; _ }]], []) -> DivU
  | CaseV ([[{ it = Atom "IRemS"; _ }]], []) -> RemS
  | CaseV ([[{ it = Atom "IRemU"; _ }]], []) -> RemU
  | CaseV ([[{ it = Atom "IAnd"; _ }]], []) -> And
  | CaseV ([[{ it = Atom "IOr"; _ }]], []) -> Or
  | CaseV ([[{ it = Atom "IXor"; _ }]], []) -> Xor
  | CaseV ([[{ it = Atom "IShl"; _ }]], []) -> Shl
  | CaseV ([[{ it = Atom "IShrS"; _ }]], []) -> ShrS
  | CaseV ([[{ it = Atom "IShrU"; _ }]], []) -> ShrU
  | CaseV ([[{ it = Atom "IRotl"; _ }]], []) -> Rotl
  | CaseV ([[{ it = Atom "IRotr"; _ }]], []) -> Rotr
  | _ -> failwith "Expected ibinop"

and sl_to_float_binop (value: Value.t) : Ast.FloatOp.binop =
  match value.it with
  | CaseV ([[{ it = Atom "FAdd"; _ }]], []) -> Add
  | CaseV ([[{ it = Atom "FSub"; _ }]], []) -> Sub
  | CaseV ([[{ it = Atom "FMul"; _ }]], []) -> Mul
  | CaseV ([[{ it = Atom "FDiv"; _ }]], []) -> Div
  | CaseV ([[{ it = Atom "FMin"; _ }]], []) -> Min
  | CaseV ([[{ it = Atom "FMax"; _ }]], []) -> Max
  | CaseV ([[{ it = Atom "FCopysign"; _ }]], []) -> CopySign
  | _ -> failwith "Expected fbinop"

and sl_to_binop (value: Value.t) : Ast.binop = sl_to_op sl_to_int_binop sl_to_float_binop value

and sl_to_int_testop (value: Value.t) : Ast.IntOp.testop =
  match value.it with
  | CaseV ([[{ it = Atom "Eqz"; _ }]], []) -> Eqz
  | _ -> failwith "Expected itestop"

and sl_to_testop (value: Value.t) : Ast.testop =
  match value.it with
  | CaseV ([[{ it = Atom "I32"; _ }]; _], [op]) -> Wasm_Value.I32 (sl_to_int_testop op)
  | CaseV ([[{ it = Atom "I64"; _ }]; _], [op]) -> Wasm_Value.I64 (sl_to_int_testop op)
  | _ -> failwith "Expected testop"

and sl_to_int_relop (value: Value.t) : Ast.IntOp.relop =
  match value.it with
  | CaseV ([[{ it = Atom "Eq"; _ }]], []) -> Eq
  | CaseV ([[{ it = Atom "Ne"; _ }]], []) -> Ne
  | CaseV ([[{ it = Atom "LtS"; _ }]], []) -> LtS
  | CaseV ([[{ it = Atom "LtU"; _ }]], []) -> LtU
  | CaseV ([[{ it = Atom "GtS"; _ }]], []) -> GtS
  | CaseV ([[{ it = Atom "GtU"; _ }]], []) -> GtU
  | CaseV ([[{ it = Atom "LeS"; _ }]], []) -> LeS
  | CaseV ([[{ it = Atom "LeU"; _ }]], []) -> LeU
  | CaseV ([[{ it = Atom "GeS"; _ }]], []) -> GeS
  | CaseV ([[{ it = Atom "GeU"; _ }]], []) -> GeU
  | _ -> failwith "Expected irelop"

and sl_to_float_relop (value: Value.t) : Ast.FloatOp.relop =
  match value.it with
  | CaseV ([[{ it = Atom "Eq"; _ }]], []) -> Eq
  | CaseV ([[{ it = Atom "Ne"; _ }]], []) -> Ne
  | CaseV ([[{ it = Atom "Lt"; _ }]], []) -> Lt
  | CaseV ([[{ it = Atom "Gt"; _ }]], []) -> Gt
  | CaseV ([[{ it = Atom "Le"; _ }]], []) -> Le
  | CaseV ([[{ it = Atom "Ge"; _ }]], []) -> Ge
  | _ -> failwith "Expected frelop"

and sl_to_relop (value: Value.t) : Ast.relop = sl_to_op sl_to_int_relop sl_to_float_relop value

and sl_to_int_cvtop (value: Value.t) : Ast.IntOp.cvtop =
  match value.it with
  | CaseV ([[{ it = Atom "ExtendSI32"; _ }]], []) -> ExtendSI32
  | CaseV ([[{ it = Atom "ExtendUI32"; _ }]], []) -> ExtendUI32
  | CaseV ([[{ it = Atom "WrapI64"; _ }]], []) -> WrapI64
  | CaseV ([[{ it = Atom "TruncSF32"; _ }]], []) -> TruncSF32
  | CaseV ([[{ it = Atom "TruncUF32"; _ }]], []) -> TruncUF32
  | CaseV ([[{ it = Atom "TruncSF64"; _ }]], []) -> TruncSF64
  | CaseV ([[{ it = Atom "TruncUF64"; _ }]], []) -> TruncUF64
  | CaseV ([[{ it = Atom "TruncSatSF32"; _ }]], []) -> TruncSatSF32
  | CaseV ([[{ it = Atom "TruncSatUF32"; _ }]], []) -> TruncSatUF32
  | CaseV ([[{ it = Atom "TruncSatSF64"; _ }]], []) -> TruncSatSF64
  | CaseV ([[{ it = Atom "TruncSatUF64"; _ }]], []) -> TruncSatUF64
  | CaseV ([[{ it = Atom "ReinterpretFloat"; _ }]], []) -> ReinterpretFloat
  | _ -> failwith "Expected icvtop"

and sl_to_float_cvtop (value: Value.t) : Ast.FloatOp.cvtop =
  match value.it with
  | CaseV ([[{ it = Atom "ConvertSI32"; _ }]], []) -> ConvertSI32
  | CaseV ([[{ it = Atom "ConvertUI32"; _ }]], []) -> ConvertUI32
  | CaseV ([[{ it = Atom "ConvertSI64"; _ }]], []) -> ConvertSI64
  | CaseV ([[{ it = Atom "ConvertUI64"; _ }]], []) -> ConvertUI64
  | CaseV ([[{ it = Atom "PromoteF32"; _ }]], []) -> PromoteF32
  | CaseV ([[{ it = Atom "DemoteF64"; _ }]], []) -> DemoteF64
  | CaseV ([[{ it = Atom "ReinterpretInt"; _ }]], []) -> ReinterpretInt
  | _ -> failwith "Expected fcvtop"

and sl_to_cvtop (value: Value.t) : Ast.cvtop = sl_to_op sl_to_int_cvtop sl_to_float_cvtop value

and sl_to_vop : type a b. (Value.t -> a) -> (Value.t -> b) -> Value.t -> ((a, a, a, a, b, b) V128.laneop) Wasm_Value.vecop =
  fun f_int f_float value ->
    match value.it with
    | CaseV ([[{ it = Atom "V128"; _ }]; _], [vop]) ->
      (match vop.it with
      | CaseV ([[{ it = Atom "I8x16"; _ }]; _], [op]) -> Wasm_Value.V128 (V128.I8x16 (f_int op))
      | CaseV ([[{ it = Atom "I16x8"; _ }]; _], [op]) -> Wasm_Value.V128 (V128.I16x8 (f_int op))
      | CaseV ([[{ it = Atom "I32x4"; _ }]; _], [op]) -> Wasm_Value.V128 (V128.I32x4 (f_int op))
      | CaseV ([[{ it = Atom "I64x2"; _ }]; _], [op]) -> Wasm_Value.V128 (V128.I64x2 (f_int op))
      | CaseV ([[{ it = Atom "F32x4"; _ }]; _], [op]) -> Wasm_Value.V128 (V128.F32x4 (f_float op))
      | CaseV ([[{ it = Atom "F64x2"; _ }]; _], [op]) -> Wasm_Value.V128 (V128.F64x2 (f_float op))
      | _ -> failwith "Expected vop lane")
    | _ -> failwith "Expected vop"

and sl_to_int_vtestop (value: Value.t) : Ast.V128Op.itestop =
  match value.it with
  | CaseV ([[{ it = Atom "AllTrue"; _ }]], []) -> AllTrue
  | _ -> failwith "Expected vitestop"

and sl_to_vtestop (value: Value.t) : Ast.vec_testop = sl_to_vop sl_to_int_vtestop (fun _ -> failwith "Expected integer vtestop lane") value

and sl_to_int_vrelop (value: Value.t) : Ast.V128Op.irelop =
  match value.it with
  | CaseV ([[{ it = Atom "Eq"; _ }]], []) -> Eq
  | CaseV ([[{ it = Atom "Ne"; _ }]], []) -> Ne
  | CaseV ([[{ it = Atom "LtS"; _ }]], []) -> LtS
  | CaseV ([[{ it = Atom "LtU"; _ }]], []) -> LtU
  | CaseV ([[{ it = Atom "LeS"; _ }]], []) -> LeS
  | CaseV ([[{ it = Atom "LeU"; _ }]], []) -> LeU
  | CaseV ([[{ it = Atom "GtS"; _ }]], []) -> GtS
  | CaseV ([[{ it = Atom "GtU"; _ }]], []) -> GtU
  | CaseV ([[{ it = Atom "GeS"; _ }]], []) -> GeS
  | CaseV ([[{ it = Atom "GeU"; _ }]], []) -> GeU
  | _ -> failwith "Expected virelop"

and sl_to_float_vrelop (value: Value.t) : Ast.V128Op.frelop =
  match value.it with
  | CaseV ([[{ it = Atom "Eq"; _ }]], []) -> Eq
  | CaseV ([[{ it = Atom "Ne"; _ }]], []) -> Ne
  | CaseV ([[{ it = Atom "Lt"; _ }]], []) -> Lt
  | CaseV ([[{ it = Atom "Le"; _ }]], []) -> Le
  | CaseV ([[{ it = Atom "Gt"; _ }]], []) -> Gt
  | CaseV ([[{ it = Atom "Ge"; _ }]], []) -> Ge
  | _ -> failwith "Expected vfrelop"

and sl_to_vrelop (value: Value.t) : Ast.vec_relop = sl_to_vop sl_to_int_vrelop sl_to_float_vrelop value

and sl_to_int_vunop (value: Value.t) : Ast.V128Op.iunop =
  match value.it with
  | CaseV ([[{ it = Atom "Abs"; _ }]], []) -> Abs
  | CaseV ([[{ it = Atom "Neg"; _ }]], []) -> Neg
  | CaseV ([[{ it = Atom "Popcnt"; _ }]], []) -> Popcnt
  | _ -> failwith "Expected viunop"

and sl_to_float_vunop (value: Value.t) : Ast.V128Op.funop =
  match value.it with
  | CaseV ([[{ it = Atom "Abs"; _ }]], []) -> Abs
  | CaseV ([[{ it = Atom "Neg"; _ }]], []) -> Neg
  | CaseV ([[{ it = Atom "Sqrt"; _ }]], []) -> Sqrt
  | CaseV ([[{ it = Atom "Ceil"; _ }]], []) -> Ceil
  | CaseV ([[{ it = Atom "Floor"; _ }]], []) -> Floor
  | CaseV ([[{ it = Atom "Trunc"; _ }]], []) -> Trunc
  | CaseV ([[{ it = Atom "Nearest"; _ }]], []) -> Nearest
  | _ -> failwith "Expected vfunop"

and sl_to_vunop (value: Value.t) : Ast.vec_unop = sl_to_vop sl_to_int_vunop sl_to_float_vunop value

and sl_to_int_vbinop (value: Value.t) : Ast.V128Op.ibinop =
  match value.it with
  | CaseV ([[{ it = Atom "Add"; _ }]], []) -> Add
  | CaseV ([[{ it = Atom "Sub"; _ }]], []) -> Sub
  | CaseV ([[{ it = Atom "Mul"; _ }]], []) -> Mul
  | CaseV ([[{ it = Atom "MinS"; _ }]], []) -> MinS
  | CaseV ([[{ it = Atom "MinU"; _ }]], []) -> MinU
  | CaseV ([[{ it = Atom "MaxS"; _ }]], []) -> MaxS
  | CaseV ([[{ it = Atom "MaxU"; _ }]], []) -> MaxU
  | CaseV ([[{ it = Atom "AvgrU"; _ }]], []) -> AvgrU
  | CaseV ([[{ it = Atom "AddSatS"; _ }]], []) -> AddSatS
  | CaseV ([[{ it = Atom "AddSatU"; _ }]], []) -> AddSatU
  | CaseV ([[{ it = Atom "SubSatS"; _ }]], []) -> SubSatS
  | CaseV ([[{ it = Atom "SubSatU"; _ }]], []) -> SubSatU
  | CaseV ([[{ it = Atom "DotS"; _ }]], []) -> DotS
  | CaseV ([[{ it = Atom "Q15MulRSatS"; _ }]], []) -> Q15MulRSatS
  | CaseV ([[{ it = Atom "ExtMulLowS"; _ }]], []) -> ExtMulLowS
  | CaseV ([[{ it = Atom "ExtMulHighS"; _ }]], []) -> ExtMulHighS
  | CaseV ([[{ it = Atom "ExtMulLowU"; _ }]], []) -> ExtMulLowU
  | CaseV ([[{ it = Atom "ExtMulHighU"; _ }]], []) -> ExtMulHighU
  | CaseV ([[{ it = Atom "Swizzle"; _ }]], []) -> Swizzle
  | CaseV ([[{ it = Atom "Shuffle"; _ }]; _], [l]) -> Shuffle (sl_to_list sl_to_int l)
  | CaseV ([[{ it = Atom "NarrowS"; _ }]], []) -> NarrowS
  | CaseV ([[{ it = Atom "NarrowU"; _ }]], []) -> NarrowU
  | CaseV ([[{ it = Atom "RelaxedSwizzle"; _ }]], []) -> RelaxedSwizzle
  | CaseV ([[{ it = Atom "RelaxedQ15MulRS"; _ }]], []) -> RelaxedQ15MulRS
  | CaseV ([[{ it = Atom "RelaxedDot"; _ }]], []) -> RelaxedDot
  | _ -> failwith "Expected vibinop"

and sl_to_float_vbinop (value: Value.t) : Ast.V128Op.fbinop =
  match value.it with
  | CaseV ([[{ it = Atom "Add"; _ }]], []) -> Add
  | CaseV ([[{ it = Atom "Sub"; _ }]], []) -> Sub
  | CaseV ([[{ it = Atom "Mul"; _ }]], []) -> Mul
  | CaseV ([[{ it = Atom "Div"; _ }]], []) -> Div
  | CaseV ([[{ it = Atom "Min"; _ }]], []) -> Min
  | CaseV ([[{ it = Atom "Max"; _ }]], []) -> Max
  | CaseV ([[{ it = Atom "Pmin"; _ }]], []) -> Pmin
  | CaseV ([[{ it = Atom "Pmax"; _ }]], []) -> Pmax
  | CaseV ([[{ it = Atom "RelaxedMin"; _ }]], []) -> RelaxedMin
  | CaseV ([[{ it = Atom "RelaxedMax"; _ }]], []) -> RelaxedMax
  | _ -> failwith "Expected vfbinop"

and sl_to_vbinop (value: Value.t) : Ast.vec_binop = sl_to_vop sl_to_int_vbinop sl_to_float_vbinop value

and sl_to_int_vternop (value: Value.t) : Ast.V128Op.iternop =
  match value.it with
  | CaseV ([[{ it = Atom "RelaxedLaneselect"; _ }]], []) -> RelaxedLaneselect
  | CaseV ([[{ it = Atom "RelaxedDotAdd"; _ }]], []) -> RelaxedDotAdd
  | _ -> failwith "Expected viternop"

and sl_to_float_vternop (value: Value.t) : Ast.V128Op.fternop =
  match value.it with
  | CaseV ([[{ it = Atom "RelaxedMadd"; _ }]], []) -> RelaxedMadd
  | CaseV ([[{ it = Atom "RelaxedNmadd"; _ }]], []) -> RelaxedNmadd
  | _ -> failwith "Expected vfternop"

and sl_to_vternop (value: Value.t) : Ast.vec_ternop = sl_to_vop sl_to_int_vternop sl_to_float_vternop value

and sl_to_int_vcvtop (value: Value.t) : Ast.V128Op.icvtop =
  match value.it with
  | CaseV ([[{ it = Atom "ExtendLowS"; _ }]], []) -> ExtendLowS
  | CaseV ([[{ it = Atom "ExtendLowU"; _ }]], []) -> ExtendLowU
  | CaseV ([[{ it = Atom "ExtendHighS"; _ }]], []) -> ExtendHighS
  | CaseV ([[{ it = Atom "ExtendHighU"; _ }]], []) -> ExtendHighU
  | CaseV ([[{ it = Atom "ExtAddPairwiseS"; _ }]], []) -> ExtAddPairwiseS
  | CaseV ([[{ it = Atom "ExtAddPairwiseU"; _ }]], []) -> ExtAddPairwiseU
  | CaseV ([[{ it = Atom "TruncSatSF32x4"; _ }]], []) -> TruncSatSF32x4
  | CaseV ([[{ it = Atom "TruncSatUF32x4"; _ }]], []) -> TruncSatUF32x4
  | CaseV ([[{ it = Atom "TruncSatSZeroF64x2"; _ }]], []) -> TruncSatSZeroF64x2
  | CaseV ([[{ it = Atom "TruncSatUZeroF64x2"; _ }]], []) -> TruncSatUZeroF64x2
  | CaseV ([[{ it = Atom "RelaxedTruncSF32x4"; _ }]], []) -> RelaxedTruncSF32x4
  | CaseV ([[{ it = Atom "RelaxedTruncUF32x4"; _ }]], []) -> RelaxedTruncUF32x4
  | CaseV ([[{ it = Atom "RelaxedTruncSZeroF64x2"; _ }]], []) -> RelaxedTruncSZeroF64x2
  | CaseV ([[{ it = Atom "RelaxedTruncUZeroF64x2"; _ }]], []) -> RelaxedTruncUZeroF64x2
  | _ -> failwith "Expected vicvtop"

and sl_to_float_vcvtop (value: Value.t) : Ast.V128Op.fcvtop =
  match value.it with
  | CaseV ([[{ it = Atom "DemoteZeroF64x2"; _ }]], []) -> DemoteZeroF64x2
  | CaseV ([[{ it = Atom "PromoteLowF32x4"; _ }]], []) -> PromoteLowF32x4
  | CaseV ([[{ it = Atom "ConvertSI32x4"; _ }]], []) -> ConvertSI32x4
  | CaseV ([[{ it = Atom "ConvertUI32x4"; _ }]], []) -> ConvertUI32x4
  | _ -> failwith "Expected vfcvtop"

and sl_to_vcvtop (value: Value.t) : Ast.vec_cvtop = sl_to_vop sl_to_int_vcvtop sl_to_float_vcvtop value

and sl_to_int_vshiftop (value: Value.t) : Ast.V128Op.ishiftop =
  match value.it with
  | CaseV ([[{ it = Atom "Shl"; _ }]], []) -> Shl
  | CaseV ([[{ it = Atom "ShrS"; _ }]], []) -> ShrS
  | CaseV ([[{ it = Atom "ShrU"; _ }]], []) -> ShrU
  | _ -> failwith "Expected vishiftop"

and sl_to_vshiftop (value: Value.t) : Ast.vec_shiftop = sl_to_vop sl_to_int_vshiftop (fun _ -> failwith "Expected integer vshiftop lane") value

and sl_to_int_vbitmaskop (value: Value.t) : Ast.V128Op.ibitmaskop =
  match value.it with
  | CaseV ([[{ it = Atom "Bitmask"; _ }]], []) -> Bitmask
  | _ -> failwith "Expected vibitmaskop"

and sl_to_vbitmaskop (value: Value.t) : Ast.vec_bitmaskop = sl_to_vop sl_to_int_vbitmaskop (fun _ -> failwith "Expected integer vbitmaskop lane") value

and sl_to_vvtestop (value: Value.t) : Ast.vec_vtestop =
  match value.it with
  | CaseV ([[{ it = Atom "V128"; _ }]; _], [op]) ->
    (match op.it with
    | CaseV ([[{ it = Atom "AnyTrue"; _ }]], []) -> Wasm_Value.V128 AnyTrue
    | _ -> failwith "Expected vvtestop")
  | _ -> failwith "Expected vvtestop_"

and sl_to_vvunop (value: Value.t) : Ast.vec_vunop =
  match value.it with
  | CaseV ([[{ it = Atom "V128"; _ }]; _], [op]) ->
    (match op.it with
    | CaseV ([[{ it = Atom "Not"; _ }]], []) -> Wasm_Value.V128 Not
    | _ -> failwith "Expected vvunop")
  | _ -> failwith "Expected vvunop_"

and sl_to_vvbinop (value: Value.t) : Ast.vec_vbinop =
  match value.it with
  | CaseV ([[{ it = Atom "V128"; _ }]; _], [op]) ->
    (match op.it with
    | CaseV ([[{ it = Atom "And"; _ }]], []) -> Wasm_Value.V128 And
    | CaseV ([[{ it = Atom "Or"; _ }]], []) -> Wasm_Value.V128 Or
    | CaseV ([[{ it = Atom "Xor"; _ }]], []) -> Wasm_Value.V128 Xor
    | CaseV ([[{ it = Atom "AndNot"; _ }]], []) -> Wasm_Value.V128 AndNot
    | _ -> failwith "Expected vvbinop")
  | _ -> failwith "Expected vvbinop_"

and sl_to_vvternop (value: Value.t) : Ast.vec_vternop =
  match value.it with
  | CaseV ([[{ it = Atom "V128"; _ }]; _], [op]) ->
    (match op.it with
    | CaseV ([[{ it = Atom "Bitselect"; _ }]], []) -> Wasm_Value.V128 Bitselect
    | _ -> failwith "Expected vvternop")
  | _ -> failwith "Expected vvternop_"

and sl_to_vnsplatop (value: Value.t) : Ast.V128Op.nsplatop =
  match value.it with
  | CaseV ([[{ it = Atom "Splat"; _ }]], []) -> Splat
  | _ -> failwith "Expected vnsplatop"

and sl_to_vsplatop (value: Value.t) : Ast.vec_splatop = sl_to_vop sl_to_vnsplatop sl_to_vnsplatop value

and sl_to_int_vnextractop (value: Value.t) : Pack.extension Ast.V128Op.nextractop =
  match value.it with
  | CaseV ([[{ it = Atom "Extract"; _ }]; _], [tuple]) ->
    let i, ext = Interface.Unwrap.unwrap_tuple_v_two tuple in
    Extract (sl_to_int i, sl_to_extension ext)
  | _ -> failwith "Expected int vnextractop"

and sl_to_float_vnextractop (value: Value.t) : unit Ast.V128Op.nextractop =
  match value.it with
  | CaseV ([[{ it = Atom "Extract"; _ }]; _], [tuple]) ->
    let i, void = Interface.Unwrap.unwrap_tuple_v_two tuple in
    sl_to_void void;
    Extract (sl_to_int i, ())
  | _ -> failwith "Expected float vnextractop"

and sl_to_vextractop (value: Value.t) : Ast.vec_extractop =
  match value.it with
  | CaseV ([[{ it = Atom "V128"; _ }]; _], [vop]) ->
    (match vop.it with
    | CaseV ([[{ it = Atom "I8x16"; _ }]; _], [op]) -> Wasm_Value.V128 (V128.I8x16 (sl_to_int_vnextractop op))
    | CaseV ([[{ it = Atom "I16x8"; _ }]; _], [op]) -> Wasm_Value.V128 (V128.I16x8 (sl_to_int_vnextractop op))
    | CaseV ([[{ it = Atom "I32x4"; _ }]; _], [op]) -> Wasm_Value.V128 (V128.I32x4 (sl_to_float_vnextractop op))
    | CaseV ([[{ it = Atom "I64x2"; _ }]; _], [op]) -> Wasm_Value.V128 (V128.I64x2 (sl_to_float_vnextractop op))
    | CaseV ([[{ it = Atom "F32x4"; _ }]; _], [op]) -> Wasm_Value.V128 (V128.F32x4 (sl_to_float_vnextractop op))
    | CaseV ([[{ it = Atom "F64x2"; _ }]; _], [op]) -> Wasm_Value.V128 (V128.F64x2 (sl_to_float_vnextractop op))
    | _ -> failwith "Expected vextractop lane")
  | _ -> failwith "Expected vextractop_"

and sl_to_vnreplaceop (value: Value.t) : Ast.V128Op.nreplaceop =
  match value.it with
  | CaseV ([[{ it = Atom "Replace"; _ }]; _], [i]) -> Replace (sl_to_int i)
  | _ -> failwith "Expected vnreplaceop"

and sl_to_vreplaceop (value: Value.t) : Ast.vec_replaceop = sl_to_vop sl_to_vnreplaceop sl_to_vnreplaceop value

and sl_to_instr' (value: Value.t) : Ast.instr' =
  match value.it with
  | CaseV ([[{ it = Atom "UNREACHABLE"; _ }]], []) -> Unreachable
  | CaseV ([[{ it = Atom "NOP"; _ }]], []) -> Nop
  | CaseV ([[{ it = Atom "DROP"; _ }]], []) -> Drop
  | CaseV ([[{ it = Atom "SELECT"; _ }]; _], [vt_opt]) -> Select (sl_to_select_type_opt vt_opt)
  | CaseV ([[{ it = Atom "BLOCK"; _ }]; _; _], [bt; instrs]) -> Block (sl_to_block_type bt, sl_to_list sl_to_instr instrs)
  | CaseV ([[{ it = Atom "LOOP"; _ }]; _; _], [bt; instrs]) -> Loop (sl_to_block_type bt, sl_to_list sl_to_instr instrs)
  | CaseV ([[{ it = Atom "IF"; _ }]; _; [{ it = Atom "ELSE"; _ }]; _], [bt; instrs1; instrs2]) -> If (sl_to_block_type bt, sl_to_list sl_to_instr instrs1, sl_to_list sl_to_instr instrs2)
  | CaseV ([[{ it = Atom "BR"; _ }]; _], [idx]) -> Br (sl_to_idx idx)
  | CaseV ([[{ it = Atom "BR_IF"; _ }]; _], [idx]) -> BrIf (sl_to_idx idx)
  | CaseV ([[{ it = Atom "BR_TABLE"; _ }]; _; _], [idxl; idx]) -> BrTable (sl_to_list sl_to_idx idxl, sl_to_idx idx)
  | CaseV ([[{ it = Atom "BR_ON_NULL"; _ }]; _], [idx]) -> BrOnNull (sl_to_idx idx)
  | CaseV ([[{ it = Atom "BR_ON_NON_NULL"; _ }]; _], [idx]) -> BrOnNonNull (sl_to_idx idx)
  | CaseV ([[{ it = Atom "BR_ON_CAST"; _ }]; _; _; _], [idx; rt1; rt2]) -> BrOnCast (sl_to_idx idx, sl_to_ref_type rt1, sl_to_ref_type rt2)
  | CaseV ([[{ it = Atom "BR_ON_CAST_FAIL"; _ }]; _; _; _], [idx; rt1; rt2]) -> BrOnCastFail (sl_to_idx idx, sl_to_ref_type rt1, sl_to_ref_type rt2)
  | CaseV ([[{ it = Atom "RETURN"; _ }]], []) -> Return
  | CaseV ([[{ it = Atom "CALL"; _ }]; _], [idx]) -> Call (sl_to_idx idx)
  | CaseV ([[{ it = Atom "CALL_REF"; _ }]; _], [idx]) -> CallRef (sl_to_idx idx)
  | CaseV ([[{ it = Atom "CALL_INDIRECT"; _ }]; _; _], [idx1; idx2]) -> CallIndirect (sl_to_idx idx1, sl_to_idx idx2)
  | CaseV ([[{ it = Atom "RETURN_CALL"; _ }]; _], [idx]) -> ReturnCall (sl_to_idx idx)
  | CaseV ([[{ it = Atom "RETURN_CALL_REF"; _ }]; _], [idx]) -> ReturnCallRef (sl_to_idx idx)
  | CaseV ([[{ it = Atom "RETURN_CALL_INDIRECT"; _ }]; _; _], [idx1; idx2]) -> ReturnCallIndirect (sl_to_idx idx1, sl_to_idx idx2)
  | CaseV ([[{ it = Atom "THROW"; _ }]; _], [idx]) -> Throw (sl_to_idx idx)
  | CaseV ([[{ it = Atom "THROW_REF"; _ }]], []) -> ThrowRef
  | CaseV ([[{ it = Atom "TRY_TABLE"; _ }]; _; _; _], [bt; catches; instrs]) -> TryTable (sl_to_block_type bt, sl_to_list sl_to_catch catches, sl_to_list sl_to_instr instrs)
  | CaseV ([[{ it = Atom "LOCAL.GET"; _ }]; _], [idx]) -> LocalGet (sl_to_idx idx)
  | CaseV ([[{ it = Atom "LOCAL.SET"; _ }]; _], [idx]) -> LocalSet (sl_to_idx idx)
  | CaseV ([[{ it = Atom "LOCAL.TEE"; _ }]; _], [idx]) -> LocalTee (sl_to_idx idx)
  | CaseV ([[{ it = Atom "GLOBAL.GET"; _ }]; _], [idx]) -> GlobalGet (sl_to_idx idx)
  | CaseV ([[{ it = Atom "GLOBAL.SET"; _ }]; _], [idx]) -> GlobalSet (sl_to_idx idx)
  | CaseV ([[{ it = Atom "TABLE.GET"; _ }]; _], [idx]) -> TableGet (sl_to_idx idx)
  | CaseV ([[{ it = Atom "TABLE.SET"; _ }]; _], [idx]) -> TableSet (sl_to_idx idx)
  | CaseV ([[{ it = Atom "TABLE.SIZE"; _ }]; _], [idx]) -> TableSize (sl_to_idx idx)
  | CaseV ([[{ it = Atom "TABLE.GROW"; _ }]; _], [idx]) -> TableGrow (sl_to_idx idx)
  | CaseV ([[{ it = Atom "TABLE.FILL"; _ }]; _], [idx]) -> TableFill (sl_to_idx idx)
  | CaseV ([[{ it = Atom "TABLE.COPY"; _ }]; _; _], [idx1; idx2]) -> TableCopy (sl_to_idx idx1, sl_to_idx idx2)
  | CaseV ([[{ it = Atom "TABLE.INIT"; _ }]; _; _], [idx1; idx2]) -> TableInit (sl_to_idx idx1, sl_to_idx idx2)
  | CaseV ([[{ it = Atom "ELEM.DROP"; _ }]; _], [idx]) -> ElemDrop (sl_to_idx idx)
  | CaseV ([[{ it = Atom "LOAD"; _ }]; _; _], [idx; op]) -> Load (sl_to_idx idx, sl_to_loadop op)
  | CaseV ([[{ it = Atom "STORE"; _ }]; _; _], [idx; op]) -> Store (sl_to_idx idx, sl_to_storeop op)
  | CaseV ([[{ it = Atom "VEC.LOAD"; _ }]; _; _], [idx; op]) -> VecLoad (sl_to_idx idx, sl_to_vec_loadop op)
  | CaseV ([[{ it = Atom "VEC.STORE"; _ }]; _; _], [idx; op]) -> VecStore (sl_to_idx idx, sl_to_vec_storeop op)
  | CaseV ([[{ it = Atom "VEC.LOAD_LANE"; _ }]; _; _; _], [idx; op; i]) -> VecLoadLane (sl_to_idx idx, sl_to_vec_laneop op, sl_to_int i)
  | CaseV ([[{ it = Atom "VEC.STORE_LANE"; _ }]; _; _; _], [idx; op; i]) -> VecStoreLane (sl_to_idx idx, sl_to_vec_laneop op, sl_to_int i)
  | CaseV ([[{ it = Atom "MEMORY.SIZE"; _ }]; _], [idx]) -> MemorySize (sl_to_idx idx)
  | CaseV ([[{ it = Atom "MEMORY.GROW"; _ }]; _], [idx]) -> MemoryGrow (sl_to_idx idx)
  | CaseV ([[{ it = Atom "MEMORY.FILL"; _ }]; _], [idx]) -> MemoryFill (sl_to_idx idx)
  | CaseV ([[{ it = Atom "MEMORY.COPY"; _ }]; _; _], [idx1; idx2]) -> MemoryCopy (sl_to_idx idx1, sl_to_idx idx2)
  | CaseV ([[{ it = Atom "MEMORY.INIT"; _ }]; _; _], [idx1; idx2]) -> MemoryInit (sl_to_idx idx1, sl_to_idx idx2)
  | CaseV ([[{ it = Atom "DATA.DROP"; _ }]; _], [idx]) -> DataDrop (sl_to_idx idx)
  | CaseV ([[{ it = Atom "REF.NULL"; _ }]; _], [ht]) -> RefNull (sl_to_heap_type ht)
  | CaseV ([[{ it = Atom "REF.FUNC"; _ }]; _], [idx]) -> RefFunc (sl_to_idx idx)
  | CaseV ([[{ it = Atom "REF.IS_NULL"; _ }]], []) -> RefIsNull
  | CaseV ([[{ it = Atom "REF.AS_NON_NULL"; _ }]], []) -> RefAsNonNull
  | CaseV ([[{ it = Atom "REF.TEST"; _ }]; _], [rt]) -> RefTest (sl_to_ref_type rt)
  | CaseV ([[{ it = Atom "REF.CAST"; _ }]; _], [rt]) -> RefCast (sl_to_ref_type rt)
  | CaseV ([[{ it = Atom "REF.EQ"; _ }]], []) -> RefEq
  | CaseV ([[{ it = Atom "REF.I31"; _ }]], []) -> RefI31
  | CaseV ([[{ it = Atom "I31.GET"; _ }]; _], [ext]) -> I31Get (sl_to_extension ext)
  | CaseV ([[{ it = Atom "STRUCT.NEW"; _ }]; _; _], [idx; initop]) -> StructNew (sl_to_idx idx, sl_to_initop initop)
  | CaseV ([[{ it = Atom "STRUCT.GET"; _ }]; _; _; _], [idx1; idx2; ext_opt]) -> StructGet (sl_to_idx idx1, sl_to_idx idx2, sl_to_opt sl_to_extension ext_opt)
  | CaseV ([[{ it = Atom "STRUCT.SET"; _ }]; _; _], [idx1; idx2]) -> StructSet (sl_to_idx idx1, sl_to_idx idx2)
  | CaseV ([[{ it = Atom "ARRAY.NEW"; _ }]; _; _], [idx; initop]) -> ArrayNew (sl_to_idx idx, sl_to_initop initop)
  | CaseV ([[{ it = Atom "ARRAY.NEW_FIXED"; _ }]; _; _], [idx; n]) -> ArrayNewFixed (sl_to_idx idx, sl_to_nat32 n)
  | CaseV ([[{ it = Atom "ARRAY.NEW_ELEM"; _ }]; _; _], [idx1; idx2]) -> ArrayNewElem (sl_to_idx idx1, sl_to_idx idx2)
  | CaseV ([[{ it = Atom "ARRAY.NEW_DATA"; _ }]; _; _], [idx1; idx2]) -> ArrayNewData (sl_to_idx idx1, sl_to_idx idx2)
  | CaseV ([[{ it = Atom "ARRAY.GET"; _ }]; _; _], [idx; ext_opt]) -> ArrayGet (sl_to_idx idx, sl_to_opt sl_to_extension ext_opt)
  | CaseV ([[{ it = Atom "ARRAY.SET"; _ }]; _], [idx]) -> ArraySet (sl_to_idx idx)
  | CaseV ([[{ it = Atom "ARRAY.LEN"; _ }]], []) -> ArrayLen
  | CaseV ([[{ it = Atom "ARRAY.COPY"; _ }]; _; _], [idx1; idx2]) -> ArrayCopy (sl_to_idx idx1, sl_to_idx idx2)
  | CaseV ([[{ it = Atom "ARRAY.FILL"; _ }]; _], [idx]) -> ArrayFill (sl_to_idx idx)
  | CaseV ([[{ it = Atom "ARRAY.INIT_DATA"; _ }]; _; _], [idx1; idx2]) -> ArrayInitData (sl_to_idx idx1, sl_to_idx idx2)
  | CaseV ([[{ it = Atom "ARRAY.INIT_ELEM"; _ }]; _; _], [idx1; idx2]) -> ArrayInitElem (sl_to_idx idx1, sl_to_idx idx2)
  | CaseV ([[{ it = Atom "EXTERN.CONVERT"; _ }]; _], [op]) -> ExternConvert (sl_to_externop op)
  | CaseV ([[{ it = Atom "CONST"; _ }]; _], [num]) -> Const (sl_to_phrase sl_to_num num)
  | CaseV ([[{ it = Atom "TEST"; _ }]; _], [op]) -> Test (sl_to_testop op)
  | CaseV ([[{ it = Atom "COMPARE"; _ }]; _], [op]) -> Compare (sl_to_relop op)
  | CaseV ([[{ it = Atom "UNARY"; _ }]; _], [op]) -> Unary (sl_to_unop op)
  | CaseV ([[{ it = Atom "BINOP"; _ }]; _], [op]) -> Binary (sl_to_binop op)
  | CaseV ([[{ it = Atom "CONVERT"; _ }]; _], [op]) -> Convert (sl_to_cvtop op)
  | CaseV ([[{ it = Atom "VEC.CONST"; _ }]; _], [vec]) -> VecConst (sl_to_phrase sl_to_vec vec)
  | CaseV ([[{ it = Atom "VEC.TEST"; _ }]; _], [op]) -> VecTest (sl_to_vtestop op)
  | CaseV ([[{ it = Atom "VEC.UNARY"; _ }]; _], [op]) -> VecUnary (sl_to_vunop op)
  | CaseV ([[{ it = Atom "VEC.BINARY"; _ }]; _], [op]) -> VecBinary (sl_to_vbinop op)
  | CaseV ([[{ it = Atom "VEC.COMPARE"; _ }]; _], [op]) -> VecCompare (sl_to_vrelop op)
  | CaseV ([[{ it = Atom "VEC.TERNARY"; _ }]; _], [op]) -> VecTernary (sl_to_vternop op)
  | CaseV ([[{ it = Atom "VEC.CONVERT"; _ }]; _], [op]) -> VecConvert (sl_to_vcvtop op)
  | CaseV ([[{ it = Atom "VEC.SHIFT"; _ }]; _], [op]) -> VecShift (sl_to_vshiftop op)
  | CaseV ([[{ it = Atom "VEC.BITMASK"; _ }]; _], [op]) -> VecBitmask (sl_to_vbitmaskop op)
  | CaseV ([[{ it = Atom "VEC.TESTBITS"; _ }]; _], [op]) -> VecTestBits (sl_to_vvtestop op)
  | CaseV ([[{ it = Atom "VEC.UNARYBITS"; _ }]; _], [op]) -> VecUnaryBits (sl_to_vvunop op)
  | CaseV ([[{ it = Atom "VEC.BINARYBITS"; _ }]; _], [op]) -> VecBinaryBits (sl_to_vvbinop op)
  | CaseV ([[{ it = Atom "VEC.TERNARYBITS"; _ }]; _], [op]) -> VecTernaryBits (sl_to_vvternop op)
  | CaseV ([[{ it = Atom "VEC.SPLAT"; _ }]; _], [op]) -> VecSplat (sl_to_vsplatop op)
  | CaseV ([[{ it = Atom "VEC.EXTRACT"; _ }]; _], [op]) -> VecExtract (sl_to_vextractop op)
  | CaseV ([[{ it = Atom "VEC.REPLACE"; _ }]; _], [op]) -> VecReplace (sl_to_vreplaceop op)
  | _ -> failwith "Unsupported instr in sl_to_instr"

and sl_to_instr (value: Value.t) : Ast.instr = sl_to_phrase sl_to_instr' value

and sl_to_const (value: Value.t) : Ast.const =
  Wasm_interpreter.Source.((sl_to_list sl_to_instr value) @@ no_region)

and sl_to_global_type (value: Value.t) : Types.global_type =
  match value.it with
  | CaseV ([[{ it = Atom "GlobalT"; _ }]; _; _], [mut; vt]) ->
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

and sl_to_name (value: Value.t) : Ast.name = Interface.Unwrap.unwrap_text_v value |> Wasm_interpreter.Utf8.decode

and sl_to_addr_type (value: Value.t) : Types.addr_type =
  match value.it with
  | CaseV ([[{ it = Atom "I32AT"; _ }]], []) -> I32AT
  | CaseV ([[{ it = Atom "I64AT"; _ }]], []) -> I64AT
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
  match value.it with
  | CaseV ([[{ it = Atom "TableT"; _ }]; _; _; _], [at; limits; rt]) -> TableT (sl_to_addr_type at, sl_to_limits limits, sl_to_ref_type rt)
  | _ -> failwith "Expected tabletype"

and sl_to_memory_type (value: Value.t) : Types.memory_type =
  match value.it with
  | CaseV ([[{ it = Atom "MemoryT"; _ }]; _; _], [at; limits]) -> MemoryT (sl_to_addr_type at, sl_to_limits limits)
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

and sl_to_segment_mode' (value: Value.t) : Ast.segment_mode' =
  match value.it with
  | CaseV ([[{ it = Atom "Passive"; _ }]], []) -> Passive
  | CaseV ([[{ it = Atom "Active"; _ }]; _], [active]) ->
    (match active.it with
    | StructV valuefields ->
      let _atoms, values = List.split valuefields in
      (match values with
      | [index; offset] -> Active { index = sl_to_idx index; offset = sl_to_const offset }
      | _ -> failwith "Expect 2 active fields")
    | _ -> failwith "Expect active struct")
  | CaseV ([[{ it = Atom "Declarative"; _ }]], []) -> Declarative
  | _ -> failwith "Expected segmentmode"

and sl_to_segment_mode (value: Value.t) : Ast.segment_mode = sl_to_phrase sl_to_segment_mode' value

and sl_to_elem' (value: Value.t) : Ast.elem_segment' =
  match (value.note.typ, value.it) with
  | VarT ({ it = "elem"; _ }, _), StructV valuefields ->
    let _atoms, values = List.split valuefields in
    (match values with
    | [etype; einit; emode] ->
      {
        etype = sl_to_ref_type etype;
        einit = sl_to_list sl_to_const einit;
        emode = sl_to_segment_mode emode;
      }
    | _ -> failwith "Expect 3 elem fields")
  | _ -> failwith "Expect elem with StructV, but different value is given."

and sl_to_elem (value: Value.t) : Ast.elem_segment = sl_to_phrase sl_to_elem' value

and sl_to_data' (value: Value.t) : Ast.data_segment' =
  match (value.note.typ, value.it) with
  | VarT ({ it = "data"; _ }, _), StructV valuefields ->
    let _atoms, values = List.split valuefields in
    (match values with
    | [dinit; dmode] ->
      {
        dinit = Interface.Unwrap.unwrap_text_v dinit;
        dmode = sl_to_segment_mode dmode;
      }
    | _ -> failwith "Expect 2 data fields")
  | _ -> failwith "Expect data with StructV, but different value is given."

and sl_to_data (value: Value.t) : Ast.data_segment = sl_to_phrase sl_to_data' value

and sl_to_import_desc' (value: Value.t) : Ast.import_desc' =
  match value.it with
  | CaseV ([[{ it = Atom "FuncImport"; _ }]; _], [idx]) -> FuncImport (sl_to_idx idx)
  | CaseV ([[{ it = Atom "TableImport"; _ }]; _], [ttype]) -> TableImport (sl_to_table_type ttype)
  | CaseV ([[{ it = Atom "MemImport"; _ }]; _], [mtype]) -> MemoryImport (sl_to_memory_type mtype)
  | CaseV ([[{ it = Atom "GlobalImport"; _ }]; _], [gtype]) -> GlobalImport (sl_to_global_type gtype)
  | CaseV ([[{ it = Atom "TagImport"; _ }]; _], [idx]) -> TagImport (sl_to_idx idx)
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
  match value.it with
  | CaseV ([[{ it = Atom "FuncExport"; _ }]; _], [idx]) -> FuncExport (sl_to_idx idx)
  | CaseV ([[{ it = Atom "TableExport"; _ }]; _], [idx]) -> TableExport (sl_to_idx idx)
  | CaseV ([[{ it = Atom "MemExport"; _ }]; _], [idx]) -> MemoryExport (sl_to_idx idx)
  | CaseV ([[{ it = Atom "GlobalExport"; _ }]; _], [idx]) -> GlobalExport (sl_to_idx idx)
  | CaseV ([[{ it = Atom "TagExport"; _ }]; _], [idx]) -> TagExport (sl_to_idx idx)
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
