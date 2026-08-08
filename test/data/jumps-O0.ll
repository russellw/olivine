; ModuleID = 'test/c/jumps.c'
source_filename = "test/c/jumps.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@thread_ops.ops = internal global [3 x ptr] [ptr blockaddress(@thread_ops, %24), ptr blockaddress(@thread_ops, %50), ptr blockaddress(@thread_ops, %70)], align 16

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

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @weight(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  %4 = load i32, ptr %3, align 4
  switch i32 %4, label %10 [
    i32 0, label %5
    i32 1, label %6
    i32 2, label %7
    i32 3, label %8
    i32 4, label %9
  ]

5:                                                ; preds = %1
  store i32 3, ptr %2, align 4
  br label %11

6:                                                ; preds = %1
  store i32 5, ptr %2, align 4
  br label %11

7:                                                ; preds = %1
  store i32 7, ptr %2, align 4
  br label %11

8:                                                ; preds = %1
  store i32 9, ptr %2, align 4
  br label %11

9:                                                ; preds = %1
  store i32 11, ptr %2, align 4
  br label %11

10:                                               ; preds = %1
  store i32 0, ptr %2, align 4
  br label %11

11:                                               ; preds = %10, %9, %8, %7, %6, %5
  %12 = load i32, ptr %2, align 4
  ret i32 %12
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @in_season(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  %4 = load i32, ptr %3, align 4
  switch i32 %4, label %6 [
    i32 3, label %5
    i32 4, label %5
    i32 5, label %5
    i32 6, label %5
  ]

5:                                                ; preds = %1, %1, %1, %1
  store i32 1, ptr %2, align 4
  br label %7

6:                                                ; preds = %1
  store i32 0, ptr %2, align 4
  br label %7

7:                                                ; preds = %6, %5
  %8 = load i32, ptr %2, align 4
  ret i32 %8
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @step_down(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  store i32 -1, ptr %3, align 4
  %4 = load i32, ptr %2, align 4
  switch i32 %4, label %9 [
    i32 10, label %5
    i32 11, label %6
    i32 12, label %7
    i32 13, label %8
  ]

5:                                                ; preds = %1
  store i32 40, ptr %3, align 4
  br label %9

6:                                                ; preds = %1
  store i32 30, ptr %3, align 4
  br label %9

7:                                                ; preds = %1
  store i32 20, ptr %3, align 4
  br label %9

8:                                                ; preds = %1
  store i32 10, ptr %3, align 4
  br label %9

9:                                                ; preds = %1, %8, %7, %6, %5
  %10 = load i32, ptr %3, align 4
  ret i32 %10
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @scattered(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  %4 = load i32, ptr %3, align 4
  switch i32 %4, label %9 [
    i32 0, label %5
    i32 1, label %6
    i32 2, label %7
    i32 3, label %8
  ]

5:                                                ; preds = %1
  store i32 4, ptr %2, align 4
  br label %10

6:                                                ; preds = %1
  store i32 9, ptr %2, align 4
  br label %10

7:                                                ; preds = %1
  store i32 2, ptr %2, align 4
  br label %10

8:                                                ; preds = %1
  store i32 7, ptr %2, align 4
  br label %10

9:                                                ; preds = %1
  store i32 -1, ptr %2, align 4
  br label %10

10:                                               ; preds = %9, %8, %7, %6, %5
  %11 = load i32, ptr %2, align 4
  ret i32 %11
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @sparse(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  %4 = load i32, ptr %3, align 4
  switch i32 %4, label %8 [
    i32 1, label %5
    i32 2, label %6
    i32 4, label %7
  ]

5:                                                ; preds = %1
  store i32 2, ptr %2, align 4
  br label %9

6:                                                ; preds = %1
  store i32 4, ptr %2, align 4
  br label %9

7:                                                ; preds = %1
  store i32 8, ptr %2, align 4
  br label %9

8:                                                ; preds = %1
  store i32 0, ptr %2, align 4
  br label %9

9:                                                ; preds = %8, %7, %6, %5
  %10 = load i32, ptr %2, align 4
  ret i32 %10
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @case_works(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store i32 %0, ptr %4, align 4
  store i32 %1, ptr %5, align 4
  %6 = load i32, ptr %4, align 4
  switch i32 %6, label %16 [
    i32 0, label %7
    i32 1, label %10
    i32 2, label %13
  ]

7:                                                ; preds = %2
  %8 = load i32, ptr %5, align 4
  %9 = add nsw i32 %8, 1
  store i32 %9, ptr %3, align 4
  br label %17

10:                                               ; preds = %2
  %11 = load i32, ptr %5, align 4
  %12 = add nsw i32 %11, 2
  store i32 %12, ptr %3, align 4
  br label %17

13:                                               ; preds = %2
  %14 = load i32, ptr %5, align 4
  %15 = add nsw i32 %14, 3
  store i32 %15, ptr %3, align 4
  br label %17

16:                                               ; preds = %2
  store i32 0, ptr %3, align 4
  br label %17

17:                                               ; preds = %16, %13, %10, %7
  %18 = load i32, ptr %3, align 4
  ret i32 %18
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @thread_ops(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  store i32 0, ptr %6, align 4
  store i32 0, ptr %7, align 4
  %8 = load i32, ptr %7, align 4
  %9 = load i32, ptr %5, align 4
  %10 = icmp sge i32 %8, %9
  br i1 %10, label %11, label %13

11:                                               ; preds = %2
  %12 = load i32, ptr %6, align 4
  store i32 %12, ptr %3, align 4
  br label %72

13:                                               ; preds = %2
  %14 = load ptr, ptr %4, align 8
  %15 = load i32, ptr %7, align 4
  %16 = sext i32 %15 to i64
  %17 = getelementptr inbounds i8, ptr %14, i64 %16
  %18 = load i8, ptr %17, align 1
  %19 = zext i8 %18 to i32
  %20 = srem i32 %19, 3
  %21 = sext i32 %20 to i64
  %22 = getelementptr inbounds [3 x ptr], ptr @thread_ops.ops, i64 0, i64 %21
  %23 = load ptr, ptr %22, align 8
  br label %74

24:                                               ; preds = %74
  %25 = load ptr, ptr %4, align 8
  %26 = load i32, ptr %7, align 4
  %27 = sext i32 %26 to i64
  %28 = getelementptr inbounds i8, ptr %25, i64 %27
  %29 = load i8, ptr %28, align 1
  %30 = zext i8 %29 to i32
  %31 = load i32, ptr %6, align 4
  %32 = add nsw i32 %31, %30
  store i32 %32, ptr %6, align 4
  %33 = load i32, ptr %7, align 4
  %34 = add nsw i32 %33, 1
  store i32 %34, ptr %7, align 4
  %35 = load i32, ptr %5, align 4
  %36 = icmp sge i32 %34, %35
  br i1 %36, label %37, label %39

37:                                               ; preds = %24
  %38 = load i32, ptr %6, align 4
  store i32 %38, ptr %3, align 4
  br label %72

39:                                               ; preds = %24
  %40 = load ptr, ptr %4, align 8
  %41 = load i32, ptr %7, align 4
  %42 = sext i32 %41 to i64
  %43 = getelementptr inbounds i8, ptr %40, i64 %42
  %44 = load i8, ptr %43, align 1
  %45 = zext i8 %44 to i32
  %46 = srem i32 %45, 3
  %47 = sext i32 %46 to i64
  %48 = getelementptr inbounds [3 x ptr], ptr @thread_ops.ops, i64 0, i64 %47
  %49 = load ptr, ptr %48, align 8
  br label %74

50:                                               ; preds = %74
  %51 = load i32, ptr %6, align 4
  %52 = mul nsw i32 %51, 2
  store i32 %52, ptr %6, align 4
  %53 = load i32, ptr %7, align 4
  %54 = add nsw i32 %53, 1
  store i32 %54, ptr %7, align 4
  %55 = load i32, ptr %5, align 4
  %56 = icmp sge i32 %54, %55
  br i1 %56, label %57, label %59

57:                                               ; preds = %50
  %58 = load i32, ptr %6, align 4
  store i32 %58, ptr %3, align 4
  br label %72

59:                                               ; preds = %50
  %60 = load ptr, ptr %4, align 8
  %61 = load i32, ptr %7, align 4
  %62 = sext i32 %61 to i64
  %63 = getelementptr inbounds i8, ptr %60, i64 %62
  %64 = load i8, ptr %63, align 1
  %65 = zext i8 %64 to i32
  %66 = srem i32 %65, 3
  %67 = sext i32 %66 to i64
  %68 = getelementptr inbounds [3 x ptr], ptr @thread_ops.ops, i64 0, i64 %67
  %69 = load ptr, ptr %68, align 8
  br label %74

70:                                               ; preds = %74
  %71 = load i32, ptr %6, align 4
  store i32 %71, ptr %3, align 4
  br label %72

72:                                               ; preds = %70, %57, %37, %11
  %73 = load i32, ptr %3, align 4
  ret i32 %73

74:                                               ; preds = %59, %39, %13
  %75 = phi ptr [ %23, %13 ], [ %49, %39 ], [ %69, %59 ]
  indirectbr ptr %75, [label %24, label %50, label %70]
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @jump_over(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %5 = load i32, ptr %2, align 4
  %6 = icmp sgt i32 %5, 0
  %7 = zext i1 %6 to i64
  %8 = select i1 %6, ptr blockaddress(@jump_over, %10), ptr blockaddress(@jump_over, %11)
  store ptr %8, ptr %3, align 8
  store i32 0, ptr %4, align 4
  %9 = load ptr, ptr %3, align 8
  br label %14

10:                                               ; preds = %14
  store i32 1, ptr %4, align 4
  br label %12

11:                                               ; preds = %14
  store i32 -1, ptr %4, align 4
  br label %12

12:                                               ; preds = %11, %10
  %13 = load i32, ptr %4, align 4
  ret i32 %13

14:                                               ; preds = %1
  %15 = phi ptr [ %9, %1 ]
  indirectbr ptr %15, [label %10, label %11]
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
