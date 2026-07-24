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

let two_to_32 = Bigint.of_string "4294967296"

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
  [ one; Bigint.of_int 32; Bigint.of_int 65536; two_to_32 ]

let default_int_values : Bigint.t list =
  [ Bigint.of_int (-16); Bigint.of_int 0; Bigint.of_int 65536; two_to_32 ]

let input_nat_values_of_bounds (bounds : int_bounds option) : Bigint.t list =
  match bounds with
  | None -> []
  | Some { min_value; max_value } ->
      [
        one;
        Bigint.(min_value - one) |> max_bigint one;
        Bigint.(max_value + one);
        two_to_32;
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
        two_to_32;
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
      ListV [] |> Option.some |> wrap_value_opt typ.it
  | IterT (typ_inner, List) ->
      let* len = Rand.random_select [ 2; 4; 8; 16 ] in
      let* values_inner =
        List.init len (fun _ -> typ_inner)
        |> gen_from_typs depth tdenv texts nums
      in
      ListV values_inner |> Option.some |> wrap_value_opt typ.it
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
  let depth = Random.int 5 + 6 in
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
      let values_shuffled = Rand.shuffle values in
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
      match Rand.random_select values with
      | Some value ->
          let values = value :: values in
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
  | ListV [] -> value.it |> wrap_value typ
  | ListV values ->
      let size = Random.int (List.length values) in
      let values = Rand.random_sample size values in
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
    | TupleV values | ListV values ->
        List.iteri
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
            let* values = rebuilds path idx values in
            ListV values |> wrap_value typ |> Option.some)
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
