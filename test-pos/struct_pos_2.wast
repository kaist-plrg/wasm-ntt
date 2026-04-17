(module
  (rec
    (type $s0 (struct (field (ref 0) (ref 1) (ref $s0) (ref $s1))))
    (type $s1 (struct (field (ref 0) (ref 1) (ref $s0) (ref $s1))))
  )

  (func (param (ref $forward)))

  (type $forward (struct))
)
