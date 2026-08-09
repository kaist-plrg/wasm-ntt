(assert_invalid
  (module
    (type $s0 (sub (struct)))
    (type $a0 (sub $s0 (array i32)))
  )
  "sub type"
)
