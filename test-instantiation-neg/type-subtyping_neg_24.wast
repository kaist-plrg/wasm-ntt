(assert_invalid
  (module
    (type $f0 (sub (func)))
    (type $f1 (sub $f0 (func (param i32))))
  )
  "sub type"
)
