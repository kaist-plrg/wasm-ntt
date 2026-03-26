(assert_invalid
  (module
    (func $f)
    (elem (i32.const 0) $f)
  )
  "unknown table"
)
