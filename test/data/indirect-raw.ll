; ModuleID = 'test/c/indirect.c'
source_filename = "test/c/indirect.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@ops = internal constant [3 x ptr] [ptr @add, ptr @sub, ptr @mul], align 16

; Function Attrs: nounwind uwtable
define dso_local i32 @dispatch(i32 noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 %0, ptr %4, align 4, !tbaa !5
  store i32 %1, ptr %5, align 4, !tbaa !5
  store i32 %2, ptr %6, align 4, !tbaa !5
  %7 = load i32, ptr %4, align 4, !tbaa !5
  %8 = urem i32 %7, 3
  %9 = zext i32 %8 to i64
  %10 = getelementptr inbounds nuw [3 x ptr], ptr @ops, i64 0, i64 %9
  %11 = load ptr, ptr %10, align 8, !tbaa !9
  %12 = load i32, ptr %5, align 4, !tbaa !5
  %13 = load i32, ptr %6, align 4, !tbaa !5
  %14 = call i32 %11(i32 noundef %12, i32 noundef %13)
  ret i32 %14
}

; Function Attrs: nounwind uwtable
define dso_local i32 @fib(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  %3 = load i32, ptr %2, align 4, !tbaa !5
  %4 = icmp slt i32 %3, 2
  br i1 %4, label %5, label %7

5:                                                ; preds = %1
  %6 = load i32, ptr %2, align 4, !tbaa !5
  br label %15

7:                                                ; preds = %1
  %8 = load i32, ptr %2, align 4, !tbaa !5
  %9 = sub nsw i32 %8, 1
  %10 = call i32 @fib(i32 noundef %9)
  %11 = load i32, ptr %2, align 4, !tbaa !5
  %12 = sub nsw i32 %11, 2
  %13 = call i32 @fib(i32 noundef %12)
  %14 = add nsw i32 %10, %13
  br label %15

15:                                               ; preds = %7, %5
  %16 = phi i32 [ %6, %5 ], [ %14, %7 ]
  ret i32 %16
}

; Function Attrs: nounwind uwtable
define dso_local i32 @gcd(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  %5 = load i32, ptr %4, align 4, !tbaa !5
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %9

7:                                                ; preds = %2
  %8 = load i32, ptr %3, align 4, !tbaa !5
  br label %15

9:                                                ; preds = %2
  %10 = load i32, ptr %4, align 4, !tbaa !5
  %11 = load i32, ptr %3, align 4, !tbaa !5
  %12 = load i32, ptr %4, align 4, !tbaa !5
  %13 = srem i32 %11, %12
  %14 = call i32 @gcd(i32 noundef %10, i32 noundef %13)
  br label %15

15:                                               ; preds = %9, %7
  %16 = phi i32 [ %8, %7 ], [ %14, %9 ]
  ret i32 %16
}

; Function Attrs: nounwind uwtable
define dso_local i32 @parity(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  %3 = load i32, ptr %2, align 4, !tbaa !5
  %4 = icmp slt i32 %3, 0
  br i1 %4, label %5, label %6

5:                                                ; preds = %1
  br label %9

6:                                                ; preds = %1
  %7 = load i32, ptr %2, align 4, !tbaa !5
  %8 = call i32 @even_(i32 noundef %7)
  br label %9

9:                                                ; preds = %6, %5
  %10 = phi i32 [ -1, %5 ], [ %8, %6 ]
  ret i32 %10
}

; Function Attrs: nounwind uwtable
define internal i32 @even_(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  %3 = load i32, ptr %2, align 4, !tbaa !5
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %5, label %6

5:                                                ; preds = %1
  br label %10

6:                                                ; preds = %1
  %7 = load i32, ptr %2, align 4, !tbaa !5
  %8 = sub nsw i32 %7, 1
  %9 = call i32 @odd_(i32 noundef %8)
  br label %10

10:                                               ; preds = %6, %5
  %11 = phi i32 [ 1, %5 ], [ %9, %6 ]
  ret i32 %11
}

; Function Attrs: nounwind uwtable
define dso_local i32 @apply_twice(ptr noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %4, align 8, !tbaa !9
  store i32 %1, ptr %5, align 4, !tbaa !5
  store i32 %2, ptr %6, align 4, !tbaa !5
  %7 = load ptr, ptr %4, align 8, !tbaa !9
  %8 = load ptr, ptr %4, align 8, !tbaa !9
  %9 = load i32, ptr %5, align 4, !tbaa !5
  %10 = load i32, ptr %6, align 4, !tbaa !5
  %11 = call i32 %8(i32 noundef %9, i32 noundef %10)
  %12 = load i32, ptr %6, align 4, !tbaa !5
  %13 = call i32 %7(i32 noundef %11, i32 noundef %12)
  ret i32 %13
}

; Function Attrs: nounwind uwtable
define internal i32 @add(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  %5 = load i32, ptr %3, align 4, !tbaa !5
  %6 = load i32, ptr %4, align 4, !tbaa !5
  %7 = add nsw i32 %5, %6
  ret i32 %7
}

; Function Attrs: nounwind uwtable
define internal i32 @sub(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  %5 = load i32, ptr %3, align 4, !tbaa !5
  %6 = load i32, ptr %4, align 4, !tbaa !5
  %7 = sub nsw i32 %5, %6
  ret i32 %7
}

; Function Attrs: nounwind uwtable
define internal i32 @mul(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  %5 = load i32, ptr %3, align 4, !tbaa !5
  %6 = load i32, ptr %4, align 4, !tbaa !5
  %7 = mul nsw i32 %5, %6
  ret i32 %7
}

; Function Attrs: nounwind uwtable
define internal i32 @odd_(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  %3 = load i32, ptr %2, align 4, !tbaa !5
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %5, label %6

5:                                                ; preds = %1
  br label %10

6:                                                ; preds = %1
  %7 = load i32, ptr %2, align 4, !tbaa !5
  %8 = sub nsw i32 %7, 1
  %9 = call i32 @even_(i32 noundef %8)
  br label %10

10:                                               ; preds = %6, %5
  %11 = phi i32 [ 0, %5 ], [ %9, %6 ]
  ret i32 %11
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
!10 = !{!"any pointer", !7, i64 0}
