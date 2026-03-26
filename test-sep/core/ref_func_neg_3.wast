(assert_invalid
  (module (start $f) (func $f (drop (ref.func $f))))
  "undeclared function reference"
)
