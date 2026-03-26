(assert_invalid
  (module
    (type $a (sub (array (mut (ref any)))))
    (type $b (sub $a (array (mut (ref none)))))
  )
  "sub type 1 does not match super type"
)
