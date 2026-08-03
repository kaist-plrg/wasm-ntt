open Wasm_interpreter
open Construct

type expectation = Positive | Negative

let logging = ref false

let num_parse_fail = ref 0

let log fmt = Printf.(if !logging then fprintf stderr fmt else ifprintf stderr fmt)

let parse parser filename =
  Printf.printf "===== %s =====\n%!" filename;
  log "===========================\n\n%s\n\n" filename;
  try
    parser filename
  with e ->
    let bt = Printexc.get_raw_backtrace () in
    print_endline ("- Failed to parse " ^ filename ^ "\n");
    log ("- Failed to parse %s\n") filename;
    num_parse_fail := !num_parse_fail + 1;
    Printexc.raise_with_backtrace e bt

let pos_leq (left : Source.pos) (right : Source.pos) =
  left.line < right.line || (left.line = right.line && left.column <= right.column)

let region_contains (outer : Source.region) (inner : Source.region) =
  outer.left.file = inner.left.file
  && pos_leq outer.left inner.left
  && pos_leq inner.right outer.right

let is_module_form_instantiation_assertion (command : Script.command) =
  match command.it with
  | Script.Assertion assertion -> (
      match assertion.it with
      | Script.AssertUninstantiable _ | Script.AssertUnlinkable _ -> true
      | _ -> false)
  | _ -> false

let normalize_desugared_regions (commands : Script.command list) =
  let rec loop = function
    | (module_command : Script.command) :: (assertion_command : Script.command) :: rest
      when (match module_command.it with Script.Module _ -> true | _ -> false)
           && is_module_form_instantiation_assertion assertion_command
           && region_contains assertion_command.at module_command.at ->
        { module_command with at = assertion_command.at } :: assertion_command :: loop rest
    | command :: rest -> command :: loop rest
    | [] -> []
  in
  loop commands

let parse_commands (filename : string) : Script.command list =
  filename |> parse Wasm_interpreter.Parse.Script.parse_file |> normalize_desugared_regions

let is_validation_command (cmd : Script.command) : bool =
  match cmd.it with
  | Script.Module _ -> true
  | Script.Assertion ass -> (
      match ass.it with
      | Script.AssertInvalid _ -> true
      | _ -> false)
  | _ -> false

let expects_validation_failure (commands : Script.command list) : bool =
  List.exists
    (fun (cmd : Script.command) ->
      match cmd.it with
      | Script.Assertion ass -> (
          match ass.it with
          | Script.AssertInvalid _ -> true
          | _ -> false)
      | _ -> false)
    commands

let module_of_validation_command (cmd : Script.command) :
    Wasm_interpreter.Ast.module_ =
  match cmd.it with
  | Script.Module (_, def) ->
    let m, _cs = Run.run_definition def in
    m
  | Script.Assertion ass -> (
      match ass.it with
      | Script.AssertInvalid (def, _) ->
        let m, _cs = Run.run_definition def in
        m
      | _ -> failwith "Unsupported assertion type")
  | _ -> failwith "Unsupported command type"

let parse_module_list_file (filename : string) : Lang.Il.value * expectation =
  match Filename.extension filename with
  | ".wast" ->
    let commands = parse_commands filename |> List.filter is_validation_command in
    let expectation = if expects_validation_failure commands then Negative else Positive in
    let wasts = List.map module_of_validation_command commands in
    let il_modules = il_of_list "module" il_of_module wasts in
    (il_modules, expectation)
  | _ -> failwith "Unsupported file extension"

let parse_file_for_rel (relname : string) (filename : string) :
    Lang.Il.value * expectation =
  if Script_harness.is_script_harness_rel relname then
    failwith "script harness relations are handled by eval_wasm_program"
  else parse_module_list_file filename

let parse_file (filename : string) : Lang.Il.value * expectation =
  parse_module_list_file filename
