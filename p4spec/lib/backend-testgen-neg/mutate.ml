open Lang
open Il
module Type = Runtime.Type
module Value = Runtime.Value
open Runtime.Testgen_neg
open Envs
open Domain.Lib
open Util.Source
module Mixfix = Domain.Mixfix
module Mixop = Domain.Mixop

(* Kinds of mutations *)

type kind = GenFromTyp | MutateList | MixopGroup | MutateTableRefType

let string_of_kind = function
  | GenFromTyp -> "GenFromTyp"
  | MutateList -> "MutateList"
  | MixopGroup -> "MixopGroup"
  | MutateTableRefType -> "MutateTableRefType"

(* Option monad *)

let ( let* ) = Option.bind

(* Helpers for wrapping values *)

let wrap_value (typ : typ') (value : value') : value =
  let vhash = Value.hash_of value in
  value $$ (no_region, { vid = -1; typ; vhash })

let wrap_value_opt (typ : typ') (value_opt : value' option) : value option =
  Option.map (wrap_value typ) value_opt

type int_bounds = { min_value : Bigint.t; max_value : Bigint.t }

type num_context = {
  nat_bounds : int_bounds option;
  int_bounds : int_bounds option;
}

let one = Bigint.of_int 1

let max_i31 = Bigint.of_string "2147483647"

let dedup_bigints (values : Bigint.t list) : Bigint.t list =
  List.fold_left
    (fun values_deduped value ->
      if
        List.exists
          (fun value_deduped -> Bigint.compare value value_deduped = 0)
          values_deduped
      then values_deduped
      else value :: values_deduped)
    [] values
  |> List.rev

let max_bigint (a : Bigint.t) (b : Bigint.t) : Bigint.t =
  if Bigint.compare a b < 0 then b else a

let default_nat_values : Bigint.t list =
  [ one; Bigint.of_int 32; Bigint.of_int 65536; max_i31 ]

let default_int_values : Bigint.t list =
  [ Bigint.of_int (-16); Bigint.of_int 0; Bigint.of_int 65536; max_i31 ]

let input_nat_values_of_bounds (bounds : int_bounds option) : Bigint.t list =
  match bounds with
  | None -> []
  | Some { min_value; max_value } ->
      [
        one;
        Bigint.(min_value - one) |> max_bigint one;
        Bigint.(max_value + one);
        max_i31;
      ]
      |> dedup_bigints

let input_int_values_of_bounds (bounds : int_bounds option) : Bigint.t list =
  match bounds with
  | None -> []
  | Some { min_value; max_value } ->
      [
        Bigint.(min_value - of_int 1);
        Bigint.of_int 0;
        Bigint.(max_value + of_int 1);
        max_i31;
      ]
      |> dedup_bigints

let random_select_from_num_pools (values_default : Bigint.t list)
    (values_input : Bigint.t list) : Bigint.t option =
  let pools =
    match values_input with
    | [] -> [ values_default ]
    | _ :: _ -> [ values_default; values_input ]
  in
  let* values = Rand.random_select pools in
  Rand.random_select values

let random_select_from_variant_pools (nottyps_nullary : nottyp' list)
    (nottyps_payload : nottyp' list) : nottyp' option =
  let pools =
    [ nottyps_nullary; nottyps_payload ]
    |> List.filter (function [] -> false | _ :: _ -> true)
  in
  let* nottyps = Rand.random_select pools in
  Rand.random_select nottyps

let nottyp_has_payload (nottyp : nottyp') : bool =
  match Mixfix.args nottyp with [] -> false | _ :: _ -> true

let update_int_bounds (bounds : int_bounds option) (value : Bigint.t) :
    int_bounds option =
  let update_min current =
    if Bigint.compare value current < 0 then value else current
  in
  let update_max current =
    if Bigint.compare value current > 0 then value else current
  in
  match bounds with
  | None -> Some { min_value = value; max_value = value }
  | Some { min_value; max_value } ->
      Some
        { min_value = update_min min_value; max_value = update_max max_value }

let collect_texts (vdg : Dep.Graph.t) : value' list =
  List.init (vdg.root + 1) Fun.id
  |> List.filter_map (fun vid ->
         let* mirror, _ = Dep.Graph.find_node vdg vid in
         match mirror.it with TextN text -> Some (TextV text) | _ -> None)

let collect_int_bounds (vdg : Dep.Graph.t) : int_bounds option =
  List.init (vdg.root + 1) Fun.id
  |> List.fold_left
       (fun bounds vid ->
         match Dep.Graph.find_node vdg vid with
         | Some (mirror, taint) when Dep.Node.is_source taint -> (
             match mirror.it with
             | NumN num -> Xl.Num.to_int num |> update_int_bounds bounds
             | _ -> bounds)
         | _ -> bounds)
       None

let collect_nat_bounds (vdg : Dep.Graph.t) : int_bounds option =
  List.init (vdg.root + 1) Fun.id
  |> List.fold_left
       (fun bounds vid ->
         match Dep.Graph.find_node vdg vid with
         | Some (mirror, taint) when Dep.Node.is_source taint -> (
             match mirror.it with
             | NumN num ->
                 let value = Xl.Num.to_int num in
                 if Bigint.compare value one >= 0 then
                   update_int_bounds bounds value
                 else bounds
             | _ -> bounds)
         | _ -> bounds)
       None

let collect_num_context (vdg : Dep.Graph.t) : num_context =
  {
    nat_bounds = collect_nat_bounds vdg;
    int_bounds = collect_int_bounds vdg;
  }

(* Type-driven mutation *)

let rec gen_from_typ (depth : int) (tdenv : TDEnv.t) (texts : value' list)
    (nums : num_context) (typ : typ) : value option =
  if depth <= 0 then None else gen_from_typ' depth tdenv texts nums typ

and gen_from_typ' (depth : int) (tdenv : TDEnv.t) (texts : value' list)
    (nums : num_context) (typ : typ) : value option =
  let depth = depth - 1 in
  match typ.it with
  | BoolT ->
      [ BoolV true; BoolV false ] |> Rand.random_select |> wrap_value_opt typ.it
  | NumT `NatT ->
      let* value =
        input_nat_values_of_bounds nums.nat_bounds
        |> random_select_from_num_pools default_nat_values
      in
      NumV (`Nat value) |> Option.some |> wrap_value_opt typ.it
  | NumT `IntT ->
      let* value =
        input_int_values_of_bounds nums.int_bounds
        |> random_select_from_num_pools default_int_values
      in
      NumV (`Int value) |> Option.some |> wrap_value_opt typ.it
  | TextT -> texts |> Rand.random_select |> wrap_value_opt typ.it
  | VarT (tid, targs) -> (
      let td = TDEnv.find_opt tid tdenv in
      match td with
      | Some (Defined (tparams, td)) -> (
          let theta = List.combine tparams targs |> TDEnv.of_list in
          match td.it with
          | PlainT typ ->
              typ |> Type.Subst.subst_typ theta
              |> gen_from_typ depth tdenv texts nums
          | StructT typfields ->
              let atoms, typs = List.split typfields in
              let* values =
                typs
                |> Type.Subst.subst_typs theta
                |> gen_from_typs depth tdenv texts nums
              in
              let valuefields = List.combine atoms values in
              StructV valuefields |> Option.some |> wrap_value_opt typ.it
          | VariantT typcases ->
              let nottyps' =
                typcases
                |> List.map (fun (nottyp, _, _) ->
                       Mixfix.map (Type.Subst.subst_typ theta) nottyp.it)
              in
              let expand_nottyp' nottyp' =
                let mixop, typs = Mixfix.split nottyp' in
                let* values = gen_from_typs depth tdenv texts nums typs in
                CaseV (Mixfix.fill mixop values) |> Option.some
              in
              let nottyps_nullary, nottyps_payload =
                List.partition
                  (fun nottyp' -> not (nottyp_has_payload nottyp'))
                  nottyps'
              in
              let* nottyp' =
                random_select_from_variant_pools nottyps_nullary
                  nottyps_payload
              in
              expand_nottyp' nottyp' |> wrap_value_opt typ.it)
      | _ -> None)
  | TupleT typs_inner ->
      let* values_inner = gen_from_typs depth tdenv texts nums typs_inner in
      TupleV values_inner |> Option.some |> wrap_value_opt typ.it
  | IterT (_, Opt) when depth = 0 ->
      OptV None |> Option.some |> wrap_value_opt typ.it
  | IterT (typ_inner, Opt) ->
      let choices : value' option list =
        [
          OptV None |> Option.some;
          (let* value_inner =
             gen_from_typ depth tdenv texts nums typ_inner
           in
           OptV (Some value_inner) |> Option.some);
        ]
      in
      let* choice =
        choices |> List.filter Option.is_some |> Rand.random_select
      in
      choice |> wrap_value_opt typ.it
  | IterT (_, List) when depth = 0 ->
      ListV Value_array.empty |> Option.some |> wrap_value_opt typ.it
  | IterT (typ_inner, List) ->
      let* len = Rand.random_select [ 2; 4; 8; 16 ] in
      let* values_inner =
        List.init len (fun _ -> typ_inner)
        |> gen_from_typs depth tdenv texts nums
      in
      ListV (Value_array.of_list values_inner)
      |> Option.some |> wrap_value_opt typ.it
  | FuncT _ -> None

and gen_from_typs (depth : int) (tdenv : TDEnv.t) (texts : value' list)
    (nums : num_context) (typs : typ list) : value list option =
  if depth <= 0 then None
  else
    List.fold_left
      (fun values_opt typ ->
        let* values = values_opt in
        let* value = gen_from_typ depth tdenv texts nums typ in
        Some (values @ [ value ]))
      (Some []) typs

let mutate_type_driven (tdenv : TDEnv.t) (texts : value' list)
    (nums : num_context) (value : value) : (kind * value) option =
  let typ = value.note.typ $ no_region in
  let depth = Random.int 4 + 1 in
  let value_opt = gen_from_typ depth tdenv texts nums typ in
  Option.map (fun value -> (GenFromTyp, value)) value_opt

(* Constructor mutation *)

let mutate_mixop (mixopenv : MixopEnv.t) (value : value) : (kind * value) option
    =
  let typ = value.note.typ in
  match typ with
  | VarT (id, _) -> (
      match value.it with
      | CaseV valuecase ->
          let mixop, values = Mixfix.split valuecase in
          let* mixop_family = MixopEnv.find_opt id mixopenv in
          let mixop_family =
            Mixops.Family.filter
              (fun mixop_group -> MixIdSet.exists (Mixop.eq mixop) mixop_group)
              mixop_family
          in
          let* mixop_group =
            if Mixops.Family.cardinal mixop_family = 0 then None
            else mixop_family |> Mixops.Family.choose |> Option.some
          in
          let* mixop =
            mixop_group
            |> MixIdSet.filter (fun mixop_e -> not (Mixop.eq mixop mixop_e))
            |> MixIdSet.elements |> Rand.random_select
          in
          let value = CaseV (Mixfix.fill mixop values) |> wrap_value typ in
          (MixopGroup, value) |> Option.some
      | _ -> assert false)
  | _ -> assert false

(* List mutations *)

let rec shuffle_list' (value : value) : value =
  let typ = value.note.typ in
  match value.it with
  | BoolV _ | NumV _ | TextV _ -> value.it |> wrap_value typ
  | StructV valuefields ->
      let atoms, values = List.split valuefields in
      let values_shuffled = List.map shuffle_list' values in
      let valuefields_shuffled = List.combine atoms values_shuffled in
      StructV valuefields_shuffled |> wrap_value typ
  | CaseV valuecase ->
      let valuecase_shuffled = Mixfix.map shuffle_list' valuecase in
      CaseV valuecase_shuffled |> wrap_value typ
  | TupleV values ->
      let values_shuffled = List.map shuffle_list' values in
      TupleV values_shuffled |> wrap_value typ
  | OptV None -> value.it |> wrap_value typ
  | OptV (Some value) ->
      let value_shuffled = shuffle_list' value in
      OptV (Some value_shuffled) |> wrap_value typ
  | ListV values ->
      let values_shuffled =
        values |> Value_array.to_list |> Rand.shuffle |> Value_array.of_list
      in
      ListV values_shuffled |> wrap_value typ
  | FuncV _ | ExternV _ -> value.it |> wrap_value typ

let shuffle_list (value : value) : value option =
  let value_shuffled = shuffle_list' value in
  if Value.eq value value_shuffled then None else Some value_shuffled

let rec duplicate_list' (value : value) : value =
  let typ = value.note.typ in
  match value.it with
  | BoolV _ | NumV _ | TextV _ -> value.it |> wrap_value typ
  | StructV valuefields ->
      let atoms, values = List.split valuefields in
      let values_duplicated = List.map duplicate_list' values in
      let valuefields_duplicated = List.combine atoms values_duplicated in
      StructV valuefields_duplicated |> wrap_value typ
  | CaseV valuecase ->
      let valuecase_duplicated = Mixfix.map duplicate_list' valuecase in
      CaseV valuecase_duplicated |> wrap_value typ
  | TupleV values ->
      let values_duplicated = List.map duplicate_list' values in
      TupleV values_duplicated |> wrap_value typ
  | OptV None -> value.it |> wrap_value typ
  | OptV (Some value) ->
      let value_duplicated = duplicate_list' value in
      OptV (Some value_duplicated) |> wrap_value typ
  | ListV values -> (
      let values = Value_array.to_list values in
      match Rand.random_select values with
      | Some value ->
          let values = value :: values |> Value_array.of_list in
          ListV values |> wrap_value typ
      | None -> value.it |> wrap_value typ)
  | FuncV _ | ExternV _ -> value.it |> wrap_value typ

let duplicate_list (value : value) : value option =
  let value_duplicated = duplicate_list' value in
  if Value.eq value value_duplicated then None else Some value_duplicated

let rec shrink_list' (value : value) : value =
  let typ = value.note.typ in
  match value.it with
  | BoolV _ | NumV _ | TextV _ -> value.it |> wrap_value typ
  | StructV valuefields ->
      let atoms, values = List.split valuefields in
      let values_shrinked = List.map shrink_list' values in
      let valuefields_shrinked = List.combine atoms values_shrinked in
      StructV valuefields_shrinked |> wrap_value typ
  | CaseV valuecase ->
      let valuecase_shrinked = Mixfix.map shrink_list' valuecase in
      CaseV valuecase_shrinked |> wrap_value typ
  | TupleV values ->
      let values_shrinked = List.map shrink_list' values in
      TupleV values_shrinked |> wrap_value typ
  | OptV None -> value.it |> wrap_value typ
  | OptV (Some value) ->
      let value_shrinked = shrink_list' value in
      OptV (Some value_shrinked) |> wrap_value typ
  | ListV values when Value_array.length values = 0 ->
      value.it |> wrap_value typ
  | ListV values ->
      let values = Value_array.to_list values in
      let size = Random.int (List.length values) in
      let values = Rand.random_sample size values |> Value_array.of_list in
      ListV values |> wrap_value typ
  | FuncV _ | ExternV _ -> value.it |> wrap_value typ

let shrink_list (value : value) : value option =
  let value_shrinked = shrink_list' value in
  if Value.eq value value_shrinked then None else Some value_shrinked

let mutate_list (value : value) : (kind * value) option =
  let wrap_kind (value_opt : value option) : (kind * value) option =
    Option.map (fun value -> (MutateList, value)) value_opt
  in
  let mutations_list =
    [
      (fun () -> shuffle_list value |> wrap_kind);
      (fun () -> duplicate_list value |> wrap_kind);
      (fun () -> shrink_list value |> wrap_kind);
    ]
  in
  let* mutation = Rand.random_select mutations_list in
  mutation ()

let mutate_node (tdenv : TDEnv.t) (mixopenv : MixopEnv.t) (texts : value' list)
    (nums : num_context) (value : value) : (kind * value) option =
  match value.it with
  | ListV _ ->
      let* mutation =
        [
          (fun () -> mutate_list value);
          (fun () -> mutate_type_driven tdenv texts nums value);
        ]
        |> Rand.random_select
      in
      mutation ()
  | CaseV _ ->
      let* mutation =
        [
          (fun () -> mutate_mixop mixopenv value);
          (fun () -> mutate_type_driven tdenv texts nums value);
        ]
        |> Rand.random_select
      in
      mutation ()
  | _ -> mutate_type_driven tdenv texts nums value

let mutate_walk (tdenv : TDEnv.t) (mixopenv : MixopEnv.t) (texts : value' list)
    (nums : num_context) (value : value) : (kind * value) option =
  (* Compute the best path to a leaf node in the value subtree *)
  let key_max = ref min_float in
  let path_best = ref [] in
  let rec traverse (path : int list) (value : value) (depth : int) : unit =
    let weight = 1.0 /. (float_of_int (depth + 1) ** 3.0) in
    let u = Random.float 1.0 in
    let key = u ** (1.0 /. weight) in
    if key > !key_max then (
      key_max := key;
      path_best := List.rev path);
    match value.it with
    | BoolV _ | NumV _ | TextV _ | OptV _ | FuncV _ | ExternV _ -> ()
    | StructV valuefields ->
        List.iteri
          (fun idx (_, value) -> traverse (idx :: path) value (depth + 1))
          valuefields
    | CaseV valuecase ->
        let values = Mixfix.args valuecase in
        List.iteri
          (fun idx value -> traverse (idx :: path) value (depth + 1))
          values
    | TupleV values ->
        List.iteri
          (fun idx value -> traverse (idx :: path) value (depth + 1))
          values
    | ListV values ->
        Value_array.iteri
          (fun idx value -> traverse (idx :: path) value (depth + 1))
          values
  in
  traverse [] value 0;
  let kind_found = ref None in

  (* Rebuild the value tree with a new value at the best path *)
  let rec rebuild (path : int list) (value : value) : value option =
    let typ = value.note.typ in
    match (path, value) with
    | [], value ->
        let* kind, value = mutate_node tdenv mixopenv texts nums value in
        kind_found := kind |> Option.some;
        value |> Option.some
    | idx :: path, value -> (
        match value.it with
        | BoolV _ | NumV _ | TextV _ | OptV _ | FuncV _ | ExternV _ ->
            value.it |> wrap_value typ |> Option.some
        | StructV valuefields ->
            let atoms, values = List.split valuefields in
            let* values = rebuilds path idx values in
            let valuefields = List.combine atoms values in
            StructV valuefields |> wrap_value typ |> Option.some
        | CaseV valuecase ->
            let mixop, values = Mixfix.split valuecase in
            let* values = rebuilds path idx values in
            CaseV (Mixfix.fill mixop values) |> wrap_value typ |> Option.some
        | TupleV values ->
            let* values = rebuilds path idx values in
            TupleV values |> wrap_value typ |> Option.some
        | ListV values ->
            let values = Value_array.to_list values in
            let* values = rebuilds path idx values in
            ListV (Value_array.of_list values) |> wrap_value typ |> Option.some)
  and rebuilds rest i (values_inner : value list) : value list option =
    values_inner
    |> List.mapi (fun j value ->
           if j = i then rebuild rest value else Some value)
    |> List.fold_left
         (fun values_opt value ->
           let* values = values_opt in
           let* value = value in
           Some (values @ [ value ]))
         (Some [])
  in
  let* value = rebuild !path_best value in
  let* kind = !kind_found in
  Some (kind, value)

(* Find parent node, if any, in the dependency graph *)

let find_parent (vdg : Dep.Graph.t) (vid_source : vid) : vid option =
  let parents =
    (* for all edges from v *)
    match Dep.Graph.G.find_opt vdg.edges vid_source with
    | None -> []
    | Some edges ->
        (* follow Expand edges to source nodes *)
        Dep.Edges.E.fold
          (fun (label, vid_target) () acc ->
            if label = Dep.Edges.Expand then vid_target :: acc else acc)
          edges []
  in
  assert (List.length parents <= 1);
  parents |> Rand.random_select

let rec choose_one (values : 'a option list) : 'a option =
  match values with
  | [] -> None
  | Some value :: _ -> Some value
  | None :: values -> choose_one values

(* Wasm table reftype mutation *)

let atom_named (name : string) (atom : atom) : bool =
  Domain.Atom.eq atom.it (Domain.Atom.Atom name)

let wrap_atom_named (name : string) : atom =
  Domain.Atom.Atom name $ no_region

let wrap_case_named (typ : typ') (mixop_names : string list list)
    (values : value list) : value =
  let mixop =
    mixop_names
    |> List.map (List.map (fun name -> Domain.Atom.Atom name))
    |> Value.Mixops.of_atoms_matrix
  in
  CaseV (Mixfix.fill mixop values) |> wrap_value typ

let mixop_head_named (name : string) (mixop : mixop) : bool =
  match Mixop.atoms_matrix mixop with
  | (atom :: _) :: _ when atom_named name atom -> true
  | _ -> false

let rec value_contains_vid (vid_target : vid) (value : value) : bool =
  value.note.vid = vid_target
  ||
  match value.it with
  | BoolV _ | NumV _ | TextV _ | FuncV _ | ExternV _ -> false
  | StructV valuefields ->
      List.exists
        (fun (_, value_inner) -> value_contains_vid vid_target value_inner)
        valuefields
  | CaseV valuecase ->
      valuecase |> Mixfix.args
      |> List.exists (value_contains_vid vid_target)
  | TupleV values -> List.exists (value_contains_vid vid_target) values
  | ListV values -> Value_array.exists (value_contains_vid vid_target) values
  | OptV None -> false
  | OptV (Some value_inner) -> value_contains_vid vid_target value_inner

let find_valuefield (name : string) (valuefields : valuefield list) :
    value option =
  valuefields
  |> List.find_map (fun (atom, value) ->
         if atom_named name atom then Some value else None)

let update_valuefield (name : string) (value_new : value)
    (valuefields : valuefield list) : valuefield list =
  valuefields
  |> List.map (fun (atom, value) ->
         if atom_named name atom then (atom, value_new) else (atom, value))

let table_valuefields (value : value) : valuefield list option =
  match (value.note.typ, value.it) with
  | VarT ({ it = "table"; _ }, _), StructV valuefields -> Some valuefields
  | _ -> None

let tabletype_components (value : value) :
    (mixop * value * value * value) option =
  match value.it with
  | CaseV valuecase -> (
      let mixop, values = Mixfix.split valuecase in
      match values with
      | [ addrtype; limits; reftype ] when mixop_head_named "TableT" mixop ->
          Some (mixop, addrtype, limits, reftype)
      | _ -> None)
  | _ -> None

let reftype_components (value : value) : (value * value) option =
  match value.it with
  | CaseV valuecase ->
      let mixop, values = Mixfix.split valuecase in
      let atoms_matrix = Mixop.atoms_matrix mixop in
      if
        List.length atoms_matrix = 3
        && List.for_all (fun atoms -> atoms = []) atoms_matrix
      then
        match values with
        | [ null; heaptype ] -> Some (null, heaptype)
        | _ -> None
      else None
  | _ -> None

let is_null_value (value : value) : bool =
  match value.it with
  | CaseV valuecase ->
      let mixop, values = Mixfix.split valuecase in
      values = [] && mixop_head_named "Null" mixop
  | _ -> false

let gen_nullable_reftype (tdenv : TDEnv.t) (texts : value' list)
    (nums : num_context) (reftype : value) : (value * value) option =
  let typ = reftype.note.typ $ no_region in
  let rec attempt remaining =
    if remaining <= 0 then None
    else
      let depth = Random.int 4 + 3 in
      match gen_from_typ' depth tdenv texts nums typ with
      | Some reftype_new -> (
          match reftype_components reftype_new with
          | Some (null_new, heaptype_new)
            when is_null_value null_new
                 && not (Value.eq reftype reftype_new) ->
              Some (reftype_new, heaptype_new)
          | _ -> attempt (remaining - 1))
      | None -> attempt (remaining - 1)
  in
  attempt 8

let instr_typ_of_tinit (tinit : value) : typ' option =
  match tinit.note.typ with
  | IterT (typ_instr, List) -> Some typ_instr.it
  | _ -> (
      match tinit.it with
      | ListV instrs when Value_array.length instrs > 0 ->
          Some (Value_array.get instrs 0).note.typ
      | _ -> None)

let ref_null_instr (typ : typ') (heaptype : value) : value =
  wrap_case_named typ [ [ "REF.NULL" ]; [] ] [ heaptype ]

let tinit_with_ref_null (tinit : value) (heaptype : value) : value option =
  let* typ_instr = instr_typ_of_tinit tinit in
  let instr = ref_null_instr typ_instr heaptype in
  ListV (Value_array.of_list [ instr ])
  |> wrap_value tinit.note.typ |> Option.some

let rec sequence_options (values : 'a option list) : 'a list option =
  match values with
  | [] -> Some []
  | value_opt :: values_opt ->
      let* value = value_opt in
      let* values = sequence_options values_opt in
      Some (value :: values)

let list_items (value : value) : value list option =
  match value.it with
  | ListV values -> Some (Value_array.to_list values)
  | _ -> None

let replace_list_item (idx_target : int) (f : value -> value option)
    (values : value list) : value list option =
  values
  |> List.mapi (fun idx value ->
         if idx = idx_target then f value else Some value)
  |> sequence_options

let list_with_items (list_value : value) (values : value list) : value =
  ListV (Value_array.of_list values) |> wrap_value list_value.note.typ

let table_reftype (table : value) : value option =
  let* valuefields = table_valuefields table in
  let* ttype = find_valuefield "TTYPE" valuefields in
  let* _, _, _, reftype = tabletype_components ttype in
  Some reftype

let tabletype_with_reftype (ttype : value) (reftype_new : value) :
    value option =
  let* mixop_tabletype, addrtype, limits, _ = tabletype_components ttype in
  CaseV (Mixfix.fill mixop_tabletype [ addrtype; limits; reftype_new ])
  |> wrap_value ttype.note.typ |> Option.some

let table_with_reftype (table : value) (reftype_new : value)
    (heaptype_new : value) : value option =
  let* valuefields = table_valuefields table in
  let* ttype = find_valuefield "TTYPE" valuefields in
  let* tinit = find_valuefield "TINIT" valuefields in
  let* ttype_new = tabletype_with_reftype ttype reftype_new in
  let* tinit_new = tinit_with_ref_null tinit heaptype_new in
  valuefields
  |> update_valuefield "TTYPE" ttype_new
  |> update_valuefield "TINIT" tinit_new
  |> fun valuefields -> StructV valuefields |> wrap_value table.note.typ
  |> Option.some

let module_valuefields (value : value) : valuefield list option =
  match (value.note.typ, value.it) with
  | VarT ({ it = "module"; _ }, _), StructV valuefields -> Some valuefields
  | _ -> None

let import_valuefields (value : value) : valuefield list option =
  match (value.note.typ, value.it) with
  | VarT ({ it = "import"; _ }, _), StructV valuefields -> Some valuefields
  | _ -> None

let elem_valuefields (value : value) : valuefield list option =
  match (value.note.typ, value.it) with
  | VarT ({ it = "elem"; _ }, _), StructV valuefields -> Some valuefields
  | _ -> None

let importdesc_tabletype (idesc : value) : (mixop * value) option =
  match idesc.it with
  | CaseV valuecase -> (
      let mixop, values = Mixfix.split valuecase in
      match values with
      | [ ttype ] when mixop_head_named "TableImport" mixop ->
          Some (mixop, ttype)
      | _ -> None)
  | _ -> None

let import_table_reftype (import : value) : value option =
  let* valuefields = import_valuefields import in
  let* idesc = find_valuefield "IDESC" valuefields in
  let* _, ttype = importdesc_tabletype idesc in
  let* _, _, _, reftype = tabletype_components ttype in
  Some reftype

let import_with_table_reftype (import : value) (reftype_new : value) :
    value option =
  let* valuefields = import_valuefields import in
  let* idesc = find_valuefield "IDESC" valuefields in
  let* mixop_importdesc, ttype = importdesc_tabletype idesc in
  let* ttype_new = tabletype_with_reftype ttype reftype_new in
  let idesc_new =
    CaseV (Mixfix.fill mixop_importdesc [ ttype_new ])
    |> wrap_value idesc.note.typ
  in
  valuefields
  |> update_valuefield "IDESC" idesc_new
  |> fun valuefields -> StructV valuefields |> wrap_value import.note.typ
  |> Option.some

let int_of_nat_value (value : value) : int option =
  match value.it with
  | NumV (`Nat value) -> (
      try Some (Bigint.to_int_exn value) with _ -> None)
  | _ -> None

let active_elem_index (elem : value) : int option =
  let* valuefields = elem_valuefields elem in
  let* emode = find_valuefield "EMODE" valuefields in
  match emode.it with
  | CaseV valuecase -> (
      let mixop, values = Mixfix.split valuecase in
      match values with
      | [ active ] when mixop_head_named "Active" mixop -> (
          match active.it with
          | StructV valuefields_active ->
              let* index = find_valuefield "INDEX" valuefields_active in
              int_of_nat_value index
          | _ -> None)
      | _ -> None)
  | _ -> None

let einit_with_ref_nulls (einit : value) (heaptype_new : value) : value option =
  let* consts = list_items einit in
  consts
  |> List.map (fun const -> tinit_with_ref_null const heaptype_new)
  |> sequence_options |> Option.map (list_with_items einit)

let elem_with_reftype (elem : value) (reftype_new : value)
    (heaptype_new : value) : value option =
  let* valuefields = elem_valuefields elem in
  let* _ = find_valuefield "ETYPE" valuefields in
  let* einit = find_valuefield "EINIT" valuefields in
  let* einit_new = einit_with_ref_nulls einit heaptype_new in
  valuefields
  |> update_valuefield "ETYPE" reftype_new
  |> update_valuefield "EINIT" einit_new
  |> fun valuefields -> StructV valuefields |> wrap_value elem.note.typ
  |> Option.some

type table_index_origin = ImportedTable of int | DefinedTable of int

type table_index_entry = {
  tableidx : int;
  origin : table_index_origin;
  reftype : value;
}

type module_table_context = {
  valuefields_module : valuefield list;
  imports_value : value;
  imports : value list;
  tables_value : value;
  tables : value list;
  elems_value : value;
  elems : value list;
  table_index_space : table_index_entry list;
}

let build_table_index_space (imports : value list) (tables : value list) :
    table_index_entry list =
  let next_tableidx = ref 0 in
  let imports_table =
    imports
    |> List.mapi (fun import_pos import ->
           match import_table_reftype import with
           | None -> None
           | Some reftype ->
               let tableidx = !next_tableidx in
               incr next_tableidx;
               Some
                 {
                   tableidx;
                   origin = ImportedTable import_pos;
                   reftype;
                 })
    |> List.filter_map Fun.id
  in
  let tables_defined =
    tables
    |> List.mapi (fun table_pos table ->
           let tableidx = !next_tableidx in
           incr next_tableidx;
           let* reftype = table_reftype table in
           Some { tableidx; origin = DefinedTable table_pos; reftype })
    |> List.filter_map Fun.id
  in
  imports_table @ tables_defined

let module_table_context (module_ : value) : module_table_context option =
  let* valuefields = module_valuefields module_ in
  let* imports_value = find_valuefield "IMPORTS" valuefields in
  let* tables_value = find_valuefield "TABLES" valuefields in
  let* elems_value = find_valuefield "ELEMS" valuefields in
  let* imports = list_items imports_value in
  let* tables = list_items tables_value in
  let* elems = list_items elems_value in
  Some
    {
      valuefields_module = valuefields;
      imports_value;
      imports;
      tables_value;
      tables;
      elems_value;
      elems;
      table_index_space = build_table_index_space imports tables;
    }

let find_table_index_entry (vid_target : vid)
    (entries : table_index_entry list) : table_index_entry option =
  entries
  |> List.find_opt (fun entry -> value_contains_vid vid_target entry.reftype)

let mutate_module_table_reftype (tdenv : TDEnv.t) (texts : value' list)
    (nums : num_context) (vid_target : vid) (module_ : value) : value option =
  let* ctx = module_table_context module_ in
  let* entry = find_table_index_entry vid_target ctx.table_index_space in
  let* reftype_new, heaptype_new =
    gen_nullable_reftype tdenv texts nums entry.reftype
  in
  let* imports_new, tables_new =
    match entry.origin with
    | ImportedTable import_pos ->
        let* imports_new =
          replace_list_item import_pos
            (fun import -> import_with_table_reftype import reftype_new)
            ctx.imports
        in
        Some (imports_new, ctx.tables)
    | DefinedTable table_pos ->
        let* tables_new =
          replace_list_item table_pos
            (fun table -> table_with_reftype table reftype_new heaptype_new)
            ctx.tables
        in
        Some (ctx.imports, tables_new)
  in
  let* elems_new =
    ctx.elems
    |> List.map (fun elem ->
           match active_elem_index elem with
           | Some tableidx when Int.equal tableidx entry.tableidx ->
               elem_with_reftype elem reftype_new heaptype_new
           | _ -> Some elem)
    |> sequence_options
  in
  ctx.valuefields_module
  |> update_valuefield "IMPORTS"
       (list_with_items ctx.imports_value imports_new)
  |> update_valuefield "TABLES" (list_with_items ctx.tables_value tables_new)
  |> update_valuefield "ELEMS" (list_with_items ctx.elems_value elems_new)
  |> fun valuefields -> StructV valuefields |> wrap_value module_.note.typ
  |> Option.some

let module_contains_table_reftype_vid (vid_target : vid) (module_ : value) :
    bool =
  match module_table_context module_ with
  | None -> false
  | Some ctx ->
      Option.is_some
        (find_table_index_entry vid_target ctx.table_index_space)

let find_module_containing_table_reftype (vid_target : vid) (value : value) :
    value option =
  let rec walk (value : value) : value option =
    match module_valuefields value with
    | Some _ when module_contains_table_reftype_vid vid_target value ->
        Some value
    | _ -> (
        match value.it with
        | BoolV _ | NumV _ | TextV _ | FuncV _ | ExternV _ -> None
        | StructV valuefields ->
            valuefields
            |> List.map (fun (_, value_inner) -> walk value_inner)
            |> choose_one
        | CaseV valuecase -> valuecase |> Mixfix.args |> List.map walk |> choose_one
        | TupleV values -> values |> List.map walk |> choose_one
        | ListV values ->
            values |> Value_array.to_list |> List.map walk |> choose_one
        | OptV None -> None
        | OptV (Some value_inner) -> walk value_inner)
  in
  walk value

let patch_program (tdenv : TDEnv.t) (value_to_mutate : value)
    (value_program : value) : value =
  let patch_value (typ : typ') (value : value) : value =
    { value with note = { value.note with typ } }
  in
  let rec walk (value : value) : value =
    let typ = value.note.typ in
    let value_patched =
      match (typ, value.it) with
      | BoolT, _ | NumT _, _ | TextT, _ -> value
      | VarT (id, targs), _ -> patch id targs value
      | TupleT typs, TupleV values ->
          assert (List.length typs = List.length values);
          let values_patched =
            List.map2
              (fun typ value -> patch_value typ.it value)
              typs values
          in
          { value with it = TupleV values_patched }
      | IterT (typ_inner, Opt), OptV value_opt -> (
          match value_opt with
          | None -> value
          | Some value_inner ->
              let value_patched = patch_value typ_inner.it value_inner in
              { value with it = OptV (Some value_patched) })
      | IterT (typ_inner, List), ListV values ->
          let values_patched =
            Value_array.map (patch_value typ_inner.it) values
          in
          { value with it = ListV values_patched }
      | FuncT _, _ -> value
      | _ -> value
    in
    match value_patched.it with
    | BoolV _ | NumV _ | TextV _ -> value_patched
    | StructV valuefields ->
        let atoms, values = List.split valuefields in
        let values_inner_patched = List.map walk values in
        let valuefields_patched = List.combine atoms values_inner_patched in
        { value_patched with it = StructV valuefields_patched }
    | CaseV valuecase ->
        { value_patched with it = CaseV (Mixfix.map walk valuecase) }
    | TupleV values ->
        { value_patched with it = TupleV (List.map walk values) }
    | OptV None -> value_patched
    | OptV (Some value_inner) ->
        { value_patched with it = OptV (Some (walk value_inner)) }
    | ListV values ->
        { value_patched with it = ListV (Value_array.map walk values) }
    | FuncV _ | ExternV _ -> value_patched
  and patch (id : TId.t) (targs : targ list) (value : value) : value =
    match TDEnv.find id tdenv with
    | Defined (tparams, deftyp) -> (
        assert (List.length tparams = List.length targs);
        let theta = List.combine tparams targs |> TDEnv.of_list in
        match (deftyp.it, value.it) with
        | VariantT typcases, CaseV valuecase ->
            let mixop_value, values_sub = Mixfix.split valuecase in
            let typs_sub =
              match
                List.find_map
                  (fun (nottyp, _, _) ->
                    let mixop_typ, typs_sub = Mixfix.split nottyp.it in
                    if Mixop.eq mixop_typ mixop_value then Some typs_sub
                    else None)
                  typcases
              with
              | Some typs_sub -> typs_sub
              | None -> failwith "patch: no typcase for mixop"
            in
            let typs_sub = Type.Subst.subst_typs theta typs_sub in
            let values_sub =
              List.map2
                (fun typ_sub value_sub -> patch_value typ_sub.it value_sub)
                typs_sub values_sub
            in
            let typ_patch = VarT (id, targs) in
            patch_value typ_patch
              { value with it = CaseV (Mixfix.fill mixop_value values_sub) }
        | StructT typfields, StructV valuefields ->
            let valuefields =
              List.map2
                (fun typfield valuefield ->
                  let atom_typ, typ_sub = typfield in
                  let atom_value, value_sub = valuefield in
                  assert (Domain.Atom.eq atom_typ.it atom_value.it);
                  let typ_sub = Type.Subst.subst_typ theta typ_sub in
                  let value_sub = patch_value typ_sub.it value_sub in
                  (atom_value, value_sub))
                typfields valuefields
            in
            let typ_patch = VarT (id, targs) in
            patch_value typ_patch { value with it = StructV valuefields }
        | PlainT typ, _ ->
            let typ = Type.Subst.subst_typ theta typ in
            patch_value typ.it value
        | _ -> failwith "patch: type mismatch between deftyp and value")
    | _ -> assert false
  in
  let vid_target = value_to_mutate.note.vid in
  let rec pick (value : value) : value option =
    if value.note.vid = vid_target then Some value
    else
      match value.it with
      | BoolV _ | NumV _ | TextV _ -> None
      | StructV valuefields ->
          let _, values = List.split valuefields in
          values |> List.map pick |> choose_one
      | CaseV valuecase -> valuecase |> Mixfix.args |> List.map pick |> choose_one
      | TupleV values -> values |> List.map pick |> choose_one
      | OptV None -> None
      | OptV (Some value) -> pick value
      | ListV values ->
          values |> Value_array.to_list |> List.map pick |> choose_one
      | FuncV _ | ExternV _ -> None
  in
  let value_program = walk value_program in
  match pick value_program with
  | Some value_to_mutate -> value_to_mutate
  | None -> failwith "patch_program: pick returned None"

(* Entry point for mutation *)

let mutate (tdenv : TDEnv.t) (mixopenv : MixopEnv.t) (texts : value' list)
    (nums : num_context) (vdg : Dep.Graph.t) (vid_source : vid) :
    (kind * value * value) option =
  (* Expand the node randomly *)
  let expansions =
    [
      (fun () -> find_parent vdg vid_source);
      (fun () -> vid_source |> Option.some);
    ]
  in
  let expansion = Rand.random_select expansions |> Option.get in
  let vid_to_mutate =
    match expansion () with Some vid_parent -> vid_parent | None -> vid_source
  in
  (* reassemble value from vid *)
  let value_to_mutate =
    Dep.Graph.reassemble_graph vdg VIdMap.empty vid_to_mutate
  in
  (* Mutate the node *)
  let* kind, value_mutated =
    mutate_walk tdenv mixopenv texts nums value_to_mutate
  in
  (kind, value_to_mutate, value_mutated) |> Option.some

let mutatew (tdenv : TDEnv.t) (mixopenv : MixopEnv.t) (texts : value' list)
    (nums : num_context) (vdg : Dep.Graph.t) (vid_source : vid) :
    (kind * value * value) option =
  let vid_to_mutate = vid_source in
  let value_to_mutate =
    Dep.Graph.reassemble_graph vdg VIdMap.empty vid_to_mutate
  in
  let value_program =
    Dep.Graph.reassemble_graph_from_root vdg VIdMap.empty
  in
  let mutate_generic () =
    let value_to_mutate_concrete =
      patch_program tdenv value_to_mutate value_program
    in
    let* kind, value_mutated =
      mutate_walk tdenv mixopenv texts nums value_to_mutate_concrete
    in
    Some (kind, value_to_mutate_concrete, value_mutated)
  in
  match find_module_containing_table_reftype vid_to_mutate value_program with
  | Some module_ -> (
      let module_concrete = patch_program tdenv module_ value_program in
      match
        mutate_module_table_reftype tdenv texts nums vid_to_mutate
          module_concrete
      with
      | Some module_mutated ->
          Some (MutateTableRefType, module_concrete, module_mutated)
      | None -> None)
  | None -> mutate_generic ()

let mutates (fuel_mutate : int) (tdenv : TDEnv.t) (mixopenv : MixopEnv.t)
    (vdg : Dep.Graph.t) (vid_source : vid) : (kind * value * value) list =
  (* Collect the text pool *)
  let texts = collect_texts vdg in
  let texts = texts @ [ TextV "lazy"; TextV "fox" ] in
  let nums = collect_num_context vdg in
  (* Do mutations *)
  List.init fuel_mutate (fun _ ->
      mutate tdenv mixopenv texts nums vdg vid_source)
  |> List.filter_map Fun.id

let mutatesw (fuel_mutate : int) (tdenv : TDEnv.t) (mixopenv : MixopEnv.t)
    (vdg : Dep.Graph.t) (vid_source : vid) : (kind * value * value) list =
  let texts = collect_texts vdg in
  let texts = texts @ [ TextV "lazy"; TextV "fox" ] in
  let nums = collect_num_context vdg in
  List.init fuel_mutate (fun _ ->
      mutatew tdenv mixopenv texts nums vdg vid_source)
  |> List.filter_map Fun.id
