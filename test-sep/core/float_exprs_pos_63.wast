(module
  (memory (data
    "\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\80\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\80"
    "\01\00\00\00\00\00\00\00\01\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00"
    "\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00"
  ))

  (func (export "f64.simple_x4_sum")
    (param $i i32)
    (param $j i32)
    (param $k i32)
    (local $x0 f64) (local $x1 f64) (local $x2 f64) (local $x3 f64)
    (local $y0 f64) (local $y1 f64) (local $y2 f64) (local $y3 f64)
    (local.set $x0 (f64.load offset=0 (local.get $i)))
    (local.set $x1 (f64.load offset=8 (local.get $i)))
    (local.set $x2 (f64.load offset=16 (local.get $i)))
    (local.set $x3 (f64.load offset=24 (local.get $i)))
    (local.set $y0 (f64.load offset=0 (local.get $j)))
    (local.set $y1 (f64.load offset=8 (local.get $j)))
    (local.set $y2 (f64.load offset=16 (local.get $j)))
    (local.set $y3 (f64.load offset=24 (local.get $j)))
    (f64.store offset=0 (local.get $k) (f64.add (local.get $x0) (local.get $y0)))
    (f64.store offset=8 (local.get $k) (f64.add (local.get $x1) (local.get $y1)))
    (f64.store offset=16 (local.get $k) (f64.add (local.get $x2) (local.get $y2)))
    (f64.store offset=24 (local.get $k) (f64.add (local.get $x3) (local.get $y3)))
  )

  (func (export "f64.load")
    (param $k i32) (result f64)
    (f64.load (local.get $k))
  )
)
