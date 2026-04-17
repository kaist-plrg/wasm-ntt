(module
  (tag $e)
  (func (try_table (catch $e 0) (catch $e 0)))
  (func (try_table (catch_all 0) (catch $e 0)))
  (func (try_table (catch_all 0) (catch_all 0)))
  (func (result exnref) (try_table (catch_ref $e 0) (catch_ref $e 0)) (unreachable))
  (func (result exnref) (try_table (catch_all_ref 0) (catch_ref $e 0)) (unreachable))
  (func (result exnref) (try_table (catch_all_ref 0) (catch_all_ref 0)) (unreachable))
)
