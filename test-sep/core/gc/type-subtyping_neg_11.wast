(assert_invalid
  (module
    (type $f0 (sub (func (param i32) (result i32))))
    (type $a0 (sub $f0 (array i32)))
  )
  "sub type"
)
