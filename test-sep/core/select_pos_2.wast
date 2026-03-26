(module (func $type-unreachable-ref-implicit
  (drop (ref.is_null (select (unreachable) (i32.const 1))))
))
