; ModuleID = 'test/c/effects.c'
source_filename = "test/c/effects.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@watched = internal global i32 0, align 4
@held = internal global [8 x i32] zeroinitializer, align 16
@spare = internal global [8 x i32] zeroinitializer, align 16
@written_total = dso_local global i32 0, align 4

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @twice_over(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  %5 = load i32, ptr %3, align 4
  %6 = load i32, ptr %4, align 4
  %7 = call i32 @mixed(i32 noundef %5, i32 noundef %6)
  %8 = load i32, ptr %3, align 4
  %9 = load i32, ptr %4, align 4
  %10 = call i32 @mixed(i32 noundef %8, i32 noundef %9)
  %11 = add nsw i32 %7, %10
  ret i32 %11
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @mixed(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca [4 x i32], align 16
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  %6 = load i32, ptr %3, align 4
  %7 = load i32, ptr %4, align 4
  %8 = add nsw i32 %6, %7
  %9 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 0
  store i32 %8, ptr %9, align 16
  %10 = load i32, ptr %3, align 4
  %11 = load i32, ptr %4, align 4
  %12 = xor i32 %10, %11
  %13 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 1
  store i32 %12, ptr %13, align 4
  %14 = load i32, ptr %3, align 4
  %15 = mul nsw i32 %14, 3
  %16 = load i32, ptr %4, align 4
  %17 = sub nsw i32 %15, %16
  %18 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 2
  store i32 %17, ptr %18, align 8
  %19 = load i32, ptr %3, align 4
  %20 = shl i32 %19, 2
  %21 = load i32, ptr %4, align 4
  %22 = ashr i32 %21, 1
  %23 = add nsw i32 %20, %22
  %24 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 3
  store i32 %23, ptr %24, align 4
  %25 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 0
  %26 = load i32, ptr %25, align 16
  %27 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 1
  %28 = load i32, ptr %27, align 4
  %29 = mul nsw i32 %28, 2
  %30 = add nsw i32 %26, %29
  %31 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 2
  %32 = load i32, ptr %31, align 8
  %33 = add nsw i32 %30, %32
  %34 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 3
  %35 = load i32, ptr %34, align 4
  %36 = sub nsw i32 %33, %35
  ret i32 %36
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @across_call(ptr noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %4, align 8
  store i32 %1, ptr %5, align 4
  store i32 %2, ptr %6, align 4
  %9 = load ptr, ptr %4, align 8
  %10 = load i32, ptr %9, align 4
  store i32 %10, ptr %7, align 4
  %11 = load i32, ptr %5, align 4
  %12 = load i32, ptr %6, align 4
  %13 = call i32 @mixed(i32 noundef %11, i32 noundef %12)
  store i32 %13, ptr %8, align 4
  %14 = load i32, ptr %7, align 4
  %15 = load ptr, ptr %4, align 8
  %16 = load i32, ptr %15, align 4
  %17 = add nsw i32 %14, %16
  %18 = load i32, ptr %8, align 4
  %19 = add nsw i32 %17, %18
  ret i32 %19
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @in_loop(ptr noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) #0 {
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store ptr %0, ptr %5, align 8
  store i32 %1, ptr %6, align 4
  store i32 %2, ptr %7, align 4
  store i32 %3, ptr %8, align 4
  store i32 0, ptr %9, align 4
  store i32 0, ptr %10, align 4
  br label %11

11:                                               ; preds = %27, %4
  %12 = load i32, ptr %10, align 4
  %13 = load i32, ptr %6, align 4
  %14 = icmp slt i32 %12, %13
  br i1 %14, label %15, label %30

15:                                               ; preds = %11
  %16 = load ptr, ptr %5, align 8
  %17 = load i32, ptr %10, align 4
  %18 = sext i32 %17 to i64
  %19 = getelementptr inbounds i32, ptr %16, i64 %18
  %20 = load i32, ptr %19, align 4
  %21 = load i32, ptr %7, align 4
  %22 = load i32, ptr %8, align 4
  %23 = call i32 @mixed(i32 noundef %21, i32 noundef %22)
  %24 = add nsw i32 %20, %23
  %25 = load i32, ptr %9, align 4
  %26 = add nsw i32 %25, %24
  store i32 %26, ptr %9, align 4
  br label %27

27:                                               ; preds = %15
  %28 = load i32, ptr %10, align 4
  %29 = add nsw i32 %28, 1
  store i32 %29, ptr %10, align 4
  br label %11, !llvm.loop !6

30:                                               ; preds = %11
  %31 = load i32, ptr %9, align 4
  ret i32 %31
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @unused_result(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  %5 = load i32, ptr %3, align 4
  %6 = load i32, ptr %4, align 4
  %7 = call i32 @mixed(i32 noundef %5, i32 noundef %6)
  %8 = load i32, ptr %3, align 4
  %9 = load i32, ptr %4, align 4
  %10 = add nsw i32 %8, %9
  ret i32 %10
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @writer_twice(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %3 = load i32, ptr %2, align 4
  %4 = call i32 @record(i32 noundef %3)
  %5 = load i32, ptr %2, align 4
  %6 = call i32 @record(i32 noundef %5)
  %7 = add nsw i32 %4, %6
  ret i32 %7
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @record(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %3 = load i32, ptr %2, align 4
  %4 = load i32, ptr @written_total, align 4
  %5 = add nsw i32 %4, %3
  store i32 %5, ptr @written_total, align 4
  %6 = load i32, ptr @written_total, align 4
  ret i32 %6
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @across_writer(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %6 = load ptr, ptr %3, align 8
  %7 = load i32, ptr %6, align 4
  store i32 %7, ptr %5, align 4
  %8 = load i32, ptr %4, align 4
  %9 = call i32 @record(i32 noundef %8)
  %10 = load i32, ptr %5, align 4
  %11 = load ptr, ptr %3, align 8
  %12 = load i32, ptr %11, align 4
  %13 = add nsw i32 %10, %12
  ret i32 %13
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @unused_writer(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %3 = load i32, ptr %2, align 4
  %4 = call i32 @record(i32 noundef %3)
  %5 = load i32, ptr %2, align 4
  ret i32 %5
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @reader_twice(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = call i32 @first_two(ptr noundef %3)
  %5 = load ptr, ptr %2, align 8
  %6 = call i32 @first_two(ptr noundef %5)
  %7 = add nsw i32 %4, %6
  ret i32 %7
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @first_two(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = getelementptr inbounds i32, ptr %3, i64 0
  %5 = load i32, ptr %4, align 4
  %6 = load ptr, ptr %2, align 8
  %7 = getelementptr inbounds i32, ptr %6, i64 1
  %8 = load i32, ptr %7, align 4
  %9 = add nsw i32 %5, %8
  ret i32 %9
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @reader_across_write(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  %6 = load ptr, ptr %3, align 8
  %7 = call i32 @first_two(ptr noundef %6)
  store i32 %7, ptr %5, align 4
  %8 = load i32, ptr %4, align 4
  %9 = load ptr, ptr %3, align 8
  store i32 %8, ptr %9, align 4
  %10 = load i32, ptr %5, align 4
  %11 = load ptr, ptr %3, align 8
  %12 = call i32 @first_two(ptr noundef %11)
  %13 = add nsw i32 %10, %12
  ret i32 %13
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @unused_loop(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  %5 = load i32, ptr %3, align 4
  %6 = load i32, ptr %4, align 4
  %7 = call i32 @weigh(i32 noundef %5, i32 noundef %6)
  %8 = load i32, ptr %3, align 4
  %9 = load i32, ptr %4, align 4
  %10 = add nsw i32 %8, %9
  ret i32 %10
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @weigh(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  store i32 0, ptr %5, align 4
  store i32 0, ptr %6, align 4
  br label %7

7:                                                ; preds = %21, %2
  %8 = load i32, ptr %6, align 4
  %9 = icmp slt i32 %8, 8
  br i1 %9, label %10, label %24

10:                                               ; preds = %7
  %11 = load i32, ptr %3, align 4
  %12 = load i32, ptr %4, align 4
  %13 = load i32, ptr %6, align 4
  %14 = add nsw i32 %12, %13
  %15 = xor i32 %11, %14
  %16 = load i32, ptr %6, align 4
  %17 = add nsw i32 %16, 3
  %18 = mul nsw i32 %15, %17
  %19 = load i32, ptr %5, align 4
  %20 = add nsw i32 %19, %18
  store i32 %20, ptr %5, align 4
  br label %21

21:                                               ; preds = %10
  %22 = load i32, ptr %6, align 4
  %23 = add nsw i32 %22, 1
  store i32 %23, ptr %6, align 4
  br label %7, !llvm.loop !8

24:                                               ; preds = %7
  %25 = load i32, ptr %5, align 4
  ret i32 %25
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @loop_of_loops(i32 noundef %0, i32 noundef %1, i32 noundef %2) #0 {
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
  %11 = load i32, ptr %4, align 4
  %12 = icmp slt i32 %10, %11
  br i1 %12, label %13, label %22

13:                                               ; preds = %9
  %14 = load i32, ptr %5, align 4
  %15 = load i32, ptr %6, align 4
  %16 = call i32 @weigh(i32 noundef %14, i32 noundef %15)
  %17 = load i32, ptr %7, align 4
  %18 = add nsw i32 %17, %16
  store i32 %18, ptr %7, align 4
  br label %19

19:                                               ; preds = %13
  %20 = load i32, ptr %8, align 4
  %21 = add nsw i32 %20, 1
  store i32 %21, ptr %8, align 4
  br label %9, !llvm.loop !9

22:                                               ; preds = %9
  %23 = load i32, ptr %7, align 4
  ret i32 %23
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @unused_spin(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %3 = load i32, ptr %2, align 4
  %4 = call i32 @settle(i32 noundef %3)
  %5 = load i32, ptr %2, align 4
  ret i32 %5
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @settle(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  store i32 0, ptr %3, align 4
  br label %4

4:                                                ; preds = %12, %1
  %5 = load i32, ptr %2, align 4
  %6 = load i32, ptr %3, align 4
  %7 = add nsw i32 %6, %5
  store i32 %7, ptr %3, align 4
  %8 = load i32, ptr %3, align 4
  %9 = icmp sgt i32 %8, 100
  br i1 %9, label %10, label %12

10:                                               ; preds = %4
  %11 = load i32, ptr %3, align 4
  ret i32 %11

12:                                               ; preds = %4
  br label %4
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @loop_of_spins(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  store i32 %1, ptr %4, align 4
  store i32 0, ptr %5, align 4
  store i32 0, ptr %6, align 4
  br label %7

7:                                                ; preds = %16, %2
  %8 = load i32, ptr %6, align 4
  %9 = load i32, ptr %3, align 4
  %10 = icmp slt i32 %8, %9
  br i1 %10, label %11, label %19

11:                                               ; preds = %7
  %12 = load i32, ptr %4, align 4
  %13 = call i32 @settle(i32 noundef %12)
  %14 = load i32, ptr %5, align 4
  %15 = add nsw i32 %14, %13
  store i32 %15, ptr %5, align 4
  br label %16

16:                                               ; preds = %11
  %17 = load i32, ptr %6, align 4
  %18 = add nsw i32 %17, 1
  store i32 %18, ptr %6, align 4
  br label %7, !llvm.loop !10

19:                                               ; preds = %7
  %20 = load i32, ptr %5, align 4
  ret i32 %20
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @unused_recursion(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %3 = load i32, ptr %2, align 4
  %4 = call i32 @chain(i32 noundef %3)
  %5 = load i32, ptr %2, align 4
  ret i32 %5
}

; Function Attrs: noinline nounwind optnone uwtable
define internal i32 @chain(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %3 = load i32, ptr %2, align 4
  %4 = icmp sle i32 %3, 0
  br i1 %4, label %5, label %6

5:                                                ; preds = %1
  br label %12

6:                                                ; preds = %1
  %7 = load i32, ptr %2, align 4
  %8 = load i32, ptr %2, align 4
  %9 = sub nsw i32 %8, 1
  %10 = call i32 @chain(i32 noundef %9)
  %11 = add nsw i32 %7, %10
  br label %12

12:                                               ; preds = %6, %5
  %13 = phi i32 [ 0, %5 ], [ %11, %6 ]
  ret i32 %13
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @seen_across_copy() #0 {
  %1 = alloca i32, align 4
  %2 = load i32, ptr @watched, align 4
  store i32 %2, ptr %1, align 4
  call void @llvm.memcpy.p0.p0.i64(ptr align 16 @held, ptr align 16 @spare, i64 32, i1 false)
  %3 = load i32, ptr %1, align 4
  %4 = load i32, ptr @watched, align 4
  %5 = add nsw i32 %3, %4
  ret i32 %5
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @seen_across_set() #0 {
  %1 = alloca i32, align 4
  %2 = load i32, ptr @watched, align 4
  store i32 %2, ptr %1, align 4
  call void @llvm.memset.p0.i64(ptr align 16 @held, i8 0, i64 32, i1 false)
  %3 = load i32, ptr %1, align 4
  %4 = load i32, ptr @watched, align 4
  %5 = add nsw i32 %3, %4
  ret i32 %5
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #2

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @copied_into() #0 {
  %1 = alloca i32, align 4
  %2 = load i32, ptr @held, align 16
  store i32 %2, ptr %1, align 4
  call void @llvm.memcpy.p0.p0.i64(ptr align 16 @held, ptr align 16 @spare, i64 32, i1 false)
  %3 = load i32, ptr %1, align 4
  %4 = load i32, ptr @held, align 16
  %5 = add nsw i32 %3, %4
  ret i32 %5
}

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nocallback nofree nounwind willreturn memory(argmem: write) }

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
