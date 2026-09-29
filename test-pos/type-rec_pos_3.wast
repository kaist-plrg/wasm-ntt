(module
  (rec (type $ft (func)))
  (func $f)  ;; the implicit type of $f is $ft
  (global (ref $ft) (ref.func $f))
)
