; Instructions nothing reads, beside ones that must stay anyway.
;
; The corpus contains no dead code — clang removes its own before writing —
; so without this the pass would be exercised by nothing.
define i32 @sift(i32 %a, i32 %b, ptr %p) {
entry:
  %unread = add i32 %a, %b
  %chain = mul i32 %unread, 3
  %quiet = load i32, ptr %p
  %noisy = load volatile i32, ptr %p
  %risky = sdiv i32 %a, %b
  %room = alloca i32, align 4
  store i32 %a, ptr %p, align 4
  %answer = add i32 %a, 1
  ret i32 %answer
}
