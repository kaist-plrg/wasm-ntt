(module
  (global (export "g") (ref $f) (ref.func $f))
  (type $f (func))
  (func $f)
)
