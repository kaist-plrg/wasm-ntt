(module (memory 1)
  (func (export "eq-in-block")
    (block
      (drop
        (block (result v128)
          (i16x8.eq
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
          (i16x8.ne
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
          (i16x8.lt_s
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
          (i16x8.le_u
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
          (i16x8.gt_u
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
          (i16x8.ge_s
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
          )
        )
      )
    )
  )
  (func (export "nested-eq")
    (drop
      (i16x8.eq
        (i16x8.eq
          (i16x8.eq
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i16x8.eq
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (i16x8.eq
          (i16x8.eq
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i16x8.eq
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-ne")
    (drop
      (i16x8.ne
        (i16x8.ne
          (i16x8.ne
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i16x8.ne
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (i16x8.ne
          (i16x8.ne
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i16x8.ne
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-lt_s")
    (drop
      (i16x8.lt_s
        (i16x8.lt_s
          (i16x8.lt_s
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i16x8.lt_s
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (i16x8.lt_s
          (i16x8.lt_s
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i16x8.lt_s
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-le_u")
    (drop
      (i16x8.le_u
        (i16x8.le_u
          (i16x8.le_u
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i16x8.le_u
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (i16x8.le_u
          (i16x8.le_u
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i16x8.le_u
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-gt_u")
    (drop
      (i16x8.gt_u
        (i16x8.gt_u
          (i16x8.gt_u
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i16x8.gt_u
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (i16x8.gt_u
          (i16x8.gt_u
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i16x8.gt_u
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-ge_s")
    (drop
      (i16x8.ge_s
        (i16x8.ge_s
          (i16x8.ge_s
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i16x8.ge_s
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (i16x8.ge_s
          (i16x8.ge_s
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i16x8.ge_s
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "as-param")
    (drop
      (i16x8.ge_u
        (i16x8.eq
          (i16x8.lt_s
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i16x8.le_u
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (i16x8.ne
          (i16x8.gt_s
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i16x8.lt_u
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
)
