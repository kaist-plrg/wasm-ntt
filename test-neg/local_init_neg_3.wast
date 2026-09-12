(assert_invalid
  (module
    (func $uninit-in-else (param $p (ref extern))
      (local $x (ref extern))
      (if (i32.const 0)
        (then (local.set $x (local.get $p)))
	(else (local.get $x))
      )
    )
  )
  "uninitialized local"
)
