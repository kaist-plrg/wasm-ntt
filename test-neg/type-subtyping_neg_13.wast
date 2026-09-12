(assert_invalid
  (module
    (type $a0 (sub (array i32)))
    (type $f0 (sub $a0 (func (param i32) (result i32))))
  )
  "sub type"
)
