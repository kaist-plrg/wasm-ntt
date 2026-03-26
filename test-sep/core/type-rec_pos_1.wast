(module
  (rec (type $f1 (func)) (type (struct (field (ref $f1)))))
  (rec (type $f2 (func)) (type (struct (field (ref $f2)))))
  (func $f (type $f2))
  (global (ref $f1) (ref.func $f))
)
