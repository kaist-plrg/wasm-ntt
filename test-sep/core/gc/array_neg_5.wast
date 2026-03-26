(assert_invalid
  (module
    (type $bvec (array i8))

    (data $d "\00\01\02\03\04")

    (global (ref $bvec)
      (array.new_data $bvec $d (i32.const 1) (i32.const 3))
    )
  )
  "constant expression required"
)
