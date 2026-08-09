(assert_invalid
  (module
    (type $a (sub (array (mut (ref any)))))
    (type $b (sub $a (array (ref any))))
  )
  "sub type 1 does not match super type"
)
