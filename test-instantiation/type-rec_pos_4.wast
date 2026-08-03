(module $M
  (rec (type $f1 (func)) (type (struct)))
  (func (export "f") (type $f1))
)

(register "M" $M)

(module
  (rec (type $f2 (func)) (type (struct)))
  (func (import "M" "f") (type $f2))
)
