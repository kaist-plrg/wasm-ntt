open Domain.Lib
module DCov = Coverage.Dangling.Single
module Value = Runtime.Value

let make_switchable () =
  (* Dangling coverage and a reader for it *)
  let coverage = ref DCov.empty in
  let coverage_backup = ref DCov.empty in
  (* When off, dangling branches are still evaluated but not recorded: a phase
     may need the value dependencies of a sub-run whose coverage it must
     discard, such as invocations replayed only to reach the observed one. *)
  let enabled = ref true in
  let set_enabled (enabled' : bool) : unit = enabled := enabled' in
  let read () = !coverage in
  (* Instruction coverage measurement handler *)
  let module H : Handler.HANDLER = struct
    include Handler.Default

    let init_spec (spec : Handler.spec) : unit =
      match spec with SL spec_sl -> coverage := DCov.init spec_sl | _ -> ()

    let backup () : unit = coverage_backup := !coverage

    let restore () : unit =
      coverage := !coverage_backup;
      coverage_backup := DCov.empty

    let on_instr_dangling (hit : bool) (iid : IId.t) (value_cond : Value.t) :
        unit =
      if !enabled then
        if hit then coverage := DCov.hit !coverage iid
        else coverage := DCov.miss !coverage iid value_cond.note.vid
  end in
  (* Return the handler, the reader, and the switch *)
  ((module H : Handler.HANDLER), read, set_enabled)

let make () =
  let handler, read, _set_enabled = make_switchable () in
  (handler, read)
