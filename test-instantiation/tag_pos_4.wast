(module
  (rec
    (type $t1 (func))
    (type $t2 (func))
  )
  (tag (export "tag") (type $t1))
)

(register "M")

(module
  (rec
    (type $t1 (func))
    (type $t2 (func))
  )
  (tag (import "M" "tag") (type $t1))
)
