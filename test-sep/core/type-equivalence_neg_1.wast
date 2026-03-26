(assert_invalid
  (module
    (type $t1 (func (param (ref $t2))))
    (type $t2 (func (param (ref $t1))))
  )
  "unknown type"
)
