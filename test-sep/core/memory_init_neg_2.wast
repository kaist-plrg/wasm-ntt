(assert_invalid
  (module
    (memory 1)
    (data "\37")
    (func (export "test")
      (data.drop 4)))
  "unknown data segment")
