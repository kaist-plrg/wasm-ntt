(assert_invalid
  (module
    (type $a0 (sub (array i32)))
    (type $s0 (sub $a0 (struct)))
  )
  "sub type"
)
