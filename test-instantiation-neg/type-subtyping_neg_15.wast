(assert_invalid
  (module
    (type $s0 (sub (struct (field i32))))
    (type $s1 (sub $s0 (struct (field i64))))
  )
  "sub type"
)
