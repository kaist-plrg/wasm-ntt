open Domain.Lib
open Lang
open Sl
module DCov_single = Coverage.Dangling.Single
module DCov_multi = Coverage.Dangling.Multi
module Dep = Runtime.Testgen_neg.Dep
module Sim = Runtime.Sim.Signature
module Candidate = Wasm_candidate
module Episode = Wasm_episode
module Evaluator = Wasm_phase_evaluator
module Metadata = Wasm_coverage_metadata
module Phase = Wasm_phase
module Policy = Wasm_policy
module F = Format
open Util.Source

(* Timeout exception for the fuzzing loop *)

exception Timeout

(* Overview of the fuzzing loop

   (#) Pre-loop: Measure the initial coverage of the dangling nodes

   (#) Loop
      1. For each danglings that were missed:
          A. Identify close-miss paths
          B. Randomly sample N close-miss paths
          C. For each close-miss path:
              i. Run SL interpreter on the program
              ii. Fetch derivations, i.e., a set of close-ASTs for the dangling
              iii. For each close-AST:
                    (1) Mutate the close-AST
                    (2) Reassemble the program with the mutated AST
                    (3) Run the SL interpreter on the mutated program
                    (4) See if it has covered the dangling
      2. Repeat the loop until the fuel is exhausted *)

(* Check if the mutated file is interesting,
   and if so, copy it to the output directory *)

let find_interesting (config : Config.t) (cover : DCov_single.t) :
    IIdSet.t * IIdSet.t =
  DCov_multi.Cover.fold
    (fun iid (branch_fuzz : DCov_multi.Branch.t)
         (iids_hit_new, iids_close_miss_new) ->
      let branch_single = DCov_single.Cover.find iid cover in
      match (branch_single.status, branch_fuzz.status) with
      (* Hits a new dangling *)
      | Hit, Miss _ ->
          let iids_hit_new = IIdSet.add iid iids_hit_new in
          (iids_hit_new, iids_close_miss_new)
      (* Adds a new close-miss *)
      | Miss (_ :: _), Miss [] ->
          let iids_close_miss_new = IIdSet.add iid iids_close_miss_new in
          (iids_hit_new, iids_close_miss_new)
      | _ -> (iids_hit_new, iids_close_miss_new))
    config.seed.cover
    (IIdSet.empty, IIdSet.empty)

let update_hit_new' (fuel : int) (iid : iid) (idx_seed : int)
    (strategy : string) (idx_method : int) (idx_mutation : int)
    (config : Config.t) (log : Logger.t) (path_hit_p4 : string)
    (kind : Mutate.kind) (welltyped : bool) (iids_hit_new : IIdSet.t) : unit =
  F.asprintf
    "[F %d] [P %d] [S %d] [%s %d] [M %d] %s hits %s (COUNT %d) (%s) (%s)" fuel
    iid idx_seed strategy idx_method idx_mutation path_hit_p4
    (IIdSet.to_string iids_hit_new)
    (IIdSet.cardinal iids_hit_new)
    (Mutate.string_of_kind kind)
    (if IIdSet.mem iid iids_hit_new then "GOODHIT" else "BADHIT")
  |> Logger.mark config.modes.logmode log;
  let oc = open_out_gen [ Open_append; Open_text ] 0o666 path_hit_p4 in
  F.asprintf "\n// Covered iids %s\n" (IIdSet.to_string iids_hit_new)
  |> output_string oc;
  close_out oc;
  (* Update the set of covered danglings *)
  Config.update_hit_seed config path_hit_p4 welltyped iids_hit_new

let update_hit_new (fuel : int) (iid : iid) (idx_seed : int) (strategy : string)
    (idx_method : int) (idx_mutation : int) (config : Config.t) (log : Logger.t)
    (path_gen_p4 : string) (kind : Mutate.kind) (iids_hit_new : IIdSet.t) : unit
    =
  (* Re-run the SL interpreter to make sure of the new hits *)
  (* Then copy the interesting test program to the output directory
     and update the running coverage *)
  let program_result, cover =
    Runner.run_program_with_dangling config.specenv.simulator
      config.specenv.spec config.specenv.relname config.specenv.includes_p4
      path_gen_p4
  in
  match program_result with
  | Pass _ when IIdSet.for_all (DCov_single.is_hit cover) iids_hit_new ->
      let path_hit_p4 =
        Util.Filesys.cp path_gen_p4 config.storage.dirname_welltyped_p4
      in
      update_hit_new' fuel iid idx_seed strategy idx_method idx_mutation config
        log path_hit_p4 kind true iids_hit_new
  | Fail (`Runtime _)
    when IIdSet.for_all (DCov_single.is_hit cover) iids_hit_new ->
      let path_hit_p4 =
        Util.Filesys.cp path_gen_p4 config.storage.dirname_illtyped_p4
      in
      update_hit_new' fuel iid idx_seed strategy idx_method idx_mutation config
        log path_hit_p4 kind false iids_hit_new
  | _ -> ()

let update_close_miss_new' (fuel : int) (iid : iid) (idx_seed : int)
    (strategy : string) (idx_method : int) (idx_mutation : int)
    (config : Config.t) (log : Logger.t) (path_close_miss_p4 : string)
    (iids_close_miss_new : IIdSet.t) : unit =
  F.asprintf "[F %d] [P %d] [S %d] [%s %d] [M %d] %s close-misses %s" fuel iid
    idx_seed strategy idx_method idx_mutation path_close_miss_p4
    (IIdSet.to_string iids_close_miss_new)
  |> Logger.log config.modes.logmode log;
  let oc = open_out_gen [ Open_append; Open_text ] 0o666 path_close_miss_p4 in
  F.asprintf "\n// Close-missed iids %s\n"
    (IIdSet.to_string iids_close_miss_new)
  |> output_string oc;
  close_out oc;
  (* Update the set of covered danglings *)
  Config.update_close_miss_seed config path_close_miss_p4 iids_close_miss_new

let update_close_miss_new (fuel : int) (iid : iid) (idx_seed : int)
    (strategy : string) (idx_method : int) (idx_mutation : int)
    (config : Config.t) (log : Logger.t) (path_gen_p4 : string)
    (iids_close_miss_new : IIdSet.t) : unit =
  (* Re-run the SL interpreter to make sure of the new close-misses *)
  (* Then copy the interesting test program to the output directory,
     and update the running coverage *)
  (* Then copy the interesting test program to the output directory
     and update the running coverage *)
  let program_result, cover =
    Runner.run_program_with_dangling config.specenv.simulator
      config.specenv.spec config.specenv.relname config.specenv.includes_p4
      path_gen_p4
  in
  match program_result with
  | Pass _
    when IIdSet.for_all (DCov_single.is_close_miss cover) iids_close_miss_new ->
      let path_close_miss_p4 =
        Util.Filesys.cp path_gen_p4 config.storage.dirname_close_miss_p4
      in
      update_close_miss_new' fuel iid idx_seed strategy idx_method idx_mutation
        config log path_close_miss_p4 iids_close_miss_new
  | _ -> ()

let update_interesting (fuel : int) (iid : iid) (idx_seed : int)
    (strategy : string) (idx_method : int) (idx_mutation : int)
    (trials : int ref) (config : Config.t) (log : Logger.t)
    (path_gen_p4 : string) (kind : Mutate.kind) (value_program : value) : unit =
  (* Evaluate the generated program to see if it is interesting *)
  let time_start = Unix.gettimeofday () in
  F.asprintf "[F %d] [P %d] [S %d] [%s %d] [M %d] [%d/%d] Evaluating %s" fuel
    iid idx_seed strategy idx_method idx_mutation !trials Config.trials_seed
    path_gen_p4
  |> Logger.log config.modes.logmode log;
  let welltyped, cover =
    let rel_result, cover =
      Runner.run_program_internal_with_dangling config.specenv.simulator
        config.specenv.spec config.specenv.relname value_program
    in
    match rel_result with Pass _ -> (true, cover) | Fail _ -> (false, cover)
  in
  let time_end = Unix.gettimeofday () in
  F.asprintf
    "[F %d] [P %d] [S %d] [%s %d] [M %d] [%d/%d] Evaluated %s (took %.2f)" fuel
    iid idx_seed strategy idx_method idx_mutation !trials Config.trials_seed
    path_gen_p4 (time_end -. time_start)
  |> Logger.log config.modes.logmode log;
  (* Find newly hit or newly close-missing nodes *)
  let iids_hit_new, iids_close_miss_new = find_interesting config cover in
  (* Collect the file if it covers a new dangling, and update the running coverage
     If in strict mode, we only collect the file if it covers the intended dangling *)
  (match config.modes.covermode with
  | Relaxed ->
      if not (IIdSet.is_empty iids_hit_new) then
        update_hit_new fuel iid idx_seed strategy idx_method idx_mutation config
          log path_gen_p4 kind iids_hit_new
  | Strict ->
      if IIdSet.mem iid iids_hit_new then
        update_hit_new fuel iid idx_seed strategy idx_method idx_mutation config
          log path_gen_p4 kind (IIdSet.singleton iid));
  (* Collect the file if it is well-typed and covers a new close-miss dangling,
     then update the running coverage *)
  if welltyped && not (IIdSet.is_empty iids_close_miss_new) then
    update_close_miss_new fuel iid idx_seed strategy idx_method idx_mutation
      config log path_gen_p4 iids_close_miss_new

(* Mutate an AST and generate a new program *)

let classify_mutation' (fuel : int) (iid : iid) (idx_seed : int)
    (strategy : string) (idx_method : int) (idx_mutation : int)
    (trials : int ref) (config : Config.t) (log : Logger.t)
    (dirname_gen_tmp : string) (path_p4 : string) (comment_gen_p4 : string)
    (kind : Mutate.kind) (value_source : value) (value_mutated : value)
    (value_program : value) : unit =
  let path_gen_p4 =
    F.asprintf "%s/%s_F%dP%dS%d%s%dM%dT%d.p4" dirname_gen_tmp
      (Util.Filesys.base ~suffix:".p4" path_p4)
      fuel iid idx_seed
      (if strategy = "Derive" then "D"
       else if strategy = "Random" then "R"
       else "")
      idx_method idx_mutation !trials
  in
  let comment_gen_p4 =
    F.asprintf "%s\n/*\nFrom %s\nTo %s\n*/\n" comment_gen_p4
      (Sl.Print.string_of_value value_source)
      (Sl.Print.string_of_value value_mutated)
  in
  (* Write the mutated program to a file *)
  let oc = open_out path_gen_p4 in
  F.asprintf "%s\n%s\n" comment_gen_p4 (config.specenv.printer value_program)
  |> output_string oc;
  close_out oc;
  (* Check if the mutated program is interesting, and if so, update *)
  update_interesting fuel iid idx_seed strategy idx_method idx_mutation trials
    config log path_gen_p4 kind value_program

let classify_mutation (fuel : int) (iid : iid) (idx_seed : int)
    (strategy : string) (idx_method : int) (idx_mutation : int)
    (trials : int ref) (config : Config.t) (log : Logger.t)
    (dirname_gen_tmp : string) (path_p4 : string) (comment_gen_p4 : string)
    (vdg : Dep.Graph.t) (kind : Mutate.kind) (value_source : value)
    (value_mutated : value) : unit =
  (* Reassemble the program with the mutated AST *)
  let renamer = VIdMap.singleton value_source.note.vid value_mutated in
  let value_program = Dep.Graph.reassemble_graph_from_root vdg renamer in
  (* Mutation may yield a syntactically ill-formed AST, so have a try block *)
  try
    classify_mutation' fuel iid idx_seed strategy idx_method idx_mutation trials
      config log dirname_gen_tmp path_p4 comment_gen_p4 kind value_source
      value_mutated value_program
  with Util.Error.UnparseError msg ->
    Logger.warn config.modes.logmode log
      (Format.asprintf "error while printing the mutated program: %s" msg)

let fuzz_mutation (fuel : int) (iid : iid) (idx_seed : int) (strategy : string)
    (idx_method : int) (trials : int ref) (config : Config.t) (log : Logger.t)
    (query : Query.t) (dirname_gen_tmp : string) (path_p4 : string)
    (comment_gen_p4 : string) (vdg : Dep.Graph.t) (vid_source : vid) : unit =
  F.asprintf "[F %d] [P %d] [S %d] [%s %d]\n[File] %s\n" fuel iid idx_seed
    strategy idx_method path_p4
  |> Query.query query;
  (* Mutate the AST *)
  let mutations =
    Mutate.mutates Config.trials_mutation config.specenv.tdenv
      config.specenv.mixopenv vdg vid_source
  in
  (* Generate the mutated program *)
  List.iteri
    (fun idx_mutation (kind, value_source, value_mutated) ->
      if
        !trials < Config.trials_seed && DCov_multi.is_miss config.seed.cover iid
      then (
        trials := !trials + 1;
        F.asprintf "[Source] %s\n" (Sl.Print.string_of_value value_source)
        |> Query.query query;
        F.asprintf "[Mutated] [%s] %s\n"
          (Mutate.string_of_kind kind)
          (Sl.Print.string_of_value value_mutated)
        |> Query.answer query;
        let comment_gen_p4 =
          F.asprintf "%s\n// Mutation %s\n" comment_gen_p4
            (Mutate.string_of_kind kind)
        in
        classify_mutation fuel iid idx_seed strategy idx_method idx_mutation
          trials config log dirname_gen_tmp path_p4 comment_gen_p4 vdg kind
          value_source value_mutated))
    mutations

(* Fuzzing from derivations *)

let fuzz_derivations (fuel : int) (iid : iid) (idx_seed : int)
    (trials : int ref) (config : Config.t) (log : Logger.t) (query : Query.t)
    (dirname_gen_tmp : string) (path_p4 : string) (vdg : Dep.Graph.t)
    (derivations_source : (vid * int) list) : unit =
  List.iteri
    (fun idx_derivation (vid_source, depth) ->
      if
        !trials < Config.trials_seed && DCov_multi.is_miss config.seed.cover iid
      then
        let comment_gen_p4 =
          F.asprintf "// Intended iid %d\n// Source vid %d\n// Depth %d\n" iid
            vid_source depth
        in
        let strategy = "Derive" in
        fuzz_mutation fuel iid idx_seed strategy idx_derivation trials config
          log query dirname_gen_tmp path_p4 comment_gen_p4 vdg vid_source)
    derivations_source

let fuzz_derivations_bounded (fuel : int) (iid : iid) (idx_seed : int)
    (config : Config.t) (log : Logger.t) (query : Query.t)
    (dirname_gen_tmp : string) (path_p4 : string) (vdg : Dep.Graph.t)
    (derivations_source : (vid * int) list) : unit =
  if derivations_source = [] then
    F.asprintf "[F %d] [P %d] [S %d] Skipping, no derivation found" fuel iid
      idx_seed
    |> Logger.log config.modes.logmode log
  else
    let derivations_total = List.length derivations_source in
    F.asprintf
      "[F %d] [P %d] [S %d] Fuzzing from %d derivations, until %d trials" fuel
      iid idx_seed derivations_total Config.trials_seed
    |> Logger.log config.modes.logmode log;
    let trials = ref 0 in
    while
      !trials < Config.trials_seed && DCov_multi.is_miss config.seed.cover iid
    do
      fuzz_derivations fuel iid idx_seed trials config log query dirname_gen_tmp
        path_p4 vdg derivations_source
    done

(* Fuzzing from a random value id *)

let fuzz_randoms (fuel : int) (iid : iid) (idx_seed : int) (trials : int ref)
    (config : Config.t) (log : Logger.t) (query : Query.t)
    (dirname_gen_tmp : string) (path_p4 : string) (vdg : Dep.Graph.t)
    (vids_source : vid list) : unit =
  List.iteri
    (fun idx_random vid_source ->
      if
        !trials < Config.trials_seed && DCov_multi.is_miss config.seed.cover iid
      then
        let comment_gen_p4 =
          F.asprintf "// Intended iid %d\n// Source vid %d\n" iid vid_source
        in
        let strategy = "Random" in
        fuzz_mutation fuel iid idx_seed strategy idx_random trials config log
          query dirname_gen_tmp path_p4 comment_gen_p4 vdg vid_source)
    vids_source

let fuzz_randoms_bounded (fuel : int) (iid : iid) (idx_seed : int)
    (config : Config.t) (log : Logger.t) (query : Query.t)
    (dirname_gen_tmp : string) (path_p4 : string) (vdg : Dep.Graph.t)
    (vids_source : vid list) : unit =
  F.asprintf
    "[F %d] [P %d] [S %d] Fuzzing from %d random values, until %d trials" fuel
    iid idx_seed (List.length vids_source) Config.trials_seed
  |> Logger.log config.modes.logmode log;
  let trials = ref 0 in
  while
    !trials < Config.trials_seed && DCov_multi.is_miss config.seed.cover iid
  do
    fuzz_randoms fuel iid idx_seed trials config log query dirname_gen_tmp
      path_p4 vdg vids_source
  done

(* Fuzzing from a seed program *)

let fuzz_seed_random (fuel : int) (iid : iid) (idx_seed : int)
    (config : Config.t) (log : Logger.t) (query : Query.t)
    (dirname_gen_tmp : string) (path_p4 : string) (vdg : Dep.Graph.t) : unit =
  (* Randomly sample N vids from the program *)
  let vids_source =
    List.init vdg.root Fun.id
    |> List.filter (fun vid -> Dep.Graph.G.mem vdg.nodes vid)
    |> Rand.random_sample Config.samples_related_vid
  in
  (* Mutate the ASTs and dump to file *)
  fuzz_randoms_bounded fuel iid idx_seed config log query dirname_gen_tmp
    path_p4 vdg vids_source

let fuzz_seed_deriving (fuel : int) (iid : iid) (idx_seed : int)
    (config : Config.t) (log : Logger.t) (query : Query.t)
    (dirname_gen_tmp : string) (path_p4 : string) (vdg : Dep.Graph.t)
    (cover : DCov_single.t) : unit =
  (* Derive closes-ASTs from the dangling *)
  F.asprintf "[F %d] [P %d] [S %d] Finding derivations from %s" fuel iid
    idx_seed path_p4
  |> Logger.log config.modes.logmode log;
  let time_start = Unix.gettimeofday () in
  let derivations_source = Derive.derive_dangling iid vdg cover in
  let time_end = Unix.gettimeofday () in
  (* Take top ranked derivations, i.e., the ones with the smallest depth *)
  F.asprintf
    "[F %d] [P %d] [S %d] Found total %d derivations, sampling top %d (took \
     %.2f)"
    fuel iid idx_seed
    (List.length derivations_source)
    Config.samples_derivation_source (time_end -. time_start)
  |> Logger.log config.modes.logmode log;
  let derivations_source =
    if List.length derivations_source < Config.samples_derivation_source then
      derivations_source
    else
      List.init Config.samples_derivation_source (List.nth derivations_source)
  in
  (* Mutate the close-ASTs and dump to file *)
  fuzz_derivations_bounded fuel iid idx_seed config log query dirname_gen_tmp
    path_p4 vdg derivations_source

let fuzz_seed_hybrid (fuel : int) (iid : iid) (idx_seed : int)
    (config : Config.t) (log : Logger.t) (query : Query.t)
    (dirname_gen_tmp : string) (path_p4 : string) (vdg : Dep.Graph.t)
    (cover : DCov_single.t) : unit =
  (* Derive closes-ASTs from the dangling *)
  F.asprintf "[F %d] [P %d] [S %d] Finding derivations from %s" fuel iid
    idx_seed path_p4
  |> Logger.log config.modes.logmode log;
  let time_start = Unix.gettimeofday () in
  let derivations_source = Derive.derive_dangling iid vdg cover in
  let time_end = Unix.gettimeofday () in
  (* Take top ranked derivations, i.e., the ones with the smallest depth *)
  F.asprintf
    "[F %d] [P %d] [S %d] Found total %d derivations, sampling top %d (took \
     %.2f)"
    fuel iid idx_seed
    (List.length derivations_source)
    Config.samples_derivation_source (time_end -. time_start)
  |> Logger.log config.modes.logmode log;
  let derivations_source =
    if List.length derivations_source < Config.samples_derivation_source then
      derivations_source
    else
      List.init Config.samples_derivation_source (List.nth derivations_source)
  in
  (* If there are no derivations, fallback to random *)
  match derivations_source with
  | [] ->
      fuzz_seed_random fuel iid idx_seed config log query dirname_gen_tmp
        path_p4 vdg
  | _ ->
      fuzz_derivations_bounded fuel iid idx_seed config log query
        dirname_gen_tmp path_p4 vdg derivations_source

let fuzz_seed (fuel : int) (iid : iid) (idx_seed : int) (config : Config.t)
    (log : Logger.t) (query : Query.t) (dirname_gen_tmp : string)
    (path_p4 : string) : unit =
  let time_start = Unix.gettimeofday () in
  F.asprintf "[F %d] [P %d] [S %d] Running SL interpreter on %s" fuel iid
    idx_seed path_p4
  |> Logger.log config.modes.logmode log;
  (* Construct the value dependency graph for deriving and hybrid modes *)
  let derive =
    match config.modes.mutationmode with
    | Random -> false
    | Derive | Hybrid -> true
  in
  (* Run SL interpreter on the program,
     and if it is well-typed, start generating tests from it *)
  let program_result, cover, vdg =
    Runner.run_program_with_dangling_and_vdg ~derive config.specenv.simulator
      config.specenv.spec config.specenv.relname config.specenv.includes_p4
      path_p4
  in
  (match program_result with
  | Pass _ ->
      let time_end = Unix.gettimeofday () in
      F.asprintf
        "[F %d] [P %d] [S %d] SL interpreter succeeded on %s (took %.2f)" fuel
        iid idx_seed path_p4 (time_end -. time_start)
      |> Logger.log config.modes.logmode log;
      (match config.modes.mutationmode with
      | Random ->
          fuzz_seed_random fuel iid idx_seed config log query dirname_gen_tmp
            path_p4 vdg
      | Derive ->
          fuzz_seed_deriving fuel iid idx_seed config log query dirname_gen_tmp
            path_p4 vdg cover
      | Hybrid ->
          fuzz_seed_hybrid fuel iid idx_seed config log query dirname_gen_tmp
            path_p4 vdg cover);
      Dep.Graph.G.reset vdg.nodes;
      Dep.Graph.G.reset vdg.edges
  | Fail _ ->
      F.asprintf "[F %d] [P %d] [S %d] SL interpreter failed on %s" fuel iid
        idx_seed path_p4
      |> Logger.log config.modes.logmode log);
  let total, hits, coverage = DCov_multi.measure_coverage config.seed.cover in
  F.asprintf "[F %d] [P %d] [S %d] Coverage %d/%d (%.2f%%)" fuel iid idx_seed
    hits total coverage
  |> Logger.log config.modes.logmode log

let fuzz_seeds (fuel : int) (iid : iid) (config : Config.t) (log : Logger.t)
    (query : Query.t) (dirname_gen_tmp : string) (paths_p4 : string list) : unit
    =
  (* Fuzz from seed programs until the target dangling node is covered *)
  List.iteri
    (fun idx_seed path_p4 ->
      if DCov_multi.is_miss config.seed.cover iid then (
        let _ =
          Sys.set_signal Sys.sigalrm
            (Sys.Signal_handle (fun _ -> raise Timeout))
        in
        Unix.alarm Config.timeout_seed |> ignore;
        (try
           fuzz_seed fuel iid idx_seed config log query dirname_gen_tmp path_p4
         with Timeout ->
           F.asprintf "[F %d] [S %d] [P %d] Timeout on %s" fuel iid idx_seed
             path_p4
           |> Logger.warn config.modes.logmode log);
        Unix.alarm 0 |> ignore))
    paths_p4

(* Fuzzing from a target dangling node *)

let fuzz_dangling (fuel : int) (iid : iid) (config : Config.t) (log : Logger.t)
    (query : Query.t) (paths_p4 : string list) : unit =
  F.asprintf "[F %d] [P %d] Targeting dangling %d" fuel iid iid
  |> Logger.log config.modes.logmode log;
  (* Create a directory for the generated programs *)
  let dirname_gen_tmp =
    config.storage.dirname_gen ^ "/fuel" ^ string_of_int fuel ^ "dangling"
    ^ string_of_int iid
  in
  Util.Filesys.mkdir dirname_gen_tmp;
  (* Randomly sample N close-miss paths *)
  let paths_p4 = Rand.random_sample Config.samples_close_miss paths_p4 in
  (* Generate tests from the files *)
  (try fuzz_seeds fuel iid config log query dirname_gen_tmp paths_p4
   with _ as err ->
     F.asprintf "[F %d] [P %d] Unexpected error occurred : %s" fuel iid
       (Printexc.to_string err)
     |> Logger.warn config.modes.logmode log);
  (* Remove the directory for the generated programs *)
  Util.Filesys.rmdir dirname_gen_tmp

let fuzz_danglings (fuel : int) (config : Config.t) (log : Logger.t)
    (query : Query.t) : unit =
  let iids = DCov_multi.Cover.dom config.seed.cover in
  IIdSet.iter
    (fun iid ->
      let branch = DCov_multi.Cover.find iid config.seed.cover in
      match branch.status with
      | Hit _ -> ()
      | Miss [] -> ()
      | Miss paths_p4 -> fuzz_dangling fuel iid config log query paths_p4)
    iids

(* Fuzzing in a loop with fuel *)

let rec fuzz_loop (fuel : int) (config : Config.t) : Config.t =
  if fuel = 0 then config
  else
    (* Create a log for the current fuel *)
    let logname = F.asprintf "%s/fuel%d.log" config.storage.dirname_log fuel in
    let log = Logger.init logname in
    (* Create q query for the current fuel *)
    let queryname =
      F.asprintf "%s/fuel%d.query" config.storage.dirname_query fuel
    in
    let query = Query.init queryname in
    (* Fuzz single iteration *)
    F.asprintf "[F %d] Start fuzzing loop" fuel
    |> Logger.log config.modes.logmode log;
    fuzz_danglings fuel config log query;
    let total, hits, coverage = DCov_multi.measure_coverage config.seed.cover in
    F.asprintf "[F %d] End fuzzing loop with coverage %d/%d (%.2f%%)" fuel hits
      total coverage
    |> Logger.log config.modes.logmode log;
    (* Close the logger *)
    Logger.close log;
    (* Close the query *)
    Query.close query;
    (* Proceed to the next fuel level *)
    fuzz_loop (fuel - 1) config

(* Entry point to main fuzzing loop *)

let fuzzer_init (spec : spec) (relname : string) (includes_p4 : string list)
    (dirname_gen : string) (name_campaign : string option)
    (randseed : int option) (logmode : Modes.logmode)
    (bootmode : Modes.bootmode) (mutationmode : Modes.mutationmode)
    (covermode : Modes.covermode) : Config.t =
  (* Name the campaign *)
  let name_campaign =
    match name_campaign with
    | Some name_campaign -> name_campaign
    | None ->
        let timestamp =
          let tm = Unix.gettimeofday () |> Unix.localtime in
          F.asprintf "%04d-%02d-%02d-%02d-%02d-%02d" (tm.Unix.tm_year + 1900)
            (tm.Unix.tm_mon + 1) tm.Unix.tm_mday tm.Unix.tm_hour tm.Unix.tm_min
            tm.Unix.tm_sec
        in
        "fuzz-" ^ timestamp
  in
  (* Create directories for storage *)
  let dirname_gen = dirname_gen ^ "/" ^ name_campaign in
  let storage = Config.init_storage dirname_gen in
  (* Create a mode *)
  let modes = Modes.{ bootmode; logmode; mutationmode; covermode } in
  (* Create a initializer log *)
  let logname_init = storage.dirname_log ^ "/init.log" in
  let log_init = Logger.init logname_init in
  (* Log the command line arguments *)
  F.asprintf "[COMMAND] testgen -gen %s%s%s%s" dirname_gen
    (match modes.bootmode with
    | Cold (excludes_p4, dirname_seed_p4) ->
        "-e" ^ String.concat " " excludes_p4 ^ "-cold " ^ dirname_seed_p4
    | Warm path_boot -> " -warm " ^ path_boot)
    (match modes.mutationmode with
    | Random -> " -random"
    | Derive -> ""
    | Hybrid -> " -hybrid")
    (match modes.covermode with Strict -> " -strict" | Relaxed -> "")
  |> Logger.log modes.logmode log_init;
  (* Create a spec environment *)
  "Loading type definitions from the spec file"
  |> Logger.log modes.logmode log_init;
  let specenv = Config.init_specenv spec relname includes_p4 in
  (* Create a seed *)
  "Booting initial coverage" |> Logger.log modes.logmode log_init;
  let cover_seed =
    match modes.bootmode with
    | Cold (excludes_p4, dirname_seed_p4) ->
        let cover_seed =
          Boot.boot_cold specenv.simulator specenv.spec relname includes_p4
            excludes_p4 dirname_seed_p4
        in
        (* Log the initial coverage for later use in warm boot *)
        let path_cov = dirname_gen ^ "/boot.coverage" in
        DCov_multi.log ~path_cov_opt:(Some path_cov) cover_seed;
        cover_seed
    | Warm path_boot -> Boot.boot_warm path_boot
  in
  let seed = Config.init_seed cover_seed in
  (* Close the initial log *)
  let total, hits, coverage = DCov_multi.measure_coverage cover_seed in
  F.asprintf "Finished booting with initial coverage %d/%d (%.2f%%)" hits total
    coverage
  |> Logger.log modes.logmode log_init;
  F.asprintf
    "[SAMPLES_CLOSE_MISS] %d [SAMPLES_RELATED_VID] %d \
     [SAMPLES_DERIVATION_SOURCE] %d [TRIALS_MUTATION] %d [TRIALS_SEED] %d \
     [TIMEOUT_SEED] %d"
    Config.samples_close_miss Config.samples_related_vid
    Config.samples_derivation_source Config.trials_mutation Config.trials_seed
    Config.timeout_seed
  |> Logger.log modes.logmode log_init;
  Logger.close log_init;
  (* Create a configuration *)
  let config = Config.init randseed modes specenv storage seed in
  config

let fuzzer (fuel : int) (spec : spec) (relname : string)
    (includes_p4 : string list) (dirname_gen : string)
    (name_campaign : string option) (randseed : int option)
    (logmode : Modes.logmode) (bootmode : Modes.bootmode)
    (mutationmode : Modes.mutationmode) (covermode : Modes.covermode) : unit =
  (* Initialize the fuzzing configuration *)
  let config =
    fuzzer_init spec relname includes_p4 dirname_gen name_campaign randseed
      logmode bootmode mutationmode covermode
  in
  (* Call the main fuzzing loop *)
  let config = fuzz_loop fuel config in
  (* Log the final coverage *)
  let path_cov = config.storage.dirname_gen ^ "/final.coverage" in
  DCov_multi.log ~path_cov_opt:(Some path_cov) config.seed.cover

(* Wasm fuzzing pipeline *)

let find_interestingw (config : Config.tw) (cover : DCov_single.t) :
    IIdSet.t * IIdSet.t =
  DCov_multi.Cover.fold
    (fun iid (branch_fuzz : DCov_multi.Branch.t)
         (iids_hit_new, iids_close_miss_new) ->
      let branch_single = DCov_single.Cover.find iid cover in
      match (branch_single.status, branch_fuzz.status) with
      | Hit, Miss _ ->
          (IIdSet.add iid iids_hit_new, iids_close_miss_new)
      | Miss (_ :: _), Miss [] ->
          (iids_hit_new, IIdSet.add iid iids_close_miss_new)
      | _ -> (iids_hit_new, iids_close_miss_new))
    config.seed.cover
    (IIdSet.empty, IIdSet.empty)

exception Focus_timeout

let phase_error_message = Boot.string_of_phase_error

let log_candidate_error (config : Config.tw) (log : Logger.t) prefix error =
  F.asprintf "%s: %s" prefix (phase_error_message error)
  |> Logger.warn config.modes.logmode log

let path_in_directory directory source =
  F.asprintf "%s/%s.wast" directory
    (Util.Filesys.base ~suffix:".wast" source)

let log_hit_neww (fuel : int) (iid : iid) (idx_seed : int)
    (strategy : string) (idx_method : int) (idx_mutation : int)
    (config : Config.tw) (log : Logger.t) (path_hit_wasm : string)
    (kind : Mutate.kind) (iids_hit_new : IIdSet.t) : unit =
  F.asprintf
    "[F %d] [P %d] [S %d] [%s %d] [M %d] %s hits %s (COUNT %d) (%s) (%s)" fuel
    iid idx_seed strategy idx_method idx_mutation path_hit_wasm
    (IIdSet.to_string iids_hit_new)
    (IIdSet.cardinal iids_hit_new)
    (Mutate.string_of_kind kind)
    (if IIdSet.mem iid iids_hit_new then "GOODHIT" else "BADHIT")
  |> Logger.mark config.modes.logmode log

let log_close_miss_neww (fuel : int) (iid : iid) (idx_seed : int)
    (strategy : string) (idx_method : int) (idx_mutation : int)
    (config : Config.tw) (log : Logger.t) (path_close_miss_wasm : string)
    (iids_close_miss_new : IIdSet.t) : unit =
  F.asprintf "[F %d] [P %d] [S %d] [%s %d] [M %d] %s close-misses %s" fuel iid
    idx_seed strategy idx_method idx_mutation path_close_miss_wasm
    (IIdSet.to_string iids_close_miss_new)
  |> Logger.log config.modes.logmode log

let save_artifacts_transactionally ~copy_artifact ~temporary_path
    ~destinations ?(rollback = fun () -> ()) commit =
  let committed = ref false in
  let cleanup path = ignore (Episode.remove_artifact path) in
  Fun.protect
    ~finally:(fun () ->
      cleanup temporary_path;
      if not !committed then
        Fun.protect
          ~finally:(fun () -> List.iter cleanup destinations)
          rollback)
    (fun () ->
      let rec copy = function
        | [] -> Ok ()
        | destination :: rest -> (
            match copy_artifact ~src_wast:temporary_path ~dst_wast:destination with
            | Ok () -> copy rest
            | Error _ as failure -> failure)
      in
      match copy destinations with
      | Error _ as failure -> failure
      | Ok () -> (
          match commit () with
          | Error _ as failure -> failure
          | Ok result ->
              committed := true;
              Ok result))

let save_verified_artifact (config : Config.tw)
    (temporary_path : string) (category : Policy.output_category)
    (policy : DCov_multi.extension_policy) (iids_hit : IIdSet.t)
    (iids_close_miss : IIdSet.t) =
  let main_path =
    if IIdSet.is_empty iids_hit then None
    else
      let directory = Config.directory_for_output_category config.storage category in
      Some (path_in_directory directory temporary_path)
  in
  let close_path =
    if IIdSet.is_empty iids_close_miss then None
    else
      Some
        (path_in_directory config.storage.dirname_close_miss_p4
           temporary_path)
  in
  let destinations = List.filter_map Fun.id [ main_path; close_path ] in
  let cover_before = config.seed.cover in
  save_artifacts_transactionally ~copy_artifact:Episode.copy_artifact
    ~temporary_path ~destinations
    ~rollback:(fun () -> config.seed.cover <- cover_before)
    (fun () ->
      let cover =
        match main_path with
        | None -> cover_before
        | Some path ->
            DCov_multi.extend_selected_with_policy cover_before path policy
              ~hits:iids_hit ~close_misses:IIdSet.empty
      in
      let cover =
        match close_path with
        | None -> cover
        | Some path ->
            DCov_multi.extend_selected_with_policy cover path policy
              ~hits:IIdSet.empty ~close_misses:iids_close_miss
      in
      config.seed.cover <- cover;
      Ok (main_path, close_path))

let update_interestingw (fuel : int) (iid : iid) (idx_seed : int)
    (strategy : string) (idx_method : int) (idx_mutation : int)
    (trials : int ref) (config : Config.tw) (log : Logger.t)
    (path_gen_wasm : string) (kind : Mutate.kind) (seed : Candidate.seed)
    (mutated_module : value) : unit =
  let time_start = Unix.gettimeofday () in
  F.asprintf "[F %d] [P %d] [S %d] [%s %d] [M %d] [%d/%d] Evaluating %s" fuel
    iid idx_seed strategy idx_method idx_mutation !trials Config.trials_seed
    path_gen_wasm
  |> Logger.log config.modes.logmode log;
  let env =
    Evaluator.make_env ~simulator:config.specenv.simulator
      ~spec:config.specenv.spec
  in
  let evaluated = Candidate.evaluate env seed mutated_module in
  let time_end = Unix.gettimeofday () in
  F.asprintf
    "[F %d] [P %d] [S %d] [%s %d] [M %d] [%d/%d] Evaluated %s (took %.2f)" fuel
    iid idx_seed strategy idx_method idx_mutation !trials Config.trials_seed
    path_gen_wasm (time_end -. time_start)
  |> Logger.log config.modes.logmode log;
  match evaluated with
  | Error error ->
      log_candidate_error config log
        (F.asprintf "[F %d] [P %d] candidate phase evaluation failed" fuel iid)
        error
  | Ok observation -> (
      match
        observation.Candidate.policy.coverage,
        observation.Candidate.emission,
        observation.Candidate.coverage,
        observation.Candidate.category
      with
      | None, Policy.DiagnosticOnly, _, _ ->
          F.asprintf
            "[F %d] [P %d] [S %d] candidate is diagnostic-only; no artifact"
            fuel iid idx_seed
          |> Logger.warn config.modes.logmode log
      | Some policy, Policy.MainArtifact category, Some cover, Some category'
        when category = category' ->
          let iids_hit_new, iids_close_miss_new =
            find_interestingw config cover
          in
          let iids_hit_new =
            Candidate.select_hits ~covermode:config.modes.covermode
              ~intended:iid iids_hit_new
          in
          let iids_close_miss_new =
            if policy.record_close_misses then iids_close_miss_new
            else IIdSet.empty
          in
          if
            not
              (IIdSet.is_empty iids_hit_new
              && IIdSet.is_empty iids_close_miss_new)
          then
            Fun.protect
              ~finally:(fun () ->
                ignore (Episode.remove_artifact path_gen_wasm))
              (fun () ->
                match
                  Candidate.render_and_recheck ~env ~seed ~mutated_module
                    ~observation ~temporary_path:path_gen_wasm
                    ~selected_hits:iids_hit_new
                    ~selected_close_misses:iids_close_miss_new
                with
                | Error error ->
                    log_candidate_error config log
                      (F.asprintf
                         "[F %d] [P %d] rendered candidate recheck failed" fuel
                         iid)
                      error
                | Ok verified -> (
                    match
                      save_verified_artifact config path_gen_wasm
                        verified.Candidate.category policy iids_hit_new
                        iids_close_miss_new
                    with
                    | Error error ->
                        log_candidate_error config log
                          (F.asprintf
                             "[F %d] [P %d] candidate artifact save failed"
                             fuel iid)
                          error
                    | Ok (main_path, close_path) ->
                        Option.iter
                          (fun path ->
                            log_hit_neww fuel iid idx_seed strategy idx_method
                              idx_mutation config log path kind iids_hit_new)
                          main_path;
                        Option.iter
                          (fun path ->
                            log_close_miss_neww fuel iid idx_seed strategy
                              idx_method idx_mutation config log path
                              iids_close_miss_new)
                          close_path))
      | _ ->
          F.asprintf
            "[F %d] [P %d] candidate policy, category, and coverage disagreed"
            fuel iid
          |> Logger.warn config.modes.logmode log)

let classify_mutationw' (fuel : int) (iid : iid) (idx_seed : int)
    (strategy : string) (idx_method : int) (idx_mutation : int)
    (trials : int ref) (config : Config.tw) (log : Logger.t)
    (dirname_gen_tmp : string) (path_wasm : string)
    (_comment_gen_wasm : string) (kind : Mutate.kind) (_value_source : value)
    (_value_mutated : value) (seed : Candidate.seed) (mutated_module : value) :
    unit =
  let path_gen_wasm =
    F.asprintf "%s/%s_F%dP%dS%d%s%dM%dT%d.wast" dirname_gen_tmp
      (Util.Filesys.base ~suffix:".wast" path_wasm)
      fuel iid idx_seed
      (if strategy = "Derive" then "D"
       else if strategy = "Random" then "R"
       else "")
      idx_method idx_mutation !trials
  in
  update_interestingw fuel iid idx_seed strategy idx_method idx_mutation trials
    config log path_gen_wasm kind seed mutated_module

let classify_mutationw (fuel : int) (iid : iid) (idx_seed : int)
    (strategy : string) (idx_method : int) (idx_mutation : int)
    (trials : int ref) (config : Config.tw) (log : Logger.t)
    (dirname_gen_tmp : string) (path_wasm : string)
    (comment_gen_wasm : string) (vdg : Dep.Graph.t) (kind : Mutate.kind)
    (value_source : value) (value_mutated : value) (seed : Candidate.seed) :
    unit =
  let value_program_before =
    Dep.Graph.reassemble_graph_from_root vdg VIdMap.empty
  in
  let renamer = VIdMap.singleton value_source.note.vid value_mutated in
  let value_program = Dep.Graph.reassemble_graph_from_root vdg renamer in
  match Candidate.single_module_of_root value_program with
  | Error error ->
      log_candidate_error config log
        (F.asprintf
           "[F %d] [P %d] [S %d] [%s %d] [M %d] candidate shape rejected"
           fuel iid idx_seed strategy idx_method idx_mutation)
        error
  | Ok mutated_module ->
    try
      classify_mutationw' fuel iid idx_seed strategy idx_method idx_mutation
        trials config log dirname_gen_tmp path_wasm comment_gen_wasm kind
        value_source value_mutated seed mutated_module
    with err ->
      Logger.warn config.modes.logmode log
        (F.asprintf
           "[F %d] [P %d] [S %d] [%s %d] [M %d] unexpected exception in \
            classify_mutationw: %s\n[Kind] %s\n[Source] %s\n[Mutated] \
            %s\n[IL Before Mutation]\n%s\n[IL After Mutation]\n%s"
           fuel iid idx_seed strategy idx_method idx_mutation
           (Printexc.to_string err)
           (Mutate.string_of_kind kind)
           (Sl.Print.string_of_value value_source)
           (Sl.Print.string_of_value value_mutated)
           (Lang.Il.Print.string_of_value value_program_before)
           (Lang.Il.Print.string_of_value value_program));
      raise err

let fuzz_mutationw (fuel : int) (iid : iid) (idx_seed : int)
    (strategy : string) (idx_method : int) (trials : int ref)
    (config : Config.tw) (log : Logger.t) (query : Query.t)
    (dirname_gen_tmp : string) (path_wasm : string)
    (comment_gen_wasm : string) (vdg : Dep.Graph.t) (seed : Candidate.seed)
    (vid_source : vid) : unit =
  F.asprintf "[F %d] [P %d] [S %d] [%s %d]\n[File] %s\n" fuel iid idx_seed
    strategy idx_method path_wasm
  |> Query.query query;
  let mutations =
    try
      Mutate.mutatesw Config.trials_mutation config.specenv.tdenv
        config.specenv.mixopenv vdg vid_source
    with
    | Z.Overflow ->
        F.asprintf
          "[F %d] [P %d] [S %d] [%s %d] mutation source %d overflowed integer conversion"
          fuel iid idx_seed strategy idx_method vid_source
        |> Logger.warn config.modes.logmode log;
        []
    | Util.Error.RuntimeError (_, message) ->
        F.asprintf
          "[F %d] [P %d] [S %d] [%s %d] mutation source %d was rejected: %s"
          fuel iid idx_seed strategy idx_method vid_source message
        |> Logger.warn config.modes.logmode log;
        []
  in
  List.iteri
    (fun idx_mutation (kind, value_source, value_mutated) ->
      if
        !trials < Config.trials_seed && DCov_multi.is_miss config.seed.cover iid
      then (
        trials := !trials + 1;
        F.asprintf "[Source] %s\n" (Sl.Print.string_of_value value_source)
        |> Query.query query;
        F.asprintf "[Mutated] [%s] %s\n"
          (Mutate.string_of_kind kind)
          (Sl.Print.string_of_value value_mutated)
        |> Query.answer query;
        let comment_gen_wasm =
          F.asprintf "%s\n;; Mutation %s\n" comment_gen_wasm
            (Mutate.string_of_kind kind)
        in
        classify_mutationw fuel iid idx_seed strategy idx_method idx_mutation
          trials config log dirname_gen_tmp path_wasm comment_gen_wasm vdg kind
          value_source value_mutated seed))
    mutations

let fuzz_derivationsw (fuel : int) (iid : iid) (idx_seed : int)
    (trials : int ref) (config : Config.tw) (log : Logger.t)
    (query : Query.t) (dirname_gen_tmp : string) (path_wasm : string)
    (vdg : Dep.Graph.t) (seed : Candidate.seed)
    (derivations_source : (vid * int) list) : unit =
  List.iteri
    (fun idx_derivation (vid_source, depth) ->
      if
        !trials < Config.trials_seed && DCov_multi.is_miss config.seed.cover iid
      then
        let comment_gen_wasm =
          F.asprintf ";; Intended iid %d\n;; Source vid %d\n;; Depth %d\n" iid
            vid_source depth
        in
        fuzz_mutationw fuel iid idx_seed "Derive" idx_derivation trials config
          log query dirname_gen_tmp path_wasm comment_gen_wasm vdg seed
          vid_source)
    derivations_source

let fuzz_derivations_boundedw (fuel : int) (iid : iid) (idx_seed : int)
    (config : Config.tw) (log : Logger.t) (query : Query.t)
    (dirname_gen_tmp : string) (path_wasm : string) (vdg : Dep.Graph.t)
    (seed : Candidate.seed) (derivations_source : (vid * int) list) : unit =
  if derivations_source = [] then
    F.asprintf "[F %d] [P %d] [S %d] Skipping, no derivation found" fuel iid
      idx_seed
    |> Logger.log config.modes.logmode log
  else
    let derivations_total = List.length derivations_source in
    F.asprintf
      "[F %d] [P %d] [S %d] Fuzzing from %d derivations, until %d trials" fuel
      iid idx_seed derivations_total Config.trials_seed
    |> Logger.log config.modes.logmode log;
    let trials = ref 0 in
    while
      !trials < Config.trials_seed && DCov_multi.is_miss config.seed.cover iid
    do
      fuzz_derivationsw fuel iid idx_seed trials config log query
        dirname_gen_tmp path_wasm vdg seed derivations_source
    done

let fuzz_randomsw (fuel : int) (iid : iid) (idx_seed : int)
    (trials : int ref) (config : Config.tw) (log : Logger.t)
    (query : Query.t) (dirname_gen_tmp : string) (path_wasm : string)
    (vdg : Dep.Graph.t) (seed : Candidate.seed) (vids_source : vid list) : unit =
  List.iteri
    (fun idx_random vid_source ->
      if
        !trials < Config.trials_seed && DCov_multi.is_miss config.seed.cover iid
      then
        let comment_gen_wasm =
          F.asprintf ";; Intended iid %d\n;; Source vid %d\n" iid vid_source
        in
        fuzz_mutationw fuel iid idx_seed "Random" idx_random trials config log
          query dirname_gen_tmp path_wasm comment_gen_wasm vdg seed vid_source)
    vids_source

let fuzz_randoms_boundedw (fuel : int) (iid : iid) (idx_seed : int)
    (config : Config.tw) (log : Logger.t) (query : Query.t)
    (dirname_gen_tmp : string) (path_wasm : string) (vdg : Dep.Graph.t)
    (seed : Candidate.seed) (vids_source : vid list) : unit =
  if vids_source = [] then
    F.asprintf "[F %d] [P %d] [S %d] Skipping, no allowed random source" fuel
      iid idx_seed
    |> Logger.log config.modes.logmode log
  else (
    F.asprintf
      "[F %d] [P %d] [S %d] Fuzzing from %d random values, until %d trials"
      fuel iid idx_seed (List.length vids_source) Config.trials_seed
    |> Logger.log config.modes.logmode log;
    let trials = ref 0 in
    while
      !trials < Config.trials_seed && DCov_multi.is_miss config.seed.cover iid
    do
      fuzz_randomsw fuel iid idx_seed trials config log query dirname_gen_tmp
        path_wasm vdg seed vids_source
    done)

let fuzz_seed_randomw (fuel : int) (iid : iid) (idx_seed : int)
    (config : Config.tw) (log : Logger.t) (query : Query.t)
    (dirname_gen_tmp : string) (path_wasm : string) (vdg : Dep.Graph.t)
    (seed : Candidate.seed) (sources : VIdSet.t) : unit =
  let vids_source =
    Candidate.random_source_vids ~limit:Config.samples_related_vid sources
  in
  fuzz_randoms_boundedw fuel iid idx_seed config log query dirname_gen_tmp
    path_wasm vdg seed vids_source

let fuzz_seed_derivingw (fuel : int) (iid : iid) (idx_seed : int)
    (config : Config.tw) (log : Logger.t) (query : Query.t)
    (dirname_gen_tmp : string) (path_wasm : string) (vdg : Dep.Graph.t)
    (seed : Candidate.seed) (sources : VIdSet.t) (cover : DCov_single.t) : unit =
  F.asprintf "[F %d] [P %d] [S %d] Finding derivations from %s" fuel iid
    idx_seed path_wasm
  |> Logger.log config.modes.logmode log;
  let time_start = Unix.gettimeofday () in
  let derivations_source =
    Derive.derive_dangling iid vdg cover
    |> Candidate.filter_derivations sources
  in
  let time_end = Unix.gettimeofday () in
  F.asprintf
    "[F %d] [P %d] [S %d] Found total %d derivations, sampling top %d (took \
     %.2f)"
    fuel iid idx_seed
    (List.length derivations_source)
    Config.samples_derivation_source (time_end -. time_start)
  |> Logger.log config.modes.logmode log;
  let derivations_source =
    if List.length derivations_source < Config.samples_derivation_source then
      derivations_source
    else
      List.init Config.samples_derivation_source (List.nth derivations_source)
  in
  fuzz_derivations_boundedw fuel iid idx_seed config log query dirname_gen_tmp
    path_wasm vdg seed derivations_source

let fuzz_seed_hybridw (fuel : int) (iid : iid) (idx_seed : int)
    (config : Config.tw) (log : Logger.t) (query : Query.t)
    (dirname_gen_tmp : string) (path_wasm : string) (vdg : Dep.Graph.t)
    (seed : Candidate.seed) (sources : VIdSet.t) (cover : DCov_single.t) : unit =
  F.asprintf "[F %d] [P %d] [S %d] Finding derivations from %s" fuel iid
    idx_seed path_wasm
  |> Logger.log config.modes.logmode log;
  let time_start = Unix.gettimeofday () in
  let derivations_source =
    Derive.derive_dangling iid vdg cover
    |> Candidate.filter_derivations sources
  in
  let time_end = Unix.gettimeofday () in
  F.asprintf
    "[F %d] [P %d] [S %d] Found total %d derivations, sampling top %d (took \
     %.2f)"
    fuel iid idx_seed
    (List.length derivations_source)
    Config.samples_derivation_source (time_end -. time_start)
  |> Logger.log config.modes.logmode log;
  let derivations_source =
    if List.length derivations_source < Config.samples_derivation_source then
      derivations_source
    else
      List.init Config.samples_derivation_source (List.nth derivations_source)
  in
  match derivations_source with
  | [] ->
      fuzz_seed_randomw fuel iid idx_seed config log query dirname_gen_tmp
        path_wasm vdg seed sources
  | _ ->
      fuzz_derivations_boundedw fuel iid idx_seed config log query
        dirname_gen_tmp path_wasm vdg seed derivations_source

let fuzz_seedw (fuel : int) (iid : iid) (idx_seed : int) (config : Config.tw)
    (log : Logger.t) (query : Query.t) (dirname_gen_tmp : string)
    (path_wasm : string) : unit =
  let time_start = Unix.gettimeofday () in
  F.asprintf "[F %d] [P %d] [S %d] Running SL interpreter on %s" fuel iid
    idx_seed path_wasm
  |> Logger.log config.modes.logmode log;
  let derive =
    match config.modes.mutationmode with
    | Random -> false
    | Derive | Hybrid -> true
  in
  let env =
    Evaluator.make_env ~simulator:config.specenv.simulator
      ~spec:config.specenv.spec
  in
  (match
     Candidate.load_seed_with_vdg ~derive ~env ~phase:config.specenv.phase
       path_wasm
   with
  | Error error ->
      log_candidate_error config log
        (F.asprintf "[F %d] [P %d] [S %d] typed seed load failed" fuel iid
           idx_seed)
        error
  | Ok (Candidate.Diagnostic category) ->
      F.asprintf "[F %d] [P %d] [S %d] Skipping typed seed: %s" fuel iid
        idx_seed category
      |> Logger.warn config.modes.logmode log
  | Ok (Candidate.Reusable loaded) ->
      let time_end = Unix.gettimeofday () in
      F.asprintf
        "[F %d] [P %d] [S %d] typed phase evaluator admitted %s (took %.2f)"
        fuel iid idx_seed path_wasm (time_end -. time_start)
      |> Logger.log config.modes.logmode log;
      Fun.protect
        ~finally:(fun () ->
          Dep.Graph.G.reset loaded.graph.nodes;
          Dep.Graph.G.reset loaded.graph.edges)
        (fun () ->
          match config.modes.mutationmode with
          | Random ->
              fuzz_seed_randomw fuel iid idx_seed config log query
                dirname_gen_tmp path_wasm loaded.graph loaded.seed
                loaded.sources
          | Derive ->
              fuzz_seed_derivingw fuel iid idx_seed config log query
                dirname_gen_tmp path_wasm loaded.graph loaded.seed
                loaded.sources loaded.coverage
          | Hybrid ->
              fuzz_seed_hybridw fuel iid idx_seed config log query
                dirname_gen_tmp path_wasm loaded.graph loaded.seed
                loaded.sources loaded.coverage));
  let total, hits, coverage = DCov_multi.measure_coverage config.seed.cover in
  F.asprintf "[F %d] [P %d] [S %d] Coverage %d/%d (%.2f%%)" fuel iid idx_seed
    hits total coverage
  |> Logger.log config.modes.logmode log

let fuzz_seedsw ?(deadline : float option) (fuel : int) (iid : iid)
    (config : Config.tw) (log : Logger.t) (query : Query.t)
    (dirname_gen_tmp : string) (paths_wasm : string list) : unit =
  List.iteri
    (fun idx_seed path_wasm ->
      if DCov_multi.is_miss config.seed.cover iid then (
        let timeout_seed =
          match deadline with
          | None -> Config.timeout_seed
          | Some deadline ->
              let remaining = deadline -. Unix.gettimeofday () in
              if remaining <= 0.0 then raise Focus_timeout;
              min Config.timeout_seed
                (max 1 (remaining |> ceil |> int_of_float))
        in
        let signal_previous =
          Sys.signal Sys.sigalrm
            (Sys.Signal_handle (fun _ ->
                 match deadline with
                 | None -> raise Timeout
                 | Some _ -> raise Focus_timeout))
        in
        Fun.protect
          ~finally:(fun () ->
            Unix.alarm 0 |> ignore;
            Sys.set_signal Sys.sigalrm signal_previous)
          (fun () ->
            Unix.alarm timeout_seed |> ignore;
            try
              fuzz_seedw fuel iid idx_seed config log query dirname_gen_tmp
                path_wasm
            with Timeout ->
              F.asprintf "[F %d] [S %d] [P %d] Timeout on %s" fuel iid idx_seed
                path_wasm
              |> Logger.warn config.modes.logmode log)))
    paths_wasm

let fuzz_danglingw ?(deadline : float option) (fuel : int) (iid : iid)
    (config : Config.tw) (log : Logger.t) (query : Query.t)
    (paths_wasm : string list) : unit =
  F.asprintf "[F %d] [P %d] Targeting dangling %d" fuel iid iid
  |> Logger.log config.modes.logmode log;
  let dirname_gen_tmp =
    config.storage.dirname_gen ^ "/fuel" ^ string_of_int fuel ^ "dangling"
    ^ string_of_int iid
  in
  Util.Filesys.mkdir dirname_gen_tmp;
  let paths_wasm =
    match config.focus with
    | Some focus when focus.iid = iid ->
        F.asprintf "[F %d] [P %d] Focus mode using seed %s" fuel iid
          focus.filename_wasm
        |> Logger.log config.modes.logmode log;
        [ focus.filename_wasm ]
    | _ -> Rand.random_sample Config.samples_close_miss paths_wasm
  in
  Fun.protect
    ~finally:(fun () -> Util.Filesys.rmdirw dirname_gen_tmp)
    (fun () ->
      try
        fuzz_seedsw ?deadline fuel iid config log query dirname_gen_tmp
          paths_wasm
      with
      | Focus_timeout as err -> raise err
      | err ->
          F.asprintf "[F %d] [P %d] Unexpected error occurred : %s" fuel iid
            (Printexc.to_string err)
          |> Logger.warn config.modes.logmode log)

let fuzz_danglingsw ?(deadline : float option) (fuel : int)
    (config : Config.tw) (log : Logger.t) (query : Query.t) : unit =
  match config.focus with
  | Some focus -> (
      match DCov_multi.Cover.find_opt focus.iid config.seed.cover with
      | None ->
          F.asprintf "[F %d] [P %d] Focus target is not in seed coverage" fuel
            focus.iid
          |> Logger.warn config.modes.logmode log
      | Some branch -> (
          match branch.status with
          | Hit _ ->
              F.asprintf "[F %d] [P %d] Focus target is already hit" fuel
                focus.iid
              |> Logger.log config.modes.logmode log
          | Miss _ ->
              fuzz_danglingw ?deadline fuel focus.iid config log query
                [ focus.filename_wasm ]))
  | None ->
      let iids = DCov_multi.Cover.dom config.seed.cover in
      IIdSet.iter
        (fun iid ->
          let branch = DCov_multi.Cover.find iid config.seed.cover in
          match branch.status with
          | Hit _ -> ()
          | Miss [] -> ()
          | Miss paths_wasm ->
              fuzz_danglingw ?deadline fuel iid config log query paths_wasm)
        iids

let fuzz_loopw_once ?(deadline : float option) (fuel : int)
    (config : Config.tw) : unit =
  let logname = F.asprintf "%s/fuel%d.log" config.storage.dirname_log fuel in
  let log = Logger.init logname in
  let queryname =
    F.asprintf "%s/fuel%d.query" config.storage.dirname_query fuel
  in
  let query = Query.init queryname in
  Fun.protect
    ~finally:(fun () ->
      Logger.close log;
      Query.close query)
    (fun () ->
      F.asprintf "[F %d] Start fuzzing loop" fuel
      |> Logger.log config.modes.logmode log;
      fuzz_danglingsw ?deadline fuel config log query;
      let total, hits, coverage = DCov_multi.measure_coverage config.seed.cover in
      F.asprintf "[F %d] End fuzzing loop with coverage %d/%d (%.2f%%)" fuel hits
        total coverage
      |> Logger.log config.modes.logmode log)

let focus_target_hit (config : Config.tw) : bool =
  match config.focus with
  | None -> false
  | Some focus -> (
      match DCov_multi.Cover.find_opt focus.iid config.seed.cover with
      | None -> false
      | Some branch -> (
          match branch.status with Hit _ -> true | Miss _ -> false))

let rec fuzz_loopw (fuel : int) (config : Config.tw) : Config.tw =
  if fuel = 0 then config
  else (
    fuzz_loopw_once fuel config;
    if focus_target_hit config then config else fuzz_loopw (fuel - 1) config)

let fuzz_loopw_until (timeout : int) (config : Config.tw) : Config.tw =
  let started_at = Unix.gettimeofday () in
  let deadline = started_at +. float_of_int timeout in
  let logname = F.asprintf "%s/timeout.log" config.storage.dirname_log in
  let log = Logger.init logname in
  Fun.protect
    ~finally:(fun () -> Logger.close log)
    (fun () ->
      F.asprintf "[TIMEOUT] Start focused fuzzing for %d seconds" timeout
      |> Logger.log config.modes.logmode log;
      let rec loop fuel =
        if Unix.gettimeofday () >= deadline then ("timeout reached", fuel - 1)
        else if focus_target_hit config then ("focus target hit", fuel - 1)
        else
          try
            fuzz_loopw_once ~deadline fuel config;
            loop (fuel + 1)
          with Focus_timeout -> ("timeout reached", fuel)
      in
      let reason, attempts = loop 1 in
      let elapsed = Unix.gettimeofday () -. started_at in
      F.asprintf "[TIMEOUT] Stop focused fuzzing: %s after %d attempts (%.2fs)"
        reason attempts elapsed
      |> Logger.log config.modes.logmode log;
      config)

let wasm_fuzzer_init (spec : spec) (phase : Config.wasm_phase)
    (dirname_gen : string)
    (name_campaign : string option) (randseed : int option)
    (logmode : Modes.logmode) (bootmode : Modes.bootmode)
    (mutationmode : Modes.mutationmode) (covermode : Modes.covermode)
    (focus : Config.wasm_focus option) (budget : Config.wasm_budget) :
    Config.tw =
  let name_campaign =
    match name_campaign with
    | Some name_campaign -> name_campaign
    | None ->
        let timestamp =
          let tm = Unix.gettimeofday () |> Unix.localtime in
          F.asprintf "%04d-%02d-%02d-%02d-%02d-%02d"
            (tm.Unix.tm_year + 1900)
            (tm.Unix.tm_mon + 1) tm.Unix.tm_mday tm.Unix.tm_hour tm.Unix.tm_min
            tm.Unix.tm_sec
        in
        "fuzz-" ^ timestamp
  in
  let dirname_gen = dirname_gen ^ "/" ^ name_campaign in
  let storage = Config.init_storage dirname_gen in
  let modes = Modes.{ bootmode; logmode; mutationmode; covermode } in
  let logname_init = storage.dirname_log ^ "/init.log" in
  let log_init = Logger.init logname_init in
  F.asprintf
    "[COMMAND] wasm-testgen -phase %s (coverage relation %s) -gen %s%s%s%s%s%s"
    (Config.string_of_wasm_phase phase)
    (Config.coverage_relation phase)
    dirname_gen
    (match modes.bootmode with
    | Cold (excludes, dirname_seed_wasm) ->
        "-e" ^ String.concat " " excludes ^ "-cold " ^ dirname_seed_wasm
    | Warm path_boot -> " -warm " ^ path_boot)
    (match modes.mutationmode with
    | Random -> " -random"
    | Derive -> ""
    | Hybrid -> " -hybrid")
    (match modes.covermode with Strict -> " -strict" | Relaxed -> "")
    (match focus with
    | Some focus ->
        F.asprintf " -focus -pid %d -w %s" focus.iid focus.filename_wasm
    | None -> "")
    (match budget with
    | Config.WasmFuel fuel -> F.asprintf " -fuel %d" fuel
    | Config.WasmTimeout timeout -> F.asprintf " -timeout %d" timeout)
  |> Logger.log modes.logmode log_init;
  "Loading type definitions from the spec file"
  |> Logger.log modes.logmode log_init;
  let specenv = Config.init_wasm_specenv spec phase in
  "Booting initial coverage" |> Logger.log modes.logmode log_init;
  let cover_seed =
    match modes.bootmode with
    | Cold (_, dirname_seed_wasm) ->
        (match
           Boot.wasm_boot_cold specenv.simulator specenv.spec phase
             dirname_seed_wasm
         with
        | Ok { Boot.coverage = cover_seed; diagnostics } ->
            List.iter
              (fun (diagnostic : Boot.wasm_boot_diagnostic) ->
                F.asprintf "[BOOT DIAGNOSTIC] %s: %s (%s)"
                  diagnostic.Boot.filename diagnostic.Boot.category
                  diagnostic.Boot.message
                |> Logger.warn modes.logmode log_init)
              diagnostics;
            let path_cov = dirname_gen ^ "/boot.coverage" in
            DCov_multi.log ~path_cov_opt:(Some path_cov) cover_seed;
            (match Metadata.write ~phase path_cov with
            | Ok () -> cover_seed
            | Error error ->
                Logger.close log_init;
                failwith
                  ("Wasm cold boot coverage metadata write failed: "
                  ^ Boot.string_of_phase_error error))
        | Error failures ->
            List.iter
              (fun (failure : Boot.wasm_boot_failure) ->
                F.asprintf "[BOOT FAILURE] %s: %s" failure.Boot.filename
                  (Boot.string_of_phase_error failure.Boot.error)
                |> Logger.warn modes.logmode log_init)
              failures;
            Logger.close log_init;
            failwith "Wasm cold boot failed; see init.log for every seed failure")
    | Warm path_boot -> (
        match Boot.wasm_boot_warm ~phase path_boot with
        | Ok coverage -> coverage
        | Error error ->
            Logger.close log_init;
            failwith
              ("Wasm warm boot failed: " ^ Boot.string_of_phase_error error))
  in
  let seed = Config.init_seed cover_seed in
  let total, hits, coverage = DCov_multi.measure_coverage cover_seed in
  F.asprintf "Finished booting with initial coverage %d/%d (%.2f%%)" hits total
    coverage
  |> Logger.log modes.logmode log_init;
  F.asprintf
    "[SAMPLES_CLOSE_MISS] %d [SAMPLES_RELATED_VID] %d \
     [SAMPLES_DERIVATION_SOURCE] %d [TRIALS_MUTATION] %d [TRIALS_SEED] %d \
     [TIMEOUT_SEED] %d"
    Config.samples_close_miss Config.samples_related_vid
    Config.samples_derivation_source Config.trials_mutation Config.trials_seed
    Config.timeout_seed
  |> Logger.log modes.logmode log_init;
  Logger.close log_init;
  Config.initw ~focus randseed modes specenv storage seed

let wasm_fuzzer (budget : Config.wasm_budget) (spec : spec)
    (phase : Config.wasm_phase)
    (dirname_gen : string) (name_campaign : string option)
    (randseed : int option) (logmode : Modes.logmode)
    (bootmode : Modes.bootmode) (mutationmode : Modes.mutationmode)
    (covermode : Modes.covermode) (focus : Config.wasm_focus option) : unit =
  let config =
    wasm_fuzzer_init spec phase dirname_gen name_campaign randseed logmode
      bootmode mutationmode covermode focus budget
  in
  let config =
    match budget with
    | Config.WasmFuel fuel -> fuzz_loopw fuel config
    | Config.WasmTimeout timeout -> fuzz_loopw_until timeout config
  in
  let path_cov = config.storage.dirname_gen ^ "/final.coverage" in
  DCov_multi.log ~path_cov_opt:(Some path_cov) config.seed.cover;
  match Metadata.write ~phase path_cov with
  | Ok () -> ()
  | Error error ->
      failwith
        ("Wasm final coverage metadata write failed: "
        ^ Boot.string_of_phase_error error)
