(assert_invalid
  (module
    (type $bvec (array i8))
    (type $vvec (array (ref $bvec)))

    (elem $e (ref $bvec) (ref.null $bvec))

    (global (ref $vvec)
      (array.new_elem $vvec $e (i32.const 0) (i32.const 1))
    )
  )
  "constant expression required"
)
