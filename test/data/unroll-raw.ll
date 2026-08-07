; ModuleID = 'test/c/unroll.c'
source_filename = "test/c/unroll.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nounwind uwtable
define dso_local i32 @total4(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store ptr %0, ptr %2, align 8, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #2
  store i32 0, ptr %3, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #2
  store i32 0, ptr %4, align 4, !tbaa !10
  br label %5

5:                                                ; preds = %17, %1
  %6 = load i32, ptr %4, align 4, !tbaa !10
  %7 = icmp slt i32 %6, 4
  br i1 %7, label %9, label %8

8:                                                ; preds = %5
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #2
  br label %20

9:                                                ; preds = %5
  %10 = load ptr, ptr %2, align 8, !tbaa !5
  %11 = load i32, ptr %4, align 4, !tbaa !10
  %12 = sext i32 %11 to i64
  %13 = getelementptr inbounds i32, ptr %10, i64 %12
  %14 = load i32, ptr %13, align 4, !tbaa !10
  %15 = load i32, ptr %3, align 4, !tbaa !10
  %16 = add nsw i32 %15, %14
  store i32 %16, ptr %3, align 4, !tbaa !10
  br label %17

17:                                               ; preds = %9
  %18 = load i32, ptr %4, align 4, !tbaa !10
  %19 = add nsw i32 %18, 1
  store i32 %19, ptr %4, align 4, !tbaa !10
  br label %5, !llvm.loop !12

20:                                               ; preds = %8
  %21 = load i32, ptr %3, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #2
  ret i32 %21
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define dso_local i32 @total_n(ptr noundef %0, i32 noundef %1) #0 {
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
  br label %7, !llvm.loop !15

23:                                               ; preds = %11
  %24 = load i32, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  ret i32 %24
}

; Function Attrs: nounwind uwtable
define dso_local i32 @every_third(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store ptr %0, ptr %2, align 8, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #2
  store i32 0, ptr %3, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #2
  store i32 0, ptr %4, align 4, !tbaa !10
  br label %5

5:                                                ; preds = %17, %1
  %6 = load i32, ptr %4, align 4, !tbaa !10
  %7 = icmp slt i32 %6, 12
  br i1 %7, label %9, label %8

8:                                                ; preds = %5
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #2
  br label %20

9:                                                ; preds = %5
  %10 = load ptr, ptr %2, align 8, !tbaa !5
  %11 = load i32, ptr %4, align 4, !tbaa !10
  %12 = sext i32 %11 to i64
  %13 = getelementptr inbounds i32, ptr %10, i64 %12
  %14 = load i32, ptr %13, align 4, !tbaa !10
  %15 = load i32, ptr %3, align 4, !tbaa !10
  %16 = add nsw i32 %15, %14
  store i32 %16, ptr %3, align 4, !tbaa !10
  br label %17

17:                                               ; preds = %9
  %18 = load i32, ptr %4, align 4, !tbaa !10
  %19 = add nsw i32 %18, 3
  store i32 %19, ptr %4, align 4, !tbaa !10
  br label %5, !llvm.loop !16

20:                                               ; preds = %8
  %21 = load i32, ptr %3, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #2
  ret i32 %21
}

; Function Attrs: nounwind uwtable
define dso_local i32 @count_back(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store ptr %0, ptr %2, align 8, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #2
  store i32 0, ptr %3, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #2
  store i32 4, ptr %4, align 4, !tbaa !10
  br label %5

5:                                                ; preds = %18, %1
  %6 = load i32, ptr %4, align 4, !tbaa !10
  %7 = icmp sgt i32 %6, 0
  br i1 %7, label %9, label %8

8:                                                ; preds = %5
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #2
  br label %21

9:                                                ; preds = %5
  %10 = load ptr, ptr %2, align 8, !tbaa !5
  %11 = load i32, ptr %4, align 4, !tbaa !10
  %12 = sub nsw i32 %11, 1
  %13 = sext i32 %12 to i64
  %14 = getelementptr inbounds i32, ptr %10, i64 %13
  %15 = load i32, ptr %14, align 4, !tbaa !10
  %16 = load i32, ptr %3, align 4, !tbaa !10
  %17 = add nsw i32 %16, %15
  store i32 %17, ptr %3, align 4, !tbaa !10
  br label %18

18:                                               ; preds = %9
  %19 = load i32, ptr %4, align 4, !tbaa !10
  %20 = add nsw i32 %19, -1
  store i32 %20, ptr %4, align 4, !tbaa !10
  br label %5, !llvm.loop !17

21:                                               ; preds = %8
  %22 = load i32, ptr %3, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #2
  ret i32 %22
}

; Function Attrs: nounwind uwtable
define dso_local void @fill4(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #2
  store i32 0, ptr %5, align 4, !tbaa !10
  br label %6

6:                                                ; preds = %18, %2
  %7 = load i32, ptr %5, align 4, !tbaa !10
  %8 = icmp slt i32 %7, 4
  br i1 %8, label %10, label %9

9:                                                ; preds = %6
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  br label %21

10:                                               ; preds = %6
  %11 = load i32, ptr %4, align 4, !tbaa !10
  %12 = load i32, ptr %5, align 4, !tbaa !10
  %13 = add nsw i32 %11, %12
  %14 = load ptr, ptr %3, align 8, !tbaa !5
  %15 = load i32, ptr %5, align 4, !tbaa !10
  %16 = sext i32 %15 to i64
  %17 = getelementptr inbounds i32, ptr %14, i64 %16
  store i32 %13, ptr %17, align 4, !tbaa !10
  br label %18

18:                                               ; preds = %10
  %19 = load i32, ptr %5, align 4, !tbaa !10
  %20 = add nsw i32 %19, 1
  store i32 %20, ptr %5, align 4, !tbaa !10
  br label %6, !llvm.loop !18

21:                                               ; preds = %9
  ret void
}

; Function Attrs: nounwind uwtable
define dso_local i32 @total64(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store ptr %0, ptr %2, align 8, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #2
  store i32 0, ptr %3, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #2
  store i32 0, ptr %4, align 4, !tbaa !10
  br label %5

5:                                                ; preds = %17, %1
  %6 = load i32, ptr %4, align 4, !tbaa !10
  %7 = icmp slt i32 %6, 64
  br i1 %7, label %9, label %8

8:                                                ; preds = %5
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #2
  br label %20

9:                                                ; preds = %5
  %10 = load ptr, ptr %2, align 8, !tbaa !5
  %11 = load i32, ptr %4, align 4, !tbaa !10
  %12 = sext i32 %11 to i64
  %13 = getelementptr inbounds i32, ptr %10, i64 %12
  %14 = load i32, ptr %13, align 4, !tbaa !10
  %15 = load i32, ptr %3, align 4, !tbaa !10
  %16 = add nsw i32 %15, %14
  store i32 %16, ptr %3, align 4, !tbaa !10
  br label %17

17:                                               ; preds = %9
  %18 = load i32, ptr %4, align 4, !tbaa !10
  %19 = add nsw i32 %18, 1
  store i32 %19, ptr %4, align 4, !tbaa !10
  br label %5, !llvm.loop !19

20:                                               ; preds = %8
  %21 = load i32, ptr %3, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #2
  ret i32 %21
}

; Function Attrs: nounwind uwtable
define dso_local i32 @wide4(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  %14 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !5
  store i32 %1, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #2
  store i32 0, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #2
  store i32 0, ptr %6, align 4, !tbaa !10
  br label %15

15:                                               ; preds = %55, %2
  %16 = load i32, ptr %6, align 4, !tbaa !10
  %17 = icmp slt i32 %16, 4
  br i1 %17, label %19, label %18

18:                                               ; preds = %15
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #2
  br label %58

19:                                               ; preds = %15
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #2
  %20 = load ptr, ptr %3, align 8, !tbaa !5
  %21 = load i32, ptr %6, align 4, !tbaa !10
  %22 = sext i32 %21 to i64
  %23 = getelementptr inbounds i32, ptr %20, i64 %22
  %24 = load i32, ptr %23, align 4, !tbaa !10
  %25 = load i32, ptr %4, align 4, !tbaa !10
  %26 = mul nsw i32 %24, %25
  store i32 %26, ptr %7, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %8) #2
  %27 = load i32, ptr %7, align 4, !tbaa !10
  %28 = load ptr, ptr %3, align 8, !tbaa !5
  %29 = load i32, ptr %6, align 4, !tbaa !10
  %30 = sext i32 %29 to i64
  %31 = getelementptr inbounds i32, ptr %28, i64 %30
  %32 = load i32, ptr %31, align 4, !tbaa !10
  %33 = add nsw i32 %27, %32
  store i32 %33, ptr %8, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %9) #2
  %34 = load i32, ptr %8, align 4, !tbaa !10
  %35 = load i32, ptr %8, align 4, !tbaa !10
  %36 = mul nsw i32 %34, %35
  store i32 %36, ptr %9, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %10) #2
  %37 = load i32, ptr %9, align 4, !tbaa !10
  %38 = load i32, ptr %7, align 4, !tbaa !10
  %39 = sub nsw i32 %37, %38
  store i32 %39, ptr %10, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %11) #2
  %40 = load i32, ptr %10, align 4, !tbaa !10
  %41 = load i32, ptr %4, align 4, !tbaa !10
  %42 = mul nsw i32 %40, %41
  store i32 %42, ptr %11, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %12) #2
  %43 = load i32, ptr %11, align 4, !tbaa !10
  %44 = load i32, ptr %9, align 4, !tbaa !10
  %45 = add nsw i32 %43, %44
  store i32 %45, ptr %12, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %13) #2
  %46 = load i32, ptr %12, align 4, !tbaa !10
  %47 = load i32, ptr %12, align 4, !tbaa !10
  %48 = mul nsw i32 %46, %47
  store i32 %48, ptr %13, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %14) #2
  %49 = load i32, ptr %13, align 4, !tbaa !10
  %50 = load i32, ptr %11, align 4, !tbaa !10
  %51 = sub nsw i32 %49, %50
  store i32 %51, ptr %14, align 4, !tbaa !10
  %52 = load i32, ptr %14, align 4, !tbaa !10
  %53 = load i32, ptr %5, align 4, !tbaa !10
  %54 = add nsw i32 %53, %52
  store i32 %54, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %14) #2
  call void @llvm.lifetime.end.p0(i64 4, ptr %13) #2
  call void @llvm.lifetime.end.p0(i64 4, ptr %12) #2
  call void @llvm.lifetime.end.p0(i64 4, ptr %11) #2
  call void @llvm.lifetime.end.p0(i64 4, ptr %10) #2
  call void @llvm.lifetime.end.p0(i64 4, ptr %9) #2
  call void @llvm.lifetime.end.p0(i64 4, ptr %8) #2
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #2
  br label %55

55:                                               ; preds = %19
  %56 = load i32, ptr %6, align 4, !tbaa !10
  %57 = add nsw i32 %56, 1
  store i32 %57, ptr %6, align 4, !tbaa !10
  br label %15, !llvm.loop !20

58:                                               ; preds = %18
  %59 = load i32, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  ret i32 %59
}

; Function Attrs: nounwind uwtable
define dso_local i32 @alternating(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store ptr %0, ptr %2, align 8, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #2
  store i32 0, ptr %3, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #2
  store i32 0, ptr %4, align 4, !tbaa !10
  br label %5

5:                                                ; preds = %33, %1
  %6 = load i32, ptr %4, align 4, !tbaa !10
  %7 = icmp slt i32 %6, 6
  br i1 %7, label %9, label %8

8:                                                ; preds = %5
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #2
  br label %36

9:                                                ; preds = %5
  %10 = load ptr, ptr %2, align 8, !tbaa !5
  %11 = load i32, ptr %4, align 4, !tbaa !10
  %12 = sext i32 %11 to i64
  %13 = getelementptr inbounds i32, ptr %10, i64 %12
  %14 = load i32, ptr %13, align 4, !tbaa !10
  %15 = icmp sgt i32 %14, 0
  br i1 %15, label %16, label %24

16:                                               ; preds = %9
  %17 = load ptr, ptr %2, align 8, !tbaa !5
  %18 = load i32, ptr %4, align 4, !tbaa !10
  %19 = sext i32 %18 to i64
  %20 = getelementptr inbounds i32, ptr %17, i64 %19
  %21 = load i32, ptr %20, align 4, !tbaa !10
  %22 = load i32, ptr %3, align 4, !tbaa !10
  %23 = add nsw i32 %22, %21
  store i32 %23, ptr %3, align 4, !tbaa !10
  br label %32

24:                                               ; preds = %9
  %25 = load ptr, ptr %2, align 8, !tbaa !5
  %26 = load i32, ptr %4, align 4, !tbaa !10
  %27 = sext i32 %26 to i64
  %28 = getelementptr inbounds i32, ptr %25, i64 %27
  %29 = load i32, ptr %28, align 4, !tbaa !10
  %30 = load i32, ptr %3, align 4, !tbaa !10
  %31 = sub nsw i32 %30, %29
  store i32 %31, ptr %3, align 4, !tbaa !10
  br label %32

32:                                               ; preds = %24, %16
  br label %33

33:                                               ; preds = %32
  %34 = load i32, ptr %4, align 4, !tbaa !10
  %35 = add nsw i32 %34, 1
  store i32 %35, ptr %4, align 4, !tbaa !10
  br label %5, !llvm.loop !21

36:                                               ; preds = %8
  %37 = load i32, ptr %3, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #2
  ret i32 %37
}

; Function Attrs: nounwind uwtable
define dso_local i32 @until_zero(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  store ptr %0, ptr %2, align 8, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #2
  store i32 0, ptr %3, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #2
  store i32 0, ptr %4, align 4, !tbaa !10
  br label %5

5:                                                ; preds = %12, %1
  %6 = load ptr, ptr %2, align 8, !tbaa !5
  %7 = load i32, ptr %4, align 4, !tbaa !10
  %8 = sext i32 %7 to i64
  %9 = getelementptr inbounds i32, ptr %6, i64 %8
  %10 = load i32, ptr %9, align 4, !tbaa !10
  %11 = icmp ne i32 %10, 0
  br i1 %11, label %12, label %22

12:                                               ; preds = %5
  %13 = load ptr, ptr %2, align 8, !tbaa !5
  %14 = load i32, ptr %4, align 4, !tbaa !10
  %15 = sext i32 %14 to i64
  %16 = getelementptr inbounds i32, ptr %13, i64 %15
  %17 = load i32, ptr %16, align 4, !tbaa !10
  %18 = load i32, ptr %3, align 4, !tbaa !10
  %19 = add nsw i32 %18, %17
  store i32 %19, ptr %3, align 4, !tbaa !10
  %20 = load i32, ptr %4, align 4, !tbaa !10
  %21 = add nsw i32 %20, 1
  store i32 %21, ptr %4, align 4, !tbaa !10
  br label %5, !llvm.loop !22

22:                                               ; preds = %5
  %23 = load i32, ptr %3, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #2
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #2
  ret i32 %23
}

; Function Attrs: nounwind uwtable
define dso_local i32 @grid(ptr noundef %0) #0 {
  %2 = alloca ptr, align 8
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store ptr %0, ptr %2, align 8, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #2
  store i32 0, ptr %3, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #2
  store i32 0, ptr %4, align 4, !tbaa !10
  br label %7

7:                                                ; preds = %31, %1
  %8 = load i32, ptr %4, align 4, !tbaa !10
  %9 = icmp slt i32 %8, 3
  br i1 %9, label %11, label %10

10:                                               ; preds = %7
  store i32 2, ptr %5, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #2
  br label %34

11:                                               ; preds = %7
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #2
  store i32 0, ptr %6, align 4, !tbaa !10
  br label %12

12:                                               ; preds = %27, %11
  %13 = load i32, ptr %6, align 4, !tbaa !10
  %14 = icmp slt i32 %13, 3
  br i1 %14, label %16, label %15

15:                                               ; preds = %12
  store i32 5, ptr %5, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #2
  br label %30

16:                                               ; preds = %12
  %17 = load ptr, ptr %2, align 8, !tbaa !5
  %18 = load i32, ptr %4, align 4, !tbaa !10
  %19 = mul nsw i32 %18, 3
  %20 = load i32, ptr %6, align 4, !tbaa !10
  %21 = add nsw i32 %19, %20
  %22 = sext i32 %21 to i64
  %23 = getelementptr inbounds i32, ptr %17, i64 %22
  %24 = load i32, ptr %23, align 4, !tbaa !10
  %25 = load i32, ptr %3, align 4, !tbaa !10
  %26 = add nsw i32 %25, %24
  store i32 %26, ptr %3, align 4, !tbaa !10
  br label %27

27:                                               ; preds = %16
  %28 = load i32, ptr %6, align 4, !tbaa !10
  %29 = add nsw i32 %28, 1
  store i32 %29, ptr %6, align 4, !tbaa !10
  br label %12, !llvm.loop !23

30:                                               ; preds = %15
  br label %31

31:                                               ; preds = %30
  %32 = load i32, ptr %4, align 4, !tbaa !10
  %33 = add nsw i32 %32, 1
  store i32 %33, ptr %4, align 4, !tbaa !10
  br label %7, !llvm.loop !24

34:                                               ; preds = %10
  %35 = load i32, ptr %3, align 4, !tbaa !10
  store i32 1, ptr %5, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #2
  ret i32 %35
}

; Function Attrs: nounwind uwtable
define dso_local i32 @first_negative(ptr noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %4) #2
  store i32 0, ptr %4, align 4, !tbaa !10
  br label %6

6:                                                ; preds = %20, %1
  %7 = load i32, ptr %4, align 4, !tbaa !10
  %8 = icmp slt i32 %7, 4
  br i1 %8, label %10, label %9

9:                                                ; preds = %6
  store i32 2, ptr %5, align 4
  br label %23

10:                                               ; preds = %6
  %11 = load ptr, ptr %3, align 8, !tbaa !5
  %12 = load i32, ptr %4, align 4, !tbaa !10
  %13 = sext i32 %12 to i64
  %14 = getelementptr inbounds i32, ptr %11, i64 %13
  %15 = load i32, ptr %14, align 4, !tbaa !10
  %16 = icmp slt i32 %15, 0
  br i1 %16, label %17, label %19

17:                                               ; preds = %10
  %18 = load i32, ptr %4, align 4, !tbaa !10
  store i32 %18, ptr %2, align 4
  store i32 1, ptr %5, align 4
  br label %23

19:                                               ; preds = %10
  br label %20

20:                                               ; preds = %19
  %21 = load i32, ptr %4, align 4, !tbaa !10
  %22 = add nsw i32 %21, 1
  store i32 %22, ptr %4, align 4, !tbaa !10
  br label %6, !llvm.loop !25

23:                                               ; preds = %17, %9
  call void @llvm.lifetime.end.p0(i64 4, ptr %4) #2
  %24 = load i32, ptr %5, align 4
  switch i32 %24, label %28 [
    i32 2, label %25
    i32 1, label %26
  ]

25:                                               ; preds = %23
  store i32 -1, ptr %2, align 4
  br label %26

26:                                               ; preds = %25, %23
  %27 = load i32, ptr %2, align 4
  ret i32 %27

28:                                               ; preds = %23
  unreachable
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
!21 = distinct !{!21, !13, !14}
!22 = distinct !{!22, !13, !14}
!23 = distinct !{!23, !13, !14}
!24 = distinct !{!24, !13, !14}
!25 = distinct !{!25, !13, !14}
