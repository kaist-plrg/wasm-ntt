module Episode = Wasm_episode
module Sexpr = Wasm_interpreter.Sexpr

let module_sexpr ~is_definition module_var
    (entry : Wasm_interface.Script_harness.module_entry) =
  Wasm_interpreter.Arrange.module_with_var_opt is_definition module_var
    (entry.module_, entry.custom)

let render_sexprs sexprs =
  sexprs
  |> List.map (Wasm_interpreter.Sexpr.to_string 80)
  |> String.concat "\n"

let mutated_entry mutated_module = Episode.module_entry_of_value mutated_module

let render_validation ~mutated_module ~valid =
  match mutated_entry mutated_module with
  | Error _ as error -> error
  | Ok entry ->
      let module_sexpr = module_sexpr ~is_definition:false None entry in
      let target =
        if valid then module_sexpr
        else
          Sexpr.Node
            ("assert_invalid", [ module_sexpr; Sexpr.Atom (Wasm_interpreter.Arrange.string "") ])
      in
      Ok (render_sexprs [ target ])

(* A finding is a program the specification could not execute, so there is no
   return value to assert. It is emitted as assert_trap: that is what a complete
   semantics does with the same program, which is what makes the discrepancy
   checkable against the unmodified specification. *)
let render_invocation ~(episode : Episode.invocation_episode) ~mutated_module =
  match mutated_entry mutated_module with
  | Error _ as error -> error
  | Ok entry ->
      let raw groups = List.map (fun group -> group.Episode.raw_text) groups in
      let prefix = raw episode.Episode.invocation_prefix in
      let target =
        module_sexpr ~is_definition:false
          episode.Episode.invocation_target_module_var entry
      in
      let replayed, observed =
        match List.rev episode.Episode.invocation_suffix with
        | [] -> ([], [])
        | last :: earlier -> (raw (List.rev earlier), [ last ])
      in
      let trapping =
        observed
        |> List.concat_map (fun group -> group.Episode.commands)
        |> List.filter_map (fun (command : Wasm_interpreter.Script.command) ->
               match (Episode.action_of_command command).it with
               | Wasm_interpreter.Script.Action act ->
                   Some
                     (Sexpr.Node
                        ( "assert_trap",
                          [ Wasm_interpreter.Arrange.action `Textual act;
                            Sexpr.Atom (Wasm_interpreter.Arrange.string "") ] ))
               | _ -> None)
      in
      Ok
        (String.concat "\n"
           (prefix @ [ render_sexprs [ target ] ] @ replayed
           @ [ render_sexprs trapping ]))

let render_instantiation ~episode ~mutated_module =
  match mutated_entry mutated_module with
  | Error _ as error -> error
  | Ok entry ->
      let prefix = List.map (fun group -> group.Episode.raw_text) episode.Episode.immutable_prefix in
      let module_var = Episode.target_module_var episode in
      let target = module_sexpr ~is_definition:false module_var entry in
      Ok (String.concat "\n" (prefix @ [ render_sexprs [ target ] ]))
