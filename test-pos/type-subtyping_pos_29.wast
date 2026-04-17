(module
  (type $t1 (sub (func)))
  (type $t2 (sub final (func)))
  (func (export "f1") (type $t1))
  (func (export "f2") (type $t2))
)
