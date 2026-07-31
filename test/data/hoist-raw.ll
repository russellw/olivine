; ModuleID = 'test/c/hoist.c'
source_filename = "test/c/hoist.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@scale = internal global i32 3, align 4

; Function Attrs: nounwind uwtable
define dso_local i32 @scaled_sum(ptr noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %4, align 8, !tbaa !5
  store i32 %1, ptr %5, align 4, !tbaa !10
  store i32 %2, ptr %6, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #2
  store i32 0, ptr %7, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %8) #2
  store i32 0, ptr %8, align 4, !tbaa !10
  br label %9

9:                                                ; preds = %27, %3
  %10 = load i32, ptr %8, align 4, !tbaa !10
  %11 = load i32, ptr %5, align 4, !tbaa !10
  %12 = icmp slt i32 %10, %11
  br i1 %12, label %14, label %13

13:                                               ; preds = %9
  call void @llvm.lifetime.end.p0(i64 4, ptr %8) #2
  br label %30

14:                                               ; preds = %9
  %15 = load ptr, ptr %4, align 8, !tbaa !5
  %16 = load i32, ptr %8, align 4, !tbaa !10
  %17 = sext i32 %16 to i64
  %18 = getelementptr inbounds i32, ptr %15, i64 %17
  %19 = load i32, ptr %18, align 4, !tbaa !10
  %20 = load i32, ptr %6, align 4, !tbaa !10
  %21 = load i32, ptr %6, align 4, !tbaa !10
  %22 = mul nsw i32 %20, %21
  %23 = add nsw i32 %22, 3
  %24 = mul nsw i32 %19, %23
  %25 = load i32, ptr %7, align 4, !tbaa !10
  %26 = add nsw i32 %25, %24
  store i32 %26, ptr %7, align 4, !tbaa !10
  br label %27

27:                                               ; preds = %14
  %28 = load i32, ptr %8, align 4, !tbaa !10
  %29 = add nsw i32 %28, 1
  store i32 %29, ptr %8, align 4, !tbaa !10
  br label %9, !llvm.loop !12

30:                                               ; preds = %13
  %31 = load i32, ptr %7, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #2
  ret i32 %31
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define dso_local i32 @nested_squares(i32 noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i32, align 4
  store i32 %0, ptr %4, align 4, !tbaa !10
  store i32 %1, ptr %5, align 4, !tbaa !10
  store i32 %2, ptr %6, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #2
  store i32 0, ptr %7, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %8) #2
  store i32 0, ptr %8, align 4, !tbaa !10
  br label %11

11:                                               ; preds = %35, %3
  %12 = load i32, ptr %8, align 4, !tbaa !10
  %13 = load i32, ptr %6, align 4, !tbaa !10
  %14 = icmp slt i32 %12, %13
  br i1 %14, label %16, label %15

15:                                               ; preds = %11
  store i32 2, ptr %9, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr %8) #2
  br label %38

16:                                               ; preds = %11
  call void @llvm.lifetime.start.p0(i64 4, ptr %10) #2
  store i32 0, ptr %10, align 4, !tbaa !10
  br label %17

17:                                               ; preds = %31, %16
  %18 = load i32, ptr %10, align 4, !tbaa !10
  %19 = load i32, ptr %6, align 4, !tbaa !10
  %20 = icmp slt i32 %18, %19
  br i1 %20, label %22, label %21

21:                                               ; preds = %17
  store i32 5, ptr %9, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr %10) #2
  br label %34

22:                                               ; preds = %17
  %23 = load i32, ptr %4, align 4, !tbaa !10
  %24 = shl i32 %23, 2
  %25 = load i32, ptr %5, align 4, !tbaa !10
  %26 = load i32, ptr %4, align 4, !tbaa !10
  %27 = xor i32 %25, %26
  %28 = add nsw i32 %24, %27
  %29 = load i32, ptr %7, align 4, !tbaa !10
  %30 = add nsw i32 %29, %28
  store i32 %30, ptr %7, align 4, !tbaa !10
  br label %31

31:                                               ; preds = %22
  %32 = load i32, ptr %10, align 4, !tbaa !10
  %33 = add nsw i32 %32, 1
  store i32 %33, ptr %10, align 4, !tbaa !10
  br label %17, !llvm.loop !15

34:                                               ; preds = %21
  br label %35

35:                                               ; preds = %34
  %36 = load i32, ptr %8, align 4, !tbaa !10
  %37 = add nsw i32 %36, 1
  store i32 %37, ptr %8, align 4, !tbaa !10
  br label %11, !llvm.loop !16

38:                                               ; preds = %15
  %39 = load i32, ptr %7, align 4, !tbaa !10
  store i32 1, ptr %9, align 4
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #2
  ret i32 %39
}

; Function Attrs: nounwind uwtable
define dso_local i32 @sometimes(ptr noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store ptr %0, ptr %4, align 8, !tbaa !5
  store i32 %1, ptr %5, align 4, !tbaa !10
  store i32 %2, ptr %6, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #2
  store i32 0, ptr %7, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %8) #2
  store i32 0, ptr %8, align 4, !tbaa !10
  br label %9

9:                                                ; preds = %28, %3
  %10 = load i32, ptr %8, align 4, !tbaa !10
  %11 = load i32, ptr %5, align 4, !tbaa !10
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
  %20 = icmp sgt i32 %19, 0
  br i1 %20, label %21, label %27

21:                                               ; preds = %14
  %22 = load i32, ptr %6, align 4, !tbaa !10
  %23 = load i32, ptr %6, align 4, !tbaa !10
  %24 = mul nsw i32 %22, %23
  %25 = load i32, ptr %7, align 4, !tbaa !10
  %26 = add nsw i32 %25, %24
  store i32 %26, ptr %7, align 4, !tbaa !10
  br label %27

27:                                               ; preds = %21, %14
  br label %28

28:                                               ; preds = %27
  %29 = load i32, ptr %8, align 4, !tbaa !10
  %30 = add nsw i32 %29, 1
  store i32 %30, ptr %8, align 4, !tbaa !10
  br label %9, !llvm.loop !17

31:                                               ; preds = %13
  %32 = load i32, ptr %7, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #2
  ret i32 %32
}

; Function Attrs: nounwind uwtable
define dso_local i32 @guarded_divide(i32 noundef %0, i32 noundef %1, i32 noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store i32 %0, ptr %4, align 4, !tbaa !10
  store i32 %1, ptr %5, align 4, !tbaa !10
  store i32 %2, ptr %6, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #2
  store i32 0, ptr %7, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %8) #2
  store i32 0, ptr %8, align 4, !tbaa !10
  br label %9

9:                                                ; preds = %20, %3
  %10 = load i32, ptr %8, align 4, !tbaa !10
  %11 = load i32, ptr %6, align 4, !tbaa !10
  %12 = icmp slt i32 %10, %11
  br i1 %12, label %14, label %13

13:                                               ; preds = %9
  call void @llvm.lifetime.end.p0(i64 4, ptr %8) #2
  br label %23

14:                                               ; preds = %9
  %15 = load i32, ptr %4, align 4, !tbaa !10
  %16 = load i32, ptr %5, align 4, !tbaa !10
  %17 = sdiv i32 %15, %16
  %18 = load i32, ptr %7, align 4, !tbaa !10
  %19 = add nsw i32 %18, %17
  store i32 %19, ptr %7, align 4, !tbaa !10
  br label %20

20:                                               ; preds = %14
  %21 = load i32, ptr %8, align 4, !tbaa !10
  %22 = add nsw i32 %21, 1
  store i32 %22, ptr %8, align 4, !tbaa !10
  br label %9, !llvm.loop !18

23:                                               ; preds = %13
  %24 = load i32, ptr %7, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #2
  ret i32 %24
}

; Function Attrs: nounwind uwtable
define dso_local i32 @carried_first(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !10
  store i32 %1, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #2
  store i32 0, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #2
  store i32 0, ptr %6, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #2
  store i32 0, ptr %7, align 4, !tbaa !10
  br label %8

8:                                                ; preds = %19, %2
  %9 = load i32, ptr %7, align 4, !tbaa !10
  %10 = load i32, ptr %3, align 4, !tbaa !10
  %11 = icmp slt i32 %9, %10
  br i1 %11, label %13, label %12

12:                                               ; preds = %8
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #2
  br label %22

13:                                               ; preds = %8
  %14 = load i32, ptr %6, align 4, !tbaa !10
  %15 = load i32, ptr %5, align 4, !tbaa !10
  %16 = add nsw i32 %15, %14
  store i32 %16, ptr %5, align 4, !tbaa !10
  %17 = load i32, ptr %4, align 4, !tbaa !10
  %18 = add nsw i32 %17, 1
  store i32 %18, ptr %6, align 4, !tbaa !10
  br label %19

19:                                               ; preds = %13
  %20 = load i32, ptr %7, align 4, !tbaa !10
  %21 = add nsw i32 %20, 1
  store i32 %21, ptr %7, align 4, !tbaa !10
  br label %8, !llvm.loop !19

22:                                               ; preds = %12
  %23 = load i32, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #2
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  ret i32 %23
}

; Function Attrs: nounwind uwtable
define dso_local i32 @scale_now() #0 {
  %1 = load i32, ptr @scale, align 4, !tbaa !10
  ret i32 %1
}

; Function Attrs: nounwind uwtable
define dso_local void @set_scale(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !10
  %3 = load i32, ptr %2, align 4, !tbaa !10
  store i32 %3, ptr @scale, align 4, !tbaa !10
  ret void
}

; Function Attrs: nounwind uwtable
define dso_local i32 @scaled_by_symbol(ptr noundef %0, i32 noundef %1) #0 {
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

7:                                                ; preds = %22, %2
  %8 = load i32, ptr %6, align 4, !tbaa !10
  %9 = load i32, ptr %4, align 4, !tbaa !10
  %10 = icmp slt i32 %8, %9
  br i1 %10, label %12, label %11

11:                                               ; preds = %7
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #2
  br label %25

12:                                               ; preds = %7
  %13 = load ptr, ptr %3, align 8, !tbaa !5
  %14 = load i32, ptr %6, align 4, !tbaa !10
  %15 = sext i32 %14 to i64
  %16 = getelementptr inbounds i32, ptr %13, i64 %15
  %17 = load i32, ptr %16, align 4, !tbaa !10
  %18 = load i32, ptr @scale, align 4, !tbaa !10
  %19 = mul nsw i32 %17, %18
  %20 = load i32, ptr %5, align 4, !tbaa !10
  %21 = add nsw i32 %20, %19
  store i32 %21, ptr %5, align 4, !tbaa !10
  br label %22

22:                                               ; preds = %12
  %23 = load i32, ptr %6, align 4, !tbaa !10
  %24 = add nsw i32 %23, 1
  store i32 %24, ptr %6, align 4, !tbaa !10
  br label %7, !llvm.loop !20

25:                                               ; preds = %11
  %26 = load i32, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  ret i32 %26
}

; Function Attrs: nounwind uwtable
define dso_local i32 @bumping(ptr noundef %0, i32 noundef %1) #0 {
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

7:                                                ; preds = %19, %2
  %8 = load i32, ptr %6, align 4, !tbaa !10
  %9 = load i32, ptr %4, align 4, !tbaa !10
  %10 = icmp slt i32 %8, %9
  br i1 %10, label %12, label %11

11:                                               ; preds = %7
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #2
  br label %22

12:                                               ; preds = %7
  %13 = load i32, ptr @scale, align 4, !tbaa !10
  %14 = load i32, ptr %5, align 4, !tbaa !10
  %15 = add nsw i32 %14, %13
  store i32 %15, ptr %5, align 4, !tbaa !10
  %16 = load ptr, ptr %3, align 8, !tbaa !5
  %17 = load i32, ptr %16, align 4, !tbaa !10
  %18 = add nsw i32 %17, 1
  store i32 %18, ptr %16, align 4, !tbaa !10
  br label %19

19:                                               ; preds = %12
  %20 = load i32, ptr %6, align 4, !tbaa !10
  %21 = add nsw i32 %20, 1
  store i32 %21, ptr %6, align 4, !tbaa !10
  br label %7, !llvm.loop !21

22:                                               ; preds = %11
  %23 = load i32, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  ret i32 %23
}

; Function Attrs: nounwind uwtable
define dso_local i32 @bumping_symbol(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !10
  %3 = load i32, ptr %2, align 4, !tbaa !10
  %4 = call i32 @bumping(ptr noundef @scale, i32 noundef %3)
  ret i32 %4
}

; Function Attrs: nounwind uwtable
define dso_local i32 @jumped_into(i32 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !10
  store i32 %1, ptr %4, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #2
  store i32 0, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #2
  store i32 0, ptr %6, align 4, !tbaa !10
  %7 = load i32, ptr %3, align 4, !tbaa !10
  %8 = and i32 %7, 1
  %9 = icmp ne i32 %8, 0
  br i1 %9, label %10, label %11

10:                                               ; preds = %2
  br label %21

11:                                               ; preds = %2
  br label %12

12:                                               ; preds = %21, %11
  %13 = load i32, ptr %6, align 4, !tbaa !10
  %14 = load i32, ptr %3, align 4, !tbaa !10
  %15 = icmp slt i32 %13, %14
  br i1 %15, label %16, label %24

16:                                               ; preds = %12
  %17 = load i32, ptr %4, align 4, !tbaa !10
  %18 = mul nsw i32 %17, 5
  %19 = load i32, ptr %5, align 4, !tbaa !10
  %20 = add nsw i32 %19, %18
  store i32 %20, ptr %5, align 4, !tbaa !10
  br label %21

21:                                               ; preds = %16, %10
  %22 = load i32, ptr %6, align 4, !tbaa !10
  %23 = add nsw i32 %22, 1
  store i32 %23, ptr %6, align 4, !tbaa !10
  br label %12, !llvm.loop !22

24:                                               ; preds = %12
  %25 = load i32, ptr %5, align 4, !tbaa !10
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #2
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #2
  ret i32 %25
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
