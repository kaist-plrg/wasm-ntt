(module
  (type (struct (field $x i32)))
  (type $t1 (struct (field i32) (field $x f32)))
  (type $t2 (struct (field i32 i32) (field $x i64)))

  (func (param (ref 0)) (result i32) (struct.get 0 $x (local.get 0)))
  (func (param (ref $t1)) (result f32) (struct.get 1 $x (local.get 0)))
  (func (param (ref $t2)) (result i64) (struct.get $t2 $x (local.get 0)))
)
