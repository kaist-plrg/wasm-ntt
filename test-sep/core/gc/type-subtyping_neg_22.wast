(assert_invalid
  (module
    (type $a (sub (struct (field (mut (ref any))))))
    (type $b (sub $a (struct (field (ref any)))))
  )
  "sub type 1 does not match super type"
)
