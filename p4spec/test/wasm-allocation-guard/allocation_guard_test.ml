module Guard = Backend_testgen_neg.Wasm_allocation_guard
module Episode = Backend_testgen_neg.Wasm_episode

let target name =
  match Episode.parse_invocation_file name with
  | Ok episode -> Episode.invocation_target_value episode
  | Error _ -> failwith ("expected an invocation episode: " ^ name)

let check name expected =
  let actual = Guard.exceeded (target name) in
  if actual <> expected then
    failwith
      (Printf.sprintf "%s: expected %s, got %s" name
         (Option.value ~default:"no limit" expected)
         (Option.value ~default:"no limit" actual))

let () =
  (* The bounds themselves are allowed *)
  check "at-bounds.wast" None;
  check "memory-over.wast" (Some "memory 0 min 1025 pages exceeds 1024");
  check "second-memory-over.wast" (Some "memory 1 min 65536 pages exceeds 1024");
  check "table-over.wast" (Some "table 0 min 4097 elements exceeds 4096");
  (* Memory64 minimums are compared as unsigned 64-bit values *)
  check "memory64-over.wast" (Some "memory 0 min 4294967296 pages exceeds 1024");
  (* An import allocates nothing in the importing module *)
  check "imported.wast" None
