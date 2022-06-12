# Clang#master + julia 1.6
using Clang.Generators

# other options, see Clang.JLLEnvs.JLL_ENV_TRIPLES
args = get_default_args("x86_64-linux-gnu")

# ctx = create_context("affinity.c", args)
ctx = create_context("affinity.c", args)

build!(ctx)
