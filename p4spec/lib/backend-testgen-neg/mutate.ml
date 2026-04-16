open Domain
open Lang
open Il
open Runtime.Testgen_neg
open Envs
open Domain.Lib
open Util.Source

(* Kinds of mutations *)

type kind = GenFromTyp | MutateList | MixopGroup

let string_of_kind = function
  | GenFromTyp -> "GenFromTyp"
  | MutateList -> "MutateList"
  | MixopGroup -> "MixopGroup"

(* Option monad *)

let ( let* ) = Option.bind

(* Helpers for wrapping values *)

let wrap_value (typ : typ') (value : value') : value =
  let vhash = Runtime.Dynamic_Il.Value.hash_of value in
  value $$$ { vid = -1; typ; vhash }

let wrap_value_opt (typ : typ') (value_opt : value' option) : value option =
  Option.map (wrap_value typ) value_opt

(* Type-driven mutation *)

let rec gen_from_typ (depth : int) (tdenv : TDEnv.t) (texts : value' list)
    (typ : typ) : value option =
  if depth <= 0 then None else gen_from_typ' depth tdenv texts typ

and gen_from_typ' (depth : int) (tdenv : TDEnv.t) (texts : value' list)
    (typ : typ) : value option =
  let depth = depth - 1 in
  match typ.it with
  | BoolT ->
      [ BoolV true; BoolV false ] |> Rand.random_select |> wrap_value_opt typ.it
  | NumT `NatT ->
      [
        NumV (`Nat (Bigint.of_int 1));
        NumV (`Nat (Bigint.of_int 4));
        NumV (`Nat (Bigint.of_int 6));
        NumV (`Nat (Bigint.of_int 8));
      ]
      |> Rand.random_select |> wrap_value_opt typ.it
  | NumT `IntT ->
      [
        NumV (`Int (Bigint.of_int (-2)));
        NumV (`Int (Bigint.of_int 0));
        NumV (`Int (Bigint.of_int 2));
        NumV (`Int (Bigint.of_int 3));
      ]
      |> Rand.random_select |> wrap_value_opt typ.it
  | TextT -> texts |> Rand.random_select |> wrap_value_opt typ.it
  | VarT (tid, targs) -> (
      let td = TDEnv.find_opt tid tdenv in
      match td with
      | Some (Defined (tparams, td)) -> (
          let theta = List.combine tparams targs |> TDEnv.of_list in
          match td.it with
          | PlainT typ ->
              typ |> Typ.subst_typ theta |> gen_from_typ depth tdenv texts
          | StructT typfields ->
              let atoms, typs = List.split typfields in
              let* values =
                typs |> Typ.subst_typs theta |> gen_from_typs depth tdenv texts
              in
              let valuefields = List.combine atoms values in
              StructV valuefields |> Option.some |> wrap_value_opt typ.it
          | VariantT typcases ->
              let nottyps' = List.map fst typcases |> List.map it in
              let nottyps' =
                List.map
                  (fun (mixop, typs) ->
                    let typs = Typ.subst_typs theta typs in
                    (mixop, typs))
                  nottyps'
              in
              let expand_nottyp' nottyp' =
                let mixop, typs = nottyp' in
                let* values = gen_from_typs depth tdenv texts typs in
                CaseV (mixop, values) |> Option.some
              in
              (* filters out failures *)
              List.map expand_nottyp' nottyps'
              |> List.filter Option.is_some |> List.map Option.get
              |> Rand.random_select |> wrap_value_opt typ.it)
      | _ -> None)
  | TupleT typs_inner ->
      let* values_inner = gen_from_typs depth tdenv texts typs_inner in
      TupleV values_inner |> Option.some |> wrap_value_opt typ.it
  | IterT (_, Opt) when depth = 0 ->
      OptV None |> Option.some |> wrap_value_opt typ.it
  | IterT (typ_inner, Opt) ->
      let choices : value' option list =
        [
          OptV None |> Option.some;
          (let* value_inner = gen_from_typ depth tdenv texts typ_inner in
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
      let len = Random.int 3 in
      let* values_inner =
        List.init len (fun _ -> typ_inner) |> gen_from_typs depth tdenv texts
      in
      ListV values_inner |> Option.some |> wrap_value_opt typ.it
  | FuncT -> None

and gen_from_typs (depth : int) (tdenv : TDEnv.t) (texts : value' list)
    (typs : typ list) : value list option =
  if depth <= 0 then None
  else
    List.fold_left
      (fun values_opt typ ->
        let* values = values_opt in
        let* value = gen_from_typ depth tdenv texts typ in
        Some (values @ [ value ]))
      (Some []) typs

let mutate_type_driven (tdenv : TDEnv.t) (texts : value' list) (value : value) :
    (kind * value) option =
  let typ = value.note.typ $ no_region in
  let depth = Random.int 4 + 1 in
  let value_opt = gen_from_typ depth tdenv texts typ in
  Option.map (fun value -> (GenFromTyp, value)) value_opt

(* Constructor mutation *)

let mutate_mixop (mixopenv : MixopEnv.t) (value : value) : (kind * value) option
    =
  let typ = value.note.typ in
  match typ with
  | VarT (id, _) -> (
      match value.it with
      | CaseV (mixop, values) ->
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
          let value = CaseV (mixop, values) |> wrap_value typ in
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
  | CaseV (mixop, values) ->
      let values_shuffled = List.map shuffle_list' values in
      CaseV (mixop, values_shuffled) |> wrap_value typ
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
  | CaseV (mixop, values) ->
      let values_duplicated = List.map duplicate_list' values in
      CaseV (mixop, values_duplicated) |> wrap_value typ
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
  | CaseV (mixop, values) ->
      let values_shrinked = List.map shrink_list' values in
      CaseV (mixop, values_shrinked) |> wrap_value typ
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
    (value : value) : (kind * value) option =
  match value.it with
  | ListV _ ->
      let* mutation =
        [
          (fun () -> mutate_list value);
          (fun () -> mutate_type_driven tdenv texts value);
        ]
        |> Rand.random_select
      in
      mutation ()
  | CaseV (_, _) ->
      let* mutation =
        [
          (fun () -> mutate_mixop mixopenv value);
          (fun () -> mutate_type_driven tdenv texts value);
        ]
        |> Rand.random_select
      in
      mutation ()
  | _ -> mutate_type_driven tdenv texts value

let mutate_walk (tdenv : TDEnv.t) (mixopenv : MixopEnv.t) (texts : value' list)
    (value : value) : (kind * value) option =
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
    | CaseV (_, values) | TupleV values | ListV values ->
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
        let* kind, value = mutate_node tdenv mixopenv texts value in
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
        | CaseV (mixop, values) ->
            let* values = rebuilds path idx values in
            CaseV (mixop, values) |> wrap_value typ |> Option.some
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

(* syntax subtype = SubT final heaptype* strtype hint(concrete "subtypeConcrete")
(* syntax subtype hint(concrete "subtypeConcrete") = AAA | BBB *)

(* syntax subtypeConcrete = SubT final typevar* strtype *)
(* syntax foo = A bar | B | C *)
(* syntax bar = D | E | F *)
(* foo : VarT ("foo", []) *)
(* tdenv : "foo" -> VariantT (A, B, C) "bar" -> Variant () *)
  (* tdenv["foo"] = VariantT (A -> [ VarT ("bar", []) ], B ->, C ->) *)
  (* tdenv["bar"] = ... *)

(* value_to_mutate --> value_to_mutate_concrete --> value_mutate_concrete --> value_mutate

   hint 가지고 잘........안되나? *)

(* Load type definitions into the environment *)

let load_def (tdenv : TDEnv.t) (tdenv_alias : TDEnv.t) (def : def) : TDEnv.t =
  match def.it with
  (* syntax subtype hint(concrete "subtypeConcrete") = AAA | BBB *)
  | TypD (id, tparams, deftyp, hints) ->
      let id_alias = match hints ... hint(concrete "subTypeConcrete" as id) -> id in
      let td_alias = TDEnv.find opt id in
      "subtype" -> "SubT final typevar* strtype"
      TDEnv.add id td_alias tdenv_alias
  | _ -> tdenv

(* Loader *)

let load_spec (tdenv : TDEnv.t) (spec : spec) :
    TDEnv.t =
  let tdenv_alias = TDEnv.empty in
  let tdenv_alias = List.fold_left (load_def tdenv) tdenv_alias spec in
  tdenv_alias

let rec magic (tdenv_alias : TDEnv.t) (value_to_mutate : value) : value =
  (*
    patch_value : tdenv (SubT final typevar* strtypeConcrete) (SubT AAA BBB CCC)
      --> (SubT AAA (BBB $ "typevar*") CCC) $ "subtypeConcrete"
    "subtype" -> SubT final typevar* strtype
    "valtype" -> ...
  *)
  match value_to_mutate.note.typ with
  | VarT (id, _) when TDEnv.mem id tdenv_alias -> (
      let td = TDEnv.find id tdenv_concrete_alias in
      let value_patched = patch_value tdenv_concrete_alias td value_to_mutate in


and patch tdenv td value_to_mutate =
  match value_to_mutate.it with
  | CaseV (_, value_sub) ->
      let value_sub_magic = magic tdenv value_sub in
      CaseV (mixop, value_sub_magic) |> wrap_value typ *)

(* tdenv 는 deftype 매핑만 들어감 *)

let rec choose_one (l : 'a option list) : 'a option =
  match l with
  | [] -> None
  | Some a :: _ -> Some a
  | None :: t -> choose_one t

let rec vid_exists (vid_target : vid) (value : value) : bool =
  if value.note.vid = vid_target then true
  else
    match value.it with
    | BoolV _ | NumV _ | TextV _ | FuncV _ | ExternV _ -> false
    | StructV valuefields ->
        let _, values = List.split valuefields in
        List.exists (vid_exists vid_target) values
    | CaseV (_, values) | TupleV values | ListV values ->
        List.exists (vid_exists vid_target) values
    | OptV None -> false
    | OptV (Some value) -> vid_exists vid_target value

let patch_program (tdenv : TDEnv.t) (tdenv_alias : TDEnvAlias.t) (value_to_mutate : value) (value_program : value) : value =
  (* Patching the type annotation of a value *)
  let patch_value (typ : typ') (value : value) : value =
    { value with note = { value.note with typ } }
  in
  (* Walker *)
  let rec walk (value : value) : value =
    let typ = value.note.typ in
    let value_patched =
      match typ with
      | VarT (id, targs) when TDEnvAlias.mem id tdenv_alias ->
          let id_alias = TDEnvAlias.find id tdenv_alias in
          patch id_alias targs value
      | _ -> value
    in
    match value_patched.it with
    | BoolV _ | NumV _ | TextV _ -> value_patched
    | StructV valuefields ->
      let atoms, values = List.split valuefields in
      let values_patched = List.map walk values in
      let valuefields_patched = List.combine atoms values_patched in
      { value_patched with it = StructV valuefields_patched }
    | CaseV (mixop, values) ->
      let values_patched = List.map walk values in
      { value_patched with it = CaseV (mixop, values_patched) }
    | TupleV values ->
      let values_patched = List.map walk values in
      { value_patched with it = TupleV values_patched }
    | OptV None -> value_patched
    | OptV (Some value) ->
      let value_patched = walk value in
      { value_patched with it = OptV (Some value_patched) }
    | ListV values ->
      let values_patched = List.map walk values in
      { value_patched with it = ListV values_patched }
    | FuncV _ | ExternV _ -> value_patched
  (* Patcher *)
  and patch (id_alias : TId.t) (targs : targ list) (value : value) : value =
    let td_alias = TDEnv.find id_alias tdenv in
    match td_alias with
    | Defined (tparams, deftyp) -> (
        let theta = List.combine tparams targs |> TIdMap.of_list in
        match (deftyp.it, value.it) with
        | VariantT typcases, CaseV (mixop_value, values_sub) ->
            let typs_sub =
              match
                List.find_map
                  (fun (nottyp, _) ->
                    let mixop_typ, typs_sub = nottyp.it in
                    if Mixop.eq mixop_typ mixop_value then Some typs_sub else None)
                  typcases
              with
              | Some typs_sub -> typs_sub
              | None ->
                  Printf.eprintf
                    "[patch_program] patch: no typcase for mixop\n\
                     [patch_program] mixop_value: %s\n%!"
                    (Il.Print.string_of_mixop mixop_value);
                  List.iteri
                    (fun idx (nottyp, _) ->
                      let mixop_typ, typs_sub = nottyp.it in
                      Printf.eprintf
                        "[patch_program] typcase[%d] mixop_typ: %s\n\
                         [patch_program] typcase[%d] typs_sub: [%s]\n%!"
                        idx
                        (Il.Print.string_of_mixop mixop_typ)
                        idx
                        (Il.Print.string_of_typs ", " typs_sub))
                    typcases;
                  failwith "patch: no typcase for mixop"
            in
            let typs_sub = Typ.subst_typs theta typs_sub in
            let values_sub =
              List.map2 (fun typ_sub value_sub -> patch_value typ_sub.it value_sub) typs_sub values_sub
            in
            let typ_patch = VarT (id_alias, targs) in
            patch_value typ_patch { value with it = CaseV (mixop_value, values_sub) }
        | StructT typfields, StructV valuefields ->
            let valuefields =
              List.map2
                (fun typfield valuefield ->
                  let atom_typ, typ_sub = typfield in
                  let atom_value, value_sub = valuefield in
                  assert (Atom.eq atom_typ atom_value);
                  let typ_sub = Typ.subst_typ theta typ_sub in
                  let value_sub = patch_value typ_sub.it value_sub in
                  (atom_value, value_sub))
                typfields valuefields
            in
            let typ_patch = VarT (id_alias, targs) in
            patch_value typ_patch { value with it = StructV valuefields }
        (* Not quite sure *)
        | PlainT typ, _ ->
            let typ = Typ.subst_typ theta typ in
            patch_value typ.it value
         | _ -> failwith "patch: type mismatch between deftyp and value"
            )
    | _ -> assert false
  in
  (* Picker *)
  let vid_target = value_to_mutate.note.vid in
  let rec pick (value : value) : value option =
    if value.note.vid = vid_target then Some value
    else
      match value.it with
      | BoolV _ | NumV _ | TextV _ -> None
      | StructV valuefields ->
        let _, values = List.split valuefields in
        values |> List.map pick |> choose_one
      | CaseV (_, values) -> values |> List.map pick |> choose_one
      | TupleV values -> values |> List.map pick |> choose_one
      | OptV None -> None
      | OptV (Some value) -> pick value
      | ListV values -> values |> List.map pick |> choose_one
      | FuncV _ | ExternV _ -> None
  in
  let value_program = walk value_program in
  let value_to_mutate_opt = pick value_program in
  match value_to_mutate_opt with
  | Some value_to_mutate -> value_to_mutate
  | None ->
      Printf.eprintf
        "[patch_program] pick returned None (target vid=%d)\n\
         [patch_program] value_to_mutate:\n%s\n\
         [patch_program] value_program:\n%s\n%!"
        value_to_mutate.note.vid
        (Il.Print.string_of_value value_to_mutate)
        (Il.Print.string_of_value value_program);
      failwith "patch_program: pick returned None"

let patch_program2 (tdenv : TDEnv.t) (value_to_mutate : value) (value_program : value) : value =
  (* Patching the type annotation of a value *)
  let patch_value (typ : typ') (value : value) : value =
    { value with note = { value.note with typ } }
  in
  (* Walker *)
  let rec walk (value : value) : value =
    let typ = value.note.typ in
    let value_patched =
      match typ, value.it with
      | BoolT, _ | NumT _, _ | TextT, _ -> value
      | VarT (id, targs), _ -> patch id targs value
      | TupleT typs, TupleV values ->
        assert (List.length typs = List.length values);
        let values_patched = List.map2 (fun typ value -> patch_value typ.it value) typs values in
        { value with it = TupleV values_patched }
      | IterT (typ_inner, Opt), OptV value_opt -> (
          match value_opt with
          | None -> value
          | Some value_inner ->
              let value_patched = patch_value typ_inner.it value_inner in
              { value with it = OptV (Some value_patched) })
      | IterT (typ_inner, List), ListV values ->
          let values_patched = List.map (patch_value typ_inner.it) values in
          { value with it = ListV values_patched }
      | FuncT, _ -> value
      | _ -> value
    in
    match value_patched.it with
    | BoolV _ | NumV _ | TextV _ -> value_patched
    | StructV valuefields ->
      let atoms, values = List.split valuefields in
      let values_inner_patched = List.map walk values in
      let valuefields_patched = List.combine atoms values_inner_patched in
      { value_patched with it = StructV valuefields_patched }
    | CaseV (mixop, values) ->
      let values_inner_patched = List.map walk values in
      { value_patched with it = CaseV (mixop, values_inner_patched) }
    | TupleV values ->
      let values_inner_patched = List.map walk values in
      { value_patched with it = TupleV values_inner_patched }
    | OptV None -> value_patched
    | OptV (Some value) ->
      let value_inner_patched = walk value in
      { value_patched with it = OptV (Some value_inner_patched) }
    | ListV values ->
      let values_inner_patched = List.map walk values in
      { value_patched with it = ListV values_inner_patched }
    | FuncV _ | ExternV _ -> value_patched
  (* Patcher *)
  and patch (id : TId.t) (targs : targ list) (value : value) : value =
    let td_alias = TDEnv.find id tdenv in
    match td_alias with
    | Defined (tparams, deftyp) -> (
        let len_tparams = List.length tparams in
        let len_targs = List.length targs in
        Printf.eprintf
          "[patch_program2] id=%s tparams_len=%d targs_len=%d\n\
           [patch_program2] tparams=%s\n\
           [patch_program2] targs=%s\n%!"
          (TId.to_string id)
          len_tparams
          len_targs
          (Il.Print.string_of_tparams tparams)
          (Il.Print.string_of_targs targs);
        if len_tparams <> len_targs then
          Printf.eprintf
            "[patch_program2] length mismatch detected\n\
             [patch_program2] deftyp=%s\n\
             [patch_program2] value.it=%s\n%!"
            (Il.Print.string_of_deftyp deftyp)
            (Il.Print.string_of_value value);
        assert (len_tparams = len_targs);
        let theta = List.combine tparams targs |> TIdMap.of_list in
        match (deftyp.it, value.it) with
        | VariantT typcases, CaseV (mixop_value, values_sub) ->
            let typs_sub =
              match
                List.find_map
                  (fun (nottyp, _) ->
                    let mixop_typ, typs_sub = nottyp.it in
                    if Mixop.eq mixop_typ mixop_value then Some typs_sub else None)
                  typcases
              with
              | Some typs_sub -> typs_sub
              | None ->
                  Printf.eprintf
                    "[patch_program2] patch: no typcase for mixop\n\
                     [patch_program2] mixop_value: %s\n%!"
                    (Il.Print.string_of_mixop mixop_value);
                  List.iteri
                    (fun idx (nottyp, _) ->
                      let mixop_typ, typs_sub = nottyp.it in
                      Printf.eprintf
                        "[patch_program2] typcase[%d] mixop_typ: %s\n\
                         [patch_program2] typcase[%d] typs_sub: [%s]\n%!"
                        idx
                        (Il.Print.string_of_mixop mixop_typ)
                        idx
                        (Il.Print.string_of_typs ", " typs_sub))
                    typcases;
                  failwith "patch: no typcase for mixop"
            in
            let typs_sub = Typ.subst_typs theta typs_sub in
            let values_sub =
              List.map2 (fun typ_sub value_sub -> patch_value typ_sub.it value_sub) typs_sub values_sub
            in
            let typ_patch = VarT (id, targs) in
            patch_value typ_patch { value with it = CaseV (mixop_value, values_sub) }
        | StructT typfields, StructV valuefields ->
            let valuefields =
              List.map2
                (fun typfield valuefield ->
                  let atom_typ, typ_sub = typfield in
                  let atom_value, value_sub = valuefield in
                  assert (Atom.eq atom_typ.it atom_value.it);
                  let typ_sub = Typ.subst_typ theta typ_sub in
                  let value_sub = patch_value typ_sub.it value_sub in
                  (atom_value, value_sub))
                typfields valuefields
            in
            let typ_patch = VarT (id, targs) in
            patch_value typ_patch { value with it = StructV valuefields }
        (* Not quite sure *)
        | PlainT typ, _ ->
            let typ = Typ.subst_typ theta typ in
            patch_value typ.it value
         | _ -> failwith "patch: type mismatch between deftyp and value"
            )
    | _ -> assert false
  in
  (* Picker *)
  let vid_target = value_to_mutate.note.vid in
  let rec pick (value : value) : value option =
    if value.note.vid = vid_target then Some value
    else
      match value.it with
      | BoolV _ | NumV _ | TextV _ -> None
      | StructV valuefields ->
        let _, values = List.split valuefields in
        values |> List.map pick |> choose_one
      | CaseV (_, values) -> values |> List.map pick |> choose_one
      | TupleV values -> values |> List.map pick |> choose_one
      | OptV None -> None
      | OptV (Some value) -> pick value
      | ListV values -> values |> List.map pick |> choose_one
      | FuncV _ | ExternV _ -> None
  in
  let value_program_input = value_program in
  let value_program = walk value_program_input in
  let value_to_mutate_opt = pick value_program in
  match value_to_mutate_opt with
  | Some value_to_mutate -> value_to_mutate
  | None ->
      let exists_in_input = vid_exists vid_target value_program_input in
      let exists_in_walked = vid_exists vid_target value_program in
      Printf.eprintf
        "[patch_program2] pick returned None (target vid=%d)\n\
         [patch_program2] vid_exists(input_program)=%b\n\
         [patch_program2] vid_exists(walked_program)=%b\n\
         [patch_program2] value_to_mutate:\n%s\n\
         [patch_program2] value_program:\n%s\n%!"
        value_to_mutate.note.vid
        exists_in_input
        exists_in_walked
        (Il.Print.string_of_value value_to_mutate)
        (Il.Print.string_of_value value_program);
      failwith "patch_program2: pick returned None"
(* let magic (tdenv : TDEnv.t) (tdenv_alias : TDEnvAlias.t) (value_program : value) (value_to_mutate : value) : value =
  (* Patching the type annotation of a value *)
  let patch_value (typ : typ') (value : value) : value =
    { value with note = { value.note with typ } }
  in
  (* Walker *)
  let rec walk (value : value) : value =
    let typ = value.note.typ in
    let value_patched =
      match typ with
      | VarT (id, targs) when TDEnvAlias.mem id tdenv_alias ->
          let id_alias = TDEnvAlias.find id tdenv_alias in
          let td_alias = TDEnv.find id_alias tdenv in
          patch id_alias targs value
      | _ -> value
    in
    match value_patched.it with
    | BoolV | NumV _ | TextV -> value_patched
    | TupleV values ->
        let values_patched = List.map walk values in
        { value_patched with it = TupleV values_patched }
    | ...
  in
  (* Patcher *)
  and patch (id_alias : TId.t) (targs : targ list) (value : value) : value =
    let td_alias = TDEnv.find id_alias tdenv in
    match td_alias with
    | Defined (tparams, deftyp) -> (
        let theta = List.combine tparams targs |> TIdMap.of_list in
        match (deftyp.it, value.it) with
        | VariantT typcases, CaseV (mixop_value, values_sub) ->
            let typs_sub =
              List.find_map
                (fun (nottyp, _) ->
                  let mixop_typ, typs_sub = nottyp.it in
                  if Mixop.eq mixop_typ mixop_value then Some typs_sub else None)
                typcases
            in
            let typs_sub = Subst.subst_typs theta typs_sub in
            let values_sub =
              List.map2 (fun typ_sub value_sub -> patch_value typ_sub.it value_sub) typs_sub values_sub
            in
            let typ_patch = VarT (id_alias, targs) in
            CaseV (mixop_value, values_sub) (* with note { typ = typ_patch } *)
        | StructT typfields, StructV valuefields ->
            let valuefields_sub =
              List.map2
                (fun typfield valuefield ->
                  let atom_typ, typ_sub = typfield in
                  let atom_value, value_sub = valuefield in
                  assert (Atom.eq atom_typ atom_value);
                  let typ_sub = Subst.subst_typ theta typ_sub in
                  let value_sub = patch_value typ_sub it value_sub in
                  (atom_value, value_sub))
                typfields valuefields
            in
            StructV valuefields_sub (* with note { typ = typ_patch } *)
        (* Not quite sure *)
        | PlainT typ, _ ->
            let typ = Subst.subst_typ theta typ in
            patch_value typ.it value)
    | _ -> assert false
  in
  (* Picker *)
  let vid_target = value_to_mutate.note.vid in
  let rec pick (value : value) : value option =
    if value.note.vid = vid_target then Some value
    else
      match value.it with
      | BoolV | NumV _ | TextV -> None
      | TupleV values -> values |> List.map pick |> choose_one |> Option.value ~default:value
      | ...
  in
  let value_program = walk value_program in
  let value_to_mutate = pick value_program |> Option.get in *)



(* let rec choose_one (l : 'a option list) : 'a option =
  match l with
  | [] -> None
  | Some a :: _ -> Some a
  | None :: t -> choose_one t

let rec patch_walk (tdenv : TDEnv.t) (tdenv_alias : TDEnvAlias.t) (value_to_mutate : value) (value_program : value) : value option =
  match value_program.note.typ with
  | BoolT | NumT _ | TextT | TupleT _ | IterT _ | FuncT ->
    let patched_value_opt = patch_value tdenv tdenv_alias None value_to_mutate value_program in
    (match patched_value_opt with
    | Some patched_value -> patched_value.it |> wrap_value patched_value.note.typ |> Option.some
    | None -> None
    )
  | VarT (id, _) ->
    (* "subtype" 인 경우, tdenv_alias에 [ "subtype" -> "subtypeConcrete" ] 매핑이 있는지 확인하는 작업 *)
    let id_alias_opt = TDEnvAlias.find_opt id tdenv_alias in (* alias가 있으면 Some id_alias, 없으면 None *)
    let patched_value_opt = patch_value tdenv tdenv_alias id_alias_opt value_to_mutate value_program in
    (match patched_value_opt with
    | Some patched_value ->
      (match id_alias_opt with
      | Some id_alias -> patched_value.it |> wrap_value (VarT (id_alias, [])) |> Option.some
      | None -> patched_value_opt
      )
    | None when value_program.note.vid = value_to_mutate.note.vid -> Some value_to_mutate
    | None -> None
    )

and patch_value (tdenv : TDEnv.t) (tdenv_alias : TDEnvAlias.t) (id_alias_opt : id option)
  (value_to_mutate : value) (value_program : value) : value option =
  match id_alias_opt with
  | Some id_alias -> (* "subtypeConcrete" *)
    let td = TDEnv.find id_alias tdenv in (* SubT final typevarConcrete* strtype *)
    (match td with
    | Defined (_, deftyp) ->
      (match deftyp.it with
      | VariantT typcases ->
        let typcases = List.map (fun (nottyp, _) -> nottyp.it) typcases in (* (mixop * typ list) list *)
        (match value_program.it with
        | CaseV (mixop, sub_values) ->
          let typs_opt = List.find_map (fun (mixop', typs) -> if Mixop.eq mixop mixop' then Some typs else None) typcases in
          (match typs_opt with
          | Some typs ->
            (*
            patch_values : value list -> typ list -> value list
            sub_values들을 concrete type으로 resolving 해주는 함수임.
            일단 patch_walk에서 현재 패치하고 있는 value_program이 subtype이라고 하자.
            그러면 id_alias = "subtypeConcrete" 이고, td -> SubT final typevarConcrete* strtype 이다.
            subtype에 대한 metatype 정의는 다음과 같다.
            ```
              syntax subtype = SubT final heaptype* strtype
              syntax subtypeConcrete = SubT final typevarConcrete* strtype
            ```
            value_program이 subtype인 CaseV (mixop, sub_values) 라고 하면,
            mixop = [ ["SubT"], [], [], [] ] 이고, sub_values = [ final; heaptype*; strtype ] 이다.

            VariantT typcases 이 (mixop * typ list) list 이라고 했을 때,
            mixop = [ ["SubT"], [], [], [] ] 인 typcase와 그에 대응하는 typ list = [ final; typevarConcrete*; strtype ] 을 갖는다.
            우리는 heaptype* value의 type annotation을 typevarConcrete*로 바꿔줘야 하는데, 이를 sub_values와 typs 를 넘겨줘서 하는 것이다.

            그 다음 각각의 sub_values에 대해서 patch_walk를 재귀적으로 호출.
            *)
            let sub_values = patch_values sub_values typs in
            let sub_values_patched = List.map (patch_walk tdenv tdenv_alias value_to_mutate) sub_values in
            sub_values_patched |> choose_one |>
            (function
            | Some v -> Some v
            | None when value_program.note.vid = value_to_mutate.note.vid -> Some value_to_mutate
            | _ -> None
            )
          | None -> failwith "patch_value': mixop not found in typcases"
          )
        | _ -> failwith "patch_value': expected CaseV"
        )
      | StructT typfields ->
        (match value_program.it with
        | StructV valuefields ->
          let _, sub_values = List.split valuefields in
          let _, typs = List.split typfields in
          let sub_values = patch_values sub_values typs in
          let sub_values_patched = List.map (patch_walk tdenv tdenv_alias value_to_mutate) sub_values in
          sub_values_patched |> choose_one |>
          (function
          | Some v -> Some v
          | None when value_program.note.vid = value_to_mutate.note.vid -> Some value_to_mutate
          | _ -> None
          )
        | _ -> failwith "patch_value': expected StructV"
        )
      | PlainT _ ->
        let sub_value_patched = patch_walk tdenv tdenv_alias value_to_mutate value_program in
        (match sub_value_patched with
        | Some sub_value_patched -> Some sub_value_patched
        | None when value_program.note.vid = value_to_mutate.note.vid -> Some value_to_mutate
        | None -> None
        )
      )
    | _ -> failwith "patch_value': expected Defined"
    )
  | None ->
    (match value_program.it with
    | BoolV _ | NumV _ | TextV _ | FuncV _ | ExternV _ ->
      if value_program.note.vid = value_to_mutate.note.vid then Some value_to_mutate
      else None
    | CaseV (_, sub_values) ->
      let sub_values_patched = List.map (patch_walk tdenv tdenv_alias value_to_mutate) sub_values in
      sub_values_patched |> choose_one |>
      (function
      | Some v -> Some v
      | None when value_program.note.vid = value_to_mutate.note.vid -> Some value_to_mutate
      | None -> None
      )
    | StructV valuefields ->
      let _, sub_values = List.split valuefields in
      let sub_values_patched = List.map (patch_walk tdenv tdenv_alias value_to_mutate) sub_values in
      sub_values_patched |> choose_one |>
      (function
      | Some v -> Some v
      | None when value_program.note.vid = value_to_mutate.note.vid -> Some value_to_mutate
      | None ->  (*ddd*)
      )
    | TupleV sub_values ->
      let sub_values_patched = List.map (patch_walk tdenv tdenv_alias value_to_mutate) sub_values in
      sub_values_patched |> choose_one |>
      (function
      | Some v -> Some v
      | None when value_program.note.vid = value_to_mutate.note.vid -> Some value_to_mutate
      | None -> None
      )
    | OptV value_opt -> (
      match value_opt with
      | None ->
        if value_program.note.vid = value_to_mutate.note.vid then Some value_to_mutate
        else None
      | Some value ->
        let value_patched = patch_walk tdenv tdenv_alias value_to_mutate value in
        (match value_patched with
        | Some value_patched -> OptV (Some value_patched) |> wrap_value value_patched.note.typ |> Option.some
        | None when value_program.note.vid = value_to_mutate.note.vid -> Some value_to_mutate
        | None -> None
        )
    )
    | ListV sub_values ->
      let sub_values_patched = List.map (patch_walk tdenv tdenv_alias value_to_mutate) sub_values in
      sub_values_patched |> choose_one |>
      (function
      | Some v -> Some v
      | None when value_program.note.vid = value_to_mutate.note.vid -> Some value_to_mutate
      | None -> None
      )
    )

and patch_values (values : value list) (typs : typ list) : value list =
  List.map2 (fun value typ -> value.it |> wrap_value typ.it) values typs *)

(* Recursively patch the type annotation of a value *)
(* let patch_program3 (tdenv : TDEnv.t) (typ : typ) (value : value) : value =
  match typ.it with
  | BoolT ->
    (match value.it with
    | BoolV _ -> value
    | _ -> failwith "patch_program3: type mismatch")
  | NumT _ ->
    (match value.it with
    | NumV _ -> value
    | _ -> failwith "patch_program3: type mismatch")
  | TextT ->
    (match value.it with
    | TextV _ -> value
    | _ -> failwith "patch_program3: type mismatch")
  | VarT (id, targs) ->
  | TupleT typs ->
    (match value.it with
    | TupleV values ->

      )
  | IterT (typ_inner, Opt) ->
  | IterT (typ_inner, List) ->
  | FuncT -> value *)

let mutate (tdenv : TDEnv.t) (mixopenv : MixopEnv.t) (texts : value' list)
    (vdg : Dep.Graph.t) (vid_source : vid) : (kind * value * value) option =
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
  let* kind, value_mutated = mutate_walk tdenv mixopenv texts value_to_mutate in
  (kind, value_to_mutate, value_mutated) |> Option.some

let mutatew (tdenv : TDEnv.t) (mixopenv : MixopEnv.t) (texts : value' list)
    (vdg : Dep.Graph.t) (vid_source : vid) : (kind * value * value) option =
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
  (* 이 value_to_mutate의 type annotation을 typeConcrete annotation으로 바꿔주어야 함 *)
  let value_to_mutate =
    Dep.Graph.reassemble_graph vdg VIdMap.empty vid_to_mutate
  in
  let value_program =
    Dep.Graph.reassemble_graph_from_root vdg VIdMap.empty
  in
  let value_to_mutate_concrete =
    patch_program2 tdenv value_to_mutate value_program
  in
  (* Mutate the node *)
  let* kind, value_mutated = mutate_walk tdenv mixopenv texts value_to_mutate_concrete in
  (kind, value_to_mutate_concrete, value_mutated) |> Option.some

let mutates (fuel_mutate : int) (tdenv : TDEnv.t) (mixopenv : MixopEnv.t)
    (vdg : Dep.Graph.t) (vid_source : vid) : (kind * value * value) list =
  (* Collect the text pool *)
  let texts =
    List.init (vdg.root + 1) Fun.id
    |> List.filter_map (fun vid ->
           let* mirror, _ = Dep.Graph.find_node vdg vid in
           match mirror.it with TextN text -> Some (TextV text) | _ -> None)
  in
  let texts = texts @ [ TextV "lazy"; TextV "fox" ] in
  (* Do mutations *)
  List.init fuel_mutate (fun _ -> mutate tdenv mixopenv texts vdg vid_source)
  |> List.filter_map Fun.id

let mutatesw (fuel_mutate : int) (tdenv : TDEnv.t) (mixopenv : MixopEnv.t)
    (vdg : Dep.Graph.t) (vid_source : vid) : (kind * value * value) list =
  (* Collect the text pool *)
  let texts =
    List.init (vdg.root + 1) Fun.id
    |> List.filter_map (fun vid ->
           let* mirror, _ = Dep.Graph.find_node vdg vid in
           match mirror.it with TextN text -> Some (TextV text) | _ -> None)
  in
  let texts = texts @ [ TextV "lazy"; TextV "fox" ] in
  (* Do mutations *)
  List.init fuel_mutate (fun _ -> mutatew tdenv mixopenv texts vdg vid_source)
  |> List.filter_map Fun.id
