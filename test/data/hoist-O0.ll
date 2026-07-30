; ModuleID = 'test/c/hoist.c'
source_filename = "test/c/hoist.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @scaled_sum(ptr noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  store i32 %2, ptr %6, align 4
  store i32 0, ptr %7, align 4
  store i32 0, ptr %8, align 4
  br label %9

9:                                                ; preds = %26, %3
  %10 = load i32, ptr %8, align 4
  %11 = load i32, ptr %5, align 4
  %12 = icmp slt i32 %10, %11
  br i1 %12, label %13, label %29

13:                                               ; preds = %9
  %14 = load ptr, ptr %4, align 8
  %15 = load i32, ptr %8, align 4
  %16 = sext i32 %15 to i64
  %17 = getelementptr inbounds i32, ptr %14, i64 %16
  %18 = load i32, ptr %17, align 4
  %19 = load i32, ptr %6, align 4
  %20 = load i32, ptr %6, align 4
  %21 = mul nsw i32 %19, %20
  %22 = add nsw i32 %21, 3
  %23 = mul nsw i32 %18, %22
  %24 = load i32, ptr %7, align 4
  %25 = add nsw i32 %24, %23
  store i32 %25, ptr %7, align 4
  br label %26

26:                                               ; preds = %13
  %27 = load i32, ptr %8, align 4
  %28 = add nsw i32 %27, 1
  store i32 %28, ptr %8, align 4
  br label %9, !llvm.loop !6

29:                                               ; preds = %9
  %30 = load i32, ptr %7, align 4
  ret i32 %30
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @nested_squares(i32 noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  store i32 %0, ptr %4, align 4
  store i32 %1, ptr %5, align 4
  store i32 %2, ptr %6, align 4
  store i32 0, ptr %7, align 4
  store i32 0, ptr %8, align 4
  br label %10

10:                                               ; preds = %32, %3
  %11 = load i32, ptr %8, align 4
  %12 = load i32, ptr %6, align 4
  %13 = icmp slt i32 %11, %12
  br i1 %13, label %14, label %35

14:                                               ; preds = %10
  store i32 0, ptr %9, align 4
  br label %15

15:                                               ; preds = %28, %14
  %16 = load i32, ptr %9, align 4
  %17 = load i32, ptr %6, align 4
  %18 = icmp slt i32 %16, %17
  br i1 %18, label %19, label %31

19:                                               ; preds = %15
  %20 = load i32, ptr %4, align 4
  %21 = shl i32 %20, 2
  %22 = load i32, ptr %5, align 4
  %23 = load i32, ptr %4, align 4
  %24 = xor i32 %22, %23
  %25 = add nsw i32 %21, %24
  %26 = load i32, ptr %7, align 4
  %27 = add nsw i32 %26, %25
  store i32 %27, ptr %7, align 4
  br label %28

28:                                               ; preds = %19
  %29 = load i32, ptr %9, align 4
  %30 = add nsw i32 %29, 1
  store i32 %30, ptr %9, align 4
  br label %15, !llvm.loop !8

31:                                               ; preds = %15
  br label %32

32:                                               ; preds = %31
  %33 = load i32, ptr %8, align 4
  %34 = add nsw i32 %33, 1
  store i32 %34, ptr %8, align 4
  br label %10, !llvm.loop !9

35:                                               ; preds = %10
  %36 = load i32, ptr %7, align 4
  ret i32 %36
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @sometimes(ptr noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  store i32 %2, ptr %6, align 4
  store i32 0, ptr %7, align 4
  store i32 0, ptr %8, align 4
  br label %9

9:                                                ; preds = %27, %3
  %10 = load i32, ptr %8, align 4
  %11 = load i32, ptr %5, align 4
  %12 = icmp slt i32 %10, %11
  br i1 %12, label %13, label %30

13:                                               ; preds = %9
  %14 = load ptr, ptr %4, align 8
  %15 = load i32, ptr %8, align 4
  %16 = sext i32 %15 to i64
  %17 = getelementptr inbounds i32, ptr %14, i64 %16
  %18 = load i32, ptr %17, align 4
  %19 = icmp sgt i32 %18, 0
  br i1 %19, label %20, label %26

20:                                               ; preds = %13
  %21 = load i32, ptr %6, align 4
  %22 = load i32, ptr %6, align 4
  %23 = mul nsw i32 %21, %22
  %24 = load i32, ptr %7, align 4
  %25 = add nsw i32 %24, %23
  store i32 %25, ptr %7, align 4
  br label %26

26:                                               ; preds = %20, %13
  br label %27

27:                                               ; preds = %26
  %28 = load i32, ptr %8, align 4
  %29 = add nsw i32 %28, 1
  store i32 %29, ptr %8, align 4
  br label %9, !llvm.loop !10

30:                                               ; preds = %9
  %31 = load i32, ptr %7, align 4
  ret i32 %31
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @guarded_divide(i32 noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store i32 %0, ptr %4, align 4
  store i32 %1, ptr %5, align 4
  store i32 %2, ptr %6, align 4
  store i32 0, ptr %7, align 4
  store i32 0, ptr %8, align 4
  br label %9

9:                                                ; preds = %19, %3
  %10 = load i32, ptr %8, align 4
  %11 = load i32, ptr %6, align 4
  %12 = icmp slt i32 %10, %11
  br i1 %12, label %13, label %22

13:                                               ; preds = %9
  %14 = load i32, ptr %4, align 4
  %15 = load i32, ptr %5, align 4
  %16 = sdiv i32 %14, %15
  %17 = load i32, ptr %7, align 4
  %18 = add nsw i32 %17, %16
  store i32 %18, ptr %7, align 4
  br label %19

19:                                               ; preds = %13
  %20 = load i32, ptr %8, align 4
  %21 = add nsw i32 %20, 1
  store i32 %21, ptr %8, align 4
  br label %9, !llvm.loop !11

22:                                               ; preds = %9
  %23 = load i32, ptr %7, align 4
  ret i32 %23
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @carried_first(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  store i32 0, ptr %5, align 4
  store i32 0, ptr %6, align 4
  store i32 0, ptr %7, align 4
  br label %8

8:                                                ; preds = %18, %2
  %9 = load i32, ptr %7, align 4
  %10 = load i32, ptr %3, align 4
  %11 = icmp slt i32 %9, %10
  br i1 %11, label %12, label %21

12:                                               ; preds = %8
  %13 = load i32, ptr %6, align 4
  %14 = load i32, ptr %5, align 4
  %15 = add nsw i32 %14, %13
  store i32 %15, ptr %5, align 4
  %16 = load i32, ptr %4, align 4
  %17 = add nsw i32 %16, 1
  store i32 %17, ptr %6, align 4
  br label %18

18:                                               ; preds = %12
  %19 = load i32, ptr %7, align 4
  %20 = add nsw i32 %19, 1
  store i32 %20, ptr %7, align 4
  br label %8, !llvm.loop !12

21:                                               ; preds = %8
  %22 = load i32, ptr %5, align 4
  ret i32 %22
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @jumped_into(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  store i32 0, ptr %5, align 4
  store i32 0, ptr %6, align 4
  %7 = load i32, ptr %3, align 4
  %8 = and i32 %7, 1
  %9 = icmp ne i32 %8, 0
  br i1 %9, label %10, label %11

10:                                               ; preds = %2
  br label %21

11:                                               ; preds = %2
  br label %12

12:                                               ; preds = %21, %11
  %13 = load i32, ptr %6, align 4
  %14 = load i32, ptr %3, align 4
  %15 = icmp slt i32 %13, %14
  br i1 %15, label %16, label %24

16:                                               ; preds = %12
  %17 = load i32, ptr %4, align 4
  %18 = mul nsw i32 %17, 5
  %19 = load i32, ptr %5, align 4
  %20 = add nsw i32 %19, %18
  store i32 %20, ptr %5, align 4
  br label %21

21:                                               ; preds = %16, %10
  %22 = load i32, ptr %6, align 4
  %23 = add nsw i32 %22, 1
  store i32 %23, ptr %6, align 4
  br label %12, !llvm.loop !13

24:                                               ; preds = %12
  %25 = load i32, ptr %5, align 4
  ret i32 %25
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
!6 = distinct !{!6, !7}
!7 = !{!"llvm.loop.mustprogress"}
!8 = distinct !{!8, !7}
!9 = distinct !{!9, !7}
!10 = distinct !{!10, !7}
!11 = distinct !{!11, !7}
!12 = distinct !{!12, !7}
!13 = distinct !{!13, !7}
