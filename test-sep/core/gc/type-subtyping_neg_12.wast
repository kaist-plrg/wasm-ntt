(assert_invalid
  (module
    (type $s0 (sub (struct)))
    (type $f0 (sub $s0 (func (param i32) (result i32))))
  )
  "sub type"
)
