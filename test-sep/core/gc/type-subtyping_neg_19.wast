(assert_invalid
  (module
    (type $a (sub (array (ref any))))
    (type $b (sub $a (array (mut (ref any)))))
  )
  "sub type 1 does not match super type"
)
