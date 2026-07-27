type 'a t

val empty : 'a t
val of_array : 'a array -> 'a t
val to_array : 'a t -> 'a array
val of_list : 'a list -> 'a t
val to_list : 'a t -> 'a list
val init : int -> (int -> 'a) -> 'a t
val length : 'a t -> int
val get : 'a t -> int -> 'a
val sub : 'a t -> int -> int -> 'a t
val cons : 'a -> 'a t -> 'a t
val append : 'a t -> 'a t -> 'a t
val map : ('a -> 'b) -> 'a t -> 'b t
val mapi : (int -> 'a -> 'b) -> 'a t -> 'b t
val iter : ('a -> unit) -> 'a t -> unit
val iteri : (int -> 'a -> unit) -> 'a t -> unit
val fold_left : ('a -> 'b -> 'a) -> 'a -> 'b t -> 'a
val exists : ('a -> bool) -> 'a t -> bool
val for_all : ('a -> bool) -> 'a t -> bool
val for_all2 : ('a -> 'b -> bool) -> 'a t -> 'b t -> bool
val copy_set : 'a t -> int -> 'a -> 'a t
val replace_slice : 'a t -> pos:int -> 'a t -> 'a t
val compare : ('a -> 'a -> int) -> 'a t -> 'a t -> int
val equal : ('a -> 'a -> bool) -> 'a t -> 'a t -> bool
val to_yojson : ('a -> Yojson.Safe.t) -> 'a t -> Yojson.Safe.t

val of_yojson :
  (Yojson.Safe.t -> ('a, string) result) ->
  Yojson.Safe.t ->
  ('a t, string) result
