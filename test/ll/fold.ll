; What a computation comes to: from its operands, from its shape, or from what
; produced an operand.
;
; The corpus cannot exercise folding either: clang folds its own before
; writing any out.  Each function here returns something a reader can check by
; hand, and the driver prints them all.  The ones below @unfoldable take an
; argument, since an identity between two constants would fold without needing
; to be one.
define i32 @arithmetic() {
  %a = add i32 20, 22
  %b = sub i32 %a, 2
  %c = mul i32 %b, 3
  %d = sdiv i32 %c, 4
  %e = srem i32 %d, 7
  ret i32 %e
}

define i32 @bitwise() {
  %a = and i32 60, 13
  %b = or i32 %a, 128
  %c = xor i32 %b, 255
  %d = shl i32 %c, 2
  %e = ashr i32 %d, 1
  ret i32 %e
}

; Wraps in 32 bits, which is defined when no flag says otherwise.  The comment
; sits outside: a comment inside a body is not a modelled instruction, so a
; function containing one is retained as syntax and never reaches the core.
define i32 @wrapping() {
  %a = mul i32 65536, 65536
  %b = add i32 %a, 7
  ret i32 %b
}

define i1 @comparisons() {
  %a = icmp slt i32 -1, 0
  %b = icmp ult i32 -1, 0
  %c = xor i1 %a, %b
  ret i1 %c
}

define i64 @conversions() {
  %a = trunc i32 300 to i8
  %b = sext i8 %a to i64
  %c = zext i8 %a to i64
  %d = add i64 %b, %c
  ret i64 %d
}

define i32 @chosen() {
  %a = icmp eq i32 3, 3
  %b = select i1 %a, i32 111, i32 222
  ret i32 %b
}

; Nothing here may fold: division by zero and a shift past the width are
; undefined, and an addition promising not to overflow that does is poison.
define i32 @unfoldable(i32 %n) {
  %a = sdiv i32 %n, 0
  %b = shl i32 1, 32
  %c = add nsw i32 2147483647, 1
  %d = add i32 %a, %b
  %e = add i32 %d, %c
  ret i32 %e
}

; An operand that makes the operation do nothing, and two operands that are the
; same value.  Every step here leaves %n where it found it or leaves nothing at
; all, so the answer is the argument.
define i32 @identities(i32 %n) {
  %a = add i32 %n, 0
  %b = mul i32 %a, 1
  %c = and i32 %b, %b
  %d = or i32 %c, 0
  %e = xor i32 %d, 0
  %f = ashr i32 %e, 0
  %g = sdiv i32 %f, 1
  ; And the ones that come to nothing whatever the operand holds, including
  ; the shift of nothing by an amount that would be poison if it were shifting
  ; something.
  %h = sub i32 %g, %g
  %i = mul i32 %n, 0
  %j = urem i32 %n, 1
  %k = shl i32 0, %n
  %l = or i32 %h, %i
  %m = or i32 %l, %j
  %o = or i32 %m, %k
  %p = add i32 %g, %o
  ret i32 %p
}

; A value compared with itself answers without the value being known.  Returns
; one.
define i32 @reflexive(i32 %n) {
  %a = icmp eq i32 %n, %n
  %b = icmp ult i32 %n, %n
  %c = icmp sge i32 %n, %n
  %d = xor i1 %a, %b
  %e = and i1 %d, %c
  %f = zext i1 %e to i32
  ret i32 %f
}

; A conversion of a conversion.  Called with 0x1234abcd: cutting back to the
; width it came from gives that again, cutting below it gives 0xabcd, and the
; two extensions of those sixteen bits are -21555 and 43981, which come to
; 22426.
define i32 @chains(i32 %n) {
  %a = zext i32 %n to i64
  %b = trunc i64 %a to i32
  %c = sext i32 %b to i64
  %d = trunc i64 %c to i16
  %e = sext i16 %d to i32
  %f = sext i32 %e to i64
  %g = zext i16 %d to i32
  %h = sext i32 %g to i64
  %i = add i64 %f, %h
  %j = trunc i64 %i to i32
  ret i32 %j
}

; Cutting a value down and putting zeroes back where it came from is a mask.
; Called with 0x1234abcd, so 0xcd.
define i32 @masked(i32 %n) {
  %a = trunc i32 %n to i8
  %b = zext i8 %a to i32
  ret i32 %b
}

; A value cut down, masked, and zeroed back to the width it came from is the
; mask by itself, which is what reading a C bit field comes to once the slot
; holding it has been promoted away.  The negative constant is the case worth
; writing down: the mask is read unsigned at the narrow width, so -9 at i16
; keeps every bit but the fourth and clears everything above the sixteenth.
; Called with 0x1234abcd, giving 5 and 0xabc5, which sum to 43978.
define i32 @bitfield(i32 %n) {
  %t = trunc i32 %n to i16
  %m = and i16 %t, 7
  %a = zext i16 %m to i32
  %v = and i16 %t, -9
  %b = zext i16 %v to i32
  %s = add i32 %a, %b
  ret i32 %s
}

; The same shape where the mask has to stay: an operation that sets the bits
; the cut took away rather than leaving them away, and a widening past the
; width the value came from, which would leave a conversion standing beside the
; mask.  Called with 0x1234abcd, giving 0xabcf and 0xabc5, which sum to 87956.
define i64 @unmasked(i32 %n) {
  %t = trunc i32 %n to i16
  %o = or i16 %t, 7
  %a = zext i16 %o to i32
  %m = and i16 %t, -9
  %b = zext i16 %m to i64
  %c = zext i32 %a to i64
  %s = add i64 %b, %c
  ret i64 %s
}

; A chain the loop carries round, which is the one that must not be followed:
; the narrowing reads what the widening left the time before, and what the
; widening widened has been assigned since.  Reading it as that would give the
; iteration's own %s.  Returns 8 for an argument of 5.
define i32 @carried(i32 %n) {
entry:
  %w0 = zext i32 %n to i64
  br label %loop

loop:
  %i = phi i32 [ 0, %entry ], [ %i1, %loop ]
  %w = phi i64 [ %w0, %entry ], [ %wn, %loop ]
  %t = trunc i64 %w to i32
  %s = add i32 %t, %i
  %wn = zext i32 %s to i64
  %i1 = add i32 %i, 1
  %done = icmp eq i32 %i1, 4
  br i1 %done, label %out, label %loop

out:
  ret i32 %t
}
