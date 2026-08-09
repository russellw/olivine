# Olivine

A whole-program optimizer for LLVM intermediate code, written in Haskell.

Olivine reads a `.ll` file and writes a `.ll` file. Everything between those two
points is optimization: there is no parser for a source language and no machine
code generator, because LLVM already has both. That is the whole reason for the
shape of the project — it can optimize any language and any target LLVM
supports, and since GHC has an LLVM back end, it can optimize itself.

```
$ olivine input.ll -o output.ll
$ olivine input.ll --verify -o output.ll   # check the program after every pass
$ clang -S -emit-llvm -O0 f.c -o - | olivine | clang -x ir - -o f
```

Status: **paused, and working.** 3173 tests pass, the whole corpus round trips,
and every corpus module behaves identically before and after. It is a portfolio
project rather than something to depend on.

## The idea

**A pass is a pure function from program to program.** Not a function from
program to `(program, changed)`, and not a monad over a mutable module. The
intermediate representation is an ordinary Haskell value, so asking whether a
pass did anything is `(/=)` on its result, iterating a pipeline to a fixed point
is a `scanl`, and the input to every pass is still there to be compared against
the output. The `--verify` flag falls straight out of that: the driver keeps the
program as each pass in turn left it, so a module that arrives whole and leaves
broken can be blamed on one named pass rather than on the compiler.

**The representation is not SSA.** A local variable has an address and can be
reassigned. This is the one substantive departure from LLVM's own design, and it
is deliberate:

- There are no phi nodes. A value that depends on which edge was taken is an
  assignment made on each edge. Phis are read in and written back out at the two
  boundaries (`Olivine.Core.Phi`) and cannot be spelled anywhere in between.
- Assignments belong to edges, where a phi belongs to a block — and an edge has
  two ends. `Blocks.liftAssignments` removes a block that holds nothing but a
  phi by pushing its operands onto the blocks that reach it, which is a
  simplification the SSA form cannot state.
- The intent is to analyse values in memory rather than only values in
  registers. Costing more analysis time for that is the trade being made.

**Structure where invalid input cannot arise; a predicate where it must
survive.** The syntax layer has to read back a block that ends in the wrong
instruction and report it, so there a terminator is an instruction plus a
predicate. The core, which nothing but Olivine constructs, holds a terminator in
a slot of its own, so a block cannot lack one. Neither layer gets a parallel
copy of the type — Haskell has no subtyping, and every place a subset relation
is encoded as a second type is a conversion and a second copy of every function
over it. Validity lives in a verifier pass, not in the shape of the data.

**The operand is the type parameter.** Every operand slot in the instruction
grammar holds it, so rewriting operands is `fmap`, reading them off is
`toList`, and retargeting control flow is a separate function that cannot touch
operands by construction. Adding an instruction is one constructor: there is no
list of operations anywhere that a new one could be left out of.

`getelementptr` is replaced by a form that takes one offset at a time.

## Layout

```
src/Olivine/Syntax/   parser, printer, verifier — LLVM's text format, faithfully
src/Olivine/Core/     the optimizer's own representation, its analyses, and the passes
src/Olivine/Pipeline.hs   the pass order, and the argument for it
app/Main.hs           the command line driver
test/                 3173 tests, plus a corpus of clang output
tools/                corpus generation and the behavioural check
```

`Syntax` and `Core` meet at `lower` and `raise`, which run either side of the
passes so that no pass ever sees the syntax layer.

### Analyses

`Alias` (may-alias over slots, symbols and pointer arithmetic), `Layout` (the
target data layout string: sizeof, alignof, offsetof), `Loops` (dominance and
natural loops), `Induction`, `Effects`, `Ssa`, `Blocks`, `Promises`.

### Passes

Aggregate splitting, memory promotion, inlining, folding, tail-recursion
elimination, loop rotation, control flow simplification, tail merging,
unrolling, strength reduction, switch folding, if-conversion, redundancy
elimination (value numbering and redundant loads in one availability walk),
loop-invariant code motion (including loads), dead store elimination, dead code
elimination, dead symbol elimination.

The pipeline runs to a fixed point, bounded at 20 rounds; over the corpus the
second round is always the one that changes nothing. The comment block above
the pass list in `Olivine/Pipeline.hs` is the most opinionated part of the
codebase: it argues each pass's position from what that pass needs another to
have done first, and records what each ordering costs.

## Where it gets to

Measured as static instruction count over a 30-source corpus, feeding Olivine
the output of `clang` at each level and comparing against `clang -O2`'s own
result for the same sources:

| Olivine's input | Olivine's output | clang `-O2` |
| --- | --- | --- |
| `clang -O0` | 2112 | 3631 |
| `clang -O1` | 2115 | |
| `clang -O2` | 3526 | |
| unoptimized front-end output | 2161 | |

The `-O2` row is Olivine run over already-optimized code, so it is the one that
reads against 3631 directly: it still finds 105 instructions `clang -O2` left.
The rows above it start from smaller input and end well below clang's figure,
which is mostly the whole-program view — dead symbol elimination can discard
what a per-module compiler has to keep — so they are not a like-for-like
comparison and should not be read as beating `-O2`. Instruction count is a proxy
in any case, not a benchmark — there are no timing numbers
here, and the honest claim is that the passes fire on real front-end output, not
that the result is faster.

The useful measurement technique, arrived at late: run **one named `opt` pass**
over Olivine's output and diff, rather than comparing totals against `-O2`. It
names the missing transform instead of reporting a number. (Loop passes have to
be isolated some other way — the pass manager runs loop-simplify and LCSSA
first, and the delta reported is that canonicalization rather than the pass.)

## Testing

```
cabal test           # 3173 unit tests
tools/check-behaviour.sh   # compile before and after, run both, compare output
```

The behavioural check is what replaces byte-identical round tripping. Once phi
nodes are eliminated and put back the text differs by design, so the question
stops being whether a module comes back unchanged and becomes whether it comes
back doing the same thing: each corpus module is compiled as-is and as Olivine
rewrote it, both linked against the same driver, and the two programs' output
and exit status compared.

The corpus (`tools/gen-corpus.sh`) is clang's own output for 30 C and C++
sources at four levels each — the C++ ones for constructs a C front end never
emits, exception handling above all. Nothing in the syntax layer is opaque over
it: every entry parses, every instruction is modelled, every definition lowers.
That mattered more than it sounds. Retaining an unmodelled construct as text is
only safe while it names nothing the optimizer renumbers, and `blockaddress`
turned out to be the exception that miscompiled.

## What is left

- **Threading past a block of assignments.** The largest single gap measured:
  28 instructions on unoptimized input. `ControlFlow.thread` declines the shape
  it was written for, because the deciding block holds one assignment — empty in
  LLVM's view, not in the core's.
- **Array splitting by element index**, and LLVM's select speculation with it.
- **A slot held as bits** — a union written at one width and read at another.
- Everything is static. There is no profile information and no cost model beyond
  instruction counts and inlining budgets.

`optnone` is deliberately not obeyed; see the comments in the pipeline for why.
Debug info is discarded at the door rather than maintained through the passes,
which is a real limitation and a considered one.

## Building

Needs GHC (tested on 9.10.3) and cabal, plus LLVM 21 tools if you want to
regenerate the corpus or run the behavioural check.

```
cabal build
cabal test
cabal list-bin exe:olivine
```

Dependencies are `containers`, `megaparsec`, `text` and `optparse-applicative`.

## License

MIT. Copyright (c) 2026 Russell Wallace.
