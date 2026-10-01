(** Repeat-hit collection for the invocation phase.

    A dangling premise normally stops being a fuzzing target once it is hit.
    With repeat collection on, a premise stays a target after its first hit
    until [hits] more distinct stuck programs have been kept for it, or until
    [fuel] fuels have passed since the first hit: the visit that hit it goes
    on, and each later fuel revisits it once. Repeat programs never change the
    campaign coverage. *)

type options = {
  hits : int;  (** repeat programs kept per premise; 0 turns collection off *)
  fuel : int option;
      (** fuels after the first hit during which the premise is revisited;
          [None] revisits it until [hits] is reached *)
}

val default_options : options

type t

val create : options -> t
val options : t -> options
val enabled : t -> bool

val record_first_hit :
  t -> iid:int -> fuel:int -> seeds:string list -> digest:string option -> unit
(** Remember the close-miss seeds of a premise at its first hit, before the
    campaign coverage replaces them by the artifact path. [digest] is the
    module of that first artifact, so that a repeat of it is not kept. Only
    the first call for an [iid] has an effect; empty [seeds] are ignored. *)

val tracked : t -> iid:int -> bool

val wants : t -> iid:int -> fuel:int -> bool
(** Whether a hit premise should still be fuzzed during [fuel]. *)

val targets : t -> fuel:int -> (int * string list) list
(** The premises to revisit during [fuel]: those that {!wants} and were first
    hit in an earlier fuel, with their recorded seeds, in ascending iid
    order. *)

type admission = Admit | Duplicate | Quota | Untracked

val admission : t -> iid:int -> digest:string -> admission

val commit : t -> iid:int -> digest:string -> int
(** Count a kept repeat program; returns the number kept for [iid]. *)

val saved : t -> iid:int -> int
val total_saved : t -> int

val digest_of_module : Lang.Il.value -> string
(** Identity of a candidate module for duplicate detection: a digest of its
    printed structure, which carries no value ids. *)
