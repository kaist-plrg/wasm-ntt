(assert_invalid
  (module
    (type $a (sub (struct (field (mut (ref any))))))
    (type $b (sub $a (struct (field (mut (ref none))))))
  )
  "sub type 1 does not match super type"
)
