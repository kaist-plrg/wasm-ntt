(assert_invalid
  (module
    (func (export "test")
      (elem.drop 0)))
  "unknown elem segment 0")
