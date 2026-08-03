(module
  (rec (type $t1 (func (param i32 (ref $t1)))))
  (func (export "f") (param (ref $t1)))
)

(register "Mr1")

(module
  (rec (type $t2 (func (param i32 (ref $t2)))))
  (func (import "Mr1" "f") (param (ref $t2)))
)
