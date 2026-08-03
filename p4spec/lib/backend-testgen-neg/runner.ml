open Lang
open Sl
open Util.Error
open Util.Source
module DCov_single = Coverage.Dangling.Single
module DCov_multi = Coverage.Dangling.Multi
module Dep = Runtime.Testgen_neg.Dep
module Sim = Runtime.Sim.Signature

(* Spec runners *)

let finish_and_clear_handlers () =
  Fun.protect
    ~finally:(fun () -> Inst.Hook.register [])
    Inst.Hook.finish

let with_instrumentation ~spec handlers f =
  if Inst.Hook.is_active () then
    error_interp no_region "instrumentation handler leaked from an earlier run";
  Inst.Hook.register handlers;
  Fun.protect ~finally:finish_and_clear_handlers (fun () ->
      Inst.Hook.init_spec spec;
      f ())

let eval_rel_with_dangling ~simulator:(module Simulator : Sim.SIM) ~spec ~root
    ~relname ~inputs : Sim.rel_result * DCov_single.t =
  let (module DH : Inst.Handler.HANDLER), read_coverage_dangling =
    Inst.Coverage_dangling.make ()
  in
  let rel_result =
    with_instrumentation ~spec [ (module DH : Inst.Handler.HANDLER) ] (fun () ->
        Inst.Hook.on_program root;
        Simulator.Interp.eval_rel relname inputs)
  in
  (rel_result, read_coverage_dangling ())

let eval_rel_with_dangling_and_vdg ~derive
    ~simulator:(module Simulator : Sim.SIM) ~spec ~root ~relname ~inputs :
    Sim.rel_result * DCov_single.t * Dep.Graph.t =
  let (module DH : Inst.Handler.HANDLER), read_coverage_dangling =
    Inst.Coverage_dangling.make ()
  in
  let (module VH : Inst.Handler.HANDLER), read_vdg =
    Inst.Value_dependency.make ~derive ~cache_on:Simulator.Cache.cache_on
      ~cache_off:Simulator.Cache.cache_off
  in
  let handlers =
    [ (module DH : Inst.Handler.HANDLER); (module VH : Inst.Handler.HANDLER) ]
  in
  let rel_result =
    with_instrumentation ~spec handlers (fun () ->
        Inst.Hook.on_program root;
        let graph = read_vdg () in
        List.iter (Dep.Graph.add_value_subtree ~taint:false graph) inputs;
        Simulator.Interp.eval_rel relname inputs)
  in
  (rel_result, read_coverage_dangling (), read_vdg ())

type wasm_program_result =
  | WasmPass of value list
  | WasmFail of [ `Syntax of region * string | `Runtime of region * string ]
  | WasmExpectedFail of
      [ `Syntax of region * string | `Runtime of region * string ]
  | WasmUnexpectedPass of value list

let run_wasm_program (module Simulator : Sim.SIM) (relname : string)
    (filename_wasm : string) : wasm_program_result =
  try
    Wasm_interface.Builtin_hooks.init ();
    let value_program, expectation =
      Wasm_interface.Parse.parse_file_for_rel relname filename_wasm
    in
    Inst.Hook.on_program value_program;
    match (expectation, Simulator.Interp.eval_rel relname [ value_program ]) with
    | Wasm_interface.Parse.Positive, Pass values -> WasmPass values
    | Wasm_interface.Parse.Positive, Fail (at, msg) ->
        WasmFail (`Runtime (at, msg))
    | Wasm_interface.Parse.Negative, Pass values -> WasmUnexpectedPass values
    | Wasm_interface.Parse.Negative, Fail (at, msg) ->
        WasmExpectedFail (`Runtime (at, msg))
  with
  | ParseError (at, msg) -> WasmFail (`Syntax (at, msg))
  | InterpError (at, msg) -> WasmFail (`Runtime (at, msg))

let run_program_with_dangling (module Simulator : Sim.SIM) (spec : Sim.spec)
    (relname : string) (includes_p4 : string list) (filename_p4 : string) :
    Sim.program_result * DCov_single.t =
  let (module DH : Inst.Handler.HANDLER), read_coverage_dangling =
    Inst.Coverage_dangling.make ()
  in
  Inst.Hook.register [ (module DH : Inst.Handler.HANDLER) ];
  Inst.Hook.init_spec spec;
  let program_result =
    Simulator.Interp.eval_program relname includes_p4 filename_p4
  in
  Inst.Hook.finish ();
  let cover = read_coverage_dangling () in
  (program_result, cover)

let run_programs_with_dangling (module Simulator : Sim.SIM) (spec : Sim.spec)
    (relname : string) (includes_p4 : string list) (filenames_p4 : string list)
    : DCov_multi.t =
  let cover_multi =
    match spec with SL spec -> DCov_multi.init spec | _ -> assert false
  in
  List.fold_left
    (fun cover_multi filename_p4 ->
      let program_result, cover_single =
        run_program_with_dangling
          (module Simulator)
          spec relname includes_p4 filename_p4
      in
      let wellformed, welltyped =
        match program_result with
        | Pass _ -> (true, true)
        | Fail (`Syntax _) -> (false, false)
        | Fail (`Runtime _) -> (true, false)
      in
      DCov_multi.extend cover_multi filename_p4 wellformed welltyped
        cover_single)
    cover_multi filenames_p4

let run_wasm_program_with_dangling (module Simulator : Sim.SIM)
    (spec : Sim.spec) (relname : string) (filename_wasm : string) :
    wasm_program_result * DCov_single.t =
  let (module DH : Inst.Handler.HANDLER), read_coverage_dangling =
    Inst.Coverage_dangling.make ()
  in
  let program_result =
    with_instrumentation ~spec [ (module DH : Inst.Handler.HANDLER) ] (fun () ->
        run_wasm_program (module Simulator) relname filename_wasm)
  in
  let cover = read_coverage_dangling () in
  (program_result, cover)

let run_wasm_programs_with_dangling (module Simulator : Sim.SIM)
    (spec : Sim.spec) (relname : string) (filenames_wasm : string list) :
    DCov_multi.t =
  let cover_multi =
    match spec with SL spec -> DCov_multi.init spec | _ -> assert false
  in
  List.fold_left
    (fun cover_multi filename_wasm ->
      let program_result, cover_single =
        run_wasm_program_with_dangling
          (module Simulator)
          spec relname filename_wasm
      in
      let wellformed, welltyped =
        match program_result with
        | WasmPass _ | WasmUnexpectedPass _ -> (true, true)
        | WasmFail (`Syntax _) -> (false, false)
        | WasmFail (`Runtime _) | WasmExpectedFail _ -> (true, false)
      in
      DCov_multi.extend cover_multi filename_wasm wellformed welltyped
        cover_single)
    cover_multi filenames_wasm

let run_program_internal_with_dangling (module Simulator : Sim.SIM)
    (spec : Sim.spec) (relname : string) (value_program : value) :
    Sim.rel_result * DCov_single.t =
  eval_rel_with_dangling ~simulator:(module Simulator) ~spec ~root:value_program
    ~relname ~inputs:[ value_program ]

let run_program_with_dangling_and_vdg ~(derive : bool)
    (module Simulator : Sim.SIM) (spec : Sim.spec) (relname : string)
    (includes_p4 : string list) (filename_p4 : string) :
    Sim.program_result * DCov_single.t * Dep.Graph.t =
  let (module DH : Inst.Handler.HANDLER), read_coverage_dangling =
    Inst.Coverage_dangling.make ()
  in
  let (module VH : Inst.Handler.HANDLER), read_vdg =
    Inst.Value_dependency.make ~derive ~cache_on:Simulator.Cache.cache_on
      ~cache_off:Simulator.Cache.cache_off
  in
  let handlers =
    [ (module DH : Inst.Handler.HANDLER); (module VH : Inst.Handler.HANDLER) ]
  in
  Inst.Hook.register handlers;
  Inst.Hook.init_spec spec;
  let program_result =
    Simulator.Interp.eval_program relname includes_p4 filename_p4
  in
  Inst.Hook.finish ();
  let cover = read_coverage_dangling () in
  let vdg = read_vdg () in
  (program_result, cover, vdg)

let run_wasm_program_with_dangling_and_vdg ~(derive : bool)
    (module Simulator : Sim.SIM) (spec : Sim.spec) (relname : string)
    (filename_wasm : string) :
    wasm_program_result * DCov_single.t * Dep.Graph.t =
  let (module DH : Inst.Handler.HANDLER), read_coverage_dangling =
    Inst.Coverage_dangling.make ()
  in
  let (module VH : Inst.Handler.HANDLER), read_vdg =
    Inst.Value_dependency.make ~derive ~cache_on:Simulator.Cache.cache_on
      ~cache_off:Simulator.Cache.cache_off
  in
  let program_result =
    with_instrumentation ~spec
      [ (module DH : Inst.Handler.HANDLER); (module VH : Inst.Handler.HANDLER) ]
      (fun () ->
        run_wasm_program (module Simulator) relname filename_wasm)
  in
  let cover = read_coverage_dangling () in
  let vdg = read_vdg () in
  (program_result, cover, vdg)
