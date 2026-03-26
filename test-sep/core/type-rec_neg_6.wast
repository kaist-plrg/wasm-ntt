(assert_invalid
  (module
    (rec
      (type (struct))
      (type $t (func))
    )
    (func $f)  ;; type is not equivalent to $t
    (global (ref $t) (ref.func $f))
  )
  "type mismatch"
)
