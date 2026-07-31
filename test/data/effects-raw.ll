; ModuleID = 'test/c/effects.c'
source_filename = "test/c/effects.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@written_total = dso_local global i32 0, align 4

; Function Attrs: nounwind uwtable
define dso_local i32 @twice_over(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  %5 = load i32, ptr %3, align 4, !tbaa !5
  %6 = load i32, ptr %4, align 4, !tbaa !5
  %7 = call i32 @mixed(i32 noundef %5, i32 noundef %6)
  %8 = load i32, ptr %3, align 4, !tbaa !5
  %9 = load i32, ptr %4, align 4, !tbaa !5
  %10 = call i32 @mixed(i32 noundef %8, i32 noundef %9)
  %11 = add nsw i32 %7, %10
  ret i32 %11
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @mixed(i32 noundef %0, i32 noundef %1) #1 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca [4 x i32], align 16
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 16, ptr %5) #3
  %6 = load i32, ptr %3, align 4, !tbaa !5
  %7 = load i32, ptr %4, align 4, !tbaa !5
  %8 = add nsw i32 %6, %7
  %9 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 0
  store i32 %8, ptr %9, align 16, !tbaa !5
  %10 = load i32, ptr %3, align 4, !tbaa !5
  %11 = load i32, ptr %4, align 4, !tbaa !5
  %12 = xor i32 %10, %11
  %13 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 1
  store i32 %12, ptr %13, align 4, !tbaa !5
  %14 = load i32, ptr %3, align 4, !tbaa !5
  %15 = mul nsw i32 %14, 3
  %16 = load i32, ptr %4, align 4, !tbaa !5
  %17 = sub nsw i32 %15, %16
  %18 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 2
  store i32 %17, ptr %18, align 8, !tbaa !5
  %19 = load i32, ptr %3, align 4, !tbaa !5
  %20 = shl i32 %19, 2
  %21 = load i32, ptr %4, align 4, !tbaa !5
  %22 = ashr i32 %21, 1
  %23 = add nsw i32 %20, %22
  %24 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 3
  store i32 %23, ptr %24, align 4, !tbaa !5
  %25 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 0
  %26 = load i32, ptr %25, align 16, !tbaa !5
  %27 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 1
  %28 = load i32, ptr %27, align 4, !tbaa !5
  %29 = mul nsw i32 %28, 2
  %30 = add nsw i32 %26, %29
  %31 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 2
  %32 = load i32, ptr %31, align 8, !tbaa !5
  %33 = add nsw i32 %30, %32
  %34 = getelementptr inbounds [4 x i32], ptr %5, i64 0, i64 3
  %35 = load i32, ptr %34, align 4, !tbaa !5
  %36 = sub nsw i32 %33, %35
  call void @llvm.lifetime.end.p0(i64 16, ptr %5) #3
  ret i32 %36
}

; Function Attrs: nounwind uwtable
define dso_local i32 @across_call(ptr noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %4, align 8, !tbaa !9
  store i32 %1, ptr %5, align 4, !tbaa !5
  store i32 %2, ptr %6, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #3
  %9 = load ptr, ptr %4, align 8, !tbaa !9
  %10 = load i32, ptr %9, align 4, !tbaa !5
  store i32 %10, ptr %7, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %8) #3
  %11 = load i32, ptr %5, align 4, !tbaa !5
  %12 = load i32, ptr %6, align 4, !tbaa !5
  %13 = call i32 @mixed(i32 noundef %11, i32 noundef %12)
  store i32 %13, ptr %8, align 4, !tbaa !5
  %14 = load i32, ptr %7, align 4, !tbaa !5
  %15 = load ptr, ptr %4, align 8, !tbaa !9
  %16 = load i32, ptr %15, align 4, !tbaa !5
  %17 = add nsw i32 %14, %16
  %18 = load i32, ptr %8, align 4, !tbaa !5
  %19 = add nsw i32 %17, %18
  call void @llvm.lifetime.end.p0(i64 4, ptr %8) #3
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #3
  ret i32 %19
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #2

; Function Attrs: nounwind uwtable
define dso_local i32 @in_loop(ptr noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) #0 {
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store ptr %0, ptr %5, align 8, !tbaa !9
  store i32 %1, ptr %6, align 4, !tbaa !5
  store i32 %2, ptr %7, align 4, !tbaa !5
  store i32 %3, ptr %8, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %9) #3
  store i32 0, ptr %9, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %10) #3
  store i32 0, ptr %10, align 4, !tbaa !5
  br label %11

11:                                               ; preds = %28, %4
  %12 = load i32, ptr %10, align 4, !tbaa !5
  %13 = load i32, ptr %6, align 4, !tbaa !5
  %14 = icmp slt i32 %12, %13
  br i1 %14, label %16, label %15

15:                                               ; preds = %11
  call void @llvm.lifetime.end.p0(i64 4, ptr %10) #3
  br label %31

16:                                               ; preds = %11
  %17 = load ptr, ptr %5, align 8, !tbaa !9
  %18 = load i32, ptr %10, align 4, !tbaa !5
  %19 = sext i32 %18 to i64
  %20 = getelementptr inbounds i32, ptr %17, i64 %19
  %21 = load i32, ptr %20, align 4, !tbaa !5
  %22 = load i32, ptr %7, align 4, !tbaa !5
  %23 = load i32, ptr %8, align 4, !tbaa !5
  %24 = call i32 @mixed(i32 noundef %22, i32 noundef %23)
  %25 = add nsw i32 %21, %24
  %26 = load i32, ptr %9, align 4, !tbaa !5
  %27 = add nsw i32 %26, %25
  store i32 %27, ptr %9, align 4, !tbaa !5
  br label %28

28:                                               ; preds = %16
  %29 = load i32, ptr %10, align 4, !tbaa !5
  %30 = add nsw i32 %29, 1
  store i32 %30, ptr %10, align 4, !tbaa !5
  br label %11, !llvm.loop !12

31:                                               ; preds = %15
  %32 = load i32, ptr %9, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %9) #3
  ret i32 %32
}

; Function Attrs: nounwind uwtable
define dso_local i32 @unused_result(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  %5 = load i32, ptr %3, align 4, !tbaa !5
  %6 = load i32, ptr %4, align 4, !tbaa !5
  %7 = call i32 @mixed(i32 noundef %5, i32 noundef %6)
  %8 = load i32, ptr %3, align 4, !tbaa !5
  %9 = load i32, ptr %4, align 4, !tbaa !5
  %10 = add nsw i32 %8, %9
  ret i32 %10
}

; Function Attrs: nounwind uwtable
define dso_local i32 @writer_twice(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  %3 = load i32, ptr %2, align 4, !tbaa !5
  %4 = call i32 @record(i32 noundef %3)
  %5 = load i32, ptr %2, align 4, !tbaa !5
  %6 = call i32 @record(i32 noundef %5)
  %7 = add nsw i32 %4, %6
  ret i32 %7
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @record(i32 noundef %0) #1 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  %3 = load i32, ptr %2, align 4, !tbaa !5
  %4 = load i32, ptr @written_total, align 4, !tbaa !5
  %5 = add nsw i32 %4, %3
  store i32 %5, ptr @written_total, align 4, !tbaa !5
  %6 = load i32, ptr @written_total, align 4, !tbaa !5
  ret i32 %6
}

; Function Attrs: nounwind uwtable
define dso_local i32 @across_writer(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !9
  store i32 %1, ptr %4, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #3
  %6 = load ptr, ptr %3, align 8, !tbaa !9
  %7 = load i32, ptr %6, align 4, !tbaa !5
  store i32 %7, ptr %5, align 4, !tbaa !5
  %8 = load i32, ptr %4, align 4, !tbaa !5
  %9 = call i32 @record(i32 noundef %8)
  %10 = load i32, ptr %5, align 4, !tbaa !5
  %11 = load ptr, ptr %3, align 8, !tbaa !9
  %12 = load i32, ptr %11, align 4, !tbaa !5
  %13 = add nsw i32 %10, %12
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #3
  ret i32 %13
}

; Function Attrs: nounwind uwtable
define dso_local i32 @unused_writer(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  %3 = load i32, ptr %2, align 4, !tbaa !5
  %4 = call i32 @record(i32 noundef %3)
  %5 = load i32, ptr %2, align 4, !tbaa !5
  ret i32 %5
}

; Function Attrs: nounwind uwtable
define dso_local i32 @reader_twice(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8, !tbaa !9
  %3 = load ptr, ptr %2, align 8, !tbaa !9
  %4 = call i32 @first_two(ptr noundef %3)
  %5 = load ptr, ptr %2, align 8, !tbaa !9
  %6 = call i32 @first_two(ptr noundef %5)
  %7 = add nsw i32 %4, %6
  ret i32 %7
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @first_two(ptr noundef %0) #1 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8, !tbaa !9
  %3 = load ptr, ptr %2, align 8, !tbaa !9
  %4 = getelementptr inbounds i32, ptr %3, i64 0
  %5 = load i32, ptr %4, align 4, !tbaa !5
  %6 = load ptr, ptr %2, align 8, !tbaa !9
  %7 = getelementptr inbounds i32, ptr %6, i64 1
  %8 = load i32, ptr %7, align 4, !tbaa !5
  %9 = add nsw i32 %5, %8
  ret i32 %9
}

; Function Attrs: nounwind uwtable
define dso_local i32 @reader_across_write(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !9
  store i32 %1, ptr %4, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #3
  %6 = load ptr, ptr %3, align 8, !tbaa !9
  %7 = call i32 @first_two(ptr noundef %6)
  store i32 %7, ptr %5, align 4, !tbaa !5
  %8 = load i32, ptr %4, align 4, !tbaa !5
  %9 = load ptr, ptr %3, align 8, !tbaa !9
  store i32 %8, ptr %9, align 4, !tbaa !5
  %10 = load i32, ptr %5, align 4, !tbaa !5
  %11 = load ptr, ptr %3, align 8, !tbaa !9
  %12 = call i32 @first_two(ptr noundef %11)
  %13 = add nsw i32 %10, %12
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #3
  ret i32 %13
}

; Function Attrs: nounwind uwtable
define dso_local i32 @unused_loop(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  %5 = load i32, ptr %3, align 4, !tbaa !5
  %6 = load i32, ptr %4, align 4, !tbaa !5
  %7 = call i32 @weigh(i32 noundef %5, i32 noundef %6)
  %8 = load i32, ptr %3, align 4, !tbaa !5
  %9 = load i32, ptr %4, align 4, !tbaa !5
  %10 = add nsw i32 %8, %9
  ret i32 %10
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @weigh(i32 noundef %0, i32 noundef %1) #1 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #3
  store i32 0, ptr %5, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #3
  store i32 0, ptr %6, align 4, !tbaa !5
  br label %7

7:                                                ; preds = %22, %2
  %8 = load i32, ptr %6, align 4, !tbaa !5
  %9 = icmp slt i32 %8, 8
  br i1 %9, label %11, label %10

10:                                               ; preds = %7
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #3
  br label %25

11:                                               ; preds = %7
  %12 = load i32, ptr %3, align 4, !tbaa !5
  %13 = load i32, ptr %4, align 4, !tbaa !5
  %14 = load i32, ptr %6, align 4, !tbaa !5
  %15 = add nsw i32 %13, %14
  %16 = xor i32 %12, %15
  %17 = load i32, ptr %6, align 4, !tbaa !5
  %18 = add nsw i32 %17, 3
  %19 = mul nsw i32 %16, %18
  %20 = load i32, ptr %5, align 4, !tbaa !5
  %21 = add nsw i32 %20, %19
  store i32 %21, ptr %5, align 4, !tbaa !5
  br label %22

22:                                               ; preds = %11
  %23 = load i32, ptr %6, align 4, !tbaa !5
  %24 = add nsw i32 %23, 1
  store i32 %24, ptr %6, align 4, !tbaa !5
  br label %7, !llvm.loop !15

25:                                               ; preds = %10
  %26 = load i32, ptr %5, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #3
  ret i32 %26
}

; Function Attrs: nounwind uwtable
define dso_local i32 @loop_of_loops(i32 noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store i32 %0, ptr %4, align 4, !tbaa !5
  store i32 %1, ptr %5, align 4, !tbaa !5
  store i32 %2, ptr %6, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #3
  store i32 0, ptr %7, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %8) #3
  store i32 0, ptr %8, align 4, !tbaa !5
  br label %9

9:                                                ; preds = %20, %3
  %10 = load i32, ptr %8, align 4, !tbaa !5
  %11 = load i32, ptr %4, align 4, !tbaa !5
  %12 = icmp slt i32 %10, %11
  br i1 %12, label %14, label %13

13:                                               ; preds = %9
  call void @llvm.lifetime.end.p0(i64 4, ptr %8) #3
  br label %23

14:                                               ; preds = %9
  %15 = load i32, ptr %5, align 4, !tbaa !5
  %16 = load i32, ptr %6, align 4, !tbaa !5
  %17 = call i32 @weigh(i32 noundef %15, i32 noundef %16)
  %18 = load i32, ptr %7, align 4, !tbaa !5
  %19 = add nsw i32 %18, %17
  store i32 %19, ptr %7, align 4, !tbaa !5
  br label %20

20:                                               ; preds = %14
  %21 = load i32, ptr %8, align 4, !tbaa !5
  %22 = add nsw i32 %21, 1
  store i32 %22, ptr %8, align 4, !tbaa !5
  br label %9, !llvm.loop !16

23:                                               ; preds = %13
  %24 = load i32, ptr %7, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #3
  ret i32 %24
}

; Function Attrs: nounwind uwtable
define dso_local i32 @unused_spin(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  %3 = load i32, ptr %2, align 4, !tbaa !5
  %4 = call i32 @settle(i32 noundef %3)
  %5 = load i32, ptr %2, align 4, !tbaa !5
  ret i32 %5
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @settle(i32 noundef %0) #1 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #3
  store i32 0, ptr %3, align 4, !tbaa !5
  br label %4

4:                                                ; preds = %12, %1
  %5 = load i32, ptr %2, align 4, !tbaa !5
  %6 = load i32, ptr %3, align 4, !tbaa !5
  %7 = add nsw i32 %6, %5
  store i32 %7, ptr %3, align 4, !tbaa !5
  %8 = load i32, ptr %3, align 4, !tbaa !5
  %9 = icmp sgt i32 %8, 100
  br i1 %9, label %10, label %12

10:                                               ; preds = %4
  %11 = load i32, ptr %3, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #3
  ret i32 %11

12:                                               ; preds = %4
  br label %4, !llvm.loop !17
}

; Function Attrs: nounwind uwtable
define dso_local i32 @loop_of_spins(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #3
  store i32 0, ptr %5, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #3
  store i32 0, ptr %6, align 4, !tbaa !5
  br label %7

7:                                                ; preds = %17, %2
  %8 = load i32, ptr %6, align 4, !tbaa !5
  %9 = load i32, ptr %3, align 4, !tbaa !5
  %10 = icmp slt i32 %8, %9
  br i1 %10, label %12, label %11

11:                                               ; preds = %7
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #3
  br label %20

12:                                               ; preds = %7
  %13 = load i32, ptr %4, align 4, !tbaa !5
  %14 = call i32 @settle(i32 noundef %13)
  %15 = load i32, ptr %5, align 4, !tbaa !5
  %16 = add nsw i32 %15, %14
  store i32 %16, ptr %5, align 4, !tbaa !5
  br label %17

17:                                               ; preds = %12
  %18 = load i32, ptr %6, align 4, !tbaa !5
  %19 = add nsw i32 %18, 1
  store i32 %19, ptr %6, align 4, !tbaa !5
  br label %7, !llvm.loop !18

20:                                               ; preds = %11
  %21 = load i32, ptr %5, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #3
  ret i32 %21
}

; Function Attrs: nounwind uwtable
define dso_local i32 @unused_recursion(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  %3 = load i32, ptr %2, align 4, !tbaa !5
  %4 = call i32 @chain(i32 noundef %3)
  %5 = load i32, ptr %2, align 4, !tbaa !5
  ret i32 %5
}

; Function Attrs: noinline nounwind uwtable
define internal i32 @chain(i32 noundef %0) #1 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  %3 = load i32, ptr %2, align 4, !tbaa !5
  %4 = icmp sle i32 %3, 0
  br i1 %4, label %5, label %6

5:                                                ; preds = %1
  br label %12

6:                                                ; preds = %1
  %7 = load i32, ptr %2, align 4, !tbaa !5
  %8 = load i32, ptr %2, align 4, !tbaa !5
  %9 = sub nsw i32 %8, 1
  %10 = call i32 @chain(i32 noundef %9)
  %11 = add nsw i32 %7, %10
  br label %12

12:                                               ; preds = %6, %5
  %13 = phi i32 [ 0, %5 ], [ %11, %6 ]
  ret i32 %13
}

attributes #0 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { noinline nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { nounwind }

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
!10 = !{!"p1 int", !11, i64 0}
!11 = !{!"any pointer", !7, i64 0}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
!16 = distinct !{!16, !13, !14}
!17 = distinct !{!17, !14}
!18 = distinct !{!18, !13, !14}
