The purpose of this project is to develop an optimizing compiler.
The optimizer reads LLVM intermediate code as input and write the same format as output, so that this project only needs to develop the optimizer, not parsers or machine code generators, and so that it can work with every language and platform supported by LLVM.
The optimizer is written in Haskell. The LLVM back end for that language means it can optimize itself.

The optimizer works on a whole program basis.
Each pass of the optimizer is a pure function that takes a program as input and returns a hopefully faster program as output.
The use of Haskell and pure functions suggests that the intermediate representation used by the optimizer consists of pure values, and indeed it is. Every program represented in intermediate form is a pure value. So for example we can check whether an optimization pass made any changes just by checking whether the output is not equal to the input.

But while the intermediate representation is purely functional at the level of the optimizer code, it is not so at the level of the code being represented. It is much more like LLVM intermediate representation in that each instruction specifies an imperative operation.
In general, it greatly resembles LLVM intermediate representation in things like the instruction set and the use of untyped pointers and integers of fixed width, with signed versus unsigned specified by the instruction rather than the data type.
One important difference is that it does not use SSA. Instead, local variables can have addresses and can be reassigned. Part of the reason for this is that we want to bite the bullet and carry out deep analysis on values stored in memory, not just local variables. It also simplifies the semantics: no phi nodes. It makes certain analyses take longer. This is an acceptable trade.

All commits are made directly to the main branch.
