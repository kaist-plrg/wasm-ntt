(module
  (type $proc (func))
  (table 1 funcref)

  (func
    (block i32.const 0 call_indirect)
    (loop i32.const 0 call_indirect)
    (if (i32.const 0) (then i32.const 0 call_indirect))
    (if (i32.const 0)
      (then i32.const 0 call_indirect)
      (else i32.const 0 call_indirect)
    )
    (block i32.const 0 call_indirect (type $proc))
    (loop i32.const 0 call_indirect (type $proc))
    (if (i32.const 0) (then i32.const 0 call_indirect (type $proc)))
    (if (i32.const 0)
      (then i32.const 0 call_indirect (type $proc))
      (else i32.const 0 call_indirect (type $proc))
    )
    (block i32.const 0 i32.const 0 call_indirect (param i32))
    (loop i32.const 0 i32.const 0 call_indirect (param i32))
    (if (i32.const 0) (then i32.const 0 i32.const 0 call_indirect (param i32)))
    (if (i32.const 0)
      (then i32.const 0 i32.const 0 call_indirect (param i32))
      (else i32.const 0 i32.const 0 call_indirect (param i32))
    )
    (block (result i32) i32.const 0 call_indirect (result i32)) (drop)
    (loop (result i32) i32.const 0 call_indirect (result i32)) (drop)
    (if (result i32) (i32.const 0)
      (then i32.const 0 call_indirect (result i32))
      (else i32.const 0 call_indirect (result i32))
    ) (drop)
    (block i32.const 0 call_indirect (type $proc) (param) (result))
    (loop i32.const 0 call_indirect (type $proc) (param) (result))
    (if (i32.const 0)
      (then i32.const 0 call_indirect (type $proc) (param) (result))
    )
    (if (i32.const 0)
      (then i32.const 0 call_indirect (type $proc) (param) (param) (result))
      (else i32.const 0 call_indirect (type $proc) (param) (result) (result))
    )

    block i32.const 0 call_indirect end
    loop i32.const 0 call_indirect end
    i32.const 0 if i32.const 0 call_indirect end
    i32.const 0 if i32.const 0 call_indirect else i32.const 0 call_indirect end
    block i32.const 0 call_indirect (type $proc) end
    loop i32.const 0 call_indirect (type $proc) end
    i32.const 0 if i32.const 0 call_indirect (type $proc) end
    i32.const 0
    if
      i32.const 0 call_indirect (type $proc)
    else
      i32.const 0 call_indirect (type $proc)
    end
    block i32.const 0 i32.const 0 call_indirect (param i32) end
    loop i32.const 0 i32.const 0 call_indirect (param i32) end
    i32.const 0 if i32.const 0 i32.const 0 call_indirect (param i32) end
    i32.const 0
    if
      i32.const 0 i32.const 0 call_indirect (param i32)
    else
      i32.const 0 i32.const 0 call_indirect (param i32)
    end
    block (result i32) i32.const 0 call_indirect (result i32) end drop
    loop (result i32) i32.const 0 call_indirect (result i32) end drop
    i32.const 0
    if (result i32)
      i32.const 0 call_indirect (result i32)
    else
      i32.const 0 call_indirect (result i32)
    end drop
    block i32.const 0 call_indirect (type $proc) (param) (result) end
    loop i32.const 0 call_indirect (type $proc) (param) (result) end
    i32.const 0 if i32.const 0 call_indirect (type $proc) (param) (result) end
    i32.const 0
    if
      i32.const 0 call_indirect (type $proc) (param) (result)
    else
      i32.const 0 call_indirect (type $proc) (param) (param) (result) (result)
    end
    i32.const 0 call_indirect
  )
)
