; ModuleID = 'test/c/linkage.c'
source_filename = "test/c/linkage.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@weak_count = weak dso_local global i32 3, align 4
@version = internal constant [12 x i8] c"olivine 0.1\00", align 1
@tentative = dso_local global i32 0, align 4
@llvm.compiler.used = appending global [2 x ptr] [ptr @kept_by_attribute, ptr @version], section "llvm.metadata"

@aliased_answer = dso_local alias i32 (), ptr @real_answer

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @real_answer() #0 {
  ret i32 42
}

; Function Attrs: noinline nounwind optnone uwtable
define hidden i32 @hidden_helper(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %3 = load i32, ptr %2, align 4
  %4 = add nsw i32 %3, 1
  ret i32 %4
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @kept_by_attribute(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %3 = load i32, ptr %2, align 4
  %4 = mul nsw i32 %3, 3
  ret i32 %4
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @never_inlined(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %3 = load i32, ptr %2, align 4
  %4 = xor i32 %3, 90
  ret i32 %4
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @uses_them(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %3 = load i32, ptr %2, align 4
  %4 = call i32 @hidden_helper(i32 noundef %3)
  %5 = load i32, ptr %2, align 4
  %6 = call i32 @never_inlined(i32 noundef %5)
  %7 = add nsw i32 %4, %6
  %8 = load i32, ptr @weak_count, align 4
  %9 = add nsw i32 %7, %8
  %10 = load i32, ptr @tentative, align 4
  %11 = add nsw i32 %9, %10
  ret i32 %11
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
