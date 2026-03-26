(module (memory 1)
  (func (export "f64x2.eq-in-block")
    (block
      (drop
        (block (result v128)
          (f64x2.eq
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
          )
        )
      )
    )
  )
  (func (export "f64x2.ne-in-block")
    (block
      (drop
        (block (result v128)
          (f64x2.ne
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
          )
        )
      )
    )
  )
  (func (export "f64x2.lt-in-block")
    (block
      (drop
        (block (result v128)
          (f64x2.lt
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
          )
        )
      )
    )
  )
  (func (export "f64x2.le-in-block")
    (block
      (drop
        (block (result v128)
          (f64x2.le
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
          )
        )
      )
    )
  )
  (func (export "f64x2.gt-in-block")
    (block
      (drop
        (block (result v128)
          (f64x2.gt
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
          )
        )
      )
    )
  )
  (func (export "f64x2.ge-in-block")
    (block
      (drop
        (block (result v128)
          (f64x2.ge
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
          )
        )
      )
    )
  )
  (func (export "nested-f64x2.eq")
    (drop
      (f64x2.eq
        (f64x2.eq
          (f64x2.eq
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f64x2.eq
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (f64x2.eq
          (f64x2.eq
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f64x2.eq
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-f64x2.ne")
    (drop
      (f64x2.ne
        (f64x2.ne
          (f64x2.ne
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f64x2.ne
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (f64x2.ne
          (f64x2.ne
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f64x2.ne
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-f64x2.lt")
    (drop
      (f64x2.lt
        (f64x2.lt
          (f64x2.lt
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f64x2.lt
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (f64x2.lt
          (f64x2.lt
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f64x2.lt
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-f64x2.le")
    (drop
      (f64x2.le
        (f64x2.le
          (f64x2.le
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f64x2.le
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (f64x2.le
          (f64x2.le
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f64x2.le
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-f64x2.gt")
    (drop
      (f64x2.gt
        (f64x2.gt
          (f64x2.gt
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f64x2.gt
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (f64x2.gt
          (f64x2.gt
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f64x2.gt
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-f64x2.ge")
    (drop
      (f64x2.ge
        (f64x2.ge
          (f64x2.ge
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f64x2.ge
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (f64x2.ge
          (f64x2.ge
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f64x2.ge
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "as-param")
    (drop
      (f64x2.eq
        (f64x2.ne
          (f64x2.lt
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f64x2.le
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (f64x2.gt
          (f64x2.ge
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f64x2.eq
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
)
