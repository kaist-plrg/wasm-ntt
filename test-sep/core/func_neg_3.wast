(assert_invalid
  (module
    (func $f (drop (ref.func $g)))
    (func $g (type 4))
    (elem declare func $g)
  )
  "unknown type"
)
