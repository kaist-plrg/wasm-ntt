module Script = Wasm_interpreter.Script
module Source = Wasm_interpreter.Source
module Harness = Wasm_interface.Script_harness
module Phase = Wasm_phase

type driver_kind =
  | PlainInstance
  | ExplicitInstance
  | ModuleTrapAssertion
  | ModuleUnlinkableAssertion

type target_driver = {
  kind : driver_kind;
  command : Script.command;
  instance_var : Script.var option;
  module_var : Script.var option;
}

type expected_driver_outcome =
  | ExpectNormalInstantiation
  | ExpectTrap
  | ExpectLink
  | ExpectRawException

type source_group = {
  ordinal : int;
  region : Source.region;
  raw_text : string;
  commands : Script.command list;
}

type target_layout =
  | SugaredInOneGroup of {
      group : source_group;
      module_command : Script.command;
      driver : target_driver;
    }
  | ExplicitAcrossGroups of {
      definition_group : source_group;
      module_command : Script.command;
      driver_group : source_group;
      driver : target_driver;
    }

type t = {
  source_path : string;
  immutable_prefix : source_group list;
  target_layout : target_layout;
  target_entry : Harness.module_entry;
  expected_outcome : expected_driver_outcome;
}

type exception_metadata = {
  tagaddr : string;
  values : string list;
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

let exception_metadata_path wast_path = wast_path ^ ".meta.json"

let metadata_error wast_path message =
  file_error wast_path ("exception metadata: " ^ message)

let string_field fields name =
  match List.assoc_opt name fields with Some (`String value) -> Ok value | _ -> Error name

let bool_field fields name =
  match List.assoc_opt name fields with Some (`Bool value) -> Ok value | _ -> Error name

let int_field fields name =
  match List.assoc_opt name fields with Some (`Int value) -> Ok value | _ -> Error name

let string_list_field fields name =
  match List.assoc_opt name fields with
  | Some (`List values) ->
      let rec collect reversed = function
        | [] -> Ok (List.rev reversed)
        | `String value :: rest -> collect (value :: reversed) rest
        | _ -> Error name
      in
      collect [] values
  | _ -> Error name

let decode_exception_metadata wast_path json =
  let expected_basename = Filename.basename wast_path in
  match json with
  | `Assoc fields -> (
      match
        ( int_field fields "schema",
          string_field fields "wast_basename",
          string_field fields "phase",
          string_field fields "outcome",
          string_field fields "relation",
          string_field fields "oracle",
          bool_field fields "self_checking_wast",
          string_field fields "tagaddr",
          string_list_field fields "values" )
      with
      | ( Ok 1,
          Ok wast_basename,
          Ok "instantiation",
          Ok "exception",
          Ok "Init_with_store_ok",
          Ok "phase-direct",
          Ok false,
          Ok tagaddr,
          Ok values )
        when String.equal wast_basename expected_basename -> Ok { tagaddr; values }
      | Ok _, Ok wast_basename, Ok _, Ok _, Ok _, Ok _, Ok _, Ok _, Ok _
        when not (String.equal wast_basename expected_basename) ->
          metadata_error wast_path "wast_basename does not match its .wast file"
      | Error field, _, _, _, _, _, _, _, _
      | _, Error field, _, _, _, _, _, _, _
      | _, _, Error field, _, _, _, _, _, _
      | _, _, _, Error field, _, _, _, _, _
      | _, _, _, _, Error field, _, _, _, _
      | _, _, _, _, _, Error field, _, _, _
      | _, _, _, _, _, _, Error field, _, _
      | _, _, _, _, _, _, _, Error field, _
      | _, _, _, _, _, _, _, _, Error field ->
          metadata_error wast_path ("missing or invalid field " ^ field)
      | _ -> metadata_error wast_path "unsupported schema or exception oracle")
  | _ -> metadata_error wast_path "expected a JSON object"

let read_exception_metadata_if_present wast_path =
  let metadata_path = exception_metadata_path wast_path in
  if not (Sys.file_exists metadata_path) then Ok None
  else
    try
      match Yojson.Safe.from_file metadata_path with
      | json -> decode_exception_metadata wast_path json |> Result.map Option.some
    with
    | Sys_error message -> metadata_error wast_path message
    | Yojson.Json_error message -> metadata_error wast_path ("malformed JSON: " ^ message)

let read_exception_metadata wast_path =
  match read_exception_metadata_if_present wast_path with
  | Ok (Some metadata) -> Ok metadata
  | Ok None -> metadata_error wast_path "missing .meta.json file"
  | Error _ as error -> error

let remove_file_if_present path =
  try if Sys.file_exists path then Sys.remove path with Sys_error _ -> ()

let write_exception_metadata_json wast_path json =
  let metadata_path = exception_metadata_path wast_path in
  let temporary = metadata_path ^ ".tmp" in
  Fun.protect
    ~finally:(fun () -> remove_file_if_present temporary)
    (fun () ->
      try
        let channel = open_out_bin temporary in
        Fun.protect ~finally:(fun () -> close_out_noerr channel) (fun () ->
            output_string channel (Yojson.Safe.pretty_to_string json);
            output_char channel '\n');
        Sys.rename temporary metadata_path;
        Ok ()
      with Sys_error message -> metadata_error wast_path message)

let write_exception_metadata wast_path ~tagaddr ~values =
  let json =
    `Assoc
      [ ("schema", `Int 1);
        ("wast_basename", `String (Filename.basename wast_path));
        ("phase", `String "instantiation");
        ("outcome", `String "exception");
        ("relation", `String "Init_with_store_ok");
        ("oracle", `String "phase-direct");
        ("self_checking_wast", `Bool false);
        ("tagaddr", `String (Lang.Il.Print.string_of_value tagaddr));
        ("values", `List (List.map (fun value -> `String (Lang.Il.Print.string_of_value value)) values)) ]
  in
  write_exception_metadata_json wast_path json

let write_exception_metadata_strings wast_path metadata =
  let json =
    `Assoc
      [ ("schema", `Int 1);
        ("wast_basename", `String (Filename.basename wast_path));
        ("phase", `String "instantiation");
        ("outcome", `String "exception");
        ("relation", `String "Init_with_store_ok");
        ("oracle", `String "phase-direct");
        ("self_checking_wast", `Bool false);
        ("tagaddr", `String metadata.tagaddr);
        ("values", `List (List.map (fun value -> `String value) metadata.values)) ]
  in
  write_exception_metadata_json wast_path json

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

let remove_metadata_if_present wast_path =
  let metadata_path = exception_metadata_path wast_path in
  if Sys.file_exists metadata_path then Sys.remove metadata_path

let copy_artifact ~src_wast ~dst_wast =
  match read_exception_metadata_if_present src_wast with
  | Error _ as error -> error
  | Ok metadata ->
      try
        remove_metadata_if_present dst_wast;
        copy_file src_wast dst_wast;
        (match metadata with
        | None -> Ok ()
        | Some metadata -> write_exception_metadata_strings dst_wast metadata)
      with Sys_error message -> file_error src_wast message

let move_artifact ~src_wast ~dst_wast =
  match read_exception_metadata_if_present src_wast with
  | Error _ as error -> error
  | Ok metadata ->
      try
        remove_metadata_if_present dst_wast;
        Sys.rename src_wast dst_wast;
        (match metadata with
        | None -> Ok ()
        | Some metadata ->
            match write_exception_metadata_strings dst_wast metadata with
            | Ok () ->
                Sys.remove (exception_metadata_path src_wast);
                Ok ()
            | Error error ->
                Sys.rename dst_wast src_wast;
                Error error)
      with Sys_error message -> file_error src_wast message

let remove_artifact wast_path =
  let metadata_path = exception_metadata_path wast_path in
  let paths = [ metadata_path ^ ".tmp"; metadata_path; wast_path ] in
  let first_error = ref None in
  List.iter
    (fun path ->
      try if Sys.file_exists path then Sys.remove path
      with Sys_error message ->
        if Option.is_none !first_error then first_error := Some message)
    paths;
  match !first_error with
  | None -> Ok ()
  | Some message -> file_error wast_path message

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
  | Script.Instance (instance_var, module_var) ->
      Some
        ({ kind = ExplicitInstance; command; instance_var; module_var },
         ExpectNormalInstantiation)
  | Script.Assertion assertion -> (
      match assertion.it with
      | Script.AssertUninstantiable (module_var, _) ->
          Some
            ({ kind = ModuleTrapAssertion; command; instance_var = None; module_var },
             ExpectTrap)
      | Script.AssertUnlinkable (module_var, _) ->
          Some
            ( { kind = ModuleUnlinkableAssertion;
                command;
                instance_var = None;
                module_var },
              ExpectLink )
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
    (final_command : Script.command) (driver : target_driver) =
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
            match driver.module_var with
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
          if selected.group.ordinal = final_group.ordinal then
            let kind =
              match driver.kind with ExplicitInstance -> PlainInstance | kind -> kind
            in
            let driver = { driver with kind } in
            Ok
              ( selected,
                driver,
                SugaredInOneGroup
                  { group = selected.group; module_command = selected.command; driver } )
          else if selected.group.ordinal + 1 = final_group.ordinal then
            Ok
              ( selected,
                driver,
                ExplicitAcrossGroups
                  { definition_group = selected.group;
                    module_command = selected.command;
                    driver_group = final_group;
                    driver } )
          else
            episode_error final_command.at
              "explicit target definition and driver are not adjacent source groups"

let parse_file filename =
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
      (match commands with
      | Error _ as error -> error
      | Ok commands ->
          match groups_of_commands filename source commands with
          | Error _ as error -> error
          | Ok groups ->
              match List.rev groups with
              | [] -> file_error filename "script contains no commands"
              | final_group :: _ -> (
                  match List.rev final_group.commands with
                  | [] -> assert false
                  | final_command :: _ -> (
                      match driver_of_command final_command with
                      | None ->
                          episode_error final_command.at
                            "final command is not an instantiation driver"
                      | Some (driver, expected_outcome) ->
                          match select_target (indexed_commands groups) final_group final_command driver with
                          | Error _ as error -> error
                          | Ok (selected, _, target_layout) -> (
                              match decode_target_entry selected.command with
                              | Error _ as error -> error
                              | Ok target_entry -> (
                                  match read_exception_metadata_if_present filename with
                                  | Error _ as error -> error
                                  | Ok (Some _) when expected_outcome <> ExpectNormalInstantiation ->
                                      episode_error final_command.at
                                        "exception metadata requires a raw normal instantiation driver"
                                  | Ok metadata ->
                                  let immutable_prefix =
                                    List.filter
                                      (fun group -> group.ordinal < selected.group.ordinal)
                                      groups
                                  in
                                  Ok
                                    { source_path = filename;
                                      immutable_prefix;
                                      target_layout;
                                      target_entry;
                                      expected_outcome =
                                        (match metadata with
                                        | Some _ -> ExpectRawException
                                        | None -> expected_outcome) })))))

let prefix_commands episode =
  List.concat_map (fun group -> group.commands) episode.immutable_prefix

let target_module_var episode =
  let command =
    match episode.target_layout with
    | SugaredInOneGroup { module_command; _ }
    | ExplicitAcrossGroups { module_command; _ } -> module_command
  in
  match command.it with
  | Script.Module (module_var, _) -> module_var
  | _ -> assert false

let target_driver episode =
  match episode.target_layout with
  | SugaredInOneGroup { driver; _ }
  | ExplicitAcrossGroups { driver; _ } -> driver

let target_driver_region episode = util_region (target_driver episode).command.at

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
