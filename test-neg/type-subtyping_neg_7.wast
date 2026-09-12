(assert_invalid
  (module
    (type $t (sub (func)))
    (type $s (sub final $t (func)))
    (type $u (sub $s (func)))
  )
  "sub type"
)
