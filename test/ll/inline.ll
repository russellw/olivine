; Calls that should be replaced by the bodies they name, next to calls that
; must not be.
;
; The arrangement is one clang does not emit: at -O0 every function it writes
; carries noinline and optnone, and at -O1 and above it has already inlined
; whatever it meant to, so the corpus contains no function that is both
; inlinable and not yet inlined.  Everything here is therefore hand written.
;
; What only running it can catch is the value arriving wrong.  A body copied
; into the wrong numbering, an argument bound to the wrong parameter, or a
; return assigning to a local something else already uses all produce a module
; LLVM accepts and computes different arithmetic in, and reading the output
; will not say which of them happened.
;
; @clamp is the case that would need a phi in single assignment form: three
; returns reaching one use.  Here each return is an assignment and nothing
; joins, and the phi that appears in the output was built on the way back to
; LLVM by reconstruction, not by inlining.
;
; @through_slot is the case that needs its allocation moved.  It is called in a
; loop, so an alloca left where the body puts it would allocate once an
; iteration and free none of it until @run returned.
;
; @fact, @even and @odd must survive: a body that can call its way back to
; itself cannot be copied in, because the copy brings the call that starts it
; over again.  @even and @odd are the pair that a check for the callee reaching
; the *caller* lets through, @run being neither of them.
;
; @kept must survive because it says so.
;
; The two calls to @addmul in @run's entry block are there so that the second
; is spliced into a block the first has already been spliced into, and has to
; avoid the numbering the first left behind.
;
; Nothing here writes a comment inside a function body.  One line of a body
; that Olivine cannot read costs the whole definition — it is retained as
; written and never lowered — and a comment is such a line, so a fixture with
; one in it would quietly test nothing at all.

declare void @sink(ptr)

define i32 @addmul(i32 %a, i32 %b) {
entry:
  %s = add i32 %a, %b
  %m = mul i32 %s, %a
  ret i32 %m
}

define i32 @clamp(i32 %x, i32 %lo, i32 %hi) {
entry:
  %below = icmp slt i32 %x, %lo
  br i1 %below, label %low, label %check

low:
  ret i32 %lo

check:
  %above = icmp sgt i32 %x, %hi
  br i1 %above, label %high, label %same

high:
  ret i32 %hi

same:
  ret i32 %x
}

define void @accumulate(ptr %p, i32 %v) {
entry:
  %o = load i32, ptr %p, align 4
  %n = add i32 %o, %v
  store i32 %n, ptr %p, align 4
  ret void
}

define i32 @through_slot(i32 %x) {
entry:
  %slot = alloca i32, align 4
  store i32 %x, ptr %slot, align 4
  call void @sink(ptr %slot)
  %r = load i32, ptr %slot, align 4
  %d = mul i32 %r, 2
  ret i32 %d
}

define i32 @fact(i32 %n) {
entry:
  %z = icmp sle i32 %n, 1
  br i1 %z, label %base, label %rec

base:
  ret i32 1

rec:
  %m = sub i32 %n, 1
  %f = call i32 @fact(i32 %m)
  %r = mul i32 %n, %f
  ret i32 %r
}

define i32 @even(i32 %n) {
entry:
  %z = icmp eq i32 %n, 0
  br i1 %z, label %yes, label %no

yes:
  ret i32 1

no:
  %m = sub i32 %n, 1
  %r = call i32 @odd(i32 %m)
  ret i32 %r
}

define i32 @odd(i32 %n) {
entry:
  %z = icmp eq i32 %n, 0
  br i1 %z, label %yes, label %no

yes:
  ret i32 0

no:
  %m = sub i32 %n, 1
  %r = call i32 @even(i32 %m)
  ret i32 %r
}

define i32 @kept(i32 %x) noinline {
entry:
  %r = mul i32 %x, 7
  ret i32 %r
}

define i32 @run(i32 %n) {
entry:
  %acc = alloca i32, align 4
  store i32 0, ptr %acc, align 4
  %first = call i32 @addmul(i32 %n, i32 2)
  %second = call i32 @addmul(i32 %first, i32 3)
  br label %head

head:
  %i = phi i32 [ 0, %entry ], [ %j, %body ]
  %c = icmp slt i32 %i, %n
  br i1 %c, label %body, label %done

body:
  %t = call i32 @through_slot(i32 %i)
  %u = call i32 @clamp(i32 %t, i32 2, i32 8)
  call void @accumulate(ptr %acc, i32 %u)
  %v = call i32 @kept(i32 %i)
  call void @accumulate(ptr %acc, i32 %v)
  %j = add i32 %i, 1
  br label %head

done:
  %f = call i32 @fact(i32 %n)
  %e = call i32 @even(i32 %n)
  %a = load i32, ptr %acc, align 4
  %r1 = add i32 %a, %second
  %r2 = add i32 %r1, %f
  %r3 = add i32 %r2, %e
  ret i32 %r3
}
