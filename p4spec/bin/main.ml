open Lang
open Runtime.Sim.Signature
open Util.Error
open Util.Source

let version = "0.1"

exception CommandError of string

let wasm_testgen_phase_arg =
  Core.Command.Arg_type.create (fun value ->
      match Backend_testgen_neg.Config.wasm_phase_of_string value with
      | Ok phase -> phase
      | Error message -> failwith message)

(* Operations *)

let run_with_instr (module Simulator : SIM) spec_sim relname includes_p4 path_p4
    =
  let (module IH : Inst.Handler.HANDLER), read_coverage_instr =
    Inst.Coverage_instr.make ()
  in
  Inst.Hook.register [ (module IH : Inst.Handler.HANDLER) ];
  Inst.Hook.init_spec spec_sim;
  let result = Simulator.Interp.eval_program relname includes_p4 path_p4 in
  Inst.Hook.finish ();
  let cover = read_coverage_instr () in
  (result, cover)

module Wasm_run = struct
  type result =
    | WasmPass of Lang.Il.value list
    | WasmFail of [ `Syntax of region * string | `Runtime of region * string ]
    | WasmExpectedFail of
        [ `Syntax of region * string | `Runtime of region * string ]
    | WasmUnexpectedPass of Lang.Il.value list

  let run_script_harness (module Simulator : SIM) (path_wasm : string) :
      result =
    let module H = Wasm_interface.Script_harness in
    let runtime = H.{ simulator = (module Simulator) } in
    let commands = Wasm_interface.Parse.parse_commands path_wasm in
    ignore (H.run_commands runtime (H.initial_state ()) commands);
    WasmPass []

  let run (module Simulator : SIM) (relname : string) (path_wasm : string) :
      result =
    try
      Wasm_interface.Builtin_hooks.init ();
      if Wasm_interface.Script_harness.is_script_harness_rel relname then
        run_script_harness (module Simulator) path_wasm
      else
        let value_program, expectation =
          Wasm_interface.Parse.parse_file_for_rel relname path_wasm
        in
        Inst.Hook.on_program value_program;
        match
          (expectation, Simulator.Interp.eval_rel relname [ value_program ])
        with
        | Wasm_interface.Parse.Positive, Pass values -> WasmPass values
        | Wasm_interface.Parse.Positive, Fail (at, msg) ->
            WasmFail (`Runtime (at, msg))
        | Wasm_interface.Parse.Negative, Pass values -> WasmUnexpectedPass values
        | Wasm_interface.Parse.Negative, Fail (at, msg) ->
            WasmExpectedFail (`Runtime (at, msg))
    with
    | ParseError (at, msg) -> WasmFail (`Syntax (at, msg))
    | InterpError (at, msg) -> WasmFail (`Runtime (at, msg))
end

let wasm_run_with_instr (module Simulator : SIM) spec_sim relname path_wasm =
  let (module IH : Inst.Handler.HANDLER), read_coverage_instr =
    Inst.Coverage_instr.make ()
  in
  Inst.Hook.register [ (module IH : Inst.Handler.HANDLER) ];
  Inst.Hook.init_spec spec_sim;
  let result = Wasm_run.run (module Simulator) relname path_wasm in
  Inst.Hook.finish ();
  let cover = read_coverage_instr () in
  (result, cover)

let run_with_dangling (module Simulator : SIM) spec_sim relname includes_p4
    path_p4 =
  let (module DH : Inst.Handler.HANDLER), read_coverage_dangling =
    Inst.Coverage_dangling.make ()
  in
  Inst.Hook.register [ (module DH : Inst.Handler.HANDLER) ];
  Inst.Hook.init_spec spec_sim;
  let result = Simulator.Interp.eval_program relname includes_p4 path_p4 in
  Inst.Hook.finish ();
  let cover = read_coverage_dangling () in
  (result, cover)

let wasm_run_with_dangling (module Simulator : SIM) spec_sim relname path_wasm =
  let (module DH : Inst.Handler.HANDLER), read_coverage_dangling =
    Inst.Coverage_dangling.make ()
  in
  Inst.Hook.register [ (module DH : Inst.Handler.HANDLER) ];
  Inst.Hook.init_spec spec_sim;
  let result = Wasm_run.run (module Simulator) relname path_wasm in
  Inst.Hook.finish ();
  let cover = read_coverage_dangling () in
  (result, cover)

let sim_with_instr (module Simulator : SIM) spec_sim includes_p4 path_p4
    path_stf =
  let (module IH : Inst.Handler.HANDLER), read_coverage_instr =
    Inst.Coverage_instr.make ()
  in
  Inst.Hook.register [ (module IH : Inst.Handler.HANDLER) ];
  Inst.Hook.init_spec spec_sim;
  let result = Simulator.run_stf_test includes_p4 path_p4 path_stf in
  Inst.Hook.finish ();
  let cover = read_coverage_instr () in
  (result, cover)

let sim_with_dangling (module Simulator : SIM) spec_sim includes_p4 path_p4
    path_stf =
  let (module DH : Inst.Handler.HANDLER), read_coverage_dangling =
    Inst.Coverage_dangling.make ()
  in
  Inst.Hook.register [ (module DH : Inst.Handler.HANDLER) ];
  Inst.Hook.init_spec spec_sim;
  let result = Simulator.run_stf_test includes_p4 path_p4 path_stf in
  Inst.Hook.finish ();
  let cover = read_coverage_dangling () in
  (result, cover)

let cover_run_instr ?(arch : string option) mode paths_spec relname includes_p4
    paths_p4 path_cov =
  let spec_sim, (module Simulator) =
    Backend_sim.Build.build ?arch ~final:true mode paths_spec
  in
  let spec_sl =
    match spec_sim with
    | SL spec_sl -> spec_sl
    | _ -> raise (CommandError "instruction coverage is only supported for SL")
  in
  let cover_multi = Coverage.Instr.Multi.init spec_sl in
  let cover_multi =
    List.fold_left
      (fun cover_multi path_p4 ->
        let _, cover_single =
          run_with_instr (module Simulator) spec_sim relname includes_p4 path_p4
        in
        Coverage.Instr.Multi.extend cover_multi path_p4 cover_single)
      cover_multi paths_p4
  in
  Coverage.Instr.Log.log_spec ~path_cov_opt:(Some path_cov) cover_multi spec_sl

let wasm_cover_run_instr ?(arch : string option) mode paths_spec relname
    paths_wasm path_cov =
  let spec_sim, (module Simulator) =
    Backend_sim.Build.build ?arch ~final:true mode paths_spec
  in
  let spec_sl =
    match spec_sim with
    | SL spec_sl -> spec_sl
    | _ -> raise (CommandError "instruction coverage is only supported for SL")
  in
  let cover_multi = Coverage.Instr.Multi.init spec_sl in
  let cover_multi =
    List.fold_left
      (fun cover_multi path_wasm ->
        let _, cover_single =
          wasm_run_with_instr (module Simulator) spec_sim relname path_wasm
        in
        Coverage.Instr.Multi.extend cover_multi path_wasm cover_single)
      cover_multi paths_wasm
  in
  Coverage.Instr.Log.log_spec ~path_cov_opt:(Some path_cov) cover_multi spec_sl

let cover_run_dangling ?(arch : string option) mode paths_spec relname
    includes_p4 paths_p4 path_cov =
  let spec_sim, (module Simulator) =
    Backend_sim.Build.build ?arch ~final:true mode paths_spec
  in
  let spec_sl =
    match spec_sim with
    | SL spec_sl -> spec_sl
    | _ -> raise (CommandError "instruction coverage is only supported for SL")
  in
  let cover_multi = Coverage.Dangling.Multi.init spec_sl in
  let cover_multi =
    List.fold_left
      (fun cover_multi path_p4 ->
        let program_result, cover_single =
          run_with_dangling
            (module Simulator)
            spec_sim relname includes_p4 path_p4
        in
        let wellformed, welltyped =
          match program_result with
          | Pass _ -> (true, true)
          | Fail (`Syntax _) -> (false, false)
          | Fail (`Runtime _) -> (true, false)
        in
        Coverage.Dangling.Multi.extend cover_multi path_p4 wellformed welltyped
          cover_single)
      cover_multi paths_p4
  in
  Coverage.Dangling.Multi.log ~path_cov_opt:(Some path_cov) cover_multi

let wasm_cover_run_dangling ?(arch : string option) mode paths_spec relname
    paths_wasm path_cov =
  let spec_sim, (module Simulator) =
    Backend_sim.Build.build ?arch ~final:true mode paths_spec
  in
  let spec_sl =
    match spec_sim with
    | SL spec_sl -> spec_sl
    | _ -> raise (CommandError "dangling coverage is only supported for SL")
  in
  let cover_multi = Coverage.Dangling.Multi.init spec_sl in
  let cover_multi =
    List.fold_left
      (fun cover_multi path_wasm ->
        let program_result, cover_single =
          wasm_run_with_dangling (module Simulator) spec_sim relname path_wasm
        in
        let wellformed, welltyped =
          match program_result with
          | Wasm_run.WasmPass _ | Wasm_run.WasmUnexpectedPass _ ->
              (true, true)
          | Wasm_run.WasmFail (`Syntax _) -> (false, false)
          | Wasm_run.WasmFail (`Runtime _)
          | Wasm_run.WasmExpectedFail _ ->
              (true, false)
        in
        Coverage.Dangling.Multi.extend cover_multi path_wasm wellformed
          welltyped cover_single)
      cover_multi paths_wasm
  in
  Coverage.Dangling.Multi.log ~path_cov_opt:(Some path_cov) cover_multi

let cover_sim_instr ?(arch : string option) mode paths_spec includes_p4 paths_p4
    paths_stf path_cov =
  let spec_sim, (module Simulator) =
    Backend_sim.Build.build ?arch ~final:true mode paths_spec
  in
  let spec_sl =
    match spec_sim with
    | SL spec_sl -> spec_sl
    | _ -> raise (CommandError "instruction coverage is only supported for SL")
  in
  let cover_multi = Coverage.Instr.Multi.init spec_sl in
  let cover_multi =
    List.fold_left2
      (fun cover_multi path_p4 path_stf ->
        let _, cover_single =
          sim_with_instr
            (module Simulator)
            spec_sim includes_p4 path_p4 path_stf
        in
        Coverage.Instr.Multi.extend cover_multi path_p4 cover_single)
      cover_multi paths_p4 paths_stf
  in
  Coverage.Instr.Log.log_spec ~path_cov_opt:(Some path_cov) cover_multi spec_sl

let cover_sim_dangling ?(arch : string option) mode paths_spec includes_p4
    paths_p4 paths_stf path_cov =
  let spec_sim, (module Simulator) =
    Backend_sim.Build.build ?arch ~final:true mode paths_spec
  in
  let spec_sl =
    match spec_sim with
    | SL spec_sl -> spec_sl
    | _ -> raise (CommandError "dangling coverage is only supported for SL")
  in
  let cover_multi = Coverage.Dangling.Multi.init spec_sl in
  let cover_multi =
    List.fold_left2
      (fun cover_multi path_p4 path_stf ->
        let program_result, cover_single =
          sim_with_dangling
            (module Simulator)
            spec_sim includes_p4 path_p4 path_stf
        in
        let wellformed, welltyped =
          match program_result with
          | Pass -> (true, true)
          | Fail (`Syntax _) -> (true, false)
          | Fail (`Runtime _) -> (false, false)
        in
        Coverage.Dangling.Multi.extend cover_multi path_p4 wellformed welltyped
          cover_single)
      cover_multi paths_p4 paths_stf
  in
  Coverage.Dangling.Multi.log ~path_cov_opt:(Some path_cov) cover_multi

(* Commands *)

let elab_command =
  Core.Command.basic ~summary:"parse and elaborate a P4 spec"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map paths_spec =
       anon (non_empty_sequence_as_list ("path" %: string))
     in
     fun () ->
       try
         let spec_il = Pass.elab paths_spec in
         Format.printf "%s\n" (Il.Print.string_of_spec spec_il);
         ()
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg) -> Format.printf "%s\n" (string_of_error at msg)
       | ElabError (at, msg) -> Format.printf "%s\n" (string_of_error at msg))

let algo_command =
  Core.Command.basic ~summary:"check algorithmic property of a P4 spec"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map paths_spec =
       anon (non_empty_sequence_as_list ("path" %: string))
     in
     fun () ->
       try
         let spec_al = Pass.algo paths_spec in
         Format.printf "%s\n" (Al.Print.string_of_spec spec_al);
         ()
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg) -> Format.printf "%s\n" (string_of_error at msg)
       | ElabError (at, msg) -> Format.printf "%s\n" (string_of_error at msg)
       | AlgoError (at, msg) -> Format.printf "%s\n" (string_of_error at msg))

let struct_command =
  Core.Command.basic ~summary:"insert structured control flow to a P4 spec"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map paths_spec =
       anon (non_empty_sequence_as_list ("path" %: string))
     in
     fun () ->
       try
         let spec_sl = Pass.structure ~final:true paths_spec in
         Format.printf "%s\n" (Sl.Print.string_of_spec spec_sl);
         ()
       with
       | ParseError (at, msg) | ElabError (at, msg) | StructError (at, msg) ->
         Format.printf "%s\n" (string_of_error at msg))

let prose_command =
  Core.Command.basic ~summary:"generate AsciiDoc prose from a P4 spec"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map paths_spec =
       anon (non_empty_sequence_as_list ("path" %: string))
     in
     fun () ->
       try
         let spec_pl = Pass.annotate paths_spec in
         Format.printf "%s\n" (Pl.Render.render_spec spec_pl);
         ()
       with
       | ParseError (at, msg)
       | ElabError (at, msg)
       | StructError (at, msg)
       | ProseError (at, msg)
       ->
         Format.printf "%s\n" (string_of_error at msg))

let run_command =
  Core.Command.basic ~summary:"execute the P4 spec against a P4 program"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map paths_spec = anon (non_empty_sequence_as_list ("path" %: string))
     and relname = flag "-rel" (required string) ~doc:"relation to run"
     and includes_p4 = flag "-i" (listed string) ~doc:"P4 include paths"
     and path_p4 = flag "-p" (required string) ~doc:"P4 program"
     and no_cache = flag "-no-cache" no_arg ~doc:"disable caching"
     and det = flag "-det" no_arg ~doc:"deterministic mode"
     and guard =
       flag "-guard" no_arg ~doc:"enable guard for builtins and externs"
     and profile = flag "-profile" no_arg ~doc:"profiling"
     and trace =
       Command.Param.choose_one
         [
           flag "-trace" no_arg ~doc:"emit execution trace"
           |> map ~f:(fun b -> Core.Option.some_if b (Some Inst.Trace.Simple));
           flag "-trace-full" no_arg ~doc:"emit full execution trace"
           |> map ~f:(fun b -> Core.Option.some_if b (Some Inst.Trace.Full));
         ]
         ~if_nothing_chosen:(Default_to None)
     and mode =
       Command.Param.choose_one
         [
           flag "al" no_arg ~doc:"run AL interpreter"
           |> map ~f:(fun b -> Core.Option.some_if b AL_mode);
           flag "sl" no_arg ~doc:"run SL interpreter"
           |> map ~f:(fun b -> Core.Option.some_if b SL_mode);
           flag "pl" no_arg ~doc:"run PL interpreter"
           |> map ~f:(fun b -> Core.Option.some_if b PL_mode);
         ]
         ~if_nothing_chosen:(Default_to SL_mode)
     in
     fun () ->
       try
         let cache = not no_cache in
         let spec_sim, (module Simulator) =
           Backend_sim.Build.build ~cache ~det ~guard ~final:true mode
             paths_spec
         in
         let handlers =
           if profile then
             let (module PH : Inst.Handler.HANDLER) = Inst.Profile.make () in
             [ (module PH : Inst.Handler.HANDLER) ]
           else []
         in
         let handlers =
           match trace with
           | Some level ->
               let (module TH : Inst.Handler.HANDLER) =
                 Inst.Trace.make ~level ()
               in
               handlers @ [ (module TH : Inst.Handler.HANDLER) ]
           | None -> handlers
         in
         Inst.Hook.register handlers;
         Inst.Hook.init_spec spec_sim;
         let result =
           Simulator.Interp.eval_program relname includes_p4 path_p4
         in
         Inst.Hook.finish ();
         match result with
         | Pass _ -> Format.printf "passed\n"
         | Fail (`Syntax (_, msg)) -> Format.printf "syntax error: %s\n" msg
         | Fail (`Runtime (_, msg)) -> Format.printf "runtime error: %s\n" msg
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg) | ElabError (at, msg) | StructError (at, msg) ->
           Format.printf "%s\n" (string_of_error at msg)
       | InterpError (at, msg) -> Format.printf "%s\n" (string_of_error at msg))

let run_wasm_command =
  Core.Command.basic ~summary:"execute the Wasm spec against a Wasm program"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map paths_spec =
       anon (non_empty_sequence_as_list ("path" %: string))
     and relname = flag "-rel" (required string) ~doc:"relation to run"
     and path_wasm = flag "-w" (required string) ~doc:"Wasm program"
     and no_cache = flag "-no-cache" no_arg ~doc:"disable caching"
     and det = flag "-det" no_arg ~doc:"deterministic mode"
     and profile = flag "-profile" no_arg ~doc:"profiling"
     and wasm_script_debug =
       flag "-wasm-script-debug" no_arg
         ~doc:"print source locations for Wasm script harness commands"
     and mode =
       Command.Param.choose_one
         [
           flag "il" no_arg ~doc:"run IL interpreter"
           |> map ~f:(fun b -> Core.Option.some_if b AL_mode);
           flag "al" no_arg ~doc:"run AL interpreter"
           |> map ~f:(fun b -> Core.Option.some_if b AL_mode);
           flag "sl" no_arg ~doc:"run SL interpreter"
           |> map ~f:(fun b -> Core.Option.some_if b SL_mode);
           flag "pl" no_arg ~doc:"run PL interpreter"
           |> map ~f:(fun b -> Core.Option.some_if b PL_mode);
         ]
         ~if_nothing_chosen:(Default_to SL_mode)
     in
     fun () ->
       try
         Wasm_interface.Script_harness.set_script_debug wasm_script_debug;
         let cache = not no_cache in
         let spec_sim, (module Simulator) =
           Backend_sim.Build.build ~cache ~det ~final:true mode paths_spec
         in
         let handlers =
           if profile then
             let (module PH : Inst.Handler.HANDLER) = Inst.Profile.make () in
             [ (module PH : Inst.Handler.HANDLER) ]
           else []
         in
         Inst.Hook.register handlers;
         Inst.Hook.init_spec spec_sim;
         let result = Wasm_run.run (module Simulator) relname path_wasm in
         Inst.Hook.finish ();
         match result with
         | Wasm_run.WasmPass _ -> Format.printf "Passed\n%!"
         | Wasm_run.WasmExpectedFail _ ->
             Format.printf "Expected fail (passed)\n%!"
         | Wasm_run.WasmFail (`Syntax (_, msg)) ->
             Format.printf "Failed (syntax error): %s\n%!" msg
         | Wasm_run.WasmFail (`Runtime (_, msg)) ->
             Format.printf "Failed (runtime error): %s\n%!" msg
         | Wasm_run.WasmUnexpectedPass _ ->
             Format.printf "Unexpected pass (failed)\n%!"
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg) -> Format.printf "%s\n" (string_of_error at msg)
       | ElabError (at, msg) -> Format.printf "%s\n" (string_of_error at msg))

let run_wasm_suite =
  Core.Command.basic ~summary:"execute the Wasm spec against a Wasm test suite"
     (let open Core.Command.Let_syntax in
      let open Core.Command.Param in
      let%map paths_spec =
        anon (non_empty_sequence_as_list ("path" %: string))
      and relname = flag "-rel" (required string) ~doc:"relation to run"
      and testdirs_wasm = flag "-wasm-dir" (listed string) ~doc:"Wasm test directories"
      and no_cache = flag "-no-cache" no_arg ~doc:"disable caching"
      and det = flag "-det" no_arg ~doc:"deterministic mode"
      and profile = flag "-profile" no_arg ~doc:"profiling"
      and wasm_script_debug =
        flag "-wasm-script-debug" no_arg
          ~doc:"print source locations for Wasm script harness commands"
      and mode =
       Command.Param.choose_one
         [
           flag "il" no_arg ~doc:"run IL interpreter"
           |> map ~f:(fun b -> Core.Option.some_if b AL_mode);
           flag "al" no_arg ~doc:"run AL interpreter"
           |> map ~f:(fun b -> Core.Option.some_if b AL_mode);
           flag "sl" no_arg ~doc:"run SL interpreter"
           |> map ~f:(fun b -> Core.Option.some_if b SL_mode);
           flag "pl" no_arg ~doc:"run PL interpreter"
           |> map ~f:(fun b -> Core.Option.some_if b PL_mode);
         ]
         ~if_nothing_chosen:(Default_to SL_mode)
      in
      fun () ->
        Wasm_interface.Script_harness.set_script_debug wasm_script_debug;
        let paths_wasm =
            testdirs_wasm
            |> List.concat_map (Util.Filesys.collect_files ~suffix:".wast")
        in
        let cache = not no_cache in
        let spec_sim, (module Simulator) =
          Backend_sim.Build.build ~cache ~det ~final:true mode paths_spec
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
          (fun path_wasm ->
            try
              Inst.Hook.register handlers;
              Inst.Hook.init_spec spec_sim;
              total := !total + 1;
              let result = Wasm_run.run (module Simulator) relname path_wasm in
              Inst.Hook.finish ();
              match result with
              | Wasm_run.WasmPass _ ->
                  passed := !passed + 1;
                  Format.printf "Passed\n%!"
              | Wasm_run.WasmExpectedFail _ ->
                  passed := !passed + 1;
                  Format.printf "Expected fail (passed)\n%!"
              | Wasm_run.WasmFail (`Syntax (_, msg)) ->
                  failed := !failed + 1;
                  Format.printf "Failed (syntax error): %s\n%!" msg
              | Wasm_run.WasmFail (`Runtime (_, msg)) ->
                  failed := !failed + 1;
                  Format.printf "Failed (runtime error): %s\n%!" msg
              | Wasm_run.WasmUnexpectedPass _ ->
                  failed := !failed + 1;
                  Format.printf "Unexpected pass (failed)\n%!"
              with
              | CommandError msg -> failed := !failed + 1; Format.printf "%s\n%!" msg
              | ParseError (at, msg) -> failed := !failed + 1; Format.printf "%s\n%!" (string_of_error at msg)
              | ElabError (at, msg) -> failed := !failed + 1; Format.printf "%s\n%!" (string_of_error at msg))
        paths_wasm;
        Format.printf "typechecker: %d/%d passed, %d failed\n%!" !passed !total !failed;
        )

let sim_command =
  Core.Command.basic
    ~summary:"simulate a target architecture with a P4 program and P4 spec"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map paths_spec = anon (non_empty_sequence_as_list ("path" %: string))
     and includes_p4 = flag "-i" (listed string) ~doc:"P4 include paths"
     and path_p4 = flag "-p" (required string) ~doc:"P4 program"
     and path_stf = flag "-stf" (required string) ~doc:"stf test file"
     and arch = flag "-arch" (required string) ~doc:"target architecture"
     and no_cache = flag "-no-cache" no_arg ~doc:"disable caching"
     and det = flag "-det" no_arg ~doc:"deterministic mode"
     and guard =
       flag "-guard" no_arg ~doc:"enable guard for builtins and externs"
     and profile = flag "-profile" no_arg ~doc:"profiling"
     and trace =
       Command.Param.choose_one
         [
           flag "-trace" no_arg ~doc:"emit execution trace"
           |> map ~f:(fun b -> Core.Option.some_if b (Some Inst.Trace.Simple));
           flag "-trace-full" no_arg ~doc:"emit full execution trace"
           |> map ~f:(fun b -> Core.Option.some_if b (Some Inst.Trace.Full));
         ]
         ~if_nothing_chosen:(Default_to None)
     and mode =
       Command.Param.choose_one
         [
           flag "al" no_arg ~doc:"run AL interpreter"
           |> map ~f:(fun b -> Core.Option.some_if b AL_mode);
           flag "sl" no_arg ~doc:"run SL interpreter"
           |> map ~f:(fun b -> Core.Option.some_if b SL_mode);
           flag "pl" no_arg ~doc:"run PL interpreter"
           |> map ~f:(fun b -> Core.Option.some_if b PL_mode);
         ]
         ~if_nothing_chosen:(Default_to SL_mode)
     in
     fun () ->
       try
         let cache = not no_cache in
         let spec_sim, (module Simulator) =
           Backend_sim.Build.build ~cache ~det ~guard ~arch ~final:true mode
             paths_spec
         in
         let handlers =
           if profile then
             let (module PH : Inst.Handler.HANDLER) = Inst.Profile.make () in
             [ (module PH : Inst.Handler.HANDLER) ]
           else []
         in
         let handlers =
           match trace with
           | Some level ->
               let (module TH : Inst.Handler.HANDLER) =
                 Inst.Trace.make ~level ()
               in
               handlers @ [ (module TH : Inst.Handler.HANDLER) ]
           | None -> handlers
         in
         Inst.Hook.register handlers;
         Inst.Hook.init_spec spec_sim;
         let result = Simulator.run_stf_test includes_p4 path_p4 path_stf in
         Inst.Hook.finish ();
         match result with
         | Pass -> Format.printf "passed\n"
         | Fail (`Syntax (_, msg)) -> Format.printf "syntax error: %s\n" msg
         | Fail (`Runtime (_, msg)) -> Format.printf "runtime error: %s\n" msg
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg)
       | ElabError (at, msg)
       | StructError (at, msg)
       | InterpError (at, msg)
       | ExternError (at, msg) ->
           Format.printf "%s\n" (string_of_error at msg)
       | StfError msg -> Format.printf "%s\n" (string_of_error no_region msg))

let cover_run_command =
  Core.Command.basic ~summary:"measure coverage of the spec"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map paths_spec = anon (non_empty_sequence_as_list ("path" %: string))
     and relname = flag "-rel" (required string) ~doc:"relation to run"
     and includes_p4 = flag "-i" (listed string) ~doc:"P4 include paths"
     and excludes_p4 = flag "-e" (listed string) ~doc:"P4 test exclude paths"
     and testdirs_p4 = flag "-p4-dir" (listed string) ~doc:"P4 test directories"
     and path_cov = flag "-cov" (required string) ~doc:"output coverage file"
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
         let paths_p4 =
           testdirs_p4
           |> List.concat_map (Util.Filesys.collect_files ~suffix:".p4")
           |> List.filter (fun path_p4 ->
                  not (List.exists (String.equal path_p4) excludes_p4))
         in
         match mode with
         | `Instr ->
             cover_run_instr SL_mode paths_spec relname includes_p4 paths_p4
               path_cov
         | `Dangling ->
             cover_run_dangling SL_mode paths_spec relname includes_p4 paths_p4
               path_cov
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg)
       | ElabError (at, msg)
       | StructError (at, msg)
       | InterpError (at, msg)
       | ExternError (at, msg) ->
           Format.printf "%s\n" (string_of_error at msg))

let wasm_cover_run_command =
  Core.Command.basic ~summary:"measure coverage of the spec"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map paths_spec =
       anon (non_empty_sequence_as_list ("path" %: string))
     and relname = flag "-rel" (required string) ~doc:"relation to run"
     and testdirs_wasm = flag "-wasm-dir" (listed string) ~doc:"Wasm test directories"
     and path_cov = flag "-cov" (required string) ~doc:"output coverage file"
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
         let paths_wasm =
           testdirs_wasm
           |> List.concat_map (Util.Filesys.collect_files ~suffix:".wast")
         in
         match mode with
         | `Instr ->
             wasm_cover_run_instr SL_mode paths_spec relname paths_wasm path_cov
         | `Dangling ->
             wasm_cover_run_dangling SL_mode paths_spec relname paths_wasm
               path_cov
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg)
       | ElabError (at, msg)
       | StructError (at, msg)
       | InterpError (at, msg)
       | ExternError (at, msg) ->
           Format.printf "%s\n" (string_of_error at msg))

let cover_sim_command =
  Core.Command.basic
    ~summary:"measure coverage of the spec when simulated on STF"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map paths_spec = anon (non_empty_sequence_as_list ("path" %: string))
     and includes_p4 = flag "-i" (listed string) ~doc:"P4 include paths"
     and excludes_p4 = flag "-e" (listed string) ~doc:"P4 test exclude paths"
     and testdirs_p4 = flag "-p4-dir" (listed string) ~doc:"P4 test directories"
     and testdirs_stf =
       flag "-stf-dir" (listed string) ~doc:"STF test directories"
     and patchdir =
       flag "-patch-dir" (listed string) ~doc:"directory for P4/STF patches"
     and path_cov = flag "-cov" (required string) ~doc:"output coverage file"
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
         let paths_p4, paths_stf =
           Util.Test.collect_test_pairs arch testdirs_p4 testdirs_stf patchdir
           |> List.map (fun (path_p4, path_stf, _) -> (path_p4, path_stf))
           |> List.filter (fun (path_p4, _) ->
                  not (List.exists (String.equal path_p4) excludes_p4))
           |> List.split
         in
         match mode with
         | `Instr ->
             cover_sim_instr ~arch SL_mode paths_spec includes_p4 paths_p4
               paths_stf path_cov
         | `Dangling ->
             cover_sim_dangling ~arch SL_mode paths_spec includes_p4 paths_p4
               paths_stf path_cov
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg)
       | ElabError (at, msg)
       | StructError (at, msg)
       | InterpError (at, msg)
       | ExternError (at, msg) ->
           Format.printf "%s\n" (string_of_error at msg))

let run_testgen_command =
  Core.Command.basic
    ~summary:"generate negative type checker tests from a p4_16 spec"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map paths_spec = anon (non_empty_sequence_as_list ("path" %: string))
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
     and path_boot =
       flag "-boot-file" (optional string) ~doc:"coverage file for boot"
     and random = flag "-random" no_arg ~doc:"randomize AST selection"
     and hybrid =
       flag "-hybrid" no_arg
         ~doc:"randomize AST selection when no derivations exist"
     and strict =
       flag "-strict" no_arg
         ~doc:"cover a new dangling only if it was intended by a mutation"
     in
     fun () ->
       try
         let spec_sl = Pass.structure ~final:true paths_spec in
         let logmode =
           if silent then Backend_testgen_neg.Modes.Silent
           else Backend_testgen_neg.Modes.Verbose
         in
         let bootmode =
           match (bootdir, path_boot) with
           | Some bootdir, None ->
               Backend_testgen_neg.Modes.Cold (excludes_p4, bootdir)
           | None, Some path_boot -> Backend_testgen_neg.Modes.Warm path_boot
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
       | ParseError (at, msg)
       | ElabError (at, msg)
       | StructError (at, msg)
       | InterpError (at, msg)
       | ExternError (at, msg) ->
           Format.printf "%s\n" (string_of_error at msg))

let wasm_run_testgen_command =
  Core.Command.basic
    ~summary:"generate negative type checker tests from a Wasm spec"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map paths_spec =
       anon (non_empty_sequence_as_list ("path" %: string))
     and phase =
       flag "-phase" (required wasm_testgen_phase_arg)
         ~doc:"PHASE validation or instantiation"
     and fuel = flag "-fuel" (optional int) ~doc:"fuel for test generation"
     and timeout =
       flag "-timeout" (optional int)
         ~doc:"seconds to run focused Wasm test generation"
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
     and path_boot =
       flag "-boot-file" (optional string) ~doc:"coverage file for boot"
     and random = flag "-random" no_arg ~doc:"randomize AST selection"
     and hybrid =
       flag "-hybrid" no_arg
         ~doc:"randomize AST selection when no derivations exist"
     and strict =
       flag "-strict" no_arg
         ~doc:"cover a new dangling only if it was intended by a mutation"
     and pid =
       flag "-pid" (optional int)
         ~doc:"legacy spelling for the dangling instruction id to close-miss"
     and filename_wasm =
       flag "-w" (optional string) ~doc:"Wasm program to close-miss with"
     and focus =
       flag "-focus" no_arg
         ~doc:"focus on one dangling id and its close-missing Wasm program"
     in
     fun () ->
       try
         let spec_sl = Pass.structure ~final:true paths_spec in
         let logmode =
           if silent then Backend_testgen_neg.Modes.Silent
           else Backend_testgen_neg.Modes.Verbose
         in
         let bootmode =
           match (bootdir, path_boot) with
           | Some bootdir, None ->
               Backend_testgen_neg.Modes.Cold ([], bootdir)
           | None, Some path_boot -> Backend_testgen_neg.Modes.Warm path_boot
           | Some _, Some _ ->
               raise
                 (CommandError
                    "Error: should specify only one of -boot-dir or -boot-file")
           | None, None ->
               raise
                 (CommandError
                    "Error: should specify either -boot-dir or -boot-file")
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
           | true, Some iid, Some filename_wasm ->
               Some Backend_testgen_neg.Config.{ iid; filename_wasm }
           | true, _, _ ->
               raise
                 (CommandError "Error: -focus requires both -pid and -w")
           | false, None, None -> None
           | false, _, _ ->
               raise
                 (CommandError
                    "Error: -pid and -w are only valid with -focus")
         in
         let budget =
           match (fuel, timeout, focus) with
           | Some _, Some _, _ ->
               raise
                 (CommandError
                    "Error: should specify only one of -fuel or -timeout")
           | Some fuel, None, _ ->
               if fuel < 0 then
                 raise (CommandError "Error: -fuel should be non-negative")
               else Backend_testgen_neg.Config.WasmFuel fuel
           | None, Some timeout, Some _ ->
               if timeout <= 0 then
                 raise (CommandError "Error: -timeout should be positive")
               else Backend_testgen_neg.Config.WasmTimeout timeout
           | None, Some _, None ->
               raise
                 (CommandError "Error: -timeout is only valid with -focus")
           | None, None, _ ->
               raise
                 (CommandError
                    "Error: should specify either -fuel or -timeout")
         in
         Backend_testgen_neg.Gen.wasm_fuzzer budget spec_sl phase gendir
           name_campaign randseed logmode bootmode mutationmode covermode focus
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg)
       | ElabError (at, msg)
       | StructError (at, msg)
       | InterpError (at, msg)
       | ExternError (at, msg) ->
           Format.printf "%s\n" (string_of_error at msg))

let run_testgen_debug_command =
  Core.Command.basic
    ~summary:"debug close-AST deriver in negative type checker generator"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map paths_spec = anon (non_empty_sequence_as_list ("path" %: string))
     and relname = flag "-rel" (required string) ~doc:"spec relation to run"
     and includes_p4 = flag "-i" (listed string) ~doc:"P4 include paths"
     and path_p4 = flag "-p" (required string) ~doc:"P4 program"
     and debugdir =
       flag "-debug" (required string) ~doc:"directory for debug files"
     and iid = flag "-iid" (required int) ~doc:"dangling id to close-miss" in
     fun () ->
       try
         let spec_sl = Pass.structure ~final:true paths_spec in
         Backend_testgen_neg.Derive.debug_dangling spec_sl relname includes_p4
           path_p4 debugdir iid
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg)
       | ElabError (at, msg)
       | StructError (at, msg)
       | InterpError (at, msg)
       | ExternError (at, msg) ->
           Format.printf "%s\n" (string_of_error at msg))

let interesting_command =
  Core.Command.basic ~summary:"interestingness test for reducing P4 programs"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map paths_spec = anon (non_empty_sequence_as_list ("path" %: string))
     and relname = flag "-rel" (required string) ~doc:"relation to run"
     and includes_p4 = flag "-i" (listed string) ~doc:"P4 include paths"
     and check_well_typed =
       flag "-well" no_arg
         ~doc:"'interesting' if well-typed (default: ill-typed)"
     and check_close_miss =
       flag "-close" no_arg ~doc:"'interesting' if close-miss (default: hit)"
     and iid = flag "-iid" (required int) ~doc:"dangling id to test"
     and path_p4 = flag "-p" (required string) ~doc:"P4 program" in
     fun () ->
       try
         let spec_sim, (module Simulator) =
           Backend_sim.Build.build ~final:true SL_mode paths_spec
         in
         let result, cover =
           run_with_dangling
             (module Simulator)
             spec_sim relname includes_p4 path_p4
         in
         match result with
         | Pass _ ->
             if check_well_typed then (
               let branch = Coverage.Dangling.Single.Cover.find iid cover in
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
               let branch = Coverage.Dangling.Single.Cover.find iid cover in
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
       | ParseError (at, msg)
       | ElabError (at, msg)
       | StructError (at, msg)
       | InterpError (at, msg)
       | ExternError (at, msg) ->
           Format.printf "%s\n" (string_of_error at msg))

let splice_command =
  Core.Command.basic ~summary:"splice a skeleton p4_16 specification document"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map paths_spec = anon (non_empty_sequence_as_list ("path" %: string))
     and paths_input = flag "-splice" (listed string) ~doc:"skeleton documents"
     and paths_output = flag "-out" (listed string) ~doc:"output files"
     and inplace = flag "-inplace" no_arg ~doc:"splice in place" in
     fun () ->
       try
         if (not inplace) && List.length paths_input <> List.length paths_output
         then raise (CommandError "number of input and output files must match");
         let paths =
           if inplace then List.combine paths_input paths_input
           else List.combine paths_input paths_output
         in
         let spec = Pass.parse paths_spec in
         let spec_pl = Pass.annotate paths_spec in
         Backend_splice.Driver.splice_files spec spec_pl paths
       with
       | CommandError msg -> Format.printf "%s\n" msg
       | ParseError (at, msg)
       | ElabError (at, msg)
       | StructError (at, msg)
       | ProseError (at, msg)
       | SpliceError (at, msg) ->
           Format.eprintf "%s\n" (string_of_error at msg);
           Format.printf "%s\n" (string_of_error at msg))

let parse_command =
  Core.Command.basic ~summary:"parse a P4 program"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map paths_spec = anon (non_empty_sequence_as_list ("path" %: string))
     and includes_p4 = flag "-i" (listed string) ~doc:"P4 include paths"
     and path_p4 = flag "-p" (required string) ~doc:"P4 program"
     and roundtrip =
       flag "-r" no_arg ~doc:"perform a round-trip parse/unparse"
     in
     fun () ->
       try
         let _, (module Simulator) =
           Backend_sim.Build.build ~final:true AL_mode paths_spec
         in
         let value_program =
           match Simulator.Interface.parse_program includes_p4 [ path_p4 ] with
           | Pass value_program -> value_program
           | Fail (`Syntax (at, msg)) -> raise (ParseError (at, msg))
         in
         let str_program = Simulator.Interface.unparse_program value_program in
         if roundtrip then
           let value_program_roundtrip =
             match Simulator.Interface.parse_string path_p4 str_program with
             | Pass value_program_roundtrip -> value_program_roundtrip
             | Fail (`Syntax (at, msg)) -> raise (ParseError (at, msg))
           in
           Il.Eq.eq_value ~dbg:true value_program value_program_roundtrip
           |> (fun b ->
                if b then "Roundtrip successful" else "Roundtrip failed")
           |> print_endline
         else str_program |> print_endline
       with
       | Sys_error msg -> Format.printf "File error: %s\n" msg
       | ElabError (at, msg) ->
           Format.printf "Elaboration error: %s\n" (string_of_error at msg)
       | ParseError (at, msg) ->
           Format.printf "Parse error: %s\n" (string_of_error at msg)
       | e -> Format.printf "Unknown error: %s\n" (Printexc.to_string e))

let unparse_wasm_value (parsed_wasm_file : Il.value) : string =
  parsed_wasm_file
  |> Wasm_interface.Deconstruct.sl_to_list
       Wasm_interface.Deconstruct.sl_to_module
  |> List.map (fun wasm_module ->
         (wasm_module, [])
         |> Wasm_interpreter.Arrange.module_with_custom
         |> Wasm_interpreter.Sexpr.to_string 80)
  |> String.concat "\n"

let rec ensure_directory (dirname : string) : unit =
  if dirname = "" || dirname = "." then ()
  else if Sys.file_exists dirname then (
    let stats = Unix.stat dirname in
    if stats.st_kind <> Unix.S_DIR then
      raise (CommandError (dirname ^ " exists but is not a directory")))
  else (
    let dirname_parent = Filename.dirname dirname in
    if dirname_parent <> dirname then ensure_directory dirname_parent;
    Unix.mkdir dirname 0o755)

let write_preprocessed_wasm ~(filename_out : string) (contents : string) :
    string =
  ensure_directory (Filename.dirname filename_out);
  let oc = open_out filename_out in
  output_string oc contents;
  if contents = "" || contents.[String.length contents - 1] <> '\n' then
    output_char oc '\n';
  close_out oc;
  filename_out

let wasm_parse_command =
  Core.Command.basic ~summary:"parse a Wasm program"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map filename_wasm = flag "-p" (required string) ~doc:"Wasm program"
     and roundtrip =
       flag "-r" no_arg ~doc:"perform a round-trip parse/unparse"
     and preprocess =
       flag "-preprocess" (optional string)
         ~doc:
           "FILE write parsed/unparsed Wasm with implicit function types made \
            explicit"
     in
     fun () ->
       try
         let (parsed_wasm_file, _) =
           Wasm_interface.Parse.parse_file filename_wasm
         in
         Format.printf "parsed_wasm_file:\n%s\n%!"
           (Il.Print.string_of_value parsed_wasm_file);
         let unparsed_wasm_string = unparse_wasm_value parsed_wasm_file in
         (match preprocess with
         | Some filename_out ->
             let filename_out =
               write_preprocessed_wasm ~filename_out unparsed_wasm_string
             in
             Format.printf "Wrote preprocessed Wasm to %s\n%!" filename_out
         | None -> ());
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
         else ()
       with
       | Sys_error msg -> Format.printf "File error: %s\n" msg
       | ElabError (at, msg) ->
           Format.printf "Elaboration error: %s\n" (string_of_error at msg)
       | ParseError (at, msg) ->
           Format.printf "Parse error: %s\n" (string_of_error at msg)
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
     and paths = anon (non_empty_sequence_as_list ("path" %: string)) in
     fun () ->
       match mode with
       | `Emit -> (
           try
             let spec_sl = Pass.structure ~final:true paths in
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
           let path = List.hd paths in
           let parsed = Yojson.Safe.from_file path |> Sl.spec_of_yojson in
           match parsed with
           | Ok spec_sl ->
               Format.printf "%s\n" (Sl.Print.string_of_spec spec_sl)
           | Error err -> Format.printf "Error while parsing %s: %s" path err))

let p4_program_value_json_command =
  Core.Command.basic
    ~summary:"convert a P4 program to a value and output as JSON"
    (let open Core.Command.Let_syntax in
     let open Core.Command.Param in
     let%map paths_spec = anon (non_empty_sequence_as_list ("path" %: string))
     and includes_p4 = flag "-i" (listed string) ~doc:"P4 include paths"
     and path_p4 = flag "-p" (required string) ~doc:"P4 program" in
     fun () ->
       let _, (module Simulator) =
         Backend_sim.Build.build ~final:true AL_mode paths_spec
       in
       try
         let value_program =
           match Simulator.Interface.parse_program includes_p4 [ path_p4 ] with
           | Pass value_program -> value_program
           | Fail (`Syntax (at, msg)) -> raise (ParseError (at, msg))
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
     let%map paths_spec = anon (non_empty_sequence_as_list ("path" %: string))
     and path_json =
       flag "-j" (required string) ~doc:"JSON file containing value"
     in
     fun () ->
       try
         let _, (module Simulator) =
           Backend_sim.Build.build ~final:true AL_mode paths_spec
         in
         let json = Yojson.Safe.from_file path_json in
         let value_result = Sl.value_of_yojson json in
         match value_result with
         | Ok value ->
             let p4_source = Simulator.Interface.unparse_program value in
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
      ("algo", algo_command);
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
