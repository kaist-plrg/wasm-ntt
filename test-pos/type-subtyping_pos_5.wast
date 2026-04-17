(module
  (rec
    (type $r1 (sub (struct (field i32 (ref $r1)))))
  )
  (rec
    (type $r2 (sub $r1 (struct (field i32 (ref $r3)))))
    (type $r3 (sub $r1 (struct (field i32 (ref $r2)))))
  )
)
