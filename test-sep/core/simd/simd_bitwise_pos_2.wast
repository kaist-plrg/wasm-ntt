(module (memory 1)
  (func (export "v128.not-in-block")
    (block
      (drop
        (block (result v128)
          (v128.not
            (block (result v128) (v128.load (i32.const 0)))
          )
        )
      )
    )
  )
  (func (export "v128.and-in-block")
    (block
      (drop
        (block (result v128)
          (v128.and
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
          )
        )
      )
    )
  )
  (func (export "v128.or-in-block")
    (block
      (drop
        (block (result v128)
          (v128.or
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
          )
        )
      )
    )
  )
  (func (export "v128.xor-in-block")
    (block
      (drop
        (block (result v128)
          (v128.xor
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
          )
        )
      )
    )
  )
  (func (export "v128.bitselect-in-block")
    (block
      (drop
        (block (result v128)
          (v128.bitselect
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
            (block (result v128) (v128.load (i32.const 2)))
          )
        )
      )
    )
  )
  (func (export "v128.andnot-in-block")
    (block
      (drop
        (block (result v128)
          (v128.andnot
            (block (result v128) (v128.load (i32.const 0)))
            (block (result v128) (v128.load (i32.const 1)))
          )
        )
      )
    )
  )
  (func (export "nested-v128.not")
    (drop
      (v128.not
        (v128.not
          (v128.not
            (v128.load (i32.const 0))
          )
        )
      )
    )
  )
  (func (export "nested-v128.and")
    (drop
      (v128.and
        (v128.and
          (v128.and
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (v128.and
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
        )
        (v128.and
          (v128.and
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (v128.and
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
        )
      )
    )
  )
  (func (export "nested-v128.or")
    (drop
      (v128.or
        (v128.or
          (v128.or
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (v128.or
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
        )
        (v128.or
          (v128.or
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (v128.or
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
        )
      )
    )
  )
  (func (export "nested-v128.xor")
    (drop
      (v128.xor
        (v128.xor
          (v128.xor
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (v128.xor
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
        )
        (v128.xor
          (v128.xor
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (v128.xor
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
        )
      )
    )
  )
  (func (export "nested-v128.bitselect")
    (drop
      (v128.bitselect
        (v128.bitselect
          (v128.bitselect
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
            (v128.load (i32.const 2))
          )
          (v128.bitselect
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
            (v128.load (i32.const 2))
          )
          (v128.bitselect
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
            (v128.load (i32.const 2))
          )
        )
        (v128.bitselect
          (v128.bitselect
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
            (v128.load (i32.const 2))
          )
          (v128.bitselect
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
            (v128.load (i32.const 2))
          )
          (v128.bitselect
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
            (v128.load (i32.const 2))
          )
        )
        (v128.bitselect
          (v128.bitselect
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
            (v128.load (i32.const 2))
          )
          (v128.bitselect
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
            (v128.load (i32.const 2))
          )
          (v128.bitselect
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
            (v128.load (i32.const 2))
          )
        )
      )
    )
  )
  (func (export "nested-v128.andnot")
    (drop
      (v128.andnot
        (v128.andnot
          (v128.andnot
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (v128.andnot
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
        )
        (v128.andnot
          (v128.andnot
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
          (v128.andnot
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
        )
      )
    )
  )
  (func (export "as-param")
    (drop
      (v128.or
        (v128.and
          (v128.not
            (v128.load (i32.const 0))
          )
          (v128.not
            (v128.load (i32.const 1))
          )
        )
        (v128.xor
          (v128.bitselect
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
            (v128.load (i32.const 2))
          )
          (v128.andnot
            (v128.load (i32.const 0))
            (v128.load (i32.const 1))
          )
        )
      )
    )
  )
)
