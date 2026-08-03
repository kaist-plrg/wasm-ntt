module Phase = Wasm_phase

type coverage_metadata = {
  schema : int;
  phase : Config.wasm_phase;
  coverage_relation : string;
  oracle : string;
}

let schema = 1

let oracle = "phase-direct"

let metadata_path coverage = coverage ^ ".meta.json"

let temporary_path coverage = metadata_path coverage ^ ".tmp"

let error format =
  Format.kasprintf (fun message -> Phase.CoverageMetadataError message) format

let metadata_for phase =
  { schema; phase; coverage_relation = Config.coverage_relation phase; oracle }

let json_of_metadata metadata =
  `Assoc
    [ ("schema", `Int metadata.schema);
      ("phase", `String (Config.string_of_wasm_phase metadata.phase));
      ("coverage_relation", `String metadata.coverage_relation);
      ("oracle", `String metadata.oracle) ]

let remove_if_present path =
  try
    if Sys.file_exists path && not (Sys.is_directory path) then Sys.remove path
  with Sys_error _ -> ()

let write ~phase coverage =
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
              (json_of_metadata (metadata_for phase)));
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
               (Printexc.to_string exception_)))

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

let parse_json = function
  | `Assoc fields ->
      if List.length fields <> 4 then
        Error
          (error
             "coverage metadata must contain exactly schema, phase, coverage_relation, and oracle")
      else
        Result.bind (int_field "schema" fields) (fun schema ->
            Result.bind (string_field "phase" fields) (fun phase_text ->
                Result.bind (string_field "coverage_relation" fields)
                  (fun coverage_relation ->
                    Result.map
                      (fun oracle -> (schema, phase_text, coverage_relation, oracle))
                      (string_field "oracle" fields))))
  | _ -> Error (error "coverage metadata must be a JSON object")

let validate ~phase coverage =
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
  Result.bind parsed (fun json ->
      Result.bind (parse_json json) (fun (actual_schema, phase_text, relation, actual_oracle) ->
          if actual_schema <> schema then
            Error
              (error "coverage metadata schema must be %d (found %d)" schema
                 actual_schema)
          else
            match Config.wasm_phase_of_string phase_text with
            | Error message -> Error (error "coverage metadata has %s" message)
            | Ok actual_phase ->
                if actual_phase <> phase then
                  Error
                    (error
                       "coverage metadata phase mismatch: requested %s but found %s"
                       (Config.string_of_wasm_phase phase)
                       (Config.string_of_wasm_phase actual_phase))
                else
                  let expected_relation = Config.coverage_relation phase in
                  if not (String.equal relation expected_relation) then
                    Error
                      (error
                         "coverage metadata relation mismatch: expected %s but found %s"
                         expected_relation relation)
                  else if not (String.equal actual_oracle oracle) then
                    Error
                      (error
                         "coverage metadata oracle mismatch: expected %s but found %s"
                         oracle actual_oracle)
                  else Ok ()))
