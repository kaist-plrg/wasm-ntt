(assert_invalid
  (module
    (type $a0 (sub (array i32)))
    (type $a1 (sub $a0 (array i64)))
  )
  "sub type"
)
