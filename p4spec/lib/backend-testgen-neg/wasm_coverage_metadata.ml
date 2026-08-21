module Phase = Wasm_phase

type coverage_metadata = {
  schema : int;
  phase : Config.wasm_phase;
  coverage_relations : string list;
  oracle : string;
}

let validation_schema = 1
let instantiation_schema = 2
let validation_oracle = "phase-direct"
let instantiation_oracle = "phase-direct-roots"

let metadata_path coverage = coverage ^ ".meta.json"
let temporary_path coverage = metadata_path coverage ^ ".tmp"

let error format =
  Format.kasprintf (fun message -> Phase.CoverageMetadataError message) format

let validate_relation_set phase relations =
  match phase with
  | Config.Validation ->
      if relations = [ "Modules_ok" ] then Ok relations
      else Error (error "validation coverage relations must be exactly Modules_ok")
  | Config.Instantiation ->
      let allowed relation =
        String.equal relation "Init_with_store_ok"
        || String.equal relation "Invoke"
      in
      let rec duplicate = function
        | [] -> None
        | relation :: rest ->
            if List.mem relation rest then Some relation else duplicate rest
      in
      (match duplicate relations with
      | Some relation ->
          Error (error "instantiation coverage relations contain duplicate %s" relation)
      | None -> (
          match List.find_opt (fun relation -> not (allowed relation)) relations with
          | Some relation ->
              Error (error "instantiation coverage relations contain unknown root %s" relation)
          | None ->
              if not (List.mem "Init_with_store_ok" relations) then
                Error
                  (error
                     "instantiation coverage relations must include Init_with_store_ok")
              else
                Ok
                  (List.filter
                     (fun relation -> List.mem relation relations)
                     [ "Init_with_store_ok"; "Invoke" ])))

let metadata_for ?coverage_relations phase =
  let relations =
    match coverage_relations with
    | Some relations -> relations
    | None -> [ Config.coverage_relation phase ]
  in
  Result.map
    (fun coverage_relations ->
      match phase with
      | Config.Validation ->
          { schema = validation_schema;
            phase;
            coverage_relations;
            oracle = validation_oracle }
      | Config.Instantiation ->
          { schema = instantiation_schema;
            phase;
            coverage_relations;
            oracle = instantiation_oracle })
    (validate_relation_set phase relations)

let json_of_metadata metadata =
  match metadata.phase with
  | Config.Validation ->
      `Assoc
        [ ("schema", `Int metadata.schema);
          ("phase", `String (Config.string_of_wasm_phase metadata.phase));
          ("coverage_relation", `String "Modules_ok");
          ("oracle", `String metadata.oracle) ]
  | Config.Instantiation ->
      `Assoc
        [ ("schema", `Int metadata.schema);
          ("phase", `String (Config.string_of_wasm_phase metadata.phase));
          ( "coverage_relations",
            `List (List.map (fun relation -> `String relation) metadata.coverage_relations) );
          ("oracle", `String metadata.oracle) ]

let remove_if_present path =
  try
    if Sys.file_exists path && not (Sys.is_directory path) then Sys.remove path
  with Sys_error _ -> ()

let write ?coverage_relations ~phase coverage =
  Result.bind (metadata_for ?coverage_relations phase) (fun metadata ->
      let path = metadata_path coverage in
      let temporary = temporary_path coverage in
      let completed = ref false in
      Fun.protect
        ~finally:(fun () -> if not !completed then remove_if_present temporary)
        (fun () ->
          try
            let channel = open_out_bin temporary in
            Fun.protect
              ~finally:(fun () -> close_out_noerr channel)
              (fun () ->
                Yojson.Safe.pretty_to_channel channel
                  (json_of_metadata metadata));
            Sys.rename temporary path;
            completed := true;
            Ok ()
          with
          | Sys_error message ->
              Error (error "cannot write coverage metadata %s: %s" path message)
          | Unix.Unix_error (code, _, _) ->
              Error
                (error "cannot write coverage metadata %s: %s" path
                   (Unix.error_message code))
          | exception_ ->
              Error
                (error "cannot write coverage metadata %s: %s" path
                   (Printexc.to_string exception_))))

let field name fields =
  match List.assoc_opt name fields with
  | Some value -> Ok value
  | None -> Error (error "coverage metadata is missing field %S" name)

let string_field name fields =
  match field name fields with
  | Ok (`String value) -> Ok value
  | Ok _ -> Error (error "coverage metadata field %S must be a string" name)
  | Error error -> Error error

let int_field name fields =
  match field name fields with
  | Ok (`Int value) -> Ok value
  | Ok _ -> Error (error "coverage metadata field %S must be an integer" name)
  | Error error -> Error error

let string_list_field name fields =
  match field name fields with
  | Ok (`List values) ->
      let rec collect reversed = function
        | [] -> Ok (List.rev reversed)
        | `String value :: rest -> collect (value :: reversed) rest
        | _ ->
            Error
              (error
                 "coverage metadata field %S must be an array of strings" name)
      in
      collect [] values
  | Ok _ ->
      Error
        (error "coverage metadata field %S must be an array of strings" name)
  | Error error -> Error error

let exact_fields expected fields =
  let names = List.map fst fields |> List.sort String.compare in
  if names = List.sort String.compare expected then Ok ()
  else
    Error
      (error "coverage metadata must contain exactly %s"
         (String.concat ", " expected))

let parse_phase fields =
  Result.bind (string_field "phase" fields) (fun phase_text ->
      match Config.wasm_phase_of_string phase_text with
      | Ok phase -> Ok phase
      | Error message -> Error (error "coverage metadata has %s" message))

let validate_validation fields =
  Result.bind
    (exact_fields [ "schema"; "phase"; "coverage_relation"; "oracle" ] fields)
    (fun () ->
      Result.bind (int_field "schema" fields) (fun schema ->
          if schema <> validation_schema then
            Error
              (error "coverage metadata schema must be %d (found %d)"
                 validation_schema schema)
          else
            Result.bind (string_field "coverage_relation" fields) (fun relation ->
                if not (String.equal relation "Modules_ok") then
                  Error
                    (error
                       "coverage metadata relation mismatch: expected Modules_ok but found %s"
                       relation)
                else
                  Result.bind (string_field "oracle" fields) (fun oracle ->
                      if String.equal oracle validation_oracle then
                        Ok [ "Modules_ok" ]
                      else
                        Error
                          (error
                             "coverage metadata oracle mismatch: expected %s but found %s"
                             validation_oracle oracle)))))

let validate_instantiation fields =
  Result.bind
    (exact_fields [ "schema"; "phase"; "coverage_relations"; "oracle" ] fields)
    (fun () ->
      Result.bind (int_field "schema" fields) (fun schema ->
          if schema <> instantiation_schema then
            Error
              (error "coverage metadata schema must be %d (found %d)"
                 instantiation_schema schema)
          else
            Result.bind (string_list_field "coverage_relations" fields)
              (fun relations ->
                Result.bind
                  (validate_relation_set Config.Instantiation relations)
                  (fun canonical_relations ->
                    Result.bind (string_field "oracle" fields) (fun oracle ->
                        if String.equal oracle instantiation_oracle then
                          Ok canonical_relations
                        else
                          Error
                            (error
                               "coverage metadata oracle mismatch: expected %s but found %s"
                               instantiation_oracle oracle))))))

let read ~phase coverage =
  let path = metadata_path coverage in
  let parsed =
    try Ok (Yojson.Safe.from_file path) with
    | Sys_error message ->
        Error
          (error "coverage metadata is missing or unreadable at %s: %s" path
             message)
    | Yojson.Json_error message ->
        Error
          (error "coverage metadata at %s is malformed JSON: %s" path message)
    | exception_ ->
        Error
          (error "cannot read coverage metadata %s: %s" path
             (Printexc.to_string exception_))
  in
  Result.bind parsed (function
    | `Assoc fields ->
        if List.length fields <> 4 then
          Error
            (error
               "coverage metadata must contain exactly four phase metadata fields")
        else
          Result.bind (parse_phase fields) (fun actual_phase ->
              if actual_phase <> phase then
                Error
                  (error
                     "coverage metadata phase mismatch: requested %s but found %s"
                     (Config.string_of_wasm_phase phase)
                     (Config.string_of_wasm_phase actual_phase))
              else
                let schema, oracle, validate_fields =
                  match phase with
                  | Config.Validation ->
                      (validation_schema, validation_oracle, validate_validation)
                  | Config.Instantiation ->
                      ( instantiation_schema,
                        instantiation_oracle,
                        validate_instantiation )
                in
                Result.map
                  (fun coverage_relations ->
                    { schema; phase; coverage_relations; oracle })
                  (validate_fields fields))
    | _ -> Error (error "coverage metadata must be a JSON object"))

let validate ~phase coverage =
  Result.map (fun _ -> ()) (read ~phase coverage)
