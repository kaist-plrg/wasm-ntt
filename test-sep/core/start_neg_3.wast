(assert_invalid
  (module
    (func $main (param $a i32))
    (start $main)
  )
  "start function"
)
