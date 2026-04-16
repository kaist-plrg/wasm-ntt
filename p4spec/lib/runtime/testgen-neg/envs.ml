open Domain.Lib

(* Type definition environment *)

module TDEnv = Dynamic.Envs.TDEnv
module TDEnvAlias = Dynamic.Envs.TDEnvAlias

(* Mixop family environment *)

module MixopEnv = MakeIdEnv (Mixops)
