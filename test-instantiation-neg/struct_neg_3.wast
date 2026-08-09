(assert_invalid
  (module
    (type (struct (field $x i64)))
    (type $t (struct (field $x i32)))
    (func (param (ref 0)) (result i32) (struct.get 0 $x (local.get 0)))
  )
  "type mismatch"
)
