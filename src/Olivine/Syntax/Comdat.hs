-- | Comdat groups.
--
-- A comdat is not a symbol.  It is a name symbols can be put into, written
-- with a sigil of its own — @$g@ — in a namespace of its own, so that @$g@
-- and @\@g@ are unrelated names that turn up side by side all the time: a
-- global written with a bare @comdat@ clause is in the group its own name
-- spells.
--
-- What a group states is a rule for the linker: of all the copies of this
-- group reaching it, keep one and discard the rest, and do so a whole group
-- at a time.  That is how the one surviving copy of an inline function or a
-- template instantiation is chosen from the many that every translation unit
-- using it emitted, and it is why the members of a group live and die
-- together.  They are the pieces of one definition — the function, the
-- variable holding its guard, the table it dispatches through — and a member
-- kept while its group was discarded would refer to what is no longer there.
module Olivine.Syntax.Comdat
  ( Selection (..)
  ) where

-- | Which copy the linker keeps, and what it may assume of the ones it
-- discards.
--
-- ELF and WebAssembly support only @any@, so @any@ is what almost every
-- module carrying comdats at all is written with; the rest are COFF's, where
-- the selection kind is a field of the section header and all five have a
-- number.
data Selection
  = -- | Keep whichever copy; they are interchangeable.
    SelectAny
  | -- | Keep whichever copy, the copies being required to have the same
    -- contents.
    SelectExactMatch
  | -- | Keep the largest copy.
    SelectLargest
  | -- | Keep every copy: this group is one whose duplicates are meant to
    -- survive as duplicates.
    SelectNoDeduplicate
  | -- | Keep whichever copy, the copies being required to have the same size.
    SelectSameSize
  deriving (Eq, Show)
