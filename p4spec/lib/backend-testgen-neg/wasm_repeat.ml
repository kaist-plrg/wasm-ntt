open Domain.Lib

type options = { hits : int; fuel : int option }

let default_options = { hits = 0; fuel = None }

type entry = {
  seeds : string list;
  first_fuel : int;
  mutable kept : int;
  digests : (string, unit) Hashtbl.t;
}

type t = { options : options; mutable entries : entry IIdMap.t }

let create options = { options; entries = IIdMap.empty }
let options t = t.options
let enabled t = t.options.hits > 0

let record_first_hit t ~iid ~fuel ~seeds ~digest =
  if enabled t && seeds <> [] && not (IIdMap.mem iid t.entries) then (
    let digests = Hashtbl.create 8 in
    Option.iter (fun digest -> Hashtbl.replace digests digest ()) digest;
    t.entries <-
      IIdMap.add iid { seeds; first_fuel = fuel; kept = 0; digests } t.entries)

let tracked t ~iid = IIdMap.mem iid t.entries

(* Fuel counts down under a fuel budget and up under a time budget, so the
   distance to the first hit is taken either way *)
let within_window t entry ~fuel =
  match t.options.fuel with
  | None -> true
  | Some window -> abs (entry.first_fuel - fuel) <= window

let wants_entry t entry ~fuel =
  entry.kept < t.options.hits && within_window t entry ~fuel

let wants t ~iid ~fuel =
  enabled t
  &&
  match IIdMap.find_opt iid t.entries with
  | Some entry -> wants_entry t entry ~fuel
  | None -> false

(* In the fuel of its first hit the visit that hit the premise goes on, so a
   revisit only starts from the next fuel and no premise is visited twice in
   one fuel *)
let targets t ~fuel =
  if not (enabled t) then []
  else
    IIdMap.fold
      (fun iid entry targets ->
        if entry.first_fuel <> fuel && wants_entry t entry ~fuel then
          (iid, entry.seeds) :: targets
        else targets)
      t.entries []
    |> List.rev

type admission = Admit | Duplicate | Quota | Untracked

let admission t ~iid ~digest =
  match IIdMap.find_opt iid t.entries with
  | None -> Untracked
  | Some entry ->
      if entry.kept >= t.options.hits then Quota
      else if Hashtbl.mem entry.digests digest then Duplicate
      else Admit

let commit t ~iid ~digest =
  match IIdMap.find_opt iid t.entries with
  | None -> 0
  | Some entry ->
      Hashtbl.replace entry.digests digest ();
      entry.kept <- entry.kept + 1;
      entry.kept

let saved t ~iid =
  match IIdMap.find_opt iid t.entries with
  | Some entry -> entry.kept
  | None -> 0

let total_saved t = IIdMap.fold (fun _ entry sum -> sum + entry.kept) t.entries 0

let digest_of_module value =
  Lang.Il.Print.string_of_value value |> Digest.string |> Digest.to_hex
