(assert_invalid
  (module
    (type $f0 (sub (func (param i32) (result i32))))
    (type $s0 (sub $f0 (struct)))
  )
  "sub type"
)
