(module
  (global (import "spectest" "global_i32") i32)
  (memory 1)
  (data (i32.mul
          (i32.const 2)
          (i32.add
            (i32.sub (global.get 0) (i32.const 1))
            (i32.const 2)
          )
        )
  )
)
