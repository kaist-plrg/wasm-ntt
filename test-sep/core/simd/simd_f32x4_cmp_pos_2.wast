(module (memory 1)
  (func (export "eq-in-block")
    (block
      (drop
        (block (result v128)
          (f32x4.eq
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
          (f32x4.ne
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
          )
        )
      )
    )
  )
  (func (export "lt-in-block")
    (block
      (drop
        (block (result v128)
          (f32x4.lt
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
          )
        )
      )
    )
  )
  (func (export "le-in-block")
    (block
      (drop
        (block (result v128)
          (f32x4.le
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
          )
        )
      )
    )
  )
  (func (export "gt-in-block")
    (block
      (drop
        (block (result v128)
          (f32x4.gt
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
          )
        )
      )
    )
  )
  (func (export "ge-in-block")
    (block
      (drop
        (block (result v128)
          (f32x4.ge
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
          )
        )
      )
    )
  )
  (func (export "nested-eq")
    (drop
      (f32x4.eq
        (f32x4.eq
          (f32x4.eq
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f32x4.eq
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (f32x4.eq
          (f32x4.eq
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f32x4.eq
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-ne")
    (drop
      (f32x4.ne
        (f32x4.ne
          (f32x4.ne
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f32x4.ne
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (f32x4.ne
          (f32x4.ne
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f32x4.ne
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-lt")
    (drop
      (f32x4.lt
        (f32x4.lt
          (f32x4.lt
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f32x4.lt
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (f32x4.lt
          (f32x4.lt
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f32x4.lt
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-le")
    (drop
      (f32x4.le
        (f32x4.le
          (f32x4.le
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f32x4.le
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (f32x4.le
          (f32x4.le
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f32x4.le
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-gt")
    (drop
      (f32x4.gt
        (f32x4.gt
          (f32x4.gt
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f32x4.gt
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (f32x4.gt
          (f32x4.gt
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f32x4.gt
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "nested-ge")
    (drop
      (f32x4.ge
        (f32x4.ge
          (f32x4.ge
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f32x4.ge
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (f32x4.ge
          (f32x4.ge
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f32x4.ge
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
  (func (export "as-param")
    (drop
      (f32x4.ge
        (f32x4.eq
          (f32x4.lt
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f32x4.le
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
        (f32x4.ne
          (f32x4.gt
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (f32x4.lt
            (v128.load (i32.const 2))
            (v128.load (i32.const 3))
          )
        )
      )
    )
  )
)
