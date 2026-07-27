; Functions no live path reaches.
;
; The corpus contains none — clang's own module is one translation unit's
; worth of code that something in it uses — so without this the whole-program
; pass would be exercised by nothing.
;
; @dispatch is reached only through the table, and @counted only through a
; constant expression, so a pass counting calls would delete both and this
; would stop printing what it prints.
@table = internal constant [1 x ptr] [ptr @dispatch]
@counted = internal global i32 0
@address = internal constant i64 ptrtoint (ptr @bump to i64)

declare i32 @puts(ptr)

define internal i32 @dispatch(i32 %x) {
  %r = mul i32 %x, 3
  ret i32 %r
}

define internal void @bump() {
  %n = load i32, ptr @counted
  %m = add i32 %n, 1
  store i32 %m, ptr @counted
  ret void
}

define internal i32 @helper(i32 %x) {
  %r = add i32 %x, 1
  ret i32 %r
}

; Nothing reaches these three: @orphan calls @stray, @stray calls @orphan, and
; @lonely calls nobody at all.
define internal i32 @orphan(i32 %x) {
  %r = call i32 @stray(i32 %x)
  ret i32 %r
}

define internal i32 @stray(i32 %x) {
  %r = call i32 @orphan(i32 %x)
  ret i32 %r
}

define internal i32 @lonely(i32 %x) {
  %r = sub i32 %x, 1
  ret i32 %r
}

define i32 @run(i32 %x) {
  %through = load ptr, ptr @table
  %a = call i32 %through(i32 %x)
  %b = call i32 @helper(i32 %a)
  %where = load i64, ptr @address
  %fn = inttoptr i64 %where to ptr
  call void %fn()
  %n = load i32, ptr @counted
  %r = add i32 %b, %n
  ret i32 %r
}
