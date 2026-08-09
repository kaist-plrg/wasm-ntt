(assert_invalid
  (module
    (type $a (sub (array (ref none))))
    (type $b (sub $a (array (ref any))))
  )
  "sub type 1 does not match super type"
)
