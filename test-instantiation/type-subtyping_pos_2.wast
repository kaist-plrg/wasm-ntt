(module
  (type $e0 (sub (struct)))
  (type $e1 (sub $e0 (struct)))
  (type $e2 (sub $e1 (struct (field i32))))
  (type $e3 (sub $e2 (struct (field i32 (ref null $e0)))))
  (type $e4 (sub $e3 (struct (field i32 (ref $e0) (mut i64)))))
  (type $e5 (sub $e4 (struct (field i32 (ref $e1) (mut i64)))))
)
