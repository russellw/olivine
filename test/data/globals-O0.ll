; ModuleID = 'test/c/globals.c'
source_filename = "test/c/globals.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@counter = dso_local global i32 0, align 4
@limit = dso_local constant i32 42, align 4
@message = dso_local global [8 x i8] c"olivine\00", align 1
@.str = private unnamed_addr constant [8 x i8] c"literal\00", align 1
@pointer_to_literal = dso_local global ptr @.str, align 8
@table = dso_local global [5 x i32] [i32 1, i32 2, i32 3, i32 4, i32 5], align 16
@.str.1 = private unnamed_addr constant [4 x i8] c"two\00", align 1
@paired = dso_local global { i32, [4 x i8], ptr } { i32 1, [4 x i8] zeroinitializer, ptr @.str.1 }, align 8
@address_of_counter = dso_local global ptr @counter, align 8
@interior = dso_local global ptr getelementptr (i8, ptr @table, i64 8), align 8
@hidden = internal global i32 7, align 4
@zeroed = dso_local global [4 x double] zeroinitializer, align 16

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @bump() #0 {
  %1 = load i32, ptr @counter, align 4
  %2 = add nsw i32 %1, 1
  store i32 %2, ptr @counter, align 4
  %3 = load i32, ptr @hidden, align 4
  %4 = add nsw i32 %2, %3
  ret i32 %4
}

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Ubuntu clang version 21.1.8 (6ubuntu1)"}
