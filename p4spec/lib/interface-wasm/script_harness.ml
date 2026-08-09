open Domain.Atom
open Lang
open Il
open Util.Source

module Script = Wasm_interpreter.Script
module Ast = Wasm_interpreter.Ast
module Custom = Wasm_interpreter.Custom
module F32 = Wasm_interpreter.F32
module F64 = Wasm_interpreter.F64
module Run = Wasm_interpreter.Run
module Types = Wasm_interpreter.Types
module Utf8 = Wasm_interpreter.Utf8
module V128 = Wasm_interpreter.V128
module WasmExtern = Wasm_interpreter.Extern
module WasmI31 = Wasm_interpreter.I31
module WasmSource = Wasm_interpreter.Source
module WasmValue = Wasm_interpreter.Value
module Sim = Runtime.Sim.Signature

module StringMap = Map.Make (String)

type module_entry = {
  module_ : Ast.module_;
  custom : Custom.section list;
  value : value;
}

type instance_entry = {
  module_inst : value;
  store : value;
}

type exec_outcome =
  | Returned of {
      store : value;
      values : value list;
    }
  | Trapped of value
  | Thrown of {
      store : value;
      tagaddr : value;
      values : value list;
    }

type import_resolution_error =
  | UnknownImport of string

type init_outcome = InitExecuted of {
  module_inst : value;
  outcome : exec_outcome;
}

type state = {
  store : value;
  modules : module_entry StringMap.t;
  instances : instance_entry StringMap.t;
  registry : instance_entry StringMap.t;
}

type runtime = {
  simulator : (module Sim.SIM);
}

let script_harness_relname = "Scripts_init_ok"

let is_script_harness_rel (relname : string) : bool =
  relname = script_harness_relname

let script_debug = ref false

let set_script_debug enabled = script_debug := enabled

let script_debug_enabled () = !script_debug

let error at msg = Util.Error.error_interp at msg

let source_cache : (string, string array) Hashtbl.t = Hashtbl.create 4

let lines_of_file filename =
  if filename = "" then None
  else
    match Hashtbl.find_opt source_cache filename with
    | Some lines -> Some lines
    | None ->
      try
        let ic = open_in filename in
        let lines =
          Fun.protect
            ~finally:(fun () -> close_in_noerr ic)
            (fun () ->
              let rec loop acc =
                match input_line ic with
                | line -> loop (line :: acc)
                | exception End_of_file -> Array.of_list (List.rev acc)
              in
              loop [])
        in
        Hashtbl.add source_cache filename lines;
        Some lines
      with Sys_error _ -> None

let source_line (at : WasmSource.region) =
  let filename = at.left.file in
  let line = at.left.line in
  if filename = "" || line <= 0 then None
  else
    match lines_of_file filename with
    | None -> None
    | Some lines ->
      if line <= Array.length lines then Some lines.(line - 1) else None

let squash_ws s =
  let buffer = Buffer.create (String.length s) in
  let last_space = ref true in
  String.iter
    (fun ch ->
      if ch = ' ' || ch = '\t' || ch = '\r' || ch = '\n' then (
        if not !last_space then Buffer.add_char buffer ' ';
        last_space := true)
      else (
        Buffer.add_char buffer ch;
        last_space := false))
    s;
  String.trim (Buffer.contents buffer)

let shorten limit s =
  if String.length s <= limit then s
  else String.sub s 0 (max 0 (limit - 3)) ^ "..."

let var_opt_label (var_opt : Script.var option) =
  match var_opt with
  | None -> ""
  | Some var -> " $" ^ var.it

let command_label (cmd : Script.command) =
  match cmd.it with
  | Script.Module (var_opt, _) -> "Module" ^ var_opt_label var_opt
  | Script.Instance (var_opt, source_var_opt) ->
    "Instance" ^ var_opt_label var_opt ^ var_opt_label source_var_opt
  | Script.Register (name, var_opt) ->
    "Register " ^ Utf8.encode name ^ var_opt_label var_opt
  | Script.Action act -> "Action " ^ (
      match act.it with
      | Script.Invoke (_, name, _) -> "Invoke " ^ Utf8.encode name
      | Script.Get (_, name) -> "Get " ^ Utf8.encode name)
  | Script.Assertion ass -> (
      match ass.it with
      | Script.AssertMalformed _ -> "Assertion AssertMalformed"
      | Script.AssertMalformedCustom _ -> "Assertion AssertMalformedCustom"
      | Script.AssertInvalid _ -> "Assertion AssertInvalid"
      | Script.AssertInvalidCustom _ -> "Assertion AssertInvalidCustom"
      | Script.AssertUnlinkable _ -> "Assertion AssertUnlinkable"
      | Script.AssertUninstantiable _ -> "Assertion AssertUninstantiable"
      | Script.AssertReturn _ -> "Assertion AssertReturn"
      | Script.AssertException _ -> "Assertion AssertException"
      | Script.AssertTrap _ -> "Assertion AssertTrap"
      | Script.AssertExhaustion _ -> "Assertion AssertExhaustion")
  | Script.Meta meta -> (
      match meta.it with
      | Script.Input _ -> "Meta Input"
      | Script.Output _ -> "Meta Output"
      | Script.Script _ -> "Meta Script")

let source_location (at : WasmSource.region) =
  if at.left.file = "" then "<unknown location>"
  else WasmSource.string_of_region at

let debug_context ?relation ?detail ~index ~total (cmd : Script.command) =
  let source =
    match source_line cmd.at with
    | None -> []
    | Some line ->
      [
        Printf.sprintf "  source_line: %s"
          (line |> squash_ws |> shorten 220);
      ]
  in
  let relation =
    match relation with
    | None -> []
    | Some rel -> [ Printf.sprintf "  relation: %s" rel ]
  in
  let detail =
    match detail with
    | None -> []
    | Some msg -> [ Printf.sprintf "  detail: %s" msg ]
  in
  String.concat "\n"
    ([
       "[wasm-script-debug]";
       Printf.sprintf "  command_index: %d/%d" index total;
       Printf.sprintf "  source_location: %s" (source_location cmd.at);
       Printf.sprintf "  desugared_command: %s" (command_label cmd);
     ]
    @ relation @ source @ detail)

let debug_error_message ?relation ~index ~total cmd msg =
  if not (script_debug_enabled ()) then msg
  else
    msg ^ "\n"
    ^ debug_context ?relation ~detail:msg ~index ~total cmd

let trace_command ~index ~total (cmd : Script.command) =
  if script_debug_enabled () then
    let source =
      match source_line cmd.at with
      | None -> ""
      | Some line ->
        " source_line=\"" ^ (line |> squash_ws |> shorten 160) ^ "\""
    in
    Format.eprintf
      "[wasm-script-debug] command_index=%d/%d source_location=%s \
       desugared_command=%s%s\n%!"
      index total (source_location cmd.at) (command_label cmd) source

let field_name (atom : atom) : string option =
  match atom.it with
  | Atom name | SilentAtom name -> Some name
  | _ -> None

let same_field actual expected =
  actual = expected
  || String.uppercase_ascii actual = String.uppercase_ascii expected

let field at expected value =
  match value.it with
  | StructV fields -> (
      match
        List.find_opt
          (fun (atom, _) ->
            match field_name atom with
            | Some actual -> same_field actual expected
            | None -> false)
          fields
      with
      | Some (_, value) -> value
      | None -> error at ("missing field " ^ expected))
  | _ -> error at ("expected struct with field " ^ expected)

let as_text at value =
  match value.it with
  | TextV text -> text
  | _ -> error at "expected text value"

let as_list at value =
  match value.it with
  | ListV values -> Value_array.to_list values
  | _ -> error at "expected list value"

let as_nat at value =
  try value |> Runtime.Value.Get.num |> Xl.Num.to_int |> Bigint.to_int_exn
  with _ -> error at "expected nat value"

let list_value typ_name values =
  Wrap.wrap_list_v typ_name values

let nat n = Wrap.wrap_num_v_nat (Bigint.of_int n)

let case typ symbols =
  let open Wrap in
  symbols #@ typ

let runtime_num num =
  case "value" [ Wrap.Term "NumV"; Wrap.NT (Construct.il_of_num num) ]

let runtime_vec vec =
  case "value" [ Wrap.Term "VecV"; Wrap.NT (Construct.il_of_vec vec) ]

let runtime_ref ref_ =
  let ref_value =
    match ref_ with
    | WasmValue.NullRef heaptype ->
      case "refval"
        [ Wrap.Term "NullRef"; Wrap.NT (Construct.il_of_heap_type heaptype) ]
    | Script.HostRef hostaddr ->
      case "refval"
        [ Wrap.Term "HostRef"; Wrap.NT (nat (Int32.to_int hostaddr)) ]
    | WasmExtern.ExternRef (Script.HostRef hostaddr) ->
      let host_ref =
        case "refval"
          [ Wrap.Term "HostRef"; Wrap.NT (nat (Int32.to_int hostaddr)) ]
      in
      case "refval" [ Wrap.Term "ExternRef"; Wrap.NT host_ref ]
    | WasmI31.I31Ref i31 ->
      case "refval" [ Wrap.Term "I31Ref"; Wrap.NT (nat i31) ]
    | _ -> error no_region "unsupported script reference literal"
  in
  case "value" [ Wrap.Term "RefV"; Wrap.NT ref_value ]

let func_addr n = case "externaddr" [ Wrap.Term "FuncAddr"; Wrap.NT (nat n) ]

let global_addr n =
  case "externaddr" [ Wrap.Term "GlobalAddr"; Wrap.NT (nat n) ]

let table_addr n = case "externaddr" [ Wrap.Term "TableAddr"; Wrap.NT (nat n) ]

let mem_addr n = case "externaddr" [ Wrap.Term "MemAddr"; Wrap.NT (nat n) ]

let host_func hostaddr =
  let hostfunc =
    case "hostfunc" [ Wrap.Term "HostFuncId"; Wrap.NT (nat hostaddr) ]
  in
  case "funccode" [ Wrap.Term "HostFunc"; Wrap.NT hostfunc ]

let null_ref heaptype =
  case "refval" [ Wrap.Term "NullRef"; Wrap.NT (Construct.il_of_heap_type heaptype) ]

let export_inst name addr =
  Wrap.wrap_struct_v "exportinst"
    [
      (Wrap.wrap_atom "NAME", Wrap.wrap_text_v name);
      (Wrap.wrap_atom "ADDR", addr);
    ]

let func_deftype params results =
  Types.(
    DefT
      ( RecT [ SubT (Final, [], DefFuncT (FuncT (params, results))) ],
        0l ))

let host_func_decl name params =
  (name, func_deftype params [])

let spectest_func_decls =
  let open Types in
  [
    host_func_decl "print" [];
    host_func_decl "print_i32" [ NumT I32T ];
    host_func_decl "print_i64" [ NumT I64T ];
    host_func_decl "print_f32" [ NumT F32T ];
    host_func_decl "print_f64" [ NumT F64T ];
    host_func_decl "print_i32_f32" [ NumT I32T; NumT F32T ];
    host_func_decl "print_f64_f64" [ NumT F64T; NumT F64T ];
  ]

let spectest_global_decls =
  let open Types in
  [
    ("global_i32", GlobalT (Cons, NumT I32T), runtime_num (WasmValue.I32 666l));
    ("global_i64", GlobalT (Cons, NumT I64T), runtime_num (WasmValue.I64 666L));
    ( "global_f32",
      GlobalT (Cons, NumT F32T),
      runtime_num (WasmValue.F32 (F32.of_float 666.6)) );
    ( "global_f64",
      GlobalT (Cons, NumT F64T),
      runtime_num (WasmValue.F64 (F64.of_float 666.6)) );
  ]

let limits min max = Types.{ min; max }

let spectest_table_decls =
  let open Types in
  [
    ("table", TableT (I32AT, limits 10L (Some 20L), (Null, FuncHT)));
    ("table64", TableT (I64AT, limits 10L (Some 20L), (Null, FuncHT)));
  ]

let spectest_memory_decls =
  let open Types in
  [ ("memory", MemoryT (I32AT, limits 1L (Some 2L))) ]

let funcinst module_inst hostaddr deftype =
  Wrap.wrap_struct_v "funcinst"
    [
      (Wrap.wrap_atom "TYPE", Construct.il_of_def_type deftype);
      (Wrap.wrap_atom "MODULE", module_inst);
      (Wrap.wrap_atom "CODE", host_func hostaddr);
    ]

let globalinst globaltype value =
  Wrap.wrap_struct_v "globalinst"
    [
      (Wrap.wrap_atom "TYPE", Construct.il_of_global_type globaltype);
      (Wrap.wrap_atom "VALUE", value);
    ]

let tableinst tabletype =
  let Types.TableT (_, limits, (_, heaptype)) = tabletype in
  let size = Int64.to_int limits.min in
  let refs = List.init size (fun _ -> null_ref heaptype) in
  Wrap.wrap_struct_v "tableinst"
    [
      (Wrap.wrap_atom "TYPE", Construct.il_of_table_type tabletype);
      (Wrap.wrap_atom "REFS", list_value "refval" refs);
    ]

let meminst memtype =
  let Types.MemoryT (_, limits) = memtype in
  let bytes = Int64.to_int limits.min * 65536 in
  let zero = nat 0 in
  Wrap.wrap_struct_v "meminst"
    [
      (Wrap.wrap_atom "TYPE", Construct.il_of_memory_type memtype);
      (Wrap.wrap_atom "BYTES", list_value "byte" (List.init bytes (fun _ -> zero)));
    ]

let make_spectest_instance () =
  let func_types = List.map snd spectest_func_decls in
  let func_addrs = List.mapi (fun index _ -> nat index) spectest_func_decls in
  let global_addrs =
    List.mapi (fun index _ -> nat index) spectest_global_decls
  in
  let table_addrs = List.mapi (fun index _ -> nat index) spectest_table_decls in
  let mem_addrs = List.mapi (fun index _ -> nat index) spectest_memory_decls in
  let exports =
    List.mapi
      (fun index (name, _) -> export_inst name (func_addr index))
      spectest_func_decls
    @ List.mapi
        (fun index (name, _, _) -> export_inst name (global_addr index))
        spectest_global_decls
    @ List.mapi
        (fun index (name, _) -> export_inst name (table_addr index))
        spectest_table_decls
    @ List.mapi
        (fun index (name, _) -> export_inst name (mem_addr index))
        spectest_memory_decls
  in
  let module_inst =
    Wrap.wrap_struct_v "moduleinst"
      [
        ( Wrap.wrap_atom "TYPES",
          list_value "deftype" (List.map Construct.il_of_def_type func_types) );
        (Wrap.wrap_atom "FUNCS", list_value "funcaddr" func_addrs);
        (Wrap.wrap_atom "GLOBALS", list_value "globaladdr" global_addrs);
        (Wrap.wrap_atom "TABLES", list_value "tableaddr" table_addrs);
        (Wrap.wrap_atom "MEMS", list_value "memaddr" mem_addrs);
        (Wrap.wrap_atom "TAGS", list_value "tagaddr" []);
        (Wrap.wrap_atom "ELEMS", list_value "elemaddr" []);
        (Wrap.wrap_atom "DATAS", list_value "dataaddr" []);
        (Wrap.wrap_atom "EXPORTS", list_value "exportinst" exports);
      ]
  in
  let funcs =
    List.mapi
      (fun index (_, deftype) -> funcinst module_inst index deftype)
      spectest_func_decls
  in
  let globals =
    List.map
      (fun (_, globaltype, value) -> globalinst globaltype value)
      spectest_global_decls
  in
  let tables = List.map (fun (_, tabletype) -> tableinst tabletype) spectest_table_decls in
  let mems = List.map (fun (_, memtype) -> meminst memtype) spectest_memory_decls in
  let store =
    Wrap.wrap_struct_v "store"
      [
        (Wrap.wrap_atom "FUNCS", list_value "funcinst" funcs);
        (Wrap.wrap_atom "GLOBALS", list_value "globalinst" globals);
        (Wrap.wrap_atom "TABLES", list_value "tableinst" tables);
        (Wrap.wrap_atom "MEMS", list_value "meminst" mems);
        (Wrap.wrap_atom "TAGS", list_value "taginst" []);
        (Wrap.wrap_atom "ELEMS", list_value "eleminst" []);
        (Wrap.wrap_atom "DATAS", list_value "datainst" []);
        (Wrap.wrap_atom "STRUCTS", list_value "structinst" []);
        (Wrap.wrap_atom "ARRAYS", list_value "arrayinst" []);
        (Wrap.wrap_atom "EXNS", list_value "exninst" []);
      ]
  in
  { module_inst; store }

let empty_store () =
  Wrap.wrap_struct_v "store"
    [
      (Wrap.wrap_atom "FUNCS", list_value "funcinst" []);
      (Wrap.wrap_atom "GLOBALS", list_value "globalinst" []);
      (Wrap.wrap_atom "TABLES", list_value "tableinst" []);
      (Wrap.wrap_atom "MEMS", list_value "meminst" []);
      (Wrap.wrap_atom "TAGS", list_value "taginst" []);
      (Wrap.wrap_atom "ELEMS", list_value "eleminst" []);
      (Wrap.wrap_atom "DATAS", list_value "datainst" []);
      (Wrap.wrap_atom "STRUCTS", list_value "structinst" []);
      (Wrap.wrap_atom "ARRAYS", list_value "arrayinst" []);
      (Wrap.wrap_atom "EXNS", list_value "exninst" []);
    ]

let initial_state () =
  let spectest = make_spectest_instance () in
  {
    store = spectest.store;
    modules = StringMap.empty;
    instances = StringMap.empty;
    registry = StringMap.add "spectest" spectest StringMap.empty;
  }

let key_of_var_opt (var_opt : Script.var option) : string =
  match var_opt with
  | None -> ""
  | Some var -> var.it

let key_of_name (name : Ast.name) : string = Utf8.encode name

let bind_default_and_named at category map key value =
  let map =
    if key = "" then map
    else if StringMap.mem key map then error at (category ^ " " ^ key ^ " already defined")
    else StringMap.add key value map
  in
  StringMap.add "" value map

let lookup at category map key =
  match StringMap.find_opt key map with
  | Some value -> value
  | None ->
      error at
        (if key = "" then "no " ^ category ^ " defined"
         else "unknown " ^ category ^ " " ^ key)

let bind_module at var_opt (entry : module_entry) state =
  let key = key_of_var_opt var_opt in
  {
    state with
    modules = bind_default_and_named at "module" state.modules key entry;
  }

let bind_module_entry state var_opt entry = bind_module no_region var_opt entry state

let lookup_module at var_opt state =
  lookup at "module" state.modules (key_of_var_opt var_opt)

let bind_instance at var_opt (entry : instance_entry) state =
  let key = key_of_var_opt var_opt in
  {
    state with
    store = entry.store;
    instances =
      bind_default_and_named at "module instance" state.instances key entry;
  }

let lookup_instance at var_opt state =
  lookup at "module instance" state.instances (key_of_var_opt var_opt)

let bind_registry name (instance : instance_entry) state =
  { state with registry = StringMap.add (key_of_name name) instance state.registry }

let lookup_export at module_inst item_name =
  let item_key = key_of_name item_name in
  let exports = field at "EXPORTS" module_inst |> as_list at in
  let matches export =
    let name = field at "NAME" export |> as_text at in
    name = item_key
  in
  match List.find_opt matches exports with
  | Some export -> field at "ADDR" export
  | None -> error at ("unknown export " ^ item_key)

let case_tag value =
  match value.it with
  | CaseV valuecase -> (
      let mixop = Domain.Mixfix.atoms_matrix valuecase in
      let values = Domain.Mixfix.args valuecase in
      match mixop with
      | ({ it = Atom tag; _ } :: _) :: _ -> Some (tag, values)
      | ({ it = SilentAtom tag; _ } :: _) :: _ -> Some (tag, values)
      | _ -> None)
  | _ -> None

let funcaddr_of_export at module_inst name =
  match case_tag (lookup_export at module_inst name) with
  | Some ("FuncAddr", [ addr ]) -> addr
  | _ -> error at "export is not a function"

let globaladdr_of_export at module_inst name =
  match case_tag (lookup_export at module_inst name) with
  | Some ("GlobalAddr", [ addr ]) -> as_nat at addr
  | _ -> error at "export is not a global"

let global_value at store globaladdr =
  let globals = field at "GLOBALS" store |> as_list at in
  let global =
    try List.nth globals globaladdr
    with Failure _ -> error at "global address out of bounds"
  in
  field at "VALUE" global

let resolve_import at state (import : Ast.import) =
  let module_key = key_of_name import.it.module_name in
  match StringMap.find_opt module_key state.registry with
  | None ->
      Error (UnknownImport ("unknown import module " ^ module_key))
  | Some provider ->
      let item_key = key_of_name import.it.item_name in
      let exports = field at "EXPORTS" provider.module_inst |> as_list at in
      let matches export =
        field at "NAME" export |> as_text at = item_key
      in
      (match List.find_opt matches exports with
      | Some export -> Ok (field at "ADDR" export)
      | None ->
          Error
            (UnknownImport
               ("unknown import " ^ module_key ^ "." ^ item_key)))

let resolve_imports at state (module_ : Ast.module_) =
  let rec loop acc = function
    | [] -> Ok (List.rev acc)
    | import :: imports -> (
        match resolve_import at state import with
        | Ok externaddr -> loop (externaddr :: acc) imports
        | Error error -> Error error)
  in
  loop [] module_.it.imports

let externaddr_list externaddrs = list_value "externaddr" externaddrs

let value_of_literal (literal : Script.literal) =
  match literal.it with
  | WasmValue.Num num -> runtime_num num
  | WasmValue.Vec vec -> runtime_vec vec
  | WasmValue.Ref ref_ -> runtime_ref ref_

let value_list values = list_value "value" values

let module_entry_of_definition def =
  let module_, custom = Run.run_definition def in
  { module_; custom; value = Construct.il_of_module module_ }

let exec_outcome_of_value at value =
  match case_tag value with
  | Some ("ValuesO", [ store; values ]) ->
      Returned { store; values = as_list at values }
  | Some ("TrapO", [ store ]) ->
      Trapped store
  | Some ("ExceptionO", [ store; tagaddr; values ]) ->
      Thrown { store; tagaddr; values = as_list at values }
  | _ -> error at "expected execoutcome"

let store_of_exec_outcome = function
  | Returned { store; _ }
  | Trapped store
  | Thrown { store; _ } ->
      store

let init_outputs at outputs =
  match outputs with
  | [ module_inst; outcome_value ] ->
      InitExecuted
        {
          module_inst;
          outcome = exec_outcome_of_value at outcome_value;
        }
  | _ -> error at "Init_with_store_ok returned unexpected outputs"

let invoke_outputs at outputs =
  match outputs with
  | [ outcome ] -> (
      match exec_outcome_of_value at outcome with
      | Returned { store; values } ->
          Returned { store; values = List.rev values }
      | outcome -> outcome)
  | _ -> error at "Invoke returned unexpected outputs"

let ref_case_tag value =
  match case_tag value with
  | Some ("RefV", [ ref_value ]) -> (
      match case_tag ref_value with
      | Some (tag, _) -> Some tag
      | None -> None)
  | _ -> None

let num_value value =
  match case_tag value with
  | Some ("NumV", [ num ]) -> Some (Deconstruct.sl_to_num num)
  | _ -> None

let vec_value value =
  match case_tag value with
  | Some ("VecV", [ vec ]) -> Some (Deconstruct.sl_to_vec vec)
  | _ -> None

let assert_nan_pat (num : WasmValue.num) (nanop : Script.nanop) =
  let open WasmValue in
  match num, nanop.it with
  | F32 z, F32 Script.CanonicalNan ->
    z = F32.pos_nan || z = F32.neg_nan
  | F64 z, F64 Script.CanonicalNan ->
    z = F64.pos_nan || z = F64.neg_nan
  | F32 z, F32 Script.ArithmeticNan ->
    let pos_nan = F32.to_bits F32.pos_nan in
    Int32.logand (F32.to_bits z) pos_nan = pos_nan
  | F64 z, F64 Script.ArithmeticNan ->
    let pos_nan = F64.to_bits F64.pos_nan in
    Int64.logand (F64.to_bits z) pos_nan = pos_nan
  | _ -> false

let num_pat_matches (num : WasmValue.num) (pat : Script.num_pat) =
  match pat with
  | Script.NumPat expected -> num = expected.it
  | Script.NanPat nanop -> assert_nan_pat num nanop

let vec_pat_matches (vec : WasmValue.vec) (pat : Script.vec_pat) =
  match (vec, pat) with
  | WasmValue.V128 vec128, Script.VecPat (WasmValue.V128 (shape, pats)) ->
    let extract =
      match shape with
      | V128.I8x16 () ->
        fun v i -> WasmValue.I32 (V128.I8x16.extract_lane_s i v)
      | V128.I16x8 () ->
        fun v i -> WasmValue.I32 (V128.I16x8.extract_lane_s i v)
      | V128.I32x4 () ->
        fun v i -> WasmValue.I32 (V128.I32x4.extract_lane_s i v)
      | V128.I64x2 () ->
        fun v i -> WasmValue.I64 (V128.I64x2.extract_lane_s i v)
      | V128.F32x4 () ->
        fun v i -> WasmValue.F32 (V128.F32x4.extract_lane i v)
      | V128.F64x2 () ->
        fun v i -> WasmValue.F64 (V128.F64x2.extract_lane i v)
    in
    List.for_all2 num_pat_matches
      (List.init (V128.num_lanes shape) (extract vec128))
      pats

let rec result_matches_value at got (expect : Script.result) =
  match expect.it with
  | Script.NumResult (Script.NumPat num) ->
    num_value got = Some num.it
  | Script.NumResult (Script.NanPat nanop) ->
    (match num_value got with
    | Some num -> assert_nan_pat num nanop
    | None -> false)
  | Script.VecResult vecpat -> (
      match vec_value got with
      | Some vec -> vec_pat_matches vec vecpat
      | None -> false)
  | Script.RefResult Script.NullPat -> (
      match ref_case_tag got with
      | Some "NullRef" -> true
      | _ -> false)
  | Script.RefResult (Script.RefPat { it = WasmValue.NullRef _; _ }) -> (
      match ref_case_tag got with
      | Some "NullRef" -> true
      | _ -> false)
  | Script.RefResult (Script.RefPat ref_) ->
    Il.Eq.eq_value got (runtime_ref ref_.it)
  | Script.RefResult (Script.RefTypePat heaptype) -> (
      match heaptype, ref_case_tag got with
      | Types.AnyHT, Some ("I31Ref" | "StructRef" | "ArrayRef" | "HostRef") ->
        true
      | Types.EqHT, Some ("I31Ref" | "StructRef" | "ArrayRef") -> true
      | Types.I31HT, Some "I31Ref" -> true
      | Types.StructHT, Some "StructRef" -> true
      | Types.ArrayHT, Some "ArrayRef" -> true
      | Types.FuncHT, Some "FuncRef" -> true
      | Types.ExternHT, Some ("ExternRef" | "HostRef") -> true
      | _ -> false)
  | Script.EitherResult results ->
    List.exists (result_matches_value at got) results

let assert_results at got expect =
  if
    List.length got <> List.length expect
    || not (List.for_all2 (result_matches_value at) got expect)
  then
    let got_values =
      got |> List.map Il.Print.string_of_value |> String.concat ", "
    in
    error at
      (Printf.sprintf
         "wrong return values: got %d value(s) [%s], expected %d"
         (List.length got) got_values (List.length expect))

let action_label (act : Script.action) =
  match act.it with
  | Script.Invoke (None, name, _) -> "invoke " ^ key_of_name name
  | Script.Invoke (Some var, name, _) ->
    "invoke " ^ var.it ^ "." ^ key_of_name name
  | Script.Get (None, name) -> "get " ^ key_of_name name
  | Script.Get (Some var, name) -> "get " ^ var.it ^ "." ^ key_of_name name

let assert_action_results at act got expect =
  try assert_results at got expect
  with Util.Error.InterpError (_, msg) ->
    error at (action_label act ^ ": " ^ msg)

let eval_dynamic_rel runtime relname values_input =
  let module Simulator = (val runtime.simulator : Sim.SIM) in
  match Simulator.Interp.eval_rel relname values_input with
  | Pass values -> values
  | Fail (at, msg) -> error at (relname ^ " failed: " ^ msg)

let eval_init runtime state module_entry =
  ignore (eval_dynamic_rel runtime "Module_ok" [ module_entry.value ]);
  match resolve_imports no_region state module_entry.module_ with
  | Error error -> Error error
  | Ok externaddrs ->
      let externaddr_value = externaddr_list externaddrs in
      Ok
        (eval_dynamic_rel runtime "Init_with_store_ok"
           [ state.store; module_entry.value; externaddr_value ]
        |> init_outputs no_region)

let instantiate runtime state var_opt module_entry =
  match eval_init runtime state module_entry with
  | Ok
      (InitExecuted
        {
          module_inst;
          outcome = Returned { store; values = [] };
        }) ->
      let instance : instance_entry = { module_inst; store } in
      bind_instance no_region var_opt instance state
  | Error (UnknownImport _) ->
      error no_region "unexpected link failure during instantiation"
  | Ok (InitExecuted { outcome = Returned _; _ }) ->
      error no_region "instantiation returned unexpected values"
  | Ok (InitExecuted { outcome = Trapped _; _ }) ->
      error no_region "unexpected trap during instantiation"
  | Ok (InitExecuted { outcome = Thrown _; _ }) ->
      error no_region "unexpected exception during instantiation"

let expect_uninstantiable runtime state module_entry =
  match eval_init runtime state module_entry with
  | Ok (InitExecuted { outcome = Trapped store; _ }) -> { state with store }
  | Error (UnknownImport _) ->
      error no_region "expected instantiation trap, got link error"
  | Ok (InitExecuted { outcome = Returned _; _ }) ->
      error no_region "expected instantiation trap, got return"
  | Ok (InitExecuted { outcome = Thrown _; _ }) ->
      error no_region "expected instantiation trap, got exception"

let run_action runtime state (act : Script.action) =
  match act.it with
  | Script.Invoke (var_opt, name, literals) ->
      let instance = lookup_instance no_region var_opt state in
      let funcaddr = funcaddr_of_export no_region instance.module_inst name in
      let arguments = value_list (List.map value_of_literal literals) in
      eval_dynamic_rel runtime "Invoke" [ state.store; funcaddr; arguments ]
      |> invoke_outputs no_region
  | Script.Get (var_opt, name) ->
      let instance = lookup_instance no_region var_opt state in
      let globaladdr = globaladdr_of_export no_region instance.module_inst name in
      let value = global_value no_region state.store globaladdr in
      Returned { store = state.store; values = [ value ] }

let run_command runtime ~index ~total state (cmd : Script.command) =
  trace_command ~index ~total cmd;
  let context_error at msg =
    error at (debug_error_message ~index ~total cmd msg)
  in
  try
    match cmd.it with
    | Script.Module (var_opt, def) ->
        let entry = module_entry_of_definition def in
        bind_module no_region var_opt entry state
    | Script.Instance (var_opt, source_var_opt) ->
        let module_entry = lookup_module no_region source_var_opt state in
        instantiate runtime state var_opt module_entry
    | Script.Register (name, var_opt) ->
        let instance = lookup_instance no_region var_opt state in
        bind_registry name instance state
    | Script.Assertion ass -> (
        match ass.it with
        | Script.AssertInvalid (def, _) ->
            let entry = module_entry_of_definition def in
            (match
               let module Simulator = (val runtime.simulator : Sim.SIM) in
               Simulator.Interp.eval_rel "Module_ok" [ entry.value ]
             with
            | Fail _ -> state
            | Pass _ -> error no_region "expected validation failure")
        | Script.AssertUninstantiable (var_opt, _) ->
            let module_entry = lookup_module no_region var_opt state in
            expect_uninstantiable runtime state module_entry
        | Script.AssertReturn (act, results) -> (
            match run_action runtime state act with
            | Returned { store; values } ->
                assert_action_results no_region act values results;
                { state with store }
            | Trapped _ -> error no_region "expected return, got trap"
            | Thrown _ -> error no_region "expected return, got exception")
        | Script.AssertTrap (act, _) -> (
            match run_action runtime state act with
            | Trapped store -> { state with store }
            | Returned _ -> error no_region "expected runtime trap, got return"
            | Thrown _ -> error no_region "expected runtime trap, got exception")
        | Script.AssertException act -> (
            match run_action runtime state act with
            | Thrown { store; _ } -> { state with store }
            | Returned _ -> error no_region "expected exception, got return"
            | Trapped _ -> error no_region "expected exception, got trap")
        | Script.AssertMalformed _
        | Script.AssertMalformedCustom _
        | Script.AssertInvalidCustom _
        | Script.AssertUnlinkable _
        | Script.AssertExhaustion _ -> state)
    | Script.Action act -> (
        match run_action runtime state act with
        | Returned { store; _ } -> { state with store }
        | Trapped _ -> error no_region "unexpected runtime trap"
        | Thrown _ -> error no_region "unexpected exception")
    | Script.Meta _ -> state
  with Util.Error.InterpError (at, msg) -> context_error at msg

let run_commands runtime state commands =
  let total = List.length commands in
  List.fold_left
    (fun state (index, command) -> run_command runtime ~index ~total state command)
    state
    (List.mapi (fun index command -> (index + 1, command)) commands)
