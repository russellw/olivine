; ModuleID = 'test/c/arith.c'
source_filename = "test/c/arith.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nounwind uwtable
define dso_local i32 @sdiv(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  %5 = load i32, ptr %3, align 4, !tbaa !5
  %6 = load i32, ptr %4, align 4, !tbaa !5
  %7 = sdiv i32 %5, %6
  ret i32 %7
}

; Function Attrs: nounwind uwtable
define dso_local i32 @udiv(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  %5 = load i32, ptr %3, align 4, !tbaa !5
  %6 = load i32, ptr %4, align 4, !tbaa !5
  %7 = udiv i32 %5, %6
  ret i32 %7
}

; Function Attrs: nounwind uwtable
define dso_local i32 @srem(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  %5 = load i32, ptr %3, align 4, !tbaa !5
  %6 = load i32, ptr %4, align 4, !tbaa !5
  %7 = srem i32 %5, %6
  ret i32 %7
}

; Function Attrs: nounwind uwtable
define dso_local i32 @urem(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  %5 = load i32, ptr %3, align 4, !tbaa !5
  %6 = load i32, ptr %4, align 4, !tbaa !5
  %7 = urem i32 %5, %6
  ret i32 %7
}

; Function Attrs: nounwind uwtable
define dso_local i32 @ashr(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  %5 = load i32, ptr %3, align 4, !tbaa !5
  %6 = load i32, ptr %4, align 4, !tbaa !5
  %7 = ashr i32 %5, %6
  ret i32 %7
}

; Function Attrs: nounwind uwtable
define dso_local i32 @lshr(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  %5 = load i32, ptr %3, align 4, !tbaa !5
  %6 = load i32, ptr %4, align 4, !tbaa !5
  %7 = lshr i32 %5, %6
  ret i32 %7
}

; Function Attrs: nounwind uwtable
define dso_local i64 @widen(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  %3 = load i32, ptr %2, align 4, !tbaa !5
  %4 = sext i32 %3 to i64
  ret i64 %4
}

; Function Attrs: nounwind uwtable
define dso_local i64 @zwiden(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  %3 = load i32, ptr %2, align 4, !tbaa !5
  %4 = zext i32 %3 to i64
  ret i64 %4
}

; Function Attrs: nounwind uwtable
define dso_local signext i16 @narrow(i64 noundef %0) #0 {
  %2 = alloca i64, align 8
  store i64 %0, ptr %2, align 8, !tbaa !9
  %3 = load i64, ptr %2, align 8, !tbaa !9
  %4 = trunc i64 %3 to i16
  ret i16 %4
}

; Function Attrs: nounwind uwtable
define dso_local i32 @compare(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  %5 = load i32, ptr %3, align 4, !tbaa !5
  %6 = icmp slt i32 %5, 0
  br i1 %6, label %7, label %10

7:                                                ; preds = %2
  %8 = load i32, ptr %4, align 4, !tbaa !5
  %9 = icmp ugt i32 %8, 7
  br label %10

10:                                               ; preds = %7, %2
  %11 = phi i1 [ false, %2 ], [ %9, %7 ]
  %12 = zext i1 %11 to i32
  ret i32 %12
}

attributes #0 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 21.1.8 (6ubuntu1)"}
!5 = !{!6, !6, i64 0}
!6 = !{!"int", !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = !{!10, !10, i64 0}
!10 = !{!"long", !7, i64 0}
