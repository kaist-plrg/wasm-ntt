(module
  (type (func (param (ref 0)) (result (ref 0))))
  (rec
    (type (func (param (ref 2))))
    (type (func (result (ref 1))))
  )

  (rec)
  (rec (type (func)))
  (rec (type $t (func)))
  (rec (type $t1 (func)) (type (func)) (type $t2 (func)))
  (rec (type $g (func (param (ref $g)) (result (ref $g)))))
  (rec
    (type $h (func (param (ref $k))))
    (type $k (func (result (ref $h))))
  )
)
