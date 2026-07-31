; ModuleID = 'test/c/jumps.c'
source_filename = "test/c/jumps.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nounwind uwtable
define dso_local i32 @search(ptr noundef %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) #0 {
  %5 = alloca i32, align 4
  %6 = alloca ptr, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  %13 = alloca i32, align 4
  store ptr %0, ptr %6, align 8, !tbaa !5
  store i32 %1, ptr %7, align 4, !tbaa !10
  store i32 %2, ptr %8, align 4, !tbaa !10
  store i32 %3, ptr %9, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %10) #2
  store i32 -1, ptr %10, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %11) #2
  store i32 0, ptr %11, align 4, !tbaa !10
  br label %14

14:                                               ; preds = %62, %4
  %15 = load i32, ptr %11, align 4, !tbaa !10
  %16 = load i32, ptr %8, align 4, !tbaa !10
  %17 = icmp slt i32 %15, %16
  br i1 %17, label %19, label %18

18:                                               ; preds = %14
  store i32 2, ptr %12, align 4
  br label %65

19:                                               ; preds = %14
  call void @llvm.lifetime.start.p0(i64 4, ptr %13) #2
  store i32 0, ptr %13, align 4, !tbaa !10
  br label %20

20:                                               ; preds = %56, %19
  %21 = load i32, ptr %13, align 4, !tbaa !10
  %22 = load i32, ptr %7, align 4, !tbaa !10
  %23 = icmp slt i32 %21, %22
  br i1 %23, label %25, label %24

24:                                               ; preds = %20
  store i32 5, ptr %12, align 4
  br label %59

25:                                               ; preds = %20
  %26 = load ptr, ptr %6, align 8, !tbaa !5
  %27 = load i32, ptr %11, align 4, !tbaa !10
  %28 = load i32, ptr %7, align 4, !tbaa !10
  %29 = mul nsw i32 %27, %28
  %30 = load i32, ptr %13, align 4, !tbaa !10
  %31 = add nsw i32 %29, %30
  %32 = sext i32 %31 to i64
  %33 = getelementptr inbounds i32, ptr %26, i64 %32
  %34 = load i32, ptr %33, align 4, !tbaa !10
  %35 = icmp slt i32 %34, 0
  br i1 %35, label %36, label %37

36:                                               ; preds = %25
  br label %56

37:                                               ; preds = %25
  %38 = load ptr, ptr %6, align 8, !tbaa !5
  %39 = load i32, ptr %11, align 4, !tbaa !10
  %40 = load i32, ptr %7, align 4, !tbaa !10
  %41 = mul nsw i32 %39, %40
  %42 = load i32, ptr %13, align 4, !tbaa !10
  %43 = add nsw i32 %41, %42
  %44 = sext i32 %43 to i64
  %45 = getelementptr inbounds i32, ptr %38, i64 %44
  %46 = load i32, ptr %45, align 4, !tbaa !10
  %47 = load i32, ptr %9, align 4, !tbaa !10
  %48 = icmp eq i32 %46, %47
  br i1 %48, label %49, label %55

49:                                               ; preds = %37
  %50 = load i32, ptr %11, align 4, !tbaa !10
  %51 = load i32, ptr %7, align 4, !tbaa !10
  %52 = mul nsw i32 %50, %51
  %53 = load i32, ptr %13, align 4, !tbaa !10
  %54 = add nsw i32 %52, %53
  store i32 %54, ptr %10, align 4, !tbaa !10
  store i32 8, ptr %12, align 4
  br label %59

55:                                               ; preds = %37
  br label %56

56:                                               ; preds = %55, %36
  %57 = load i32, ptr %13, align 4, !tbaa !10
  %58 = add nsw i32 %57, 1
  store i32 %58, ptr %13, align 4, !tbaa !10
  br label %20, !llvm.loop !12

59:                                               ; preds = %49, %24
  call void @llvm.lifetime.end.p0(i64 4, ptr %13) #2
  %60 = load i32, ptr %12, align 4
  switch i32 %60, label %65 [
    i32 5, label %61
  ]

61:                                               ; preds = %59
  br label %62

62:                                               ; preds = %61
  %63 = load i32, ptr %11, align 4, !tbaa !10
  %64 = add nsw i32 %63, 1
  store i32 %64, ptr %11, align 4, !tbaa !10
  br label %14, !llvm.loop !15

65:                                               ; preds = %59, %18
  call void @llvm.lifetime.end.p0(i64 4, ptr %11) #2
  %66 = load i32, ptr %12, align 4
  switch i32 %66, label %70 [
    i32 2, label %67
    i32 8, label %68
  ]

67:                                               ; preds = %65
  br label %68

68:                                               ; preds = %67, %65
  %69 = load i32, ptr %10, align 4, !tbaa !10
  store i32 %69, ptr %5, align 4
  store i32 1, ptr %12, align 4
  br label %70

70:                                               ; preds = %68, %65
  call void @llvm.lifetime.end.p0(i64 4, ptr %10) #2
  %71 = load i32, ptr %5, align 4
  ret i32 %71
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define dso_local i32 @digits(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #2
  store i32 0, ptr %3, align 4, !tbaa !10
  br label %4

4:                                                ; preds = %9, %1
  %5 = load i32, ptr %3, align 4, !tbaa !10
  %6 = add nsw i32 %5, 1
  store i32 %6, ptr %3, align 4, !tbaa !10
  %7 = load i32, ptr %2, align 4, !tbaa !10
  %8 = udiv i32 %7, 10
  store i32 %8, ptr %2, align 4, !tbaa !10
  br label %9

9:                                                ; preds = %4
  %10 = load i32, ptr %2, align 4, !tbaa !10
  %11 = icmp ne i32 %10, 0
  br i1 %11, label %4, label %12, !llvm.loop !16

12:                                               ; preds = %9
  %13 = load i32, ptr %3, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #2
  ret i32 %13
}

; Function Attrs: nounwind uwtable
define dso_local i32 @falls_through(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %3) #2
  store i32 0, ptr %3, align 4, !tbaa !10
  %4 = load i32, ptr %2, align 4, !tbaa !10
  switch i32 %4, label %15 [
    i32 3, label %5
    i32 2, label %8
    i32 1, label %11
    i32 9, label %14
  ]

5:                                                ; preds = %1
  %6 = load i32, ptr %3, align 4, !tbaa !10
  %7 = add nsw i32 %6, 8
  store i32 %7, ptr %3, align 4, !tbaa !10
  br label %8

8:                                                ; preds = %1, %5
  %9 = load i32, ptr %3, align 4, !tbaa !10
  %10 = add nsw i32 %9, 4
  store i32 %10, ptr %3, align 4, !tbaa !10
  br label %11

11:                                               ; preds = %1, %8
  %12 = load i32, ptr %3, align 4, !tbaa !10
  %13 = add nsw i32 %12, 2
  store i32 %13, ptr %3, align 4, !tbaa !10
  br label %16

14:                                               ; preds = %1
  store i32 99, ptr %3, align 4, !tbaa !10
  br label %16

15:                                               ; preds = %1
  store i32 -1, ptr %3, align 4, !tbaa !10
  br label %16

16:                                               ; preds = %15, %14, %11
  %17 = load i32, ptr %3, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %3) #2
  ret i32 %17
}

; Function Attrs: nounwind uwtable
define dso_local i32 @two_exits(ptr noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store ptr %0, ptr %5, align 8, !tbaa !5
  store i32 %1, ptr %6, align 4, !tbaa !10
  store i32 %2, ptr %7, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %8) #2
  store i32 0, ptr %8, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %9) #2
  store i32 0, ptr %9, align 4, !tbaa !10
  br label %11

11:                                               ; preds = %31, %3
  %12 = load i32, ptr %9, align 4, !tbaa !10
  %13 = load i32, ptr %6, align 4, !tbaa !10
  %14 = icmp slt i32 %12, %13
  br i1 %14, label %16, label %15

15:                                               ; preds = %11
  store i32 2, ptr %10, align 4
  br label %34

16:                                               ; preds = %11
  %17 = load ptr, ptr %5, align 8, !tbaa !5
  %18 = load i32, ptr %9, align 4, !tbaa !10
  %19 = sext i32 %18 to i64
  %20 = getelementptr inbounds i32, ptr %17, i64 %19
  %21 = load i32, ptr %20, align 4, !tbaa !10
  %22 = load i32, ptr %8, align 4, !tbaa !10
  %23 = add nsw i32 %22, %21
  store i32 %23, ptr %8, align 4, !tbaa !10
  %24 = load i32, ptr %8, align 4, !tbaa !10
  %25 = load i32, ptr %7, align 4, !tbaa !10
  %26 = icmp sgt i32 %24, %25
  br i1 %26, label %27, label %30

27:                                               ; preds = %16
  %28 = load i32, ptr %8, align 4, !tbaa !10
  %29 = sub nsw i32 0, %28
  store i32 %29, ptr %4, align 4
  store i32 1, ptr %10, align 4
  br label %34

30:                                               ; preds = %16
  br label %31

31:                                               ; preds = %30
  %32 = load i32, ptr %9, align 4, !tbaa !10
  %33 = add nsw i32 %32, 1
  store i32 %33, ptr %9, align 4, !tbaa !10
  br label %11, !llvm.loop !17

34:                                               ; preds = %27, %15
  call void @llvm.lifetime.end.p0(i64 4, ptr %9) #2
  %35 = load i32, ptr %10, align 4
  switch i32 %35, label %38 [
    i32 2, label %36
  ]

36:                                               ; preds = %34
  %37 = load i32, ptr %8, align 4, !tbaa !10
  store i32 %37, ptr %4, align 4
  store i32 1, ptr %10, align 4
  br label %38

38:                                               ; preds = %36, %34
  call void @llvm.lifetime.end.p0(i64 4, ptr %8) #2
  %39 = load i32, ptr %4, align 4
  ret i32 %39
}

; Function Attrs: nounwind uwtable
define dso_local i32 @nested_while(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !10
  store i32 %1, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #2
  store i32 0, ptr %5, align 4, !tbaa !10
  br label %7

7:                                                ; preds = %25, %2
  %8 = load i32, ptr %3, align 4, !tbaa !10
  %9 = icmp sgt i32 %8, 0
  br i1 %9, label %10, label %28

10:                                               ; preds = %7
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #2
  %11 = load i32, ptr %4, align 4, !tbaa !10
  store i32 %11, ptr %6, align 4, !tbaa !10
  br label %12

12:                                               ; preds = %20, %10
  %13 = load i32, ptr %6, align 4, !tbaa !10
  %14 = icmp sgt i32 %13, 0
  br i1 %14, label %15, label %25

15:                                               ; preds = %12
  %16 = load i32, ptr %6, align 4, !tbaa !10
  %17 = load i32, ptr %3, align 4, !tbaa !10
  %18 = icmp eq i32 %16, %17
  br i1 %18, label %19, label %20

19:                                               ; preds = %15
  br label %25

20:                                               ; preds = %15
  %21 = load i32, ptr %6, align 4, !tbaa !10
  %22 = add nsw i32 %21, -1
  store i32 %22, ptr %6, align 4, !tbaa !10
  %23 = load i32, ptr %5, align 4, !tbaa !10
  %24 = add nsw i32 %23, 1
  store i32 %24, ptr %5, align 4, !tbaa !10
  br label %12, !llvm.loop !18

25:                                               ; preds = %19, %12
  %26 = load i32, ptr %3, align 4, !tbaa !10
  %27 = add nsw i32 %26, -1
  store i32 %27, ptr %3, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #2
  br label %7, !llvm.loop !19

28:                                               ; preds = %7
  %29 = load i32, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  ret i32 %29
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
