(** Allocation guard for mutated instantiation and invocation candidates.

    P4-SpecTec materializes every byte of a memory and every reference of a
    table when it instantiates a module. A mutated minimum such as 65536 pages
    therefore exhausts host memory in a single allocation, which neither the
    candidate nor the seed timer can interrupt. A candidate whose locally
    defined memory or table minimum exceeds these bounds is an external limit,
    like a timeout, and is not evaluated. Imported memories and tables are
    allocated by their provider and are not checked. *)

val max_memory_pages : int64
(** About 0.6 GB and under a second to instantiate; seeds use at most 5. *)

val max_table_elems : int64
(** About 0.2 GB; seeds use at most 128. Table instantiation grows faster
    than linearly: 65536 elements take about 16 GB. *)

val exceeded : Lang.Il.value -> string option
(** The first locally defined memory or table of the module whose minimum
    exceeds its bound, described for the log, or [None]. A module that does
    not decode is left to the evaluation, which reports it. *)
