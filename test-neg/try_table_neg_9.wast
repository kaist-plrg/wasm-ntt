(assert_invalid
  (module
    (type $t (func))
    (tag $e (param (ref null $t)))
    (func (export "catch_ref") (result (ref $t))
      (block $l (result (ref $t) (ref exn))
        (try_table (catch $e $l))
        (unreachable)
      )
    )
  )
  "type mismatch"
)
