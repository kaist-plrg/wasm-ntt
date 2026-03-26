(assert_invalid
  (module
    (memory i64 1)
    (data "\37")
    (func (export "test")
      (data.drop 4)))
  "unknown data segment")
