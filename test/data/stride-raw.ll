; ModuleID = 'test/c/stride.c'
source_filename = "test/c/stride.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nounwind uwtable
define dso_local i32 @stride_walk(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #2
  store i32 0, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #2
  store i32 0, ptr %6, align 4, !tbaa !10
  br label %7

7:                                                ; preds = %20, %2
  %8 = load i32, ptr %6, align 4, !tbaa !10
  %9 = load i32, ptr %4, align 4, !tbaa !10
  %10 = icmp slt i32 %8, %9
  br i1 %10, label %12, label %11

11:                                               ; preds = %7
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #2
  br label %23

12:                                               ; preds = %7
  %13 = load ptr, ptr %3, align 8, !tbaa !5
  %14 = load i32, ptr %6, align 4, !tbaa !10
  %15 = sext i32 %14 to i64
  %16 = getelementptr inbounds i32, ptr %13, i64 %15
  %17 = load i32, ptr %16, align 4, !tbaa !10
  %18 = load i32, ptr %5, align 4, !tbaa !10
  %19 = add nsw i32 %18, %17
  store i32 %19, ptr %5, align 4, !tbaa !10
  br label %20

20:                                               ; preds = %12
  %21 = load i32, ptr %6, align 4, !tbaa !10
  %22 = add nsw i32 %21, 1
  store i32 %22, ptr %6, align 4, !tbaa !10
  br label %7, !llvm.loop !12

23:                                               ; preds = %11
  %24 = load i32, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  ret i32 %24
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define dso_local i32 @stride_dot(ptr noundef %0, ptr noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %4, align 8, !tbaa !5
  store ptr %1, ptr %5, align 8, !tbaa !5
  store i32 %2, ptr %6, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #2
  store i32 0, ptr %7, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %8) #2
  store i32 0, ptr %8, align 4, !tbaa !10
  br label %9

9:                                                ; preds = %28, %3
  %10 = load i32, ptr %8, align 4, !tbaa !10
  %11 = load i32, ptr %6, align 4, !tbaa !10
  %12 = icmp slt i32 %10, %11
  br i1 %12, label %14, label %13

13:                                               ; preds = %9
  call void @llvm.lifetime.end.p0(i64 4, ptr %8) #2
  br label %31

14:                                               ; preds = %9
  %15 = load ptr, ptr %4, align 8, !tbaa !5
  %16 = load i32, ptr %8, align 4, !tbaa !10
  %17 = sext i32 %16 to i64
  %18 = getelementptr inbounds i32, ptr %15, i64 %17
  %19 = load i32, ptr %18, align 4, !tbaa !10
  %20 = load ptr, ptr %5, align 8, !tbaa !5
  %21 = load i32, ptr %8, align 4, !tbaa !10
  %22 = sext i32 %21 to i64
  %23 = getelementptr inbounds i32, ptr %20, i64 %22
  %24 = load i32, ptr %23, align 4, !tbaa !10
  %25 = mul nsw i32 %19, %24
  %26 = load i32, ptr %7, align 4, !tbaa !10
  %27 = add nsw i32 %26, %25
  store i32 %27, ptr %7, align 4, !tbaa !10
  br label %28

28:                                               ; preds = %14
  %29 = load i32, ptr %8, align 4, !tbaa !10
  %30 = add nsw i32 %29, 1
  store i32 %30, ptr %8, align 4, !tbaa !10
  br label %9, !llvm.loop !15

31:                                               ; preds = %13
  %32 = load i32, ptr %7, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #2
  ret i32 %32
}

; Function Attrs: nounwind uwtable
define dso_local i32 @stride_third(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #2
  store i32 0, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #2
  store i32 0, ptr %6, align 4, !tbaa !10
  br label %7

7:                                                ; preds = %20, %2
  %8 = load i32, ptr %6, align 4, !tbaa !10
  %9 = load i32, ptr %4, align 4, !tbaa !10
  %10 = icmp slt i32 %8, %9
  br i1 %10, label %12, label %11

11:                                               ; preds = %7
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #2
  br label %23

12:                                               ; preds = %7
  %13 = load ptr, ptr %3, align 8, !tbaa !5
  %14 = load i32, ptr %6, align 4, !tbaa !10
  %15 = sext i32 %14 to i64
  %16 = getelementptr inbounds i32, ptr %13, i64 %15
  %17 = load i32, ptr %16, align 4, !tbaa !10
  %18 = load i32, ptr %5, align 4, !tbaa !10
  %19 = add nsw i32 %18, %17
  store i32 %19, ptr %5, align 4, !tbaa !10
  br label %20

20:                                               ; preds = %12
  %21 = load i32, ptr %6, align 4, !tbaa !10
  %22 = add nsw i32 %21, 3
  store i32 %22, ptr %6, align 4, !tbaa !10
  br label %7, !llvm.loop !16

23:                                               ; preds = %11
  %24 = load i32, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  ret i32 %24
}

; Function Attrs: nounwind uwtable
define dso_local i32 @backwards(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #2
  store i32 0, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #2
  %7 = load i32, ptr %4, align 4, !tbaa !10
  %8 = sub nsw i32 %7, 1
  store i32 %8, ptr %6, align 4, !tbaa !10
  br label %9

9:                                                ; preds = %21, %2
  %10 = load i32, ptr %6, align 4, !tbaa !10
  %11 = icmp sge i32 %10, 0
  br i1 %11, label %13, label %12

12:                                               ; preds = %9
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #2
  br label %24

13:                                               ; preds = %9
  %14 = load ptr, ptr %3, align 8, !tbaa !5
  %15 = load i32, ptr %6, align 4, !tbaa !10
  %16 = sext i32 %15 to i64
  %17 = getelementptr inbounds i32, ptr %14, i64 %16
  %18 = load i32, ptr %17, align 4, !tbaa !10
  %19 = load i32, ptr %5, align 4, !tbaa !10
  %20 = add nsw i32 %19, %18
  store i32 %20, ptr %5, align 4, !tbaa !10
  br label %21

21:                                               ; preds = %13
  %22 = load i32, ptr %6, align 4, !tbaa !10
  %23 = add nsw i32 %22, -1
  store i32 %23, ptr %6, align 4, !tbaa !10
  br label %9, !llvm.loop !17

24:                                               ; preds = %12
  %25 = load i32, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  ret i32 %25
}

; Function Attrs: nounwind uwtable
define dso_local void @scale(ptr noundef %0, ptr noundef %1, i32 noundef %2, i32 noundef %3) #0 {
  %5 = alloca ptr, align 8
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  store ptr %0, ptr %5, align 8, !tbaa !5
  store ptr %1, ptr %6, align 8, !tbaa !5
  store i32 %2, ptr %7, align 4, !tbaa !10
  store i32 %3, ptr %8, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %9) #2
  store i32 0, ptr %9, align 4, !tbaa !10
  br label %10

10:                                               ; preds = %27, %4
  %11 = load i32, ptr %9, align 4, !tbaa !10
  %12 = load i32, ptr %7, align 4, !tbaa !10
  %13 = icmp slt i32 %11, %12
  br i1 %13, label %15, label %14

14:                                               ; preds = %10
  call void @llvm.lifetime.end.p0(i64 4, ptr %9) #2
  br label %30

15:                                               ; preds = %10
  %16 = load ptr, ptr %6, align 8, !tbaa !5
  %17 = load i32, ptr %9, align 4, !tbaa !10
  %18 = sext i32 %17 to i64
  %19 = getelementptr inbounds i32, ptr %16, i64 %18
  %20 = load i32, ptr %19, align 4, !tbaa !10
  %21 = load i32, ptr %8, align 4, !tbaa !10
  %22 = mul nsw i32 %20, %21
  %23 = load ptr, ptr %5, align 8, !tbaa !5
  %24 = load i32, ptr %9, align 4, !tbaa !10
  %25 = sext i32 %24 to i64
  %26 = getelementptr inbounds i32, ptr %23, i64 %25
  store i32 %22, ptr %26, align 4, !tbaa !10
  br label %27

27:                                               ; preds = %15
  %28 = load i32, ptr %9, align 4, !tbaa !10
  %29 = add nsw i32 %28, 1
  store i32 %29, ptr %9, align 4, !tbaa !10
  br label %10, !llvm.loop !18

30:                                               ; preds = %14
  ret void
}

; Function Attrs: nounwind uwtable
define dso_local i32 @stride_weighted(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #2
  store i32 0, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #2
  store i32 0, ptr %6, align 4, !tbaa !10
  br label %7

7:                                                ; preds = %24, %2
  %8 = load i32, ptr %6, align 4, !tbaa !10
  %9 = load i32, ptr %4, align 4, !tbaa !10
  %10 = icmp slt i32 %8, %9
  br i1 %10, label %12, label %11

11:                                               ; preds = %7
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #2
  br label %27

12:                                               ; preds = %7
  %13 = load ptr, ptr %3, align 8, !tbaa !5
  %14 = load i32, ptr %6, align 4, !tbaa !10
  %15 = sext i32 %14 to i64
  %16 = getelementptr inbounds i32, ptr %13, i64 %15
  %17 = load i32, ptr %16, align 4, !tbaa !10
  %18 = mul nsw i32 %17, 5
  %19 = load i32, ptr %6, align 4, !tbaa !10
  %20 = mul nsw i32 %19, 7
  %21 = add nsw i32 %18, %20
  %22 = load i32, ptr %5, align 4, !tbaa !10
  %23 = add nsw i32 %22, %21
  store i32 %23, ptr %5, align 4, !tbaa !10
  br label %24

24:                                               ; preds = %12
  %25 = load i32, ptr %6, align 4, !tbaa !10
  %26 = add nsw i32 %25, 1
  store i32 %26, ptr %6, align 4, !tbaa !10
  br label %7, !llvm.loop !19

27:                                               ; preds = %11
  %28 = load i32, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  ret i32 %28
}

; Function Attrs: nounwind uwtable
define dso_local i32 @stride_unsigned(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #2
  store i32 0, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #2
  store i32 0, ptr %6, align 4, !tbaa !10
  br label %7

7:                                                ; preds = %20, %2
  %8 = load i32, ptr %6, align 4, !tbaa !10
  %9 = load i32, ptr %4, align 4, !tbaa !10
  %10 = icmp ult i32 %8, %9
  br i1 %10, label %12, label %11

11:                                               ; preds = %7
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #2
  br label %23

12:                                               ; preds = %7
  %13 = load ptr, ptr %3, align 8, !tbaa !5
  %14 = load i32, ptr %6, align 4, !tbaa !10
  %15 = zext i32 %14 to i64
  %16 = getelementptr inbounds nuw i32, ptr %13, i64 %15
  %17 = load i32, ptr %16, align 4, !tbaa !10
  %18 = load i32, ptr %5, align 4, !tbaa !10
  %19 = add i32 %18, %17
  store i32 %19, ptr %5, align 4, !tbaa !10
  br label %20

20:                                               ; preds = %12
  %21 = load i32, ptr %6, align 4, !tbaa !10
  %22 = add i32 %21, 1
  store i32 %22, ptr %6, align 4, !tbaa !10
  br label %7, !llvm.loop !20

23:                                               ; preds = %11
  %24 = load i32, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  ret i32 %24
}

; Function Attrs: nounwind uwtable
define dso_local i32 @through_handle(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !21
  store i32 %1, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #2
  store i32 0, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #2
  store i32 0, ptr %6, align 4, !tbaa !10
  br label %7

7:                                                ; preds = %21, %2
  %8 = load i32, ptr %6, align 4, !tbaa !10
  %9 = load i32, ptr %4, align 4, !tbaa !10
  %10 = icmp slt i32 %8, %9
  br i1 %10, label %12, label %11

11:                                               ; preds = %7
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #2
  br label %24

12:                                               ; preds = %7
  %13 = load ptr, ptr %3, align 8, !tbaa !21
  %14 = load ptr, ptr %13, align 8, !tbaa !5
  %15 = load i32, ptr %6, align 4, !tbaa !10
  %16 = sext i32 %15 to i64
  %17 = getelementptr inbounds i32, ptr %14, i64 %16
  %18 = load i32, ptr %17, align 4, !tbaa !10
  %19 = load i32, ptr %5, align 4, !tbaa !10
  %20 = add nsw i32 %19, %18
  store i32 %20, ptr %5, align 4, !tbaa !10
  br label %21

21:                                               ; preds = %12
  %22 = load i32, ptr %6, align 4, !tbaa !10
  %23 = add nsw i32 %22, 1
  store i32 %23, ptr %6, align 4, !tbaa !10
  br label %7, !llvm.loop !24

24:                                               ; preds = %11
  %25 = load i32, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  ret i32 %25
}

; Function Attrs: nounwind uwtable
define dso_local i32 @gathered(ptr noundef %0, ptr noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %4, align 8, !tbaa !5
  store ptr %1, ptr %5, align 8, !tbaa !5
  store i32 %2, ptr %6, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #2
  store i32 0, ptr %7, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %8) #2
  store i32 0, ptr %8, align 4, !tbaa !10
  br label %9

9:                                                ; preds = %26, %3
  %10 = load i32, ptr %8, align 4, !tbaa !10
  %11 = load i32, ptr %6, align 4, !tbaa !10
  %12 = icmp slt i32 %10, %11
  br i1 %12, label %14, label %13

13:                                               ; preds = %9
  call void @llvm.lifetime.end.p0(i64 4, ptr %8) #2
  br label %29

14:                                               ; preds = %9
  %15 = load ptr, ptr %4, align 8, !tbaa !5
  %16 = load ptr, ptr %5, align 8, !tbaa !5
  %17 = load i32, ptr %8, align 4, !tbaa !10
  %18 = sext i32 %17 to i64
  %19 = getelementptr inbounds i32, ptr %16, i64 %18
  %20 = load i32, ptr %19, align 4, !tbaa !10
  %21 = sext i32 %20 to i64
  %22 = getelementptr inbounds i32, ptr %15, i64 %21
  %23 = load i32, ptr %22, align 4, !tbaa !10
  %24 = load i32, ptr %7, align 4, !tbaa !10
  %25 = add nsw i32 %24, %23
  store i32 %25, ptr %7, align 4, !tbaa !10
  br label %26

26:                                               ; preds = %14
  %27 = load i32, ptr %8, align 4, !tbaa !10
  %28 = add nsw i32 %27, 1
  store i32 %28, ptr %8, align 4, !tbaa !10
  br label %9, !llvm.loop !25

29:                                               ; preds = %13
  %30 = load i32, ptr %7, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #2
  ret i32 %30
}

; Function Attrs: nounwind uwtable
define dso_local i32 @grid_total(ptr noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store ptr %0, ptr %4, align 8, !tbaa !5
  store i32 %1, ptr %5, align 4, !tbaa !10
  store i32 %2, ptr %6, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #2
  store i32 0, ptr %7, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %8) #2
  store i32 0, ptr %8, align 4, !tbaa !10
  br label %11

11:                                               ; preds = %37, %3
  %12 = load i32, ptr %8, align 4, !tbaa !10
  %13 = load i32, ptr %5, align 4, !tbaa !10
  %14 = icmp slt i32 %12, %13
  br i1 %14, label %16, label %15

15:                                               ; preds = %11
  store i32 2, ptr %9, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr %8) #2
  br label %40

16:                                               ; preds = %11
  call void @llvm.lifetime.start.p0(i64 4, ptr %10) #2
  store i32 0, ptr %10, align 4, !tbaa !10
  br label %17

17:                                               ; preds = %33, %16
  %18 = load i32, ptr %10, align 4, !tbaa !10
  %19 = load i32, ptr %6, align 4, !tbaa !10
  %20 = icmp slt i32 %18, %19
  br i1 %20, label %22, label %21

21:                                               ; preds = %17
  store i32 5, ptr %9, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr %10) #2
  br label %36

22:                                               ; preds = %17
  %23 = load ptr, ptr %4, align 8, !tbaa !5
  %24 = load i32, ptr %8, align 4, !tbaa !10
  %25 = mul nsw i32 %24, 8
  %26 = load i32, ptr %10, align 4, !tbaa !10
  %27 = add nsw i32 %25, %26
  %28 = sext i32 %27 to i64
  %29 = getelementptr inbounds i32, ptr %23, i64 %28
  %30 = load i32, ptr %29, align 4, !tbaa !10
  %31 = load i32, ptr %7, align 4, !tbaa !10
  %32 = add nsw i32 %31, %30
  store i32 %32, ptr %7, align 4, !tbaa !10
  br label %33

33:                                               ; preds = %22
  %34 = load i32, ptr %10, align 4, !tbaa !10
  %35 = add nsw i32 %34, 1
  store i32 %35, ptr %10, align 4, !tbaa !10
  br label %17, !llvm.loop !26

36:                                               ; preds = %21
  br label %37

37:                                               ; preds = %36
  %38 = load i32, ptr %8, align 4, !tbaa !10
  %39 = add nsw i32 %38, 1
  store i32 %39, ptr %8, align 4, !tbaa !10
  br label %11, !llvm.loop !27

40:                                               ; preds = %15
  %41 = load i32, ptr %7, align 4, !tbaa !10
  store i32 1, ptr %9, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #2
  ret i32 %41
}

attributes #0 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 21.1.8 (6ubuntu1)"}
!5 = !{!6, !6, i64 0}
!6 = !{!"p1 int", !7, i64 0}
!7 = !{!"any pointer", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!11, !11, i64 0}
!11 = !{!"int", !8, i64 0}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
!16 = distinct !{!16, !13, !14}
!17 = distinct !{!17, !13, !14}
!18 = distinct !{!18, !13, !14}
!19 = distinct !{!19, !13, !14}
!20 = distinct !{!20, !13, !14}
!21 = !{!22, !22, i64 0}
!22 = !{!"p2 int", !23, i64 0}
!23 = !{!"any p2 pointer", !7, i64 0}
!24 = distinct !{!24, !13, !14}
!25 = distinct !{!25, !13, !14}
!26 = distinct !{!26, !13, !14}
!27 = distinct !{!27, !13, !14}
