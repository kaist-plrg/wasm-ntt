module Episode = Wasm_episode
module Harness = Wasm_interface.Script_harness
module Types = Wasm_interpreter.Types

let max_memory_pages = 1024L
let max_table_elems = 4096L

(* Limits are unsigned; a memory64 minimum may not fit a signed int64 *)
let over bound (limits : Types.limits) =
  Int64.unsigned_compare limits.min bound > 0

let first_exceeding describe items =
  List.mapi (fun index item -> (index, item)) items
  |> List.find_map (fun (index, item) -> describe index item)

let exceeded value =
  match Episode.module_entry_of_value value with
  | Error _ -> None
  | Ok entry -> (
      let module_ = entry.Harness.module_.it in
      let memory index (memory : Wasm_interpreter.Ast.memory) =
        let (Types.MemoryT (_, limits)) = memory.it.mtype in
        if over max_memory_pages limits then
          Some
            (Format.asprintf "memory %d min %Lu pages exceeds %Ld" index
               limits.min max_memory_pages)
        else None
      in
      let table index (table : Wasm_interpreter.Ast.table) =
        let (Types.TableT (_, limits, _)) = table.it.ttype in
        if over max_table_elems limits then
          Some
            (Format.asprintf "table %d min %Lu elements exceeds %Ld" index
               limits.min max_table_elems)
        else None
      in
      match first_exceeding memory module_.memories with
      | Some _ as reason -> reason
      | None -> first_exceeding table module_.tables)
