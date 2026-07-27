; Two phi nodes at the head of a block that exchange their values.
;
; This is the shape phi elimination is easiest to get wrong on: the phis
; happen at once on arrival, so writing them out in order leaves both holding
; what the second one had.  Olivine got this wrong until the behaviour was
; compared rather than the structure, so it is kept as a regression test.
;
; Hand written rather than generated: no C the corpus compiles produces it.
define i32 @rotate(i32 %a, i32 %b, i32 %n) {
entry:
  br label %loop

loop:
  %x = phi i32 [ %a, %entry ], [ %y, %loop ]
  %y = phi i32 [ %b, %entry ], [ %x, %loop ]
  %i = phi i32 [ 0, %entry ], [ %j, %loop ]
  %j = add i32 %i, 1
  %c = icmp slt i32 %j, %n
  br i1 %c, label %loop, label %done

done:
  ret i32 %x
}
