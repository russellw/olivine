; ModuleID = 'test/c/tail.c'
source_filename = "test/c/tail.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nounwind uwtable
define dso_local i32 @gcd_of(i32 noundef %0, i32 noundef %1) #0 {
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
  %14 = call i32 @gcd_of(i32 noundef %10, i32 noundef %13)
  br label %15

15:                                               ; preds = %9, %7
  %16 = phi i32 [ %8, %7 ], [ %14, %9 ]
  ret i32 %16
}

; Function Attrs: nounwind uwtable
define dso_local i32 @alternate(i32 noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store i32 %0, ptr %5, align 4, !tbaa !5
  store i32 %1, ptr %6, align 4, !tbaa !5
  store i32 %2, ptr %7, align 4, !tbaa !5
  %8 = load i32, ptr %7, align 4, !tbaa !5
  %9 = icmp eq i32 %8, 0
  br i1 %9, label %10, label %15

10:                                               ; preds = %3
  %11 = load i32, ptr %5, align 4, !tbaa !5
  %12 = mul nsw i32 %11, 10
  %13 = load i32, ptr %6, align 4, !tbaa !5
  %14 = add nsw i32 %12, %13
  store i32 %14, ptr %4, align 4
  br label %21

15:                                               ; preds = %3
  %16 = load i32, ptr %6, align 4, !tbaa !5
  %17 = load i32, ptr %5, align 4, !tbaa !5
  %18 = load i32, ptr %7, align 4, !tbaa !5
  %19 = sub nsw i32 %18, 1
  %20 = call i32 @alternate(i32 noundef %16, i32 noundef %17, i32 noundef %19)
  store i32 %20, ptr %4, align 4
  br label %21

21:                                               ; preds = %15, %10
  %22 = load i32, ptr %4, align 4
  ret i32 %22
}

; Function Attrs: nounwind uwtable
define dso_local i32 @steps(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  store i32 %0, ptr %4, align 4, !tbaa !5
  store i32 %1, ptr %5, align 4, !tbaa !5
  %6 = load i32, ptr %4, align 4, !tbaa !5
  %7 = icmp sle i32 %6, 0
  br i1 %7, label %8, label %10

8:                                                ; preds = %2
  %9 = load i32, ptr %5, align 4, !tbaa !5
  store i32 %9, ptr %3, align 4
  br label %26

10:                                               ; preds = %2
  %11 = load i32, ptr %4, align 4, !tbaa !5
  %12 = srem i32 %11, 2
  %13 = icmp ne i32 %12, 0
  br i1 %13, label %14, label %20

14:                                               ; preds = %10
  %15 = load i32, ptr %4, align 4, !tbaa !5
  %16 = sub nsw i32 %15, 1
  %17 = load i32, ptr %5, align 4, !tbaa !5
  %18 = add nsw i32 %17, 1
  %19 = call i32 @steps(i32 noundef %16, i32 noundef %18)
  store i32 %19, ptr %3, align 4
  br label %26

20:                                               ; preds = %10
  %21 = load i32, ptr %4, align 4, !tbaa !5
  %22 = sdiv i32 %21, 2
  %23 = load i32, ptr %5, align 4, !tbaa !5
  %24 = add nsw i32 %23, 2
  %25 = call i32 @steps(i32 noundef %22, i32 noundef %24)
  store i32 %25, ptr %3, align 4
  br label %26

26:                                               ; preds = %20, %14, %8
  %27 = load i32, ptr %3, align 4
  ret i32 %27
}

; Function Attrs: nounwind uwtable
define dso_local void @walk_down(ptr noundef %0, i32 noundef %1) #0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !9
  store i32 %1, ptr %4, align 4, !tbaa !5
  %5 = load i32, ptr %4, align 4, !tbaa !5
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %7, label %8

7:                                                ; preds = %2
  br label %16

8:                                                ; preds = %2
  %9 = load i32, ptr %4, align 4, !tbaa !5
  %10 = load ptr, ptr %3, align 8, !tbaa !9
  %11 = load i32, ptr %10, align 4, !tbaa !5
  %12 = add nsw i32 %11, %9
  store i32 %12, ptr %10, align 4, !tbaa !5
  %13 = load ptr, ptr %3, align 8, !tbaa !9
  %14 = load i32, ptr %4, align 4, !tbaa !5
  %15 = sub nsw i32 %14, 1
  call void @walk_down(ptr noundef %13, i32 noundef %15)
  br label %16

16:                                               ; preds = %8, %7
  ret void
}

; Function Attrs: nounwind uwtable
define dso_local i32 @buffered(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca [4 x i32], align 16
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store i32 %0, ptr %4, align 4, !tbaa !5
  store i32 %1, ptr %5, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 16, ptr %6) #2
  %9 = load i32, ptr %4, align 4, !tbaa !5
  %10 = icmp sle i32 %9, 0
  br i1 %10, label %11, label %13

11:                                               ; preds = %2
  %12 = load i32, ptr %5, align 4, !tbaa !5
  store i32 %12, ptr %3, align 4
  store i32 1, ptr %7, align 4
  br label %39

13:                                               ; preds = %2
  call void @llvm.lifetime.start.p0(i64 4, ptr %8) #2
  store i32 0, ptr %8, align 4, !tbaa !5
  br label %14

14:                                               ; preds = %25, %13
  %15 = load i32, ptr %8, align 4, !tbaa !5
  %16 = icmp slt i32 %15, 4
  br i1 %16, label %18, label %17

17:                                               ; preds = %14
  store i32 2, ptr %7, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr %8) #2
  br label %28

18:                                               ; preds = %14
  %19 = load i32, ptr %4, align 4, !tbaa !5
  %20 = load i32, ptr %8, align 4, !tbaa !5
  %21 = add nsw i32 %19, %20
  %22 = load i32, ptr %8, align 4, !tbaa !5
  %23 = sext i32 %22 to i64
  %24 = getelementptr inbounds [4 x i32], ptr %6, i64 0, i64 %23
  store i32 %21, ptr %24, align 4, !tbaa !5
  br label %25

25:                                               ; preds = %18
  %26 = load i32, ptr %8, align 4, !tbaa !5
  %27 = add nsw i32 %26, 1
  store i32 %27, ptr %8, align 4, !tbaa !5
  br label %14, !llvm.loop !12

28:                                               ; preds = %17
  %29 = load i32, ptr %4, align 4, !tbaa !5
  %30 = sub nsw i32 %29, 1
  %31 = load i32, ptr %5, align 4, !tbaa !5
  %32 = load i32, ptr %4, align 4, !tbaa !5
  %33 = and i32 %32, 3
  %34 = sext i32 %33 to i64
  %35 = getelementptr inbounds [4 x i32], ptr %6, i64 0, i64 %34
  %36 = load i32, ptr %35, align 4, !tbaa !5
  %37 = add nsw i32 %31, %36
  %38 = call i32 @buffered(i32 noundef %30, i32 noundef %37)
  store i32 %38, ptr %3, align 4
  store i32 1, ptr %7, align 4
  br label %39

39:                                               ; preds = %28, %11
  call void @llvm.lifetime.end.p0(i64 16, ptr %6) #2
  %40 = load i32, ptr %3, align 4
  ret i32 %40
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define dso_local i32 @via_local(i32 noundef %0, ptr noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store i32 %0, ptr %4, align 4, !tbaa !5
  store ptr %1, ptr %5, align 8, !tbaa !9
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #2
  %8 = load i32, ptr %4, align 4, !tbaa !5
  %9 = mul nsw i32 %8, 3
  store i32 %9, ptr %6, align 4, !tbaa !5
  %10 = load i32, ptr %4, align 4, !tbaa !5
  %11 = icmp eq i32 %10, 0
  br i1 %11, label %12, label %21

12:                                               ; preds = %2
  %13 = load ptr, ptr %5, align 8, !tbaa !9
  %14 = icmp ne ptr %13, null
  br i1 %14, label %15, label %18

15:                                               ; preds = %12
  %16 = load ptr, ptr %5, align 8, !tbaa !9
  %17 = load i32, ptr %16, align 4, !tbaa !5
  br label %19

18:                                               ; preds = %12
  br label %19

19:                                               ; preds = %18, %15
  %20 = phi i32 [ %17, %15 ], [ -1, %18 ]
  store i32 %20, ptr %3, align 4
  store i32 1, ptr %7, align 4
  br label %25

21:                                               ; preds = %2
  %22 = load i32, ptr %4, align 4, !tbaa !5
  %23 = sub nsw i32 %22, 1
  %24 = call i32 @via_local(i32 noundef %23, ptr noundef %6)
  store i32 %24, ptr %3, align 4
  store i32 1, ptr %7, align 4
  br label %25

25:                                               ; preds = %21, %19
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #2
  %26 = load i32, ptr %3, align 4
  ret i32 %26
}

; Function Attrs: nounwind uwtable
define dso_local i32 @product_to(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  %3 = load i32, ptr %2, align 4, !tbaa !5
  %4 = icmp sle i32 %3, 1
  br i1 %4, label %5, label %6

5:                                                ; preds = %1
  br label %12

6:                                                ; preds = %1
  %7 = load i32, ptr %2, align 4, !tbaa !5
  %8 = load i32, ptr %2, align 4, !tbaa !5
  %9 = sub nsw i32 %8, 1
  %10 = call i32 @product_to(i32 noundef %9)
  %11 = mul nsw i32 %7, %10
  br label %12

12:                                               ; preds = %6, %5
  %13 = phi i32 [ 1, %5 ], [ %11, %6 ]
  ret i32 %13
}

; Function Attrs: nounwind uwtable
define dso_local i32 @forwards(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  %3 = load i32, ptr %2, align 4, !tbaa !5
  %4 = call i32 @plus_one(i32 noundef %3)
  ret i32 %4
}

; Function Attrs: nounwind uwtable
define internal i32 @plus_one(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  %3 = load i32, ptr %2, align 4, !tbaa !5
  %4 = add nsw i32 %3, 1
  ret i32 %4
}

; Function Attrs: nounwind uwtable
define dso_local i32 @bounced(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  %3 = load i32, ptr %2, align 4, !tbaa !5
  %4 = call i32 @ping(i32 noundef %3)
  ret i32 %4
}

; Function Attrs: nounwind uwtable
define internal i32 @ping(i32 noundef %0) #0 {
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
  %9 = call i32 @pong(i32 noundef %8)
  br label %10

10:                                               ; preds = %6, %5
  %11 = phi i32 [ 10, %5 ], [ %9, %6 ]
  ret i32 %11
}

; Function Attrs: nounwind uwtable
define dso_local i32 @skipping(ptr noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  store ptr %0, ptr %5, align 8, !tbaa !9
  store i32 %1, ptr %6, align 4, !tbaa !5
  store i32 %2, ptr %7, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %8) #2
  store i32 0, ptr %8, align 4, !tbaa !5
  br label %10

10:                                               ; preds = %23, %3
  %11 = load i32, ptr %8, align 4, !tbaa !5
  %12 = load i32, ptr %6, align 4, !tbaa !5
  %13 = icmp slt i32 %11, %12
  br i1 %13, label %14, label %21

14:                                               ; preds = %10
  %15 = load ptr, ptr %5, align 8, !tbaa !9
  %16 = load i32, ptr %8, align 4, !tbaa !5
  %17 = sext i32 %16 to i64
  %18 = getelementptr inbounds i32, ptr %15, i64 %17
  %19 = load i32, ptr %18, align 4, !tbaa !5
  %20 = icmp sgt i32 %19, 0
  br label %21

21:                                               ; preds = %14, %10
  %22 = phi i1 [ false, %10 ], [ %20, %14 ]
  br i1 %22, label %23, label %33

23:                                               ; preds = %21
  %24 = load ptr, ptr %5, align 8, !tbaa !9
  %25 = load i32, ptr %8, align 4, !tbaa !5
  %26 = sext i32 %25 to i64
  %27 = getelementptr inbounds i32, ptr %24, i64 %26
  %28 = load i32, ptr %27, align 4, !tbaa !5
  %29 = load i32, ptr %7, align 4, !tbaa !5
  %30 = add nsw i32 %29, %28
  store i32 %30, ptr %7, align 4, !tbaa !5
  %31 = load i32, ptr %8, align 4, !tbaa !5
  %32 = add nsw i32 %31, 1
  store i32 %32, ptr %8, align 4, !tbaa !5
  br label %10, !llvm.loop !15

33:                                               ; preds = %21
  %34 = load i32, ptr %8, align 4, !tbaa !5
  %35 = load i32, ptr %6, align 4, !tbaa !5
  %36 = icmp eq i32 %34, %35
  br i1 %36, label %37, label %39

37:                                               ; preds = %33
  %38 = load i32, ptr %7, align 4, !tbaa !5
  store i32 %38, ptr %4, align 4
  store i32 1, ptr %9, align 4
  br label %52

39:                                               ; preds = %33
  %40 = load ptr, ptr %5, align 8, !tbaa !9
  %41 = load i32, ptr %8, align 4, !tbaa !5
  %42 = sext i32 %41 to i64
  %43 = getelementptr inbounds i32, ptr %40, i64 %42
  %44 = getelementptr inbounds i32, ptr %43, i64 1
  %45 = load i32, ptr %6, align 4, !tbaa !5
  %46 = load i32, ptr %8, align 4, !tbaa !5
  %47 = sub nsw i32 %45, %46
  %48 = sub nsw i32 %47, 1
  %49 = load i32, ptr %7, align 4, !tbaa !5
  %50 = sub nsw i32 %49, 1
  %51 = call i32 @skipping(ptr noundef %44, i32 noundef %48, i32 noundef %50)
  store i32 %51, ptr %4, align 4
  store i32 1, ptr %9, align 4
  br label %52

52:                                               ; preds = %39, %37
  call void @llvm.lifetime.end.p0(i64 4, ptr %8) #2
  %53 = load i32, ptr %4, align 4
  ret i32 %53
}

; Function Attrs: nounwind uwtable
define internal i32 @pong(i32 noundef %0) #0 {
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
  %9 = call i32 @ping(i32 noundef %8)
  br label %10

10:                                               ; preds = %6, %5
  %11 = phi i32 [ 20, %5 ], [ %9, %6 ]
  ret i32 %11
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
