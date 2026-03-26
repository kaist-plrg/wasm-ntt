(assert_invalid
  (module
    (type $t (struct))
    (type $s (sub $t (struct)))
  )
  "sub type"
)
