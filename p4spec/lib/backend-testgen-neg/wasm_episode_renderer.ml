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

let render_instantiation ~episode ~mutated_module =
  match mutated_entry mutated_module with
  | Error _ as error -> error
  | Ok entry ->
      let prefix = List.map (fun group -> group.Episode.raw_text) episode.Episode.immutable_prefix in
      let module_var = Episode.target_module_var episode in
      let target = module_sexpr ~is_definition:false module_var entry in
      Ok (String.concat "\n" (prefix @ [ render_sexprs [ target ] ]))
