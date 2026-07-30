; ModuleID = 'test/c/atomics.c'
source_filename = "test/c/atomics.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @fetched(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %9 = load i32, ptr %4, align 4
  %10 = mul nsw i32 %9, 2
  %11 = add nsw i32 %10, 1
  store i32 %11, ptr %5, align 4
  %12 = load ptr, ptr %3, align 8
  %13 = load i32, ptr %5, align 4
  store i32 %13, ptr %7, align 4
  %14 = load i32, ptr %7, align 4
  %15 = atomicrmw add ptr %12, i32 %14 seq_cst, align 4
  store i32 %15, ptr %8, align 4
  %16 = load i32, ptr %8, align 4
  store i32 %16, ptr %6, align 4
  %17 = load i32, ptr %6, align 4
  %18 = mul nsw i32 %17, 3
  %19 = load i32, ptr %5, align 4
  %20 = add nsw i32 %18, %19
  ret i32 %20
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @raised_to(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i8, align 1
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  %10 = load ptr, ptr %4, align 8
  %11 = load atomic i32, ptr %10 seq_cst, align 4
  store i32 %11, ptr %7, align 4
  %12 = load i32, ptr %7, align 4
  store i32 %12, ptr %6, align 4
  br label %13

13:                                               ; preds = %31, %2
  %14 = load i32, ptr %6, align 4
  %15 = load i32, ptr %5, align 4
  %16 = icmp slt i32 %14, %15
  br i1 %16, label %17, label %32

17:                                               ; preds = %13
  %18 = load ptr, ptr %4, align 8
  %19 = load i32, ptr %5, align 4
  store i32 %19, ptr %8, align 4
  %20 = load i32, ptr %6, align 4
  %21 = load i32, ptr %8, align 4
  %22 = cmpxchg weak ptr %18, i32 %20, i32 %21 seq_cst seq_cst, align 4
  %23 = extractvalue { i32, i1 } %22, 0
  %24 = extractvalue { i32, i1 } %22, 1
  br i1 %24, label %26, label %25

25:                                               ; preds = %17
  store i32 %23, ptr %6, align 4
  br label %26

26:                                               ; preds = %25, %17
  %27 = zext i1 %24 to i8
  store i8 %27, ptr %9, align 1
  %28 = load i8, ptr %9, align 1
  %29 = trunc i8 %28 to i1
  br i1 %29, label %30, label %31

30:                                               ; preds = %26
  store i32 1, ptr %3, align 4
  br label %33

31:                                               ; preds = %26
  br label %13, !llvm.loop !6

32:                                               ; preds = %13
  store i32 0, ptr %3, align 4
  br label %33

33:                                               ; preds = %32, %30
  %34 = load i32, ptr %3, align 4
  ret i32 %34
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @weighted(ptr noundef %0, ptr noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store ptr %1, ptr %5, align 8
  store i32 %2, ptr %6, align 4
  store i32 0, ptr %7, align 4
  store i32 0, ptr %8, align 4
  br label %11

11:                                               ; preds = %28, %3
  %12 = load i32, ptr %8, align 4
  %13 = load i32, ptr %6, align 4
  %14 = icmp slt i32 %12, %13
  br i1 %14, label %15, label %31

15:                                               ; preds = %11
  %16 = load ptr, ptr %4, align 8
  %17 = load atomic i32, ptr %16 monotonic, align 4
  store i32 %17, ptr %10, align 4
  %18 = load i32, ptr %10, align 4
  store i32 %18, ptr %9, align 4
  %19 = load ptr, ptr %5, align 8
  %20 = load i32, ptr %8, align 4
  %21 = sext i32 %20 to i64
  %22 = getelementptr inbounds i32, ptr %19, i64 %21
  %23 = load i32, ptr %22, align 4
  %24 = load i32, ptr %9, align 4
  %25 = mul nsw i32 %23, %24
  %26 = load i32, ptr %7, align 4
  %27 = add nsw i32 %26, %25
  store i32 %27, ptr %7, align 4
  br label %28

28:                                               ; preds = %15
  %29 = load i32, ptr %8, align 4
  %30 = add nsw i32 %29, 1
  store i32 %30, ptr %8, align 4
  br label %11, !llvm.loop !8

31:                                               ; preds = %11
  %32 = load i32, ptr %7, align 4
  ret i32 %32
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @fenced(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  %7 = load i32, ptr %3, align 4
  %8 = load i32, ptr %3, align 4
  %9 = mul nsw i32 %7, %8
  %10 = load i32, ptr %4, align 4
  %11 = add nsw i32 %9, %10
  store i32 %11, ptr %5, align 4
  fence seq_cst
  %12 = load i32, ptr %4, align 4
  %13 = load i32, ptr %4, align 4
  %14 = mul nsw i32 %12, %13
  %15 = load i32, ptr %3, align 4
  %16 = add nsw i32 %14, %15
  store i32 %16, ptr %6, align 4
  %17 = load i32, ptr %5, align 4
  %18 = load i32, ptr %6, align 4
  %19 = add nsw i32 %17, %18
  ret i32 %19
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @published(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %7 = load i32, ptr %4, align 4
  store i32 %7, ptr %5, align 4
  %8 = load i32, ptr %5, align 4
  %9 = load i32, ptr %5, align 4
  %10 = add nsw i32 %8, %9
  store i32 %10, ptr %5, align 4
  %11 = load ptr, ptr %3, align 8
  %12 = load i32, ptr %5, align 4
  store i32 %12, ptr %6, align 4
  %13 = load i32, ptr %6, align 4
  store atomic i32 %13, ptr %11 seq_cst, align 4
  %14 = load i32, ptr %5, align 4
  ret i32 %14
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
