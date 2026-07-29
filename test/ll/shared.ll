; Computations worth sharing, next to ones that must not be shared.
;
; Hand written rather than generated: clang at -O0 writes the same expression
; twice readily enough, but not next to the arrangements that matter here — a
; call that counts how often it is called, a load either side of a store
; through the same pointer, and a local read either side of being reassigned.
;
; The point of driving these rather than reading them is that sharing any of
; them is not a malformed module.  It produces a module LLVM accepts in which
; the program computes something else, and only running it says so.

@count = internal global i32 0

define i32 @tick() {
entry:
  %v = load i32, ptr @count, align 4
  %w = add i32 %v, 1
  store i32 %w, ptr @count, align 4
  ret i32 %w
}

; Two calls with the same arguments are two calls.  Sharing them would leave
; the counter one lower and the sum one less than the two answers together.
define i32 @counted() {
entry:
  %a = call i32 @tick()
  %b = call i32 @tick()
  %s = add i32 %a, %b
  ret i32 %s
}

; What a load answers is what memory holds, which the store in between
; changes.
define i32 @reloaded(ptr %p) {
entry:
  %a = load i32, ptr %p, align 4
  store i32 99, ptr %p, align 4
  %b = load i32, ptr %p, align 4
  %s = add i32 %a, %b
  ret i32 %s
}

; A slot promotion turns into a local assigned twice, read either side of the
; second assignment.  The two additions are written identically and add one to
; different numbers; sharing them would answer as though the store were not
; there.
define i32 @stale(i32 %n) {
entry:
  %s = alloca i32, align 4
  store i32 %n, ptr %s, align 4
  %a = load i32, ptr %s, align 4
  store i32 7, ptr %s, align 4
  %b = load i32, ptr %s, align 4
  %x = add i32 %a, 1
  %y = add i32 %b, 1
  %t = mul i32 %x, %y
  ret i32 %t
}

; And what is genuinely the same: a subscript computed in the entry block and
; again in a block the entry block is the only way into.  This one has to keep
; answering what it answered while the pass takes an instruction away.
define i32 @subscripted(ptr %p, i64 %i, i32 %c) {
entry:
  %q = getelementptr inbounds [4 x i32], ptr %p, i64 %i, i64 2
  %a = load i32, ptr %q, align 4
  %t = icmp ne i32 %c, 0
  br i1 %t, label %again, label %done

again:
  %r = getelementptr inbounds [4 x i32], ptr %p, i64 %i, i64 2
  %b = load i32, ptr %r, align 4
  %s = add i32 %a, %b
  ret i32 %s

done:
  ret i32 %a
}

; Two allocations are two objects, however alike the instructions asking for
; them.
define i32 @separate() {
entry:
  %x = alloca i32, align 4
  %y = alloca i32, align 4
  store i32 1, ptr %x, align 4
  store i32 2, ptr %y, align 4
  %a = load i32, ptr %x, align 4
  %b = load i32, ptr %y, align 4
  %s = add i32 %a, %b
  ret i32 %s
}
