-- | Discarding debug information, which Olivine does to every module it
-- reads.
--
-- The reasoning is in "Olivine.Syntax.Parser"'s @pDebugRecord@ for the
-- records and here for everything else, and it comes to one thing: the
-- optimizer treats its input as a specification of what the program computes
-- and is free to compute it any other way.  A debug location is not part of
-- that specification — it is a claim about where a value lives, and the
-- passes exist to stop it living there.  Olivine cannot maintain such a claim
-- and will not pretend to, so it says so once, at the door, rather than
-- leaving attachments to go quietly stale.
--
-- Carrying them was not a middle course.  Inlining copies a callee's @!dbg@
-- into the caller, where its scope is the wrong subprogram; @llvm-as@ answers
-- that with @!dbg attachment points at wrong subprogram for function@,
-- @warning: ignoring invalid debug info@, and then discards every attachment
-- in the module.  The old policy therefore already discarded the lot, just
-- further downstream and without saying so.
--
-- What is /not/ discarded is the rest of the metadata, which is a different
-- question wearing the same syntax.  @!tbaa@ is what tells the aliasing that
-- a @float@ store cannot clobber an @int@ load; @!llvm.loop@, @!prof@,
-- @!range@, @!alias.scope@ and @!noalias@ each say something the optimizer
-- would otherwise have to prove or assume.  Discarding those would make the
-- optimizer worse at its one job.  So the line is drawn by what a node /is/,
-- not by where it is written, and the two are not the same line: a
-- @!DIAssignID@ stands in an instruction's attachment list beside @!tbaa@,
-- and a @!llvm.loop@ node holds the loop's start and end @DILocation@s among
-- its properties.
--
-- Checked against @opt --strip-debug@, which is the same operation: it keeps
-- @!tbaa@, rewrites each @!llvm.loop@ node to drop the locations while
-- keeping the properties, and leaves the @Dwarf Version@,
-- @Debug Info Version@ and @debug-info-assignment-tracking@ module flags
-- behind — a flag describing debug information that is no longer there being
-- harmless, where a missing @Debug Info Version@ beside debug information
-- that is still there makes LLVM discard it.
module Olivine.Syntax.Debug
  ( stripDebugInfo
  , debugNodeNumber
  ) where

import Data.Char (isDigit, isUpper)
import Data.Map.Strict qualified as Map
import Data.Maybe (mapMaybe)
import Data.Set (Set)
import Data.Set qualified as Set
import Data.Text (Text)
import Data.Text qualified as T
import Numeric.Natural (Natural)

import Olivine.Syntax.Ast (Entry (..), Module (..))
import Olivine.Syntax.Function
import Olivine.Syntax.Global (Global (..))
import Olivine.Syntax.Instruction (Instruction (..), MetadataAttachment (..))
import Olivine.Syntax.Metadata (MetadataOperand (..))
import Olivine.Syntax.Name (Name (..))

-- | A module with its debug information taken out.
--
-- Three things go, and the order matters because each is defined in terms of
-- the one before:
--
-- 1. The specialized debug nodes, @!10 = distinct !DISubprogram(...)@ and its
--    thirty-odd relatives.  Those /are/ the debug information; everything
--    else here only refers to it.
--
-- 2. Every attachment naming one of them, wherever it stands — on an
--    instruction, on a function, on a global.  Asking which node an
--    attachment names rather than what the attachment is called is what makes
--    this complete without a list to keep up to date: @!dbg@ names a
--    @DILocation@ on an instruction and a @DISubprogram@ on a function,
--    @!DIAssignID@ names an assignment-tracking node, @!heapallocsite@ names
--    a @DIType@, and one question catches all of them.  @!llvm.dbg.cu@ is
--    named rather than deduced, being a list of compile units and nothing
--    without them.
--
-- 3. Every node nothing refers to any more.  A @DISubroutineType@ names a
--    plain tuple of its argument types, so removing the debug nodes leaves
--    ordinary tuples behind that no attachment and no named node can reach —
--    and, worse, tuples still pointing at nodes that are gone.  Those are one
--    defect and this is the one rule for it.  A node nothing refers to is not
--    part of the program: LLVM's own printer never writes one.
--
-- A node that survives has any operand pointing into the removed set taken
-- out, which is exactly and only the @!llvm.loop@ case — the loop's start and
-- end locations, standing among the properties that must stay.
stripDebugInfo :: Module -> Module
stripDebugInfo (Module entries) = Module (mapMaybe keep detached)
  where
    described = Set.fromList (mapMaybe debugNodeNumber [t | EOpaque t <- entries])

    -- The attachments come off first, so that what the reachability walk
    -- starts from is what is left rather than what was written.
    detached = map (detach described) (filter (not . compileUnits) entries)

    reached = grow Set.empty (rootNodes described detached)
    graph = Map.fromListWith (<>) [(n, operands) | EMetadata n _ operands <- detached]

    grow seen [] = seen
    grow seen (node : rest)
      | node `Set.member` seen || node `Set.member` described = grow seen rest
      | otherwise = grow (Set.insert node seen) (referred node <> rest)
    referred node = concatMap referenced (Map.findWithDefault [] node graph)

    live node = node `Set.member` reached

    keep entry = case entry of
      EMetadata node distinctness operands
        | live node ->
            Just (EMetadata node distinctness (map descend (filter present operands)))
        | otherwise -> Nothing
      EOpaque text
        | Just _ <- debugNodeNumber text -> Nothing
        | Just node <- nodeNumber text, not (live node) -> Nothing
      ENamedMetadata name operands -> Just (ENamedMetadata name (filter live operands))
      _ -> Just entry

    descend (MDTuple operands) = MDTuple (map descend (filter present operands))
    descend other = other
    present (MDRef node) = live node
    present _ = True

    compileUnits (ENamedMetadata (Name _ "llvm.dbg.cu") _) = True
    compileUnits _ = False

-- | An entry with every attachment naming one of the removed nodes taken off.
detach :: Set Natural -> Entry -> Entry
detach described entry = case entry of
  EGlobal g -> EGlobal g {globalMetadata = attached (globalMetadata g)}
  EDeclare s -> EDeclare (signature s)
  EDefine d ->
    EDefine
      d
        { definitionSignature = signature (definitionSignature d)
        , definitionBlocks = map block (definitionBlocks d)
        }
  _ -> entry
  where
    signature s = s {signatureMetadata = attached (signatureMetadata s)}
    block b = b {blockBody = map instruction (blockBody b)}
    instruction (IOperation result operation attachments) =
      IOperation result operation (attached attachments)
    instruction other = other
    attached = filter (\a -> not (attachmentNode a `Set.member` described))

-- | Everything that can name a node without being one.
--
-- A line this layer has not read can name a node as readily as it can name a
-- symbol, so its text is a root like any other.  That is what keeps a
-- construct the grammar has not reached from losing what it refers to.
rootNodes :: Set Natural -> [Entry] -> [Natural]
rootNodes described = concatMap entry
  where
    entry e = case e of
      ENamedMetadata _ operands -> operands
      EGlobal g -> map attachmentNode (globalMetadata g)
      EDeclare s -> map attachmentNode (signatureMetadata s)
      EDefine d ->
        map attachmentNode (signatureMetadata (definitionSignature d))
          <> concatMap instruction (concatMap blockBody (definitionBlocks d))
      EOpaque text
        | Just node <- debugNodeNumber text, node `Set.member` described -> []
        | otherwise -> mentioned text
      _ -> []
    instruction (IOperation _ _ attachments) = map attachmentNode attachments
    instruction (IOpaque text) = mentioned text

referenced :: MetadataOperand -> [Natural]
referenced (MDRef node) = [node]
referenced (MDTuple operands) = concatMap referenced operands
referenced _ = []

-- | The number a line defines a metadata node under, if it defines one.
nodeNumber :: Text -> Maybe Natural
nodeNumber text = fst <$> definition text

-- | The number of a specialized debug node, if the line defines one.
--
-- Every kind in the family is spelled with a leading @DI@ — @!DILocation@,
-- @!DISubprogram@, @!DIExpression@ — but for @!GenericDINode@, which is what
-- LLVM writes for a kind its own reader does not know.  That is the whole
-- test: a specialized node stands on its own line as its own construct, so
-- recognizing the family is recognizing a prefix, and nothing else in the
-- grammar is written this way.
debugNodeNumber :: Text -> Maybe Natural
debugNodeNumber text = do
  (node, body) <- definition text
  if specialized body then Just node else Nothing
  where
    specialized body =
      "!GenericDINode(" `T.isPrefixOf` body
        || case T.stripPrefix "!DI" body of
          Just rest -> maybe False (isUpper . fst) (T.uncons rest)
          Nothing -> False

-- | A line of the form @!N = \<body\>@, split into the two.
definition :: Text -> Maybe (Natural, Text)
definition text = do
  rest <- T.stripPrefix "!" (T.stripStart text)
  let (digits, after) = T.span isDigit rest
  assigned <- T.stripPrefix "=" (T.stripStart after)
  if T.null digits
    then Nothing
    else Just (read (T.unpack digits), undistinguished (T.stripStart assigned))
  where
    undistinguished body =
      maybe body T.stripStart (T.stripPrefix "distinct" body)

-- | Every metadata node a line Olivine has not read refers to.
--
-- An over-approximation: @!@ followed by digits inside a string counts too.
-- Keeping a node that nothing needs costs a line of output, where losing one
-- something needs costs a reference to a node the module no longer defines.
mentioned :: Text -> [Natural]
mentioned text =
  [ read (T.unpack digits)
  | piece <- drop 1 (T.splitOn "!" text)
  , let digits = T.takeWhile isDigit piece
  , not (T.null digits)
  ]
