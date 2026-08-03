(module definition $N
  (global $glob (mut i32) (i32.const 0))
  (table $tab 10 funcref (ref.null func))
  (memory $mem 1)
  (tag $tag)

  (export "glob1" (global $glob))
  (export "glob2" (global $glob))
  (export "tab1" (table $tab))
  (export "tab2" (table $tab))
  (export "mem1" (memory $mem))
  (export "mem2" (memory $mem))
  (export "tag1" (tag $tag))
  (export "tag2" (tag $tag))
)

(module instance $I $N)
