(module
  (func $inc)
  (func $main
    (call $inc)
    (call $inc)
    (call $inc)
  )
  (start $main)
)
