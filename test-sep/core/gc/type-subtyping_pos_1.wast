(module
  (type $e0 (sub (array i32)))
  (type $e1 (sub $e0 (array i32)))

  (type $e2 (sub (array anyref)))
  (type $e3 (sub (array (ref null $e0))))
  (type $e4 (sub (array (ref $e1))))

  (type $m1 (sub (array (mut i32))))
  (type $m2 (sub $m1 (array (mut i32))))
)
