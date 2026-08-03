open Util.Source

type run = {
  rel_id : Lang.Sl.id;
  count : int;
}

type t = run list

let empty = []

let same_id (left : Lang.Sl.id) (right : Lang.Sl.id) =
  left.it = right.it && left.at = right.at

let push id history =
  match history with
  | ({ rel_id = head_id; count } as head) :: tail when same_id id head_id ->
      { head with count = count + 1 } :: tail
  | _ -> { rel_id = id; count = 1 } :: history

let relation_trace rel_id =
  ( rel_id.at,
    fun () -> Format.asprintf "relation %s failed" rel_id.it )

let rec prepend_repeated trace count traces =
  if count = 0 then traces
  else prepend_repeated trace (count - 1) (trace :: traces)

let expand history traces =
  List.fold_left
    (fun traces { rel_id; count } ->
      prepend_repeated (relation_trace rel_id) count traces)
    traces history

let nest history current backtrace =
  let history = push current history in
  match backtrace with
  | Interp_common.Backtrace.Err traces ->
      Interp_common.Backtrace.Err (expand history traces)
  | Interp_common.Backtrace.Unmatch traces ->
      Interp_common.Backtrace.Unmatch (expand history traces)
