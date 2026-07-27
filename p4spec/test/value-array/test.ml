open Lang.Il

module A = Value_array
module Typ = Runtime.Type.Typ
module Value = Runtime.Value

let expect_equal expected actual =
  assert (A.equal Int.equal expected actual)

let int_of_yojson = function
  | `Int n -> Ok n
  | _ -> Error "expected an integer"

let () =
  let source = [| 1; 2 |] in
  let isolated = A.of_array source in
  source.(0) <- 99;
  assert (A.get isolated 0 = 1);
  let exposed_copy = A.to_array isolated in
  exposed_copy.(1) <- 99;
  assert (A.get isolated 1 = 2);

  let original = A.of_list [ 1; 2; 3; 4 ] in
  assert (A.length original = 4);
  assert (A.get original 2 = 3);
  assert (A.to_list original = [ 1; 2; 3; 4 ]);
  expect_equal (A.of_list [ 2; 3 ]) (A.sub original 1 2);
  expect_equal (A.of_list [ 0; 1; 2; 3; 4 ]) (A.cons 0 original);
  expect_equal
    (A.of_list [ 1; 2; 3; 4; 5; 6 ])
    (A.append original (A.of_list [ 5; 6 ]));

  let index_updated = A.copy_set original 1 20 in
  expect_equal (A.of_list [ 1; 20; 3; 4 ]) index_updated;
  expect_equal (A.of_list [ 1; 2; 3; 4 ]) original;

  let slice_updated =
    A.replace_slice original ~pos:1 (A.of_list [ 20; 30 ])
  in
  expect_equal (A.of_list [ 1; 20; 30; 4 ]) slice_updated;
  expect_equal (A.of_list [ 1; 2; 3; 4 ]) original;

  assert (A.compare Int.compare original (A.of_list [ 1; 2; 3; 4 ]) = 0);
  assert (A.compare Int.compare original (A.of_list [ 1; 2; 4 ]) < 0);
  assert (not (A.for_all2 Int.equal original (A.of_list [ 1; 2; 3 ])));

  let json = A.to_yojson (fun n -> `Int n) original in
  assert (json = `List [ `Int 1; `Int 2; `Int 3; `Int 4 ]);
  (match A.of_yojson int_of_yojson json with
  | Ok roundtrip -> expect_equal original roundtrip
  | Error message -> failwith message);

  let values =
    [ Value.Make.nat (Bigint.of_int 1); Value.Make.nat (Bigint.of_int 2) ]
  in
  let typ = Typ.Make.list Typ.Make.nat in
  let value_l = Value.Make.list typ values in
  let value_r = Value.Make.list typ values in
  assert (Value.eq value_l value_r);
  assert (value_l.note.vhash = value_r.note.vhash);
  let value_updated =
    value_l |> Value.Get.list_array
    |> fun payload ->
    A.copy_set payload 0 (Value.Make.nat (Bigint.of_int 3))
    |> Value.Make.list_array typ
  in
  assert (value_l.note.vid <> value_updated.note.vid);
  assert (value_l.note.vhash <> value_updated.note.vhash);
  assert (not (Value.eq value_l value_updated));
  assert (
    Value.Get.list value_l |> List.map Value.Get.num
    = [ `Nat (Bigint.of_int 1); `Nat (Bigint.of_int 2) ]);
  assert (
    Value.Get.list value_updated |> List.map Value.Get.num
    = [ `Nat (Bigint.of_int 3); `Nat (Bigint.of_int 2) ]);
  let value_json = Value.to_yojson value_l in
  match Value.of_yojson value_json with
  | Ok value_roundtrip ->
      assert (
        Value.Get.list value_roundtrip |> List.map Value.Get.num
        = [ `Nat (Bigint.of_int 1); `Nat (Bigint.of_int 2) ]);
      assert (value_roundtrip.note.vhash = value_l.note.vhash)
  | Error message -> failwith message
