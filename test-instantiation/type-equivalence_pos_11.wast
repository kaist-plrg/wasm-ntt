(module
  (type $t1 (func (param f32 f32) (result f32)))
  (func (export "f") (param (ref $t1)))
)

(register "M")

(module
  (type $t2 (func (param $x f32) (param $y f32) (result f32)))
  (func (import "M" "f") (param (ref $t2)))
)
