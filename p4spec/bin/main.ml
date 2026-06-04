open Lang
open Pass
open Util.Error
open Util.Source

let version = "0.1"

exception CommandError of string

(* Operations *)

let frontend filenames_spec =
  filenames_spec |> List.concat_map Frontend.Parse.parse_file

let elab filenames_spec = filenames_spec |> frontend |> Elaborate.Elab.elab_spec

let structure ~(final : bool) filenames_spec =
  filenames_spec |> elab |> Structure.Struct.struct_spec ~final

let prosify filenames_spec =
  filenames_spec |> structure ~final:false |> Prose.Prosify.prosify_spec

let runner ?(cache = true) ?(det = false) ?(arch : string option) ~(final : bool) mode
    filenames_spec =
  let spec_sim =
    match mode with
    | `IL ->
        let spec_il = elab filenames_spec in
        (Runtime.Sim.Simulator.IL spec_il : Runtime.Sim.Simulator.spec)
    | `SL ->
        let spec_sl = structure ~final filenames_spec in
        (Runtime.Sim.Simulator.SL spec_sl : Runtime.Sim.Simulator.spec)
  in
  let (module Driver) =
    match arch with
    | Some arch -> Backend_sim.Gen.gen arch
    | None -> Backend_sim.Gen.gen_placeholder ()
  in
  Driver.init ~cache ~det spec_sim;
  (spec_sim, (module Driver : Runtime.Sim.Simulator.DRIVER))

let run_with_instr (module Driver : Runtime.Sim.Simulator.DRIVER) spec_sim
    relname includes_p4 filename_p4 =
  let (module IH : Inst.Handler.HANDLER), read_coverage_instr =
    Inst.Coverage_instr.make ()
  in
  Inst.Hook.register [ (module IH : Inst.Handler.HANDLER) ];
  Inst.Hook.init_spec spec_sim;
  let result = Driver.run_program relname includes_p4 filename_p4 in
  Inst.Hook.finish ();
  let cover = read_coverage_instr () in
  (result, cover)

let wasm_run_with_instr (module Driver : Runtime.Sim.Simulator.DRIVER) spec_sim
    relname filename_wasm =
  let (module IH : Inst.Handler.HANDLER), read_coverage_instr =
    Inst.Coverage_instr.make ()
  in
  Inst.Hook.register [ (module IH : Inst.Handler.HANDLER) ];
  Inst.Hook.init_spec spec_sim;
  let result = Driver.run_wasm_program relname filename_wasm in
  Inst.Hook.finish ();
  let cover = read_coverage_instr () in
  (result, cover)

let run_with_dangling (module Driver : Runtime.Sim.Simulator.DRIVER) spec_sim
    relname includes_p4 filename_p4 =
  let (module DH : Inst.Handler.HANDLER), read_coverage_dangling =
    Inst.Coverage_dangling.make ()
  in
  Inst.Hook.register [ (module DH : Inst.Handler.HANDLER) ];
  Inst.Hook.init_spec spec_sim;
  let result = Driver.run_program relname includes_p4 filename_p4 in
  Inst.Hook.finish ();
  let cover = read_coverage_dangling () in
  (result, cover)

let wasm_run_with_dangling (module Driver : Runtime.Sim.Simulator.DRIVER) spec_sim
    relname filename_wasm =
  let (module DH : Inst.Handler.HANDLER), read_coverage_dangling =
    Inst.Coverage_dangling.make ()
  in
  Inst.Hook.register [ (module DH : Inst.Handler.HANDLER) ];
  Inst.Hook.init_spec spec_sim;
  let result = Driver.run_wasm_program relname filename_wasm in
  Inst.Hook.finish ();
  let cover = read_coverage_dangling () in
  (result, cover)

let sim_with_instr (module Driver : Runtime.Sim.Simulator.DRIVER) spec_sim
    includes_p4 filename_p4 filename_stf =
  let (module IH : Inst.Handler.HANDLER), read_coverage_instr =
    Inst.Coverage_instr.make ()
  in
  Inst.Hook.register [ (module IH : Inst.Handler.HANDLER) ];
  Inst.Hook.init_spec spec_sim;
  let result = Driver.run_stf_test includes_p4 filename_p4 filename_stf in
  Inst.Hook.finish ();
  let cover = read_coverage_instr () in
  (result, cover)

let sim_with_dangling (module Driver : Runtime.Sim.Simulator.DRIVER) spec_sim
    includes_p4 filename_p4 filename_stf =
  let (module DH : Inst.Handler.HANDLER), read_coverage_dangling =
    Inst.Coverage_dangling.make ()
  in
  Inst.Hook.register [ (module DH : Inst.Handler.HANDLER) ];
  Inst.Hook.init_spec spec_sim;
  let result = Driver.run_stf_test includes_p4 filename_p4 filename_stf in
  Inst.Hook.finish ();
  let cover = read_coverage_dangling () in
  (result, cover)

let cover_run_instr ?(arch : string option) mode filenames_spec relname
    includes_p4 filenames_p4 filename_cov =
  let spec_sim, (module Driver) = runner ?arch ~final:true mode filenames_spec in
  let spec_sl =
    match spec_sim with
    | Runtime.Sim.Simulator.SL spec_sl -> spec_sl
    | _ -> raise (CommandError "instruction coverage is only supported for SL")
  in
  let cover_multi = Coverage.Instr.Multi.init spec_sl in
  let cover_multi =
    List.fold_left
      (fun cover_multi filename_p4 ->
        let _, cover_single =
          run_with_instr
            (module Driver)
            spec_sim relname includes_p4 filename_p4
        in
        Coverage.Instr.Multi.extend cover_multi filename_p4 cover_single)
      cover_multi filenames_p4
  in
  Coverage.Instr.Log.log_spec ~filename_cov_opt:(Some filename_cov) cover_multi
    spec_sl

let wasm_cover_run_instr ?(arch : string option) mode filenames_spec relname
    filenames_wasm filename_cov =
  let spec_sim, (module Driver) = runner ?arch ~final:true mode filenames_spec in
  let spec_sl =
    match spec_sim with
    | Runtime.Sim.Simulator.SL spec_sl -> spec_sl
    | _ -> raise (CommandError "instruction coverage is only supported for SL")
  in
  let cover_multi = Coverage.Instr.Multi.init spec_sl in
  let cover_multi =
    List.fold_left
      (fun cover_multi filename_p4 ->
        let _, cover_single =
          wasm_run_with_instr
            (module Driver)
            spec_sim relname filename_p4
        in
        Coverage.Instr.Multi.extend cover_multi filename_p4 cover_single)
      cover_multi filenames_wasm
  in
  Coverage.Instr.Log.log_spec ~filename_cov_opt:(Some filename_cov) cover_multi
    spec_sl

let cover_run_dangling ?(arch : string option) mode filenames_spec relname
    includes_p4 filenames_p4 filename_cov =
  let spec_sim, (module Driver) = runner ?arch ~final:true mode filenames_spec in
  let spec_sl =
    match spec_sim with
    | Runtime.Sim.Simulator.SL spec_sl -> spec_sl
    | _ -> raise (CommandError "instruction coverage is only supported for SL")
  in
  let cover_multi = Coverage.Dangling.Multi.init spec_sl in
  let cover_multi =
    List.fold_left
      (fun cover_multi filename_p4 ->
        let program_result, cover_single =
          run_with_dangling
            (module Driver)
            spec_sim relname includes_p4 filename_p4
        in
        let wellformed, welltyped =
          match program_result with
          | Pass _ -> (true, true)
          | Fail (`Syntax _) -> (true, false)
          | Fail (`Runtime _) -> (false, false)
        in
        Coverage.Dangling.Multi.extend cover_multi filename_p4 wellformed
          welltyped cover_single)
      cover_multi filenames_p4
  in
  Coverage.Dangling.Multi.log ~filename_cov_opt:(Some filename_cov) cover_multi

let wasm_cover_run_dangling ?(arch : string option) mode filenames_spec relname
    filenames_wasm filename_cov =
  let spec_sim, (module Driver) = runner ?arch ~final:true mode filenames_spec in
  let spec_sl =
    match spec_sim with
    | Runtime.Sim.Simulator.SL spec_sl -> spec_sl
    | _ -> raise (CommandError "instruction coverage is only supported for SL")
  in
  let cover_multi = Coverage.Dangling.Multi.init spec_sl in
  let cover_multi =
    List.fold_left
      (fun cover_multi filename_wasm ->
        let program_result, cover_single =
          wasm_run_with_dangling
            (module Driver)
            spec_sim relname filename_wasm
        in
        let wellformed, welltyped =
          match program_result with
          | Pass _ | UnexpectedPass _ -> (true, true)
          | Fail (`Syntax _) -> (false, false)
          | Fail (`Runtime _) | ExpectedFail _ -> (true, false)
        in
        Coverage.Dangling.Multi.extend cover_multi filename_wasm wellformed
          welltyped cover_single)
      cover_multi filenames_wasm
  in
  Coverage.Dangling.Multi.log ~filename_cov_opt:(Some filename_cov) cover_multi

let cover_sim_instr ?(arch : string option) mode filenames_spec includes_p4
    filenames_p4 filenames_stf filename_cov =
  let spec_sim, (module Driver) = runner ?arch ~final:true mode filenames_spec in
  let spec_sl =
    match spec_sim with
    | Runtime.Sim.Simulator.SL spec_sl -> spec_sl
    | _ -> raise (CommandError "instruction coverage is only supported for SL")
  in
  let cover_multi = Coverage.Instr.Multi.init spec_sl in
  let cover_multi =
    List.fold_left2
      (fun cover_multi filename_p4 filename_stf ->
        let _, cover_single =
          sim_with_instr
            (module Driver)
            spec_sim includes_p4 filename_p4 filename_stf
        in
        Coverage.Instr.Multi.extend cover_multi filename_p4 cover_single)
      cover_multi filenames_p4 filenames_stf
  in
  Coverage.Instr.Log.log_spec ~filename_cov_opt:(Some filename_cov) cover_multi
    spec_sl

let cover_sim_dangling ?(arch : string option) mode filenames_spec includes_p4
    filenames_p4 filenames_stf filename_cov =
  let spec_sim, (module Driver) = runner ?arch ~final:true mode filenames_spec in
  let spec_sl =
    match spec_sim with
    | Runtime.Sim.Simulator.SL spec_sl -> spec_sl
    | _ -> raise (CommandError "dangling coverage is only supported for SL")
  in
  let cover_multi = Coverage.Dangling.Multi.init spec_sl in
  let cover_multi =
    List.fold_left2
      (fun cover_multi filename_p4 filename_stf ->
        let program_result, cover_single =
          sim_with_dangling
            (module Driver)
            spec_sim includes_p4 filename_p4 filename_stf
        in
        let wellformed, welltyped =
          match program_result with
          | Pass -> (true, true)
          | Fail (`Syntax _) -> (true, false)
          | Fail (`Runtime _) -> (false, false)
        in
        Coverage.Dangling.Multi.extend cover_multi filename_p4 wellformed
          welltyped cover_single)
      cover_multi filenames_p4 filenames_stf
  in
  Coverage.Dangling.Multi.log ~filename_cov_opt:(Some filename_cov) cover_multi

(* Commands *)

let elab_command =
  Core.Command.basic ~summary:"parse and elaborate a P4 spec"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map filenames_spec =
       anon (non_empty_sequence_as_list ("filename" %: string))
     in
     fun () ->
       try
         let spec_il = elab filenames_spec in
         Format.printf "%s\n" (Il.Print.string_of_spec spec_il);
         ()
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg) -> Format.printf "%s\n" (string_of_error at msg)
       | ElabError (at, msg) -> Format.printf "%s\n" (string_of_error at msg))

let struct_command =
  Core.Command.basic ~summary:"insert structured control flow to a P4 spec"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map filenames_spec =
       anon (non_empty_sequence_as_list ("filename" %: string))
     in
     fun () ->
       try
         let spec_sl = structure ~final:true filenames_spec in
         Format.printf "%s\n" (Sl.Print.string_of_spec spec_sl);
         ()
       with
       | ParseError (at, msg) -> Format.printf "%s\n" (string_of_error at msg)
       | ElabError (at, msg) -> Format.printf "%s\n" (string_of_error at msg))

let prose_command =
  Core.Command.basic ~summary:"generate AsciiDoc prose from a P4 spec"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map filenames_spec =
       anon (non_empty_sequence_as_list ("filename" %: string))
     in
     fun () ->
       try
         let spec_pl = prosify filenames_spec in
         Format.printf "%s\n" (Pl.Render.render_spec spec_pl);
         ()
       with
       | ParseError (at, msg) | ElabError (at, msg) | ProseError (at, msg) ->
         Format.printf "%s\n" (string_of_error at msg))

let run_command =
  Core.Command.basic ~summary:"execute the P4 spec against a P4 program"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map filenames_spec =
       anon (non_empty_sequence_as_list ("filename" %: string))
     and relname = flag "-rel" (required string) ~doc:"relation to run"
     and includes_p4 = flag "-i" (listed string) ~doc:"P4 include paths"
     and filename_p4 = flag "-p" (required string) ~doc:"P4 program"
     and no_cache = flag "-no-cache" no_arg ~doc:"disable caching"
     and det = flag "-det" no_arg ~doc:"deterministic mode"
     and profile = flag "-profile" no_arg ~doc:"profiling"
     and mode =
       Command.Param.choose_one
         [
           flag "il" no_arg ~doc:"run IL interpreter"
           |> map ~f:(fun b -> Core.Option.some_if b `IL);
           flag "sl" no_arg ~doc:"run SL interpreter"
           |> map ~f:(fun b -> Core.Option.some_if b `SL);
         ]
         ~if_nothing_chosen:(Default_to `SL)
     in
     fun () ->
       try
         let cache = not no_cache in
         let spec_sim, (module Driver) =
           runner ~cache ~det ~final:true mode filenames_spec
         in
         let handlers =
           if profile then
             let (module PH : Inst.Handler.HANDLER) = Inst.Profile.make () in
             [ (module PH : Inst.Handler.HANDLER) ]
           else []
         in
         Inst.Hook.register handlers;
         Inst.Hook.init_spec spec_sim;
         let result = Driver.run_program relname includes_p4 filename_p4 in
         Inst.Hook.finish ();
         match result with
         | Pass _ -> Format.printf "passed\n"
         | Fail (`Syntax (_, msg)) -> Format.printf "sytax error: %s\n" msg
         | Fail (`Runtime (_, msg)) -> Format.printf "runtime error: %s\n" msg
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg) -> Format.printf "%s\n" (string_of_error at msg)
       | ElabError (at, msg) -> Format.printf "%s\n" (string_of_error at msg))

let run_wasm_command =
  Core.Command.basic ~summary:"execute the Wasm spec against a Wasm program"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map filenames_spec =
       anon (non_empty_sequence_as_list ("filename" %: string))
     and relname = flag "-rel" (required string) ~doc:"relation to run"
     and filename_wasm = flag "-w" (required string) ~doc:"Wasm program"
     and no_cache = flag "-no-cache" no_arg ~doc:"disable caching"
     and det = flag "-det" no_arg ~doc:"deterministic mode"
     and profile = flag "-profile" no_arg ~doc:"profiling"
     and mode =
       Command.Param.choose_one
         [
           flag "il" no_arg ~doc:"run IL interpreter"
           |> map ~f:(fun b -> Core.Option.some_if b `IL);
           flag "sl" no_arg ~doc:"run SL interpreter"
           |> map ~f:(fun b -> Core.Option.some_if b `SL);
         ]
         ~if_nothing_chosen:(Default_to `SL)
     in
     fun () ->
       try
         let cache = not no_cache in
         let spec_sim, (module Driver) =
           runner ~cache ~det ~final:true mode filenames_spec
         in
         let handlers =
           if profile then
             let (module PH : Inst.Handler.HANDLER) = Inst.Profile.make () in
             [ (module PH : Inst.Handler.HANDLER) ]
           else []
         in
         Inst.Hook.register handlers;
         Inst.Hook.init_spec spec_sim;
         let result = Driver.run_wasm_program relname filename_wasm in
         Inst.Hook.finish ();
         match result with
        | Pass _ -> Format.printf "Passed\n%!";
        | ExpectedFail _ -> Format.printf "Expected fail (passed)\n%!"
        | Fail (`Syntax (_, msg)) -> Format.printf "Failed (syntax error): %s\n%!" msg
        | Fail (`Runtime (_, msg)) -> Format.printf "Failed (runtime error): %s\n%!" msg
        | UnexpectedPass _ -> Format.printf "Unexpected pass (failed)\n%!";
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg) -> Format.printf "%s\n" (string_of_error at msg)
       | ElabError (at, msg) -> Format.printf "%s\n" (string_of_error at msg))

let run_wasm_suite =
  Core.Command.basic ~summary:"execute the Wasm spec against a Wasm test suite"
     (let open Core.Command.Let_syntax in
      let open Core.Command.Param in
      let%map filenames_spec =
        anon (non_empty_sequence_as_list ("filename" %: string))
      and relname = flag "-rel" (required string) ~doc:"relation to run"
      and testdirs_wasm = flag "-wasm-dir" (listed string) ~doc:"Wasm test directories"
      and no_cache = flag "-no-cache" no_arg ~doc:"disable caching"
      and det = flag "-det" no_arg ~doc:"deterministic mode"
      and profile = flag "-profile" no_arg ~doc:"profiling"
      and mode =
       Command.Param.choose_one
         [
           flag "il" no_arg ~doc:"run IL interpreter"
           |> map ~f:(fun b -> Core.Option.some_if b `IL);
           flag "sl" no_arg ~doc:"run SL interpreter"
           |> map ~f:(fun b -> Core.Option.some_if b `SL);
         ]
         ~if_nothing_chosen:(Default_to `SL)
      in
      fun () ->
        let filenames_wasm =
            testdirs_wasm
            |> List.concat_map (Util.Filesys.collect_files ~suffix:".wast")
        in
        let cache = not no_cache in
        let spec_sim, (module Driver) =
          runner ~cache ~det ~final:true mode filenames_spec
        in
        let handlers =
          if profile then
            let (module PH : Inst.Handler.HANDLER) = Inst.Profile.make () in
            [ (module PH : Inst.Handler.HANDLER) ]
          else []
        in
        let total = ref 0 in
        let passed = ref 0 in
        let failed = ref 0 in
        List.iter
          (fun filename_wasm ->
            try
              Inst.Hook.register handlers;
              Inst.Hook.init_spec spec_sim;
              total := !total + 1;
              let result = Driver.run_wasm_program relname filename_wasm in
              Inst.Hook.finish ();
              match result with
              | Pass _ -> passed := !passed + 1; Format.printf "Passed\n%!"
              | ExpectedFail _ -> passed := !passed + 1; Format.printf "Expected fail (passed)\n%!"
              | Fail (`Syntax (_, msg)) -> failed := !failed + 1; Format.printf "Failed (syntax error): %s\n%!" msg
              | Fail (`Runtime (_, msg)) -> failed := !failed + 1; Format.printf "Failed (runtime error): %s\n%!" msg
              | UnexpectedPass _ -> failed := !failed + 1; Format.printf "Unexpected pass (failed)\n%!"
              with
              | CommandError msg -> failed := !failed + 1; Format.printf "%s\n%!" msg
              | ParseError (at, msg) -> failed := !failed + 1; Format.printf "%s\n%!" (string_of_error at msg)
              | ElabError (at, msg) -> failed := !failed + 1; Format.printf "%s\n%!" (string_of_error at msg))
        filenames_wasm;
        Format.printf "typechecker: %d/%d passed, %d failed\n%!" !passed !total !failed;
        )

let sim_command =
  Core.Command.basic
    ~summary:"simulate a target architecture with a P4 program and P4 spec"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map filenames_spec =
       anon (non_empty_sequence_as_list ("filename" %: string))
     and includes_p4 = flag "-i" (listed string) ~doc:"P4 include paths"
     and filename_p4 = flag "-p" (required string) ~doc:"P4 program"
     and filename_stf = flag "-stf" (required string) ~doc:"stf test file"
     and arch = flag "-arch" (required string) ~doc:"target architecture"
     and no_cache = flag "-no-cache" no_arg ~doc:"disable caching"
     and det = flag "-det" no_arg ~doc:"deterministic mode"
     and profile = flag "-profile" no_arg ~doc:"profiling"
     and mode =
       Command.Param.choose_one
         [
           flag "il" no_arg ~doc:"run IL interpreter"
           |> map ~f:(fun b -> Core.Option.some_if b `IL);
           flag "sl" no_arg ~doc:"run SL interpreter"
           |> map ~f:(fun b -> Core.Option.some_if b `SL);
         ]
         ~if_nothing_chosen:(Default_to `SL)
     in
     fun () ->
       try
         let cache = not no_cache in
         let spec_sim, (module Driver) =
           runner ~cache ~det ~final:true ~arch mode filenames_spec
         in
         let handlers =
           if profile then
             let (module PH : Inst.Handler.HANDLER) = Inst.Profile.make () in
             [ (module PH : Inst.Handler.HANDLER) ]
           else []
         in
         Inst.Hook.register handlers;
         Inst.Hook.init_spec spec_sim;
         let result =
           Driver.run_stf_test includes_p4 filename_p4 filename_stf
         in
         Inst.Hook.finish ();
         match result with
         | Pass -> Format.printf "passed\n"
         | Fail (`Syntax (_, msg)) -> Format.printf "sytax error: %s\n" msg
         | Fail (`Runtime (_, msg)) -> Format.printf "runtime error: %s\n" msg
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg) | ElabError (at, msg) | ArchError (at, msg) ->
           Format.printf "%s\n" (string_of_error at msg)
       | StfError msg -> Format.printf "%s\n" (string_of_error no_region msg))

let cover_run_command =
  Core.Command.basic ~summary:"measure coverage of the spec"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map filenames_spec =
       anon (non_empty_sequence_as_list ("filename" %: string))
     and relname = flag "-rel" (required string) ~doc:"relation to run"
     and includes_p4 = flag "-i" (listed string) ~doc:"P4 include paths"
     and excludes_p4 = flag "-e" (listed string) ~doc:"P4 test exclude paths"
     and testdirs_p4 = flag "-p4-dir" (listed string) ~doc:"P4 test directories"
     and filename_cov =
       flag "-cov" (required string) ~doc:"output coverage file"
     and mode =
       Command.Param.choose_one
         [
           flag "instr" no_arg ~doc:"measure instruction coverage"
           |> map ~f:(fun b -> Core.Option.some_if b `Instr);
           flag "dangling" no_arg ~doc:"measure dangling coverage"
           |> map ~f:(fun b -> Core.Option.some_if b `Dangling);
         ]
         ~if_nothing_chosen:(Default_to `Instr)
     in
     fun () ->
       try
         let excludes_p4 = Util.Test.collect_excludes excludes_p4 in
         let filenames_p4 =
           testdirs_p4
           |> List.concat_map (Util.Filesys.collect_files ~suffix:".p4")
           |> List.filter (fun filename_p4 ->
                  not (List.exists (String.equal filename_p4) excludes_p4))
         in
         match mode with
         | `Instr ->
             cover_run_instr `SL filenames_spec relname includes_p4 filenames_p4
               filename_cov
         | `Dangling ->
             cover_run_dangling `SL filenames_spec relname includes_p4
               filenames_p4 filename_cov
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg) | ElabError (at, msg) ->
           Format.printf "%s\n" (string_of_error at msg))

let wasm_cover_run_command =
  Core.Command.basic ~summary:"measure coverage of the spec"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map filenames_spec =
       anon (non_empty_sequence_as_list ("filename" %: string))
     and relname = flag "-rel" (required string) ~doc:"relation to run"
     and testdirs_wasm = flag "-wasm-dir" (listed string) ~doc:"Wasm test directories"
     and filename_cov =
       flag "-cov" (required string) ~doc:"output coverage file"
     and mode =
       Command.Param.choose_one
         [
           flag "instr" no_arg ~doc:"measure instruction coverage"
           |> map ~f:(fun b -> Core.Option.some_if b `Instr);
           flag "dangling" no_arg ~doc:"measure dangling coverage"
           |> map ~f:(fun b -> Core.Option.some_if b `Dangling);
         ]
         ~if_nothing_chosen:(Default_to `Instr)
     in
     fun () ->
       try
         let filenames_wasm =
           testdirs_wasm
           |> List.concat_map (Util.Filesys.collect_files ~suffix:".wast")
         in
         match mode with
         | `Instr ->
             wasm_cover_run_instr `SL filenames_spec relname filenames_wasm filename_cov
         | `Dangling ->
             wasm_cover_run_dangling `SL filenames_spec relname filenames_wasm filename_cov
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg) | ElabError (at, msg) ->
           Format.printf "%s\n" (string_of_error at msg))

let cover_sim_command =
  Core.Command.basic
    ~summary:"measure coverage of the spec when simulated on STF"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map filenames_spec =
       anon (non_empty_sequence_as_list ("filename" %: string))
     and includes_p4 = flag "-i" (listed string) ~doc:"P4 include paths"
     and excludes_p4 = flag "-e" (listed string) ~doc:"P4 test exclude paths"
     and testdirs_p4 = flag "-p4-dir" (listed string) ~doc:"P4 test directories"
     and testdirs_stf =
       flag "-stf-dir" (listed string) ~doc:"STF test directories"
     and patchdir =
       flag "-patch-dir" (listed string) ~doc:"directory for P4/STF patches"
     and filename_cov =
       flag "-cov" (required string) ~doc:"output coverage file"
     and arch = flag "-arch" (required string) ~doc:"target architecture"
     and mode =
       Command.Param.choose_one
         [
           flag "instr" no_arg ~doc:"measure instruction coverage"
           |> map ~f:(fun b -> Core.Option.some_if b `Instr);
           flag "dangling" no_arg ~doc:"measure dangling coverage"
           |> map ~f:(fun b -> Core.Option.some_if b `Dangling);
         ]
         ~if_nothing_chosen:(Default_to `Instr)
     in
     fun () ->
       try
         let excludes_p4 = Util.Test.collect_excludes excludes_p4 in
         let filenames_p4, filenames_stf =
           Util.Test.collect_test_pairs arch testdirs_p4 testdirs_stf patchdir
           |> List.map (fun (filename_p4, filename_stf, _) ->
                  (filename_p4, filename_stf))
           |> List.filter (fun (filename_p4, _) ->
                  not (List.exists (String.equal filename_p4) excludes_p4))
           |> List.split
         in
         match mode with
         | `Instr ->
             cover_sim_instr ~arch `SL filenames_spec includes_p4 filenames_p4
               filenames_stf filename_cov
         | `Dangling ->
             cover_sim_dangling ~arch `SL filenames_spec includes_p4
               filenames_p4 filenames_stf filename_cov
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg) | ElabError (at, msg) ->
           Format.printf "%s\n" (string_of_error at msg))

let run_testgen_command =
  Core.Command.basic
    ~summary:"generate negative type checker tests from a p4_16 spec"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map filenames_spec =
       anon (non_empty_sequence_as_list ("filename" %: string))
     and relname = flag "-rel" (required string) ~doc:"relation to run"
     and fuel = flag "-fuel" (required int) ~doc:"fuel for test generation"
     and includes_p4 = flag "-i" (listed string) ~doc:"P4 include paths"
     and excludes_p4 = flag "-e" (listed string) ~doc:"P4 test exclude paths"
     and gendir =
       flag "-gen-dir" (required string)
         ~doc:"directory for generated p4 programs"
     and name_campaign =
       flag "-name" (optional string)
         ~doc:"name of the test generation campaign"
     and silent = flag "-silent" no_arg ~doc:"do not print logs to stdout"
     and randseed =
       flag "-seed" (optional int) ~doc:"seed for random number generator"
     and bootdir =
       flag "-boot-dir" (optional string) ~doc:"seed p4 directory for boot"
     and filename_boot =
       flag "-boot-file" (optional string) ~doc:"coverage file for boot"
     and random = flag "-random" no_arg ~doc:"randomize AST selection"
     and hybrid =
       flag "-hybrid" no_arg
         ~doc:"randomize AST selection when no derivations exist"
     and strict =
       flag "-strict" no_arg
         ~doc:"cover a new phantom only if it was intended by a mutation"
     in
     fun () ->
       try
         let spec_sl = structure ~final:true filenames_spec in
         let logmode =
           if silent then Backend_testgen_neg.Modes.Silent
           else Backend_testgen_neg.Modes.Verbose
         in
         let bootmode =
           match (bootdir, filename_boot) with
           | Some bootdir, None ->
               Backend_testgen_neg.Modes.Cold (excludes_p4, bootdir)
           | None, Some filename_boot ->
               Backend_testgen_neg.Modes.Warm filename_boot
           | Some _, Some _ ->
               raise
                 (CommandError
                    "Error: should specify only one of -boot-dir or -boot-file")
           | None, None ->
               raise
                 (CommandError "Error: should specify either -cold or -warm")
         in
         let mutationmode =
           if random then Backend_testgen_neg.Modes.Random
           else if hybrid then Backend_testgen_neg.Modes.Hybrid
           else Backend_testgen_neg.Modes.Derive
         in
         let covermode =
           if strict then Backend_testgen_neg.Modes.Strict
           else Backend_testgen_neg.Modes.Relaxed
         in
         Backend_testgen_neg.Gen.fuzzer fuel spec_sl relname includes_p4 gendir
           name_campaign randseed logmode bootmode mutationmode covermode
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg) | ElabError (at, msg) ->
           Format.printf "%s\n" (string_of_error at msg))

let wasm_run_testgen_command =
  Core.Command.basic
    ~summary:"generate negative type checker tests from a Wasm spec"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map filenames_spec =
       anon (non_empty_sequence_as_list ("filename" %: string))
     and relname = flag "-rel" (required string) ~doc:"relation to run"
     and fuel = flag "-fuel" (required int) ~doc:"fuel for test generation"
     and gendir =
       flag "-gen-dir" (required string)
         ~doc:"directory for generated wasm programs"
     and name_campaign =
       flag "-name" (optional string)
         ~doc:"name of the test generation campaign"
     and silent = flag "-silent" no_arg ~doc:"do not print logs to stdout"
     and randseed =
       flag "-seed" (optional int) ~doc:"seed for random number generator"
     and bootdir =
       flag "-boot-dir" (optional string) ~doc:"seed wasm directory for boot"
     and filename_boot =
       flag "-boot-file" (optional string) ~doc:"coverage file for boot"
     and random = flag "-random" no_arg ~doc:"randomize AST selection"
     and hybrid =
       flag "-hybrid" no_arg
         ~doc:"randomize AST selection when no derivations exist"
     and strict =
       flag "-strict" no_arg
         ~doc:"cover a new phantom only if it was intended by a mutation"
     and pid = flag "-pid" (optional int) ~doc:"phantom id to close-miss"
     and filename_wasm =
       flag "-w" (optional string) ~doc:"Wasm program to close-miss with"
     and focus =
       flag "-focus" no_arg
         ~doc:"focus on one phantom ID and its close-missing Wasm program"
     in
     fun () ->
       try
         let spec_sl = structure ~final:true filenames_spec in
         let logmode =
           if silent then Backend_testgen_neg.Modes.Silent
           else Backend_testgen_neg.Modes.Verbose
         in
         let bootmode =
           match (bootdir, filename_boot) with
           | Some bootdir, None ->
               Backend_testgen_neg.Modes.Cold ([], bootdir)
           | None, Some filename_boot ->
               Backend_testgen_neg.Modes.Warm filename_boot
           | Some _, Some _ ->
               raise
                 (CommandError
                    "Error: should specify only one of -boot-dir or -boot-file")
           | None, None ->
               raise
                 (CommandError "Error: should specify either -cold or -warm")
         in
         let mutationmode =
           if random then Backend_testgen_neg.Modes.Random
           else if hybrid then Backend_testgen_neg.Modes.Hybrid
           else Backend_testgen_neg.Modes.Derive
         in
         let covermode =
           if strict then Backend_testgen_neg.Modes.Strict
           else Backend_testgen_neg.Modes.Relaxed
         in
         let focus =
           match (focus, pid, filename_wasm) with
           | true, Some pid, Some filename_wasm ->
               Some Backend_testgen_neg.Config.{ pid; filename_wasm }
           | true, _, _ ->
               raise
                 (CommandError
                    "Error: -focus requires both -pid and -w")
           | false, None, None -> None
           | false, _, _ ->
               raise
                 (CommandError
                    "Error: -pid and -w are only valid with -focus")
         in
         Backend_testgen_neg.Gen.wasm_fuzzer fuel spec_sl relname gendir
           name_campaign randseed logmode bootmode mutationmode covermode focus
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg) | ElabError (at, msg) ->
           Format.printf "%s\n" (string_of_error at msg))

let run_testgen_debug_command =
  Core.Command.basic
    ~summary:"debug close-AST deriver in negative type checker generator"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map filenames_spec =
       anon (non_empty_sequence_as_list ("filename" %: string))
     and relname = flag "-rel" (required string) ~doc:"spec relation to run"
     and includes_p4 = flag "-i" (listed string) ~doc:"P4 include paths"
     and filename_p4 = flag "-p" (required string) ~doc:"P4 program"
     and debugdir =
       flag "-debug" (required string) ~doc:"directory for debug files"
     and pid = flag "-pid" (required int) ~doc:"phantom id to close-miss" in
     fun () ->
       try
         let spec_sl = structure ~final:true filenames_spec in
         Backend_testgen_neg.Derive.debug_phantom spec_sl relname includes_p4
           filename_p4 debugdir pid
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg) | ElabError (at, msg) ->
           Format.printf "%s\n" (string_of_error at msg))

let wasm_run_testgen_debug_command =
  Core.Command.basic
    ~summary:"debug close-AST deriver in negative type checker generator for Wasm"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map filenames_spec =
       anon (non_empty_sequence_as_list ("filename" %: string))
     and relname = flag "-rel" (required string) ~doc:"spec relation to run"
     and filename_wasm = flag "-w" (required string) ~doc:"Wasm program"
     and debugdir =
       flag "-debug" (required string) ~doc:"directory for debug files"
     and pid = flag "-pid" (required int) ~doc:"phantom id to close-miss" in
     fun () ->
       try
         let spec_sl = structure ~final:true filenames_spec in
         Backend_testgen_neg.Derive.debug_phantom_wasm spec_sl relname filename_wasm debugdir pid
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg) | ElabError (at, msg) ->
           Format.printf "%s\n" (string_of_error at msg))

let interesting_command =
  Core.Command.basic ~summary:"interestingness test for reducing P4 programs"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map filenames_spec =
       anon (non_empty_sequence_as_list ("filename" %: string))
     and relname = flag "-rel" (required string) ~doc:"relation to run"
     and includes_p4 = flag "-i" (listed string) ~doc:"P4 include paths"
     and check_well_typed =
       flag "-well" no_arg
         ~doc:"'interesting' if well-typed (default: ill-typed)"
     and check_close_miss =
       flag "-close" no_arg ~doc:"'interesting' if close-miss (default: hit)"
     and pid = flag "-pid" (required int) ~doc:"phantom id to test"
     and filename_p4 = flag "-p" (required string) ~doc:"P4 program" in
     fun () ->
       try
         let spec_sim, (module Driver) = runner ~final:true `SL filenames_spec in
         let result, cover =
           run_with_dangling
             (module Driver)
             spec_sim relname includes_p4 filename_p4
         in
         match result with
         | Pass _ ->
             if check_well_typed then (
               let branch = Coverage.Dangling.Single.Cover.find pid cover in
               match branch.status with
               | Hit ->
                   Printf.printf "WellTyped: Hit\n";
                   if check_close_miss then exit 3 else exit 0
               | Miss (_ :: _) ->
                   Printf.printf "WellTyped: Close\n";
                   if check_close_miss then exit 0 else exit 2
               | Miss [] ->
                   Printf.printf "WellTyped: Miss\n";
                   exit 1)
             else (
               Printf.printf "WellTyped\n";
               exit 11)
         | Fail (`Syntax _) ->
             Printf.printf "IllFormed";
             exit 12
         | Fail (`Runtime _) -> (
             if check_well_typed then (
               Printf.printf "IllTyped\n";
               exit 10)
             else
               let branch = Coverage.Dangling.Single.Cover.find pid cover in
               match branch.status with
               | Hit ->
                   Printf.printf "IllTyped: Hit\n";
                   if check_close_miss then exit 3 else exit 0
               | Miss (_ :: _) ->
                   Printf.printf "IllTyped: Close\n";
                   if check_close_miss then exit 0 else exit 2
               | Miss [] ->
                   Printf.printf "IllTyped: Miss\n";
                   exit 1)
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg) | ElabError (at, msg) ->
           Format.printf "%s\n" (string_of_error at msg))

let splice_command =
  Core.Command.basic ~summary:"splice a skeleton p4_16 specification document"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map filenames_spec =
       anon (non_empty_sequence_as_list ("filename" %: string))
     and filenames_input =
       flag "-splice" (listed string) ~doc:"skeleton documents"
     and filenames_output = flag "-out" (listed string) ~doc:"output files"
     and inplace = flag "-inplace" no_arg ~doc:"splice in place" in
     fun () ->
       try
         if
           (not inplace)
           && List.length filenames_input <> List.length filenames_output
         then raise (CommandError "number of input and output files must match");
         let filenames =
           if inplace then List.combine filenames_input filenames_input
           else List.combine filenames_input filenames_output
         in
         let spec = frontend filenames_spec in
         let spec_pl = prosify filenames_spec in
         Backend_splice.Driver.splice_files spec spec_pl filenames
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg) | ElabError (at, msg) | SpliceError (at, msg) ->
           Format.printf "%s\n" (string_of_error at msg))

let parse_command =
  Core.Command.basic ~summary:"parse a P4 program"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map filenames_spec =
       anon (non_empty_sequence_as_list ("filename" %: string))
     and includes_p4 = flag "-i" (listed string) ~doc:"P4 include paths"
     and filename_p4 = flag "-p" (required string) ~doc:"P4 program"
     and roundtrip =
       flag "-r" no_arg ~doc:"perform a round-trip parse/unparse"
     in
     fun () ->
       try
         let spec_il = elab filenames_spec in
         let parsed_p4_file =
           Interface.Parse.parse_file includes_p4 filename_p4
         in
         let unparsed_p4_string =
           Format.asprintf "%a\n"
             (Interface.Unparse.pp_program_il spec_il)
             parsed_p4_file
         in
         if roundtrip then
           let parsed_p4_string =
             Interface.Parse.parse_string filename_p4 unparsed_p4_string
           in
           Il.Eq.eq_value ~dbg:true parsed_p4_file parsed_p4_string
           |> (fun b ->
                if b then "Roundtrip successful" else "Roundtrip failed")
           |> print_endline
         else unparsed_p4_string |> print_endline
       with
       | Sys_error msg -> Format.printf "File error: %s\n" msg
       | ElabError (at, msg) ->
           Format.printf "Elaboration error: %s\n" (string_of_error at msg)
       | ParseError (at, msg) ->
           Format.printf "Parse error: %s\n" (string_of_error at msg)
       | Interface.Lexer.Error msg -> Format.printf "Lexer error: %s\n" msg
       | e -> Format.printf "Unknown error: %s\n" (Printexc.to_string e))

let wasm_parse_command =
  Core.Command.basic ~summary:"parse a Wasm program"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map filename_wasm = flag "-p" (required string) ~doc:"Wasm program"
     and roundtrip =
       flag "-r" no_arg ~doc:"perform a round-trip parse/unparse"
     in
     fun () ->
       try
         let (parsed_wasm_file, _) =
           Wasm_interface.Parse.parse_file filename_wasm
         in
         let unparsed_wasm_string =
           (List.hd (Wasm_interface.Deconstruct.sl_to_list Wasm_interface.Deconstruct.sl_to_module parsed_wasm_file), [])
           |> Wasm_interpreter.Arrange.module_with_custom
           |> Wasm_interpreter.Sexpr.to_string 80
         in
         if roundtrip then
           let parsed_wasm_string =
             Wasm_interpreter.Parse.Module.parse_string unparsed_wasm_string
             |> snd
             |> (fun def ->
                  match def.it with
                  | Wasm_interpreter.Script.Textual (m, _) -> [m]
                  | _ -> failwith "Expected textual Wasm definition")
             |> Wasm_interface.Construct.il_of_list "module" Wasm_interface.Construct.il_of_module
           in
           Il.Eq.eq_value ~dbg:true parsed_wasm_file parsed_wasm_string
           |> (fun b ->
                if b then "Roundtrip successful" else "Roundtrip failed")
           |> print_endline
         else unparsed_wasm_string |> print_endline
       with
       | Sys_error msg -> Format.printf "File error: %s\n" msg
       | ElabError (at, msg) ->
           Format.printf "Elaboration error: %s\n" (string_of_error at msg)
       | ParseError (at, msg) ->
           Format.printf "Parse error: %s\n" (string_of_error at msg)
       | Interface.Lexer.Error msg -> Format.printf "Lexer error: %s\n" msg
       | e -> Format.printf "Unknown error: %s\n" (Printexc.to_string e))

let wasm_suite_roundtrip_command =
  Core.Command.basic ~summary:"parse Wasm programs in directories"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map testdirs_wasm = flag "-wasm-dir" (listed string) ~doc:"Wasm test directories"
     and roundtrip =
       flag "-r" no_arg ~doc:"perform a round-trip parse/unparse"
     in
     fun () ->
       try
         if List.is_empty testdirs_wasm then
           raise (CommandError "Error: should specify at least one -wasm-dir");
         let filenames_wasm =
           testdirs_wasm
           |> List.concat_map (Util.Filesys.collect_files ~suffix:".wast")
           |> List.sort String.compare
         in
         let total_files = List.length filenames_wasm in
         let roundtrip_success = ref 0 in
         let roundtrip_failed = ref 0 in
         let roundtrip_failed_files = ref [] in
         List.iter
           (fun filename_wasm ->
             Format.printf "===== %s =====\n%!" filename_wasm;
             try
               let (parsed_wasm_file, _) =
                 Wasm_interface.Parse.parse_file filename_wasm
               in
               let unparsed_wasm_string =
                 (List.hd (Wasm_interface.Deconstruct.sl_to_list Wasm_interface.Deconstruct.sl_to_module parsed_wasm_file), [])
                 |> Wasm_interpreter.Arrange.module_with_custom
                 |> Wasm_interpreter.Sexpr.to_string 80
               in
               if roundtrip then
                 let parsed_wasm_string =
                   Wasm_interpreter.Parse.Module.parse_string unparsed_wasm_string
                   |> snd
                   |> (fun def ->
                        match def.it with
                        | Wasm_interpreter.Script.Textual (m, _) -> [m]
                        | _ -> failwith "Expected textual Wasm definition")
                   |> Wasm_interface.Construct.il_of_list "module" Wasm_interface.Construct.il_of_module
                 in
                 Il.Eq.eq_value ~dbg:true parsed_wasm_file parsed_wasm_string
                 |> (fun b ->
                      if b then roundtrip_success := !roundtrip_success + 1
                      else (
                        roundtrip_failed := !roundtrip_failed + 1;
                        roundtrip_failed_files := filename_wasm :: !roundtrip_failed_files
                      );
                      if b then "Roundtrip successful" else "Roundtrip failed")
                 |> print_endline
               else unparsed_wasm_string |> print_endline
             with
             | Sys_error msg ->
                 if roundtrip then (
                   roundtrip_failed := !roundtrip_failed + 1;
                   roundtrip_failed_files := filename_wasm :: !roundtrip_failed_files
                 );
                 Format.printf "File error: %s\n%!" msg
             | ElabError (at, msg) ->
                 if roundtrip then (
                   roundtrip_failed := !roundtrip_failed + 1;
                   roundtrip_failed_files := filename_wasm :: !roundtrip_failed_files
                 );
                 Format.printf "Elaboration error: %s\n%!" (string_of_error at msg)
             | ParseError (at, msg) ->
                 if roundtrip then (
                   roundtrip_failed := !roundtrip_failed + 1;
                   roundtrip_failed_files := filename_wasm :: !roundtrip_failed_files
                 );
                 Format.printf "Parse error: %s\n%!" (string_of_error at msg)
             | Interface.Lexer.Error msg ->
                 if roundtrip then (
                   roundtrip_failed := !roundtrip_failed + 1;
                   roundtrip_failed_files := filename_wasm :: !roundtrip_failed_files
                 );
                 Format.printf "Lexer error: %s\n%!" msg
             | e ->
                 if roundtrip then (
                   roundtrip_failed := !roundtrip_failed + 1;
                   roundtrip_failed_files := filename_wasm :: !roundtrip_failed_files
                 );
                 Format.printf "Unknown error: %s\n%!" (Printexc.to_string e))
           filenames_wasm;
         Format.printf "===== Summary =====\n%!";
         Format.printf "Total files: %d\n%!" total_files;
         if roundtrip then (
           Format.printf "Roundtrip successful: %d\n%!" !roundtrip_success;
           Format.printf "Roundtrip failed: %d\n%!" !roundtrip_failed;
           if !roundtrip_failed > 0 then (
             Format.printf "Failed files:\n%!";
             List.rev !roundtrip_failed_files
             |> List.iter (fun filename -> Format.printf "%s\n%!" filename)
           )
         )
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | e -> Format.printf "Unknown error: %s\n" (Printexc.to_string e))

let json_ast_command =
  Core.Command.basic ~summary:"Emit/Parse JSON AST for Structured Language"
    ~readme:(fun () ->
      "./p4spectec json-ast -emit spec/*.watsup\n\
       ./p4spectec json-ast -parse <ast-file.json>")
    (let%map_open.Command mode =
       Command.Param.choose_one
         [
           flag "emit" no_arg ~doc:"Emit JSON AST from supplied spec files"
           |> map ~f:(fun b -> Core.Option.some_if b `Emit);
           flag "parse" no_arg
             ~doc:
               "Parse JSON AST from supplied JSON file and produce Structured \
                Language"
           |> map ~f:(fun b -> Core.Option.some_if b `Parse);
         ]
         ~if_nothing_chosen:(Default_to `Emit)
     and filenames = anon (non_empty_sequence_as_list ("filename" %: string)) in
     fun () ->
       match mode with
       | `Emit -> (
           try
             let spec_sl = structure ~final:true filenames in
             let sl_ast_json = Sl.spec_to_yojson spec_sl in
             Yojson.Safe.pretty_print Format.std_formatter sl_ast_json;
             ()
           with
           | ParseError (at, msg) ->
               Format.printf "%s\n" (string_of_error at msg)
           | ElabError (at, msg) ->
               Format.printf "%s\n" (string_of_error at msg))
       | `Parse -> (
           (* only take the first argument *)
           let filename = List.hd filenames in
           let parsed = Yojson.Safe.from_file filename |> Sl.spec_of_yojson in
           match parsed with
           | Ok spec_sl ->
               Format.printf "%s\n" (Sl.Print.string_of_spec spec_sl)
           | Error err ->
               Format.printf "Error while parsing %s: %s" filename err))

let p4_program_value_json_command =
  Core.Command.basic
    ~summary:"convert a P4 program to a value and output as JSON"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map includes_p4 = flag "-i" (listed string) ~doc:"P4 include paths"
     and filename_p4 = flag "-p" (required string) ~doc:"P4 program" in
     fun () ->
       try
         let value_program =
           Interface.Parse.parse_file_fresh includes_p4 filename_p4
         in
         let json = Sl.value_to_yojson value_program in
         Yojson.Safe.to_string json |> print_string
       with ParseError (at, msg) ->
         Format.printf "ill-formed: %s\n" (string_of_error at msg))

let unparse_json_value_command =
  Core.Command.basic
    ~summary:"parse a JSON value and unparse it back to P4 source code"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map filenames_spec =
       anon (non_empty_sequence_as_list ("filename" %: string))
     and filename_json =
       flag "-j" (required string) ~doc:"JSON file containing value"
     in
     fun () ->
       try
         let spec_sl = structure ~final:true filenames_spec in
         let json = Yojson.Safe.from_file filename_json in
         let value_result = Sl.value_of_yojson json in
         match value_result with
         | Ok value ->
             let p4_source =
               Format.asprintf "%a\n"
                 (Interface.Unparse.pp_program_sl spec_sl)
                 value
             in
             print_string p4_source
         | Error err -> Format.printf "Error parsing JSON value: %s\n" err
       with
       | Sys_error msg -> Format.printf "File error: %s\n" msg
       | Yojson.Json_error msg -> Format.printf "JSON parsing error: %s\n" msg
       | e -> Format.printf "Unknown error: %s\n" (Printexc.to_string e))

let command =
  Core.Command.group
    ~summary:"p4spectec: a language design framework for the p4_16 language"
    [
      (* Transformations *)
      ("elab", elab_command);
      ("struct", struct_command);
      ("prose", prose_command);
      (* Execution *)
      ("run", run_command);
      ("run-wasm", run_wasm_command);
      ("run-wasm-suite", run_wasm_suite);
      ("sim", sim_command);
      (* Coverage *)
      ("cover-run", cover_run_command);
      ("wasm-cover-run", wasm_cover_run_command);
      ("cover-sim", cover_sim_command);
      (* Negative type checker test generation and coverage *)
      ("testgen", run_testgen_command);
      ("wasm-testgen", wasm_run_testgen_command);
      ("testgen-dbg", run_testgen_debug_command);
      ("wasm-testgen-dbg", wasm_run_testgen_debug_command);
      ("interesting", interesting_command);
      (* Splicing *)
      ("splice", splice_command);
      (* Interfacing with P4 *)
      ("parse", parse_command);
      (* Interfacing with Wasm *)
      ("wasm-parse", wasm_parse_command);
      ("wasm-suite-roundtrip", wasm_suite_roundtrip_command);
      (* Interfacing with external tools via JSON *)
      ("json-ast", json_ast_command);
      ("p4-program-value-json", p4_program_value_json_command);
      ("unparse-json-value", unparse_json_value_command);
    ]

let () = Command_unix.run ~version command
