(module (memory 1)
  (func (export "eq-in-block")
    (block
      (drop
        (block (result v128)
          (i32x4.eq
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
          (i32x4.ne
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
          (i32x4.lt_s
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
          (i32x4.le_u
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
          (i32x4.gt_u
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
          (i32x4.ge_s
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
          )
        )
      )
    )
  )
  (func (export "nested-eq")
    (drop
      (i32x4.eq
        (i32x4.eq
          (i32x4.eq
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i32x4.eq
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (i32x4.eq
          (i32x4.eq
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i32x4.eq
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-ne")
    (drop
      (i32x4.ne
        (i32x4.ne
          (i32x4.ne
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i32x4.ne
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (i32x4.ne
          (i32x4.ne
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i32x4.ne
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-lt_s")
    (drop
      (i32x4.lt_s
        (i32x4.lt_s
          (i32x4.lt_s
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i32x4.lt_s
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (i32x4.lt_s
          (i32x4.lt_s
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i32x4.lt_s
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-le_u")
    (drop
      (i32x4.le_u
        (i32x4.le_u
          (i32x4.le_u
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i32x4.le_u
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (i32x4.le_u
          (i32x4.le_u
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i32x4.le_u
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-gt_u")
    (drop
      (i32x4.gt_u
        (i32x4.gt_u
          (i32x4.gt_u
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i32x4.gt_u
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (i32x4.gt_u
          (i32x4.gt_u
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i32x4.gt_u
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-ge_s")
    (drop
      (i32x4.ge_s
        (i32x4.ge_s
          (i32x4.ge_s
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i32x4.ge_s
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (i32x4.ge_s
          (i32x4.ge_s
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i32x4.ge_s
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "as-param")
    (drop
      (i32x4.ge_u
        (i32x4.eq
          (i32x4.lt_s
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i32x4.le_u
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (i32x4.ne
          (i32x4.gt_s
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (i32x4.lt_u
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
)
