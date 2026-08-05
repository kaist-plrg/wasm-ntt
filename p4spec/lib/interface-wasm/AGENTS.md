# AGENTS.md

> Historical task note: the `sl_to_global`-only scope below records an earlier
> deconstruction task and is not the current Wasm semantics assignment unless
> the user explicitly reactivates it. For current work, first read the
> repository-root `AGENTS.md`, `docs/wasm-semantics-context.md`, and the latest
> relevant entries in `docs/wasm-semantics-worklog.md`.

## 1. Instructions
- 내가 지금 작업하고 있는 파일은 /Users/jwpark/Workspace/wasm-ntt/p4spec/lib/interface-wasm/deconstruct.ml 입니다.
- 이 파일이 하고 있는 것은 기본적으로 같은 위치에 있는 construct.ml과 반대되는 역할을 하는 파일입니다. construct.ml은 OCaml로 작성된
Wasm AST를 P4-SpecTec IL value로 변환하는 parser 역할을 하는 반면, deconstruct.ml은 P4-SpecTec IL value를 OCaml로 작성된 Wasm AST로 변환하는 unparser 역할을 합니다. deconstruct.ml 파일을 보면, sl_to_* 함수들이 보이는데, 여기서 sl은 SL-value를 의미하고, SL-value = IL-value로 alising되어 있어서 사실상 같은 것이야.
- 그러니까 너가 가장 많이 참고해야 하는 파일은 construct.ml이야. construct.ml에서 il_of_rec_type이라고 하면 desconstruct.ml에서는
sl_to_rec_type이라는 역함수가 존재해야 하는 식으로 말이야. 그리고 construct.ml 패턴매칭에서 왼쪽에 있는 패턴이 이제 deconstruct.ml에서 오른쪽에
constructor로 등장해야 하는 것이지. Wasm constructor가 무엇이 있는지 궁금하면 /Users/jwpark/Workspace/wasm-ntt/p4spec/lib/interface-wasm/interpreter/syntax/ast.ml 파일과 /Users/jwpark/Workspace/wasm-ntt/p4spec/lib/interface-wasm/interpreter/syntax/types.ml 파일을 참고하면 된다.
- 내가 네가 참고할 수 있도록 큰 틀은 짜놨거든? sl_to_module'이 가장 top-level이 될 것 같아. 그 안에서 sl_to_type, sl_to_global,
sl_to_table 등 module을 구성하는 컴포넌트에 대한 역함수들을 구현해야 하는 것이지. recursively 파고 들면서 말이야. 내가 sl_to_type을 구현해놨으니까,내가 위에 언급한 파일들을 참고해서 어떤 것이 어떻게 작성됐는지 확인하고 그 패턴을 학습해. 그리고 나서 일단 sl_to_global을 완성해보자.
다른 함수들은 아직 구현하지 말고. sl_to_global까지만 완성되면, wasm-ntt 폴더에서 make build 했을 때, 다음 컴포넌트인 sl_to_table에서 에러가 나면 된 거겠지? 너가 하는 것을 보고 더 맡길지 말지 결정하려고 그래. 일단 sl_to_global을 완성해보자. global은 ast.ml에서 module_' 에서 확인할 수 있다. 여기를 보면 시작점이 될 것이야.
- 그리고 코드 패턴은 일관되게 지켜줘. 내가 작성한 코드를 보고 그 형식을 지켜줘. 예를 들어 value: Value.t 처럼 타입 애노테이션 해준 것처럼 말이야. 자, 이제 시작해봐.
