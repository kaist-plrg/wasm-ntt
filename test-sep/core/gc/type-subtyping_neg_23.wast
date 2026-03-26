(assert_invalid
  (module
    (type $a (sub (struct (field (ref any)))))
    (type $b (sub $a (struct (field (mut (ref any))))))
  )
  "sub type 1 does not match super type"
)
