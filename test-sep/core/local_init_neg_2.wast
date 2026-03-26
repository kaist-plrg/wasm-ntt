(assert_invalid
  (module
    (func $uninit-after-end (param $p (ref extern))
      (local $x (ref extern))
      (block (local.set $x (local.get $p)) (drop (local.tee $x (local.get $p))))
      (drop (local.get $x))
    )
  )
  "uninitialized local"
)
