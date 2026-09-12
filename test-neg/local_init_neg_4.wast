(assert_invalid
  (module
    (func $uninit-from-if (param $p (ref extern))
      (local $x (ref extern))
      (if (i32.const 0)
        (then (local.set $x (local.get $p)))
	(else (local.set $x (local.get $p)))
      )
      (drop (local.get $x))
    )
  )
  "uninitialized local"
)
