(assert_invalid
  (module (tag $t0 (export "t0")) (tag $t1 (export "t0")))
  "duplicate export name"
)
