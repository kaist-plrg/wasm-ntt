(module
  (rec
    (type $s0 (array (ref $s1)))
    (type $s1 (array (ref $s0)))
  )

  (func (param (ref $forward)))

  (type $forward (array i32))
)
