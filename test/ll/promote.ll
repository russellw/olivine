; Slots that may be promoted, next to one that may not.
;
; %sum and %i are only ever loaded and stored, so promotion takes both, and
; what the loop carries round through memory comes back out as a phi.  %kept
; has its address passed to a function that writes through it, so promotion
; must leave it where it is.
;
; The point of driving it rather than reading it is that missing that escape is
; not a malformed module: it produces a module LLVM accepts, in which the loop
; adds up the value stored before the call instead of the one @bump left
; behind, and only running it says so.
;
; Hand written rather than generated: clang at -O0 does not pass the address of
; a local to a function that writes through it and then keep reading the local
; in a loop, which is the arrangement being tested.

define void @bump(ptr %p) {
entry:
  %v = load i32, ptr %p, align 4
  %w = add i32 %v, 100
  store i32 %w, ptr %p, align 4
  ret void
}

define i32 @total(i32 %n) {
entry:
  %sum = alloca i32, align 4
  %i = alloca i32, align 4
  %kept = alloca i32, align 4
  store i32 0, ptr %sum, align 4
  store i32 0, ptr %i, align 4
  store i32 5, ptr %kept, align 4
  call void @bump(ptr %kept)
  br label %head

head:
  %a = load i32, ptr %i, align 4
  %c = icmp slt i32 %a, %n
  br i1 %c, label %body, label %done

body:
  %b = load i32, ptr %sum, align 4
  %k = load i32, ptr %kept, align 4
  %s = add i32 %b, %k
  store i32 %s, ptr %sum, align 4
  %d = load i32, ptr %i, align 4
  %e = add i32 %d, 1
  store i32 %e, ptr %i, align 4
  br label %head

done:
  %r = load i32, ptr %sum, align 4
  ret i32 %r
}
