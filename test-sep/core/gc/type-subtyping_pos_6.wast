(module
  (rec
    (type $a1 (sub (struct (field i32 (ref $a2)))))
    (type $a2 (sub (struct (field i64 (ref $a1)))))
  )
  (rec
    (type $b1 (sub $a2 (struct (field i64 (ref $a1) i32))))
    (type $b2 (sub $a1 (struct (field i32 (ref $a2) i32))))
    (type $b3 (sub $a2 (struct (field i64 (ref $b2) i32))))
  )
)
