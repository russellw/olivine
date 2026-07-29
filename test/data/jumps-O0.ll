; ModuleID = 'test/c/jumps.c'
source_filename = "test/c/jumps.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @search(ptr noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) #0 {
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  store i32 %2, ptr %7, align 4
  store i32 %3, ptr %8, align 4
  store i32 -1, ptr %9, align 4
  store i32 0, ptr %10, align 4
  br label %12

12:                                               ; preds = %56, %4
  %13 = load i32, ptr %10, align 4
  %14 = load i32, ptr %7, align 4
  %15 = icmp slt i32 %13, %14
  br i1 %15, label %16, label %59

16:                                               ; preds = %12
  store i32 0, ptr %11, align 4
  br label %17

17:                                               ; preds = %52, %16
  %18 = load i32, ptr %11, align 4
  %19 = load i32, ptr %6, align 4
  %20 = icmp slt i32 %18, %19
  br i1 %20, label %21, label %55

21:                                               ; preds = %17
  %22 = load ptr, ptr %5, align 8
  %23 = load i32, ptr %10, align 4
  %24 = load i32, ptr %6, align 4
  %25 = mul nsw i32 %23, %24
  %26 = load i32, ptr %11, align 4
  %27 = add nsw i32 %25, %26
  %28 = sext i32 %27 to i64
  %29 = getelementptr inbounds i32, ptr %22, i64 %28
  %30 = load i32, ptr %29, align 4
  %31 = icmp slt i32 %30, 0
  br i1 %31, label %32, label %33

32:                                               ; preds = %21
  br label %52

33:                                               ; preds = %21
  %34 = load ptr, ptr %5, align 8
  %35 = load i32, ptr %10, align 4
  %36 = load i32, ptr %6, align 4
  %37 = mul nsw i32 %35, %36
  %38 = load i32, ptr %11, align 4
  %39 = add nsw i32 %37, %38
  %40 = sext i32 %39 to i64
  %41 = getelementptr inbounds i32, ptr %34, i64 %40
  %42 = load i32, ptr %41, align 4
  %43 = load i32, ptr %8, align 4
  %44 = icmp eq i32 %42, %43
  br i1 %44, label %45, label %51

45:                                               ; preds = %33
  %46 = load i32, ptr %10, align 4
  %47 = load i32, ptr %6, align 4
  %48 = mul nsw i32 %46, %47
  %49 = load i32, ptr %11, align 4
  %50 = add nsw i32 %48, %49
  store i32 %50, ptr %9, align 4
  br label %60

51:                                               ; preds = %33
  br label %52

52:                                               ; preds = %51, %32
  %53 = load i32, ptr %11, align 4
  %54 = add nsw i32 %53, 1
  store i32 %54, ptr %11, align 4
  br label %17, !llvm.loop !6

55:                                               ; preds = %17
  br label %56

56:                                               ; preds = %55
  %57 = load i32, ptr %10, align 4
  %58 = add nsw i32 %57, 1
  store i32 %58, ptr %10, align 4
  br label %12, !llvm.loop !8

59:                                               ; preds = %12
  br label %60

60:                                               ; preds = %59, %45
  %61 = load i32, ptr %9, align 4
  ret i32 %61
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @digits(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  store i32 0, ptr %3, align 4
  br label %4

4:                                                ; preds = %9, %1
  %5 = load i32, ptr %3, align 4
  %6 = add nsw i32 %5, 1
  store i32 %6, ptr %3, align 4
  %7 = load i32, ptr %2, align 4
  %8 = udiv i32 %7, 10
  store i32 %8, ptr %2, align 4
  br label %9

9:                                                ; preds = %4
  %10 = load i32, ptr %2, align 4
  %11 = icmp ne i32 %10, 0
  br i1 %11, label %4, label %12, !llvm.loop !9

12:                                               ; preds = %9
  %13 = load i32, ptr %3, align 4
  ret i32 %13
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @falls_through(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  store i32 0, ptr %3, align 4
  %4 = load i32, ptr %2, align 4
  switch i32 %4, label %15 [
    i32 3, label %5
    i32 2, label %8
    i32 1, label %11
    i32 9, label %14
  ]

5:                                                ; preds = %1
  %6 = load i32, ptr %3, align 4
  %7 = add nsw i32 %6, 8
  store i32 %7, ptr %3, align 4
  br label %8

8:                                                ; preds = %1, %5
  %9 = load i32, ptr %3, align 4
  %10 = add nsw i32 %9, 4
  store i32 %10, ptr %3, align 4
  br label %11

11:                                               ; preds = %1, %8
  %12 = load i32, ptr %3, align 4
  %13 = add nsw i32 %12, 2
  store i32 %13, ptr %3, align 4
  br label %16

14:                                               ; preds = %1
  store i32 99, ptr %3, align 4
  br label %16

15:                                               ; preds = %1
  store i32 -1, ptr %3, align 4
  br label %16

16:                                               ; preds = %15, %14, %11
  %17 = load i32, ptr %3, align 4
  ret i32 %17
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @two_exits(ptr noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  store i32 %2, ptr %7, align 4
  store i32 0, ptr %8, align 4
  store i32 0, ptr %9, align 4
  br label %10

10:                                               ; preds = %29, %3
  %11 = load i32, ptr %9, align 4
  %12 = load i32, ptr %6, align 4
  %13 = icmp slt i32 %11, %12
  br i1 %13, label %14, label %32

14:                                               ; preds = %10
  %15 = load ptr, ptr %5, align 8
  %16 = load i32, ptr %9, align 4
  %17 = sext i32 %16 to i64
  %18 = getelementptr inbounds i32, ptr %15, i64 %17
  %19 = load i32, ptr %18, align 4
  %20 = load i32, ptr %8, align 4
  %21 = add nsw i32 %20, %19
  store i32 %21, ptr %8, align 4
  %22 = load i32, ptr %8, align 4
  %23 = load i32, ptr %7, align 4
  %24 = icmp sgt i32 %22, %23
  br i1 %24, label %25, label %28

25:                                               ; preds = %14
  %26 = load i32, ptr %8, align 4
  %27 = sub nsw i32 0, %26
  store i32 %27, ptr %4, align 4
  br label %34

28:                                               ; preds = %14
  br label %29

29:                                               ; preds = %28
  %30 = load i32, ptr %9, align 4
  %31 = add nsw i32 %30, 1
  store i32 %31, ptr %9, align 4
  br label %10, !llvm.loop !10

32:                                               ; preds = %10
  %33 = load i32, ptr %8, align 4
  store i32 %33, ptr %4, align 4
  br label %34

34:                                               ; preds = %32, %25
  %35 = load i32, ptr %4, align 4
  ret i32 %35
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @nested_while(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  store i32 0, ptr %5, align 4
  br label %7

7:                                                ; preds = %25, %2
  %8 = load i32, ptr %3, align 4
  %9 = icmp sgt i32 %8, 0
  br i1 %9, label %10, label %28

10:                                               ; preds = %7
  %11 = load i32, ptr %4, align 4
  store i32 %11, ptr %6, align 4
  br label %12

12:                                               ; preds = %20, %10
  %13 = load i32, ptr %6, align 4
  %14 = icmp sgt i32 %13, 0
  br i1 %14, label %15, label %25

15:                                               ; preds = %12
  %16 = load i32, ptr %6, align 4
  %17 = load i32, ptr %3, align 4
  %18 = icmp eq i32 %16, %17
  br i1 %18, label %19, label %20

19:                                               ; preds = %15
  br label %25

20:                                               ; preds = %15
  %21 = load i32, ptr %6, align 4
  %22 = add nsw i32 %21, -1
  store i32 %22, ptr %6, align 4
  %23 = load i32, ptr %5, align 4
  %24 = add nsw i32 %23, 1
  store i32 %24, ptr %5, align 4
  br label %12, !llvm.loop !11

25:                                               ; preds = %19, %12
  %26 = load i32, ptr %3, align 4
  %27 = add nsw i32 %26, -1
  store i32 %27, ptr %3, align 4
  br label %7, !llvm.loop !12

28:                                               ; preds = %7
  %29 = load i32, ptr %5, align 4
  ret i32 %29
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
