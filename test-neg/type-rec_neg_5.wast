(assert_invalid
  (module
    (rec
      (type $s (struct))
      (type $t (func (param (ref $s))))
    )
    (func $f (param (ref $s)))  ;; type is not equivalent to $t
    (global (ref $t) (ref.func $f))
  )
  "type mismatch"
)
