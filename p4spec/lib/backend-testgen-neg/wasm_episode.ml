module Script = Wasm_interpreter.Script
module Source = Wasm_interpreter.Source
module Harness = Wasm_interface.Script_harness
module Phase = Wasm_phase

type source_group = {
  ordinal : int;
  region : Source.region;
  raw_text : string;
  commands : Script.command list;
}

type t = {
  source_path : string;
  immutable_prefix : source_group list;
  target_module_var : Script.var option;
  target_entry : Harness.module_entry;
}

type grouped_command = {
  index : int;
  command : Script.command;
  group : source_group;
}

let util_pos (position : Source.pos) : Util.Source.pos =
  { file = position.file; line = position.line; column = position.column }

let util_region (region : Source.region) : Util.Source.region =
  { left = util_pos region.left; right = util_pos region.right }

let episode_error region message = Error (Phase.EpisodeError (util_region region, message))

let file_error filename message =
  Error (Phase.EpisodeError (Util.Source.region_of_file filename, message))

let copy_file source destination =
  let input_channel = open_in_bin source in
  Fun.protect
    ~finally:(fun () -> close_in_noerr input_channel)
    (fun () ->
      let output_channel = open_out_bin destination in
      Fun.protect
        ~finally:(fun () -> close_out_noerr output_channel)
        (fun () ->
          let buffer = Bytes.create 4096 in
          let rec loop () =
            match Stdlib.input input_channel buffer 0 (Bytes.length buffer) with
            | 0 -> ()
            | count -> Stdlib.output output_channel buffer 0 count; loop ()
          in
          loop ()))

let copy_artifact ~src_wast ~dst_wast =
  try
    copy_file src_wast dst_wast;
    Ok ()
  with Sys_error message -> file_error src_wast message

let move_artifact ~src_wast ~dst_wast =
  try
    Sys.rename src_wast dst_wast;
    Ok ()
  with Sys_error message -> file_error src_wast message

let remove_artifact wast_path =
  try
    if Sys.file_exists wast_path then Sys.remove wast_path;
    Ok ()
  with Sys_error message -> file_error wast_path message

let syntax_error region message = Error (Phase.SyntaxError (util_region region, message))

let compare_pos (left : Source.pos) (right : Source.pos) =
  match Int.compare left.line right.line with
  | 0 -> Int.compare left.column right.column
  | comparison -> comparison

let line_offsets source =
  let offsets = ref [ 0 ] in
  String.iteri
    (fun index character ->
      if character = '\n' then offsets := (index + 1) :: !offsets)
    source;
  Array.of_list (List.rev !offsets)

let offset_of_pos filename source offsets (position : Source.pos) =
  if position.file <> filename then
    Error ("region belongs to a different source file: " ^ position.file)
  else if position.line <= 0 || position.column < 0 then
    Error "region contains a non-textual source position"
  else
    let line_index = position.line - 1 in
    if line_index >= Array.length offsets then
      Error "region line lies beyond the source file"
    else
      let offset = offsets.(line_index) + position.column in
      let line_end =
        if line_index + 1 = Array.length offsets then String.length source
        else offsets.(line_index + 1) - 1
      in
      if offset > line_end then Error "region column lies beyond its source line"
      else Ok offset

let slice_region filename source offsets (region : Source.region) =
  match
    ( offset_of_pos filename source offsets region.left,
      offset_of_pos filename source offsets region.right )
  with
  | Ok left, Ok right when left <= right -> Ok (String.sub source left (right - left))
  | Ok _, Ok _ -> Error "region has an end before its start"
  | Error message, _ | _, Error message -> Error message

let groups_of_commands filename source (commands : Script.command list) =
  let offsets = line_offsets source in
  let valid_bounds (region : Source.region) =
    match
      ( offset_of_pos filename source offsets region.left,
        offset_of_pos filename source offsets region.right )
    with
    | Ok left, Ok right when left <= right -> Ok ()
    | Ok _, Ok _ -> Error "region has an end before its start"
    | Error message, _ | _, Error message -> Error message
  in
  let make_group ordinal (region : Source.region) reversed_commands =
    match slice_region filename source offsets region with
    | Ok raw_text ->
        Ok { ordinal; region; raw_text; commands = List.rev reversed_commands }
    | Error message -> episode_error region message
  in
  let rec collect ordinal current reversed_groups = function
    | [] -> (
        match current with
        | None -> Ok (List.rev reversed_groups)
        | Some (region, reversed_commands) -> (
            match make_group ordinal region reversed_commands with
            | Ok group -> Ok (List.rev (group :: reversed_groups))
            | Error _ as error -> error))
    | (command : Script.command) :: rest ->
        let region = command.at in
        (match valid_bounds region with
        | Error message -> episode_error region message
        | Ok () ->
            match current with
            | None -> collect ordinal (Some (region, [ command ])) reversed_groups rest
            | Some (current_region, reversed_commands) when current_region = region ->
                collect ordinal (Some (current_region, command :: reversed_commands))
                  reversed_groups rest
            | Some (current_region, reversed_commands) ->
                if compare_pos current_region.right region.left > 0 then
                  episode_error region "source groups overlap"
                else
                  match make_group ordinal current_region reversed_commands with
                  | Error _ as error -> error
                  | Ok group ->
                      collect (ordinal + 1) (Some (region, [ command ]))
                        (group :: reversed_groups) rest)
  in
  collect 0 None [] commands

let indexed_commands groups =
  let _, reversed =
    List.fold_left
      (fun (index, collected) group ->
        List.fold_left
          (fun (index, collected) command ->
            (index + 1, { index; command; group } :: collected))
          (index, collected) group.commands)
      (0, []) groups
  in
  List.rev reversed

let module_of_command (command : Script.command) =
  match command.it with Script.Module _ -> Some command | _ -> None

let module_var_of_command (command : Script.command) =
  match command.it with
  | Script.Module (module_var, _) -> Some module_var
  | _ -> None

let driver_of_command (command : Script.command) =
  match command.it with
  | Script.Instance (_, module_var) -> Some module_var
  | Script.Assertion assertion -> (
      match assertion.it with
      | Script.AssertUninstantiable (module_var, _) ->
          Some module_var
      | Script.AssertUnlinkable (module_var, _) ->
          Some module_var
      | _ -> None)
  | _ -> None

let target_entry_of_command (command : Script.command) =
  match command.it with
  | Script.Module (_, definition) -> Ok (Harness.module_entry_of_definition definition)
  | _ -> assert false

let decode_target_entry command =
  try target_entry_of_command command with
  | Wasm_interpreter.Parse.Syntax (region, message) -> syntax_error region message
  | Wasm_interpreter.Decode.Code (region, message) -> syntax_error region message
  | Wasm_interpreter.Custom.Syntax (region, message) -> syntax_error region message

let decode_observation_target (command : Script.command) =
  try
    match command.it with
    | Script.Assertion assertion -> (
        match assertion.it with
        | Script.AssertInvalid (definition, _) ->
            Ok (Harness.module_entry_of_definition definition)
        | _ -> episode_error command.at "final command is not assert_invalid")
    | _ -> episode_error command.at "final command is not assert_invalid"
  with
  | Wasm_interpreter.Parse.Syntax (region, message) -> syntax_error region message
  | Wasm_interpreter.Decode.Code (region, message) -> syntax_error region message
  | Wasm_interpreter.Custom.Syntax (region, message) -> syntax_error region message

let validate_named_module_bindings (modules : grouped_command list) =
  let rec loop names = function
    | [] -> Ok ()
    | candidate :: rest -> (
        match module_var_of_command candidate.command with
        | Some (Some module_var) when List.mem module_var.it names ->
            episode_error candidate.command.at
              ("duplicate module binding: " ^ module_var.it)
        | Some (Some module_var) -> loop (module_var.it :: names) rest
        | Some None -> loop names rest
        | None -> assert false)
  in
  loop [] modules

let select_target (indexed : grouped_command list) (final_group : source_group)
    (final_command : Script.command) (driver_module_var : Script.var option) =
  let modules =
    List.filter (fun candidate -> Option.is_some (module_of_command candidate.command)) indexed
  in
  match validate_named_module_bindings modules with
  | Error _ as error -> error
  | Ok () ->
      let last_module =
        match List.rev modules with candidate :: _ -> Some candidate | [] -> None
      in
      match last_module with
      | None -> episode_error final_command.at "script contains no module definition"
      | Some last_module ->
          let paired_modules =
            List.filter (fun candidate -> candidate.group.ordinal = final_group.ordinal) modules
          in
          let selected =
        match paired_modules with
        | [ candidate ] -> Ok candidate
        | _ :: _ :: _ ->
            episode_error final_command.at
              "target source group contains multiple module definitions"
        | [] -> (
            match driver_module_var with
            | Some module_var -> (
                match
                  List.filter
                    (fun candidate ->
                      match module_var_of_command candidate.command with
                      | Some (Some bound) -> bound.it = module_var.it
                      | Some None -> false
                      | None -> false)
                    modules
                with
                | [ candidate ] -> Ok candidate
                | [] ->
                    episode_error final_command.at
                      "driver refers to an unresolved module binding"
                | _ ->
                    episode_error final_command.at
                      "driver refers to an ambiguous module binding")
            | None -> Ok last_module)
          in
          match selected with
          | Error _ as error -> error
          | Ok selected when selected.index <> last_module.index ->
              episode_error final_command.at
                "final driver does not resolve to the last module definition"
          | Ok selected ->
              if
                selected.group.ordinal = final_group.ordinal
                || selected.group.ordinal + 1 = final_group.ordinal
              then Ok selected
              else
                episode_error final_command.at
                  "explicit target definition and driver are not adjacent source groups"

let parse_groups filename =
  let source =
    try
      let channel = open_in_bin filename in
      Fun.protect
        ~finally:(fun () -> close_in_noerr channel)
        (fun () -> Ok (really_input_string channel (in_channel_length channel)))
    with Sys_error message -> file_error filename message
  in
  match source with
  | Error _ as error -> error
  | Ok source ->
      let commands =
        try Ok (Wasm_interface.Parse.parse_commands filename) with
        | Wasm_interpreter.Parse.Syntax (region, message) -> syntax_error region message
        | Wasm_interpreter.Custom.Syntax (region, message) -> syntax_error region message
      in
      Result.bind commands (groups_of_commands filename source)

let parse_file filename =
  match parse_groups filename with
  | Error _ as error -> error
  | Ok groups ->
      (match List.rev groups with
              | [] -> file_error filename "script contains no commands"
              | final_group :: _ -> (
                  match List.rev final_group.commands with
                  | [] -> assert false
                  | final_command :: _ -> (
                      match driver_of_command final_command with
                      | None ->
                          episode_error final_command.at
                            "final command is not an instantiation driver"
                      | Some driver_module_var ->
                          match
                            select_target (indexed_commands groups) final_group
                              final_command driver_module_var
                          with
                          | Error _ as error -> error
                          | Ok selected -> (
                              match decode_target_entry selected.command with
                              | Error _ as error -> error
                              | Ok target_entry ->
                                  let immutable_prefix =
                                    List.filter
                                      (fun group -> group.ordinal < selected.group.ordinal)
                                      groups
                                  in
                                  let target_module_var =
                                    match module_var_of_command selected.command with
                                    | Some module_var -> module_var
                                    | None -> assert false
                                  in
                                  Ok
                                    { source_path = filename;
                                      immutable_prefix;
                                      target_module_var;
                                      target_entry }))))

let parse_observation_file ~prefix_paths filename =
  let rec load_prefix reversed = function
    | [] -> Ok (List.concat (List.rev reversed))
    | prefix_path :: rest -> (
        match parse_groups prefix_path with
        | Error _ as error -> error
        | Ok groups -> load_prefix (groups :: reversed) rest)
  in
  match load_prefix [] prefix_paths with
  | Error _ as error -> error
  | Ok prefix_groups -> (
      match parse_groups filename with
      | Error _ as error -> error
      | Ok groups -> (
          match List.rev groups with
          | [] -> file_error filename "script contains no commands"
          | final_group :: _ -> (
              match List.rev final_group.commands with
              | [] -> assert false
              | final_command :: _ -> (
                  match decode_observation_target final_command with
                  | Error _ as error -> error
                  | Ok target_entry ->
                      let inline_prefix =
                        List.filter
                          (fun group -> group.ordinal < final_group.ordinal)
                          groups
                      in
                      Ok
                        { source_path = filename;
                          immutable_prefix = prefix_groups @ inline_prefix;
                          target_module_var = None;
                          target_entry }))))

let prefix_commands episode =
  List.concat_map (fun group -> group.commands) episode.immutable_prefix

let target_module_var episode = episode.target_module_var

let target_value episode = episode.target_entry.value

let mutation_root mutated_module =
  Wasm_interface.Construct.il_of_list "module" (fun value -> value) [ mutated_module ]

let module_entry_of_value (value : Lang.Il.value) =
  try
    let module_ = Wasm_interface.Deconstruct.sl_to_module value in
    Ok Harness.{ module_; custom = []; value }
  with
  | Failure message
  | Invalid_argument message ->
      Error (Phase.HarnessFailure (Util.Source.no_region, message))
  | Util.Error.RuntimeError (at, message) ->
      Error (Phase.HarnessFailure (at, message))
  | Z.Overflow ->
      Error
        (Phase.HarnessFailure
           (Util.Source.no_region,
            "integer conversion overflow while reconstructing mutated module"))

let prepare runtime episode mutated_target =
  if Inst.Hook.is_active () then
    Error
      (Phase.HarnessFailure
         (Util.Source.no_region,
          "instrumentation handler leaked from an earlier run"))
  else (
    Wasm_interface.Builtin_hooks.init ();
    try
      let state =
        Harness.run_commands runtime (Harness.initial_state ())
          (prefix_commands episode)
      in
      match module_entry_of_value mutated_target with
      | Error _ as error -> error
      | Ok entry ->
          Ok
            ( Harness.bind_module_entry state (target_module_var episode) entry,
              entry )
    with
    | Util.Error.InterpError (at, message) ->
        Error (Phase.EpisodeError (at, message)))
