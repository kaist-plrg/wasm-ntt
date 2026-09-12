(assert_invalid
  (module (func $f (drop (ref.func $f))))
  "undeclared function reference"
)
