(assert_invalid
  (module
    (type $t (sub final (func)))
    (type $s (sub $t (func)))
  )
  "sub type"
)
