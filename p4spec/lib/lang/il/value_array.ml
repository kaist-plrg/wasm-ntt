type 'a t = 'a array

let empty = [||]
let of_array values = Array.copy values
let to_array values = Array.copy values
let of_list = Array.of_list
let to_list = Array.to_list
let init = Array.init
let length = Array.length
let get = Array.get
let sub = Array.sub

let cons value values =
  let len = length values in
  init (len + 1) (fun index ->
      if index = 0 then value else Array.get values (index - 1))

let append = Array.append
let map = Array.map
let mapi = Array.mapi
let iter = Array.iter
let iteri = Array.iteri
let fold_left = Array.fold_left
let exists = Array.exists
let for_all = Array.for_all
let for_all2 predicate values_l values_r =
  length values_l = length values_r
  && Array.for_all2 predicate values_l values_r

let copy_set values index value =
  let updated = Array.copy values in
  Array.set updated index value;
  updated

let replace_slice values ~pos replacement =
  let updated = Array.copy values in
  Array.blit replacement 0 updated pos (Array.length replacement);
  updated

let compare compare_element values_l values_r =
  let len_l = length values_l in
  let len_r = length values_r in
  let rec compare_at index =
    if index = len_l then Int.compare len_l len_r
    else if index = len_r then 1
    else
      let result =
        compare_element (Array.get values_l index) (Array.get values_r index)
      in
      if result = 0 then compare_at (index + 1) else result
  in
  compare_at 0

let equal equal_element values_l values_r =
  let len = length values_l in
  len = length values_r
  &&
  let rec equal_at index =
    index = len
    ||
    (equal_element (Array.get values_l index) (Array.get values_r index)
    && equal_at (index + 1))
  in
  equal_at 0

let to_yojson element_to_yojson values =
  `List (values |> Array.to_list |> List.map element_to_yojson)

let of_yojson element_of_yojson = function
  | `List jsons ->
      let rec convert converted_rev = function
        | [] -> Ok (converted_rev |> List.rev |> Array.of_list)
        | json :: jsons -> (
            match element_of_yojson json with
            | Ok value -> convert (value :: converted_rev) jsons
            | Error _ as error -> error)
      in
      convert [] jsons
  | _ -> Error "expected a JSON list"
