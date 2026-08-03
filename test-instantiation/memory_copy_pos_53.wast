(module
  (memory i64 1 1)
  (func (export "test")
    (memory.fill (i64.const 10) (i32.const 0x55) (i64.const 10))
    (memory.copy (i64.const 9) (i64.const 10) (i64.const 5)))
  
  (func (export "checkRange") (param $from i64) (param $to i64) (param $expected i32) (result i64)
    (loop $cont
      (if (i64.eq (local.get $from) (local.get $to))
        (then
          (return (i64.const -1))))
      (if (i32.eq (i32.load8_u (local.get $from)) (local.get $expected))
        (then
          (local.set $from (i64.add (local.get $from) (i64.const 1)))
          (br $cont))))
    (return (local.get $from)))
)
