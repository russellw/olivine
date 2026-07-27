; Computations whose operands are known.
;
; The corpus cannot exercise folding either: clang folds its own before
; writing any out.  Each function here returns something a reader can check by
; hand, and the driver prints them all.
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
