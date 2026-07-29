; Blocks written in an order that is not the order a value travels in.
;
; %late is written before %mid, the only block that branches to it, so walking
; the blocks as written reaches %late before anything is known about what
; arrives there.  Reconstruction did exactly that.  %out, whose only
; predecessor is %late, then read %u -- a local phi elimination had taken the
; name of -- and nothing had been carried to it, so raising had a use of a local
; it had dropped and stopped there.
;
; The phis in %mid have one incoming edge each, which is what makes the walk
; order matter here: a block with one predecessor gets no phi of its own to
; stand for what arrives, so it takes what its predecessor was left holding, and
; that has to have been worked out first.  Both halves of the shape -- the
; single-incoming phi and the block written before the block that reaches it --
; are what clang emits at -O1, together, which is where this was found.
;
; What makes it a behaviour test rather than a crash test is the answer:
; @accumulate(n) adds up 0 + 1 + ... + n-1, and it can only do that if what
; %out reads is what the loop carried.

define i32 @accumulate(i32 %n) {
entry:
  br label %head

late:
  %more = icmp slt i32 %y, %n
  br i1 %more, label %head, label %out

head:
  %x = phi i32 [ 0, %entry ], [ %y, %late ]
  %t = phi i32 [ 0, %entry ], [ %u, %late ]
  %step = add i32 %x, 1
  %acc = add i32 %t, %x
  br label %mid

mid:
  %y = phi i32 [ %step, %head ]
  %u = phi i32 [ %acc, %head ]
  br label %late

out:
  ret i32 %u
}
