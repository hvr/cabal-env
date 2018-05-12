# cabal-env

`cabal-env` is a prototype UI for managing the new [package environments](https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/packages.html#package-environments) facility implement in GHC for use by cabal's [nix-style local builds](http://cabal.readthedocs.io/en/latest/nix-local-build-overview.html) which allows to provide seamless access to the nix-style package store for direct invocations GHC and GHCi.

## Usage

```
Usage: ./cabal-env.sh [-n <env-name>] (-r | -l | [DEP]+)"

Creates GHC package environment named '<env-name>' (default = 'default')
containing the specified deps.

Flags:

  -n <env-name>   set environment name to operate on;
                  use the special env-name '.' to create a
                  local '.ghc.environment' file in the current folder.
                  (default: 'default')

  -r              deletes the specified environment (via -n)

  -l              lists available environments for current 'ghc'
                  (cannot be combined with other flags)

  -i              create temporary environment and invoke GHCi with it
                  (cannot be combined with other flags)


GHC Package environments are supported since GHC 8.0.2 and Cabal 2.2;
By default, the environment named 'default' is loaded by GHC and GHCi
if it exists.

You can select a specific package environment for GHC(i) via e.g.
'ghci -package-env myenv' or by setting an environment variable
'GHC_ENVIRONMENT=myenv ghci'

Examples:

  ./cabal-env.sh -n lens 'lens == 4.15.*' 'lens-aeson == 1.0.*' http-streams

  ./cabal-env.sh unordered-containers QuickCheck quickcheck-instances

  ./cabal-env.sh -i lens-aeson
```

