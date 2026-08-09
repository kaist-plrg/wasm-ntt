(assert_invalid
  (module (func $unbound-local (local i32 i64) (local.tee 3 (i32.const 0)) drop))
  "unknown local"
)
