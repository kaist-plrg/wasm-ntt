module Episode = Wasm_episode
module Phase = Wasm_phase
module Script = Wasm_interpreter.Script
module Source = Wasm_interpreter.Source
module Sexpr = Wasm_interpreter.Sexpr

type render_kind =
  | PlainInstantiation
  | AssertTrap
  | AssertUnlinkable
  | RawException

let error at message = Error (Phase.EpisodeError (at, message))

let command_sexpr at command =
  match Wasm_interpreter.Arrange.script `Textual [ command ] with
  | [ sexpr ] -> Ok sexpr
  | _ -> error at "could not arrange a single target command"

let instance_command instance_var module_var =
  Source.{ it = Script.Instance (instance_var, module_var); at = no_region }

let module_sexpr ~is_definition module_var
    (entry : Wasm_interface.Script_harness.module_entry) =
  Wasm_interpreter.Arrange.module_with_var_opt is_definition module_var
    (entry.module_, entry.custom)

let assertion_node kind target =
  let name =
    match kind with
    | AssertTrap -> "assert_trap"
    | AssertUnlinkable -> "assert_unlinkable"
    | PlainInstantiation | RawException -> assert false
  in
  Sexpr.Node (name, [ target; Sexpr.Atom (Wasm_interpreter.Arrange.string "") ])

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

let same_var (left : Script.var option) (right : Script.var option) =
  match left, right with
  | None, None -> true
  | Some left, Some right -> String.equal left.it right.it
  | None, Some _ | Some _, None -> false

let render_instantiation ~episode ~mutated_module ~kind =
  match mutated_entry mutated_module with
  | Error _ as error -> error
  | Ok entry ->
      let at = Episode.target_driver_region episode in
      let prefix = List.map (fun group -> group.Episode.raw_text) episode.Episode.immutable_prefix in
      let module_var = Episode.target_module_var episode in
      let driver = Episode.target_driver episode in
      let module_sexpr =
        match episode.Episode.target_layout with
        | Episode.SugaredInOneGroup _ ->
            Ok (module_sexpr ~is_definition:false module_var entry)
        | Episode.ExplicitAcrossGroups _ ->
            Ok (module_sexpr ~is_definition:true module_var entry)
      in
      (match module_sexpr with
      | Error _ as error -> error
      | Ok module_sexpr ->
          let target =
            match episode.Episode.target_layout with
            | Episode.SugaredInOneGroup _ -> (
                match kind with
                | PlainInstantiation | RawException -> Ok [ module_sexpr ]
                | AssertTrap | AssertUnlinkable -> Ok [ assertion_node kind module_sexpr ])
            | Episode.ExplicitAcrossGroups _ ->
                if not (same_var module_var driver.module_var) then
                  error at "explicit target driver no longer names the target module"
                else
                  let instance = instance_command driver.instance_var driver.module_var in
                  match command_sexpr at instance with
                  | Error _ as error -> error
                  | Ok instance_sexpr -> (
                      match kind with
                      | PlainInstantiation | RawException -> Ok [ module_sexpr; instance_sexpr ]
                      | AssertTrap | AssertUnlinkable ->
                          Ok [ module_sexpr; assertion_node kind instance_sexpr ])
          in
          target
          |> Result.map (fun target ->
                 String.concat "\n" (prefix @ [ render_sexprs target ])))
