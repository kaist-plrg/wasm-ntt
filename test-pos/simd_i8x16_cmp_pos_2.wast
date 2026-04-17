(module (memory 1)
  (func (export "eq-in-block")
    (block
      (drop
        (block (result v128)
          (i8x16.eq
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
          )
        )
      )
    )
  )
  (func (export "ne-in-block")
    (block
      (drop
        (block (result v128)
          (i8x16.ne
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
          )
        )
      )
    )
  )
  (func (export "lt_s-in-block")
    (block
      (drop
        (block (result v128)
          (i8x16.lt_s
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
          )
        )
      )
    )
  )
  (func (export "le_u-in-block")
    (block
      (drop
        (block (result v128)
          (i8x16.le_u
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
          )
        )
      )
    )
  )
  (func (export "gt_u-in-block")
    (block
      (drop
        (block (result v128)
          (i8x16.gt_u
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
          )
        )
      )
    )
  )
  (func (export "ge_s-in-block")
    (block
      (drop
        (block (result v128)
          (i8x16.ge_s
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
          )
        )
      )
    )
  )
  (func (export "nested-eq")
    (drop
      (i8x16.eq
        (i8x16.eq
          (i8x16.eq
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i8x16.eq
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (i8x16.eq
          (i8x16.eq
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i8x16.eq
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-ne")
    (drop
      (i8x16.ne
        (i8x16.ne
          (i8x16.ne
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i8x16.ne
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (i8x16.ne
          (i8x16.ne
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i8x16.ne
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-lt_s")
    (drop
      (i8x16.lt_s
        (i8x16.lt_s
          (i8x16.lt_s
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i8x16.lt_s
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (i8x16.lt_s
          (i8x16.lt_s
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i8x16.lt_s
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-le_u")
    (drop
      (i8x16.le_u
        (i8x16.le_u
          (i8x16.le_u
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i8x16.le_u
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (i8x16.le_u
          (i8x16.le_u
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i8x16.le_u
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-gt_u")
    (drop
      (i8x16.gt_u
        (i8x16.gt_u
          (i8x16.gt_u
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i8x16.gt_u
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (i8x16.gt_u
          (i8x16.gt_u
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i8x16.gt_u
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-ge_s")
    (drop
      (i8x16.ge_s
        (i8x16.ge_s
          (i8x16.ge_s
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i8x16.ge_s
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (i8x16.ge_s
          (i8x16.ge_s
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i8x16.ge_s
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "as-param")
    (drop
      (i8x16.ge_u
        (i8x16.eq
          (i8x16.lt_s
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i8x16.le_u
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (i8x16.ne
          (i8x16.gt_s
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i8x16.lt_u
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
)
