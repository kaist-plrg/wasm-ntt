(module (memory 1)
  (func (export "i8x16.shl-in-block")
    (block
      (drop
        (block (result v128)
          (i8x16.shl
            (block (result v128) (v128.load (i32.const 0))) (i32.const 1)
          )
        )
      )
    )
  )
  (func (export "i8x16.shr_s-in-block")
    (block
      (drop
        (block (result v128)
          (i8x16.shr_s
            (block (result v128) (v128.load (i32.const 0))) (i32.const 1)
          )
        )
      )
    )
  )
  (func (export "i8x16.shr_u-in-block")
    (block
      (drop
        (block (result v128)
          (i8x16.shr_u
            (block (result v128) (v128.load (i32.const 0))) (i32.const 1)
          )
        )
      )
    )
  )
  (func (export "i16x8.shl-in-block")
    (block
      (drop
        (block (result v128)
          (i16x8.shl
            (block (result v128) (v128.load (i32.const 0))) (i32.const 1)
          )
        )
      )
    )
  )
  (func (export "i16x8.shr_s-in-block")
    (block
      (drop
        (block (result v128)
          (i16x8.shr_s
            (block (result v128) (v128.load (i32.const 0))) (i32.const 1)
          )
        )
      )
    )
  )
  (func (export "i16x8.shr_u-in-block")
    (block
      (drop
        (block (result v128)
          (i16x8.shr_u
            (block (result v128) (v128.load (i32.const 0))) (i32.const 1)
          )
        )
      )
    )
  )
  (func (export "i32x4.shl-in-block")
    (block
      (drop
        (block (result v128)
          (i32x4.shl
            (block (result v128) (v128.load (i32.const 0))) (i32.const 1)
          )
        )
      )
    )
  )
  (func (export "i32x4.shr_s-in-block")
    (block
      (drop
        (block (result v128)
          (i32x4.shr_s
            (block (result v128) (v128.load (i32.const 0))) (i32.const 1)
          )
        )
      )
    )
  )
  (func (export "i32x4.shr_u-in-block")
    (block
      (drop
        (block (result v128)
          (i32x4.shr_u
            (block (result v128) (v128.load (i32.const 0))) (i32.const 1)
          )
        )
      )
    )
  )
  (func (export "i64x2.shl-in-block")
    (block
      (drop
        (block (result v128)
          (i64x2.shl
            (block (result v128) (v128.load (i32.const 0))) (i32.const 1)
          )
        )
      )
    )
  )
  (func (export "i64x2.shr_s-in-block")
    (block
      (drop
        (block (result v128)
          (i64x2.shr_s
            (block (result v128) (v128.load (i32.const 0))) (i32.const 1)
          )
        )
      )
    )
  )
  (func (export "i64x2.shr_u-in-block")
    (block
      (drop
        (block (result v128)
          (i64x2.shr_u
            (block (result v128) (v128.load (i32.const 0))) (i32.const 1)
          )
        )
      )
    )
  )
  (func (export "nested-i8x16.shl")
    (drop
      (i8x16.shl
        (i8x16.shl
          (i8x16.shl
            (v128.load (i32.const 0)) (i32.const 1)
          )
          (i32.const 1)
        )
        (i32.const 1)
      )
    )
  )
  (func (export "nested-i8x16.shr_s")
    (drop
      (i8x16.shr_s
        (i8x16.shr_s
          (i8x16.shr_s
            (v128.load (i32.const 0)) (i32.const 1)
          )
          (i32.const 1)
        )
        (i32.const 1)
      )
    )
  )
  (func (export "nested-i8x16.shr_u")
    (drop
      (i8x16.shr_u
        (i8x16.shr_u
          (i8x16.shr_u
            (v128.load (i32.const 0)) (i32.const 1)
          )
          (i32.const 1)
        )
        (i32.const 1)
      )
    )
  )
  (func (export "nested-i16x8.shl")
    (drop
      (i16x8.shl
        (i16x8.shl
          (i16x8.shl
            (v128.load (i32.const 0)) (i32.const 1)
          )
          (i32.const 1)
        )
        (i32.const 1)
      )
    )
  )
  (func (export "nested-i16x8.shr_s")
    (drop
      (i16x8.shr_s
        (i16x8.shr_s
          (i16x8.shr_s
            (v128.load (i32.const 0)) (i32.const 1)
          )
          (i32.const 1)
        )
        (i32.const 1)
      )
    )
  )
  (func (export "nested-i16x8.shr_u")
    (drop
      (i16x8.shr_u
        (i16x8.shr_u
          (i16x8.shr_u
            (v128.load (i32.const 0)) (i32.const 1)
          )
          (i32.const 1)
        )
        (i32.const 1)
      )
    )
  )
  (func (export "nested-i32x4.shl")
    (drop
      (i32x4.shl
        (i32x4.shl
          (i32x4.shl
            (v128.load (i32.const 0)) (i32.const 1)
          )
          (i32.const 1)
        )
        (i32.const 1)
      )
    )
  )
  (func (export "nested-i32x4.shr_s")
    (drop
      (i32x4.shr_s
        (i32x4.shr_s
          (i32x4.shr_s
            (v128.load (i32.const 0)) (i32.const 1)
          )
          (i32.const 1)
        )
        (i32.const 1)
      )
    )
  )
  (func (export "nested-i32x4.shr_u")
    (drop
      (i32x4.shr_u
        (i32x4.shr_u
          (i32x4.shr_u
            (v128.load (i32.const 0)) (i32.const 1)
          )
          (i32.const 1)
        )
        (i32.const 1)
      )
    )
  )
  (func (export "nested-i64x2.shl")
    (drop
      (i64x2.shl
        (i64x2.shl
          (i64x2.shl
            (v128.load (i32.const 0)) (i32.const 1)
          )
          (i32.const 1)
        )
        (i32.const 1)
      )
    )
  )
  (func (export "nested-i64x2.shr_s")
    (drop
      (i64x2.shr_s
        (i64x2.shr_s
          (i64x2.shr_s
            (v128.load (i32.const 0)) (i32.const 1)
          )
          (i32.const 1)
        )
        (i32.const 1)
      )
    )
  )
  (func (export "nested-i64x2.shr_u")
    (drop
      (i64x2.shr_u
        (i64x2.shr_u
          (i64x2.shr_u
            (v128.load (i32.const 0)) (i32.const 1)
          )
          (i32.const 1)
        )
        (i32.const 1)
      )
    )
  )
)
