(module
  (rec (type $s (struct)))
  (rec (type $t (func (param (ref $s)))))
  (func $f (param (ref $s)))  ;; okay, type is equivalent to $t
  (global (ref $t) (ref.func $f))
)
