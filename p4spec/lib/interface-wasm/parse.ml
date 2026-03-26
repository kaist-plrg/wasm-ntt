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

let parse_file (filename : string) : Lang.Il.value * expectation =
  match Filename.extension filename with
  | ".wast" ->
    let commands : Script.command list =
      filename
      |> parse Wasm_interpreter.Parse.Script.parse_file
      |> List.filter (fun (cmd : Script.command) ->
        match cmd.it with
        | Script.Module _ -> true
        | Script.Assertion ass -> (
            match ass.it with
            | Script.AssertInvalid _  -> true
            | _ -> false)
        | _ -> false)
    in
    let expectation =
      if
        List.exists
          (fun (cmd : Script.command) ->
            match cmd.it with
            | Script.Assertion ass -> (
                match ass.it with
                | Script.AssertInvalid _  -> true
                | _ -> false)
            | _ -> false)
          commands
      then Negative
      else Positive
    in
    let wasts = List.map (fun (cmd : Script.command) ->
      match cmd.it with
      | Script.Module (_, def) ->
        let m, cs = Run.run_definition def in
        (m, cs)
      | Script.Assertion ass ->
        (match ass.it with
        | Script.AssertInvalid (def, _) ->
          let m, cs = Run.run_definition def in
          (m, cs)
        | _ -> failwith "Unsupported assertion type")
      | _ -> failwith "Unsupported command type") commands
      |> List.map fst
    in
    let il_modules = il_of_list "module" il_of_module wasts in
    (il_modules, expectation)
  | _ -> failwith "Unsupported file extension"
