; ModuleID = 'test/c/hoist.c'
source_filename = "test/c/hoist.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @scaled_sum(ptr noundef readonly captures(none) %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %35

5:                                                ; preds = %3
  %6 = mul nsw i32 %2, %2
  %7 = add nuw nsw i32 %6, 3
  %8 = zext nneg i32 %1 to i64
  %9 = icmp ult i32 %1, 8
  br i1 %9, label %32, label %10

10:                                               ; preds = %5
  %11 = and i64 %8, 2147483640
  %12 = insertelement <4 x i32> poison, i32 %7, i64 0
  %13 = shufflevector <4 x i32> %12, <4 x i32> poison, <4 x i32> zeroinitializer
  br label %14

14:                                               ; preds = %14, %10
  %15 = phi i64 [ 0, %10 ], [ %26, %14 ]
  %16 = phi <4 x i32> [ zeroinitializer, %10 ], [ %24, %14 ]
  %17 = phi <4 x i32> [ zeroinitializer, %10 ], [ %25, %14 ]
  %18 = getelementptr inbounds nuw i32, ptr %0, i64 %15
  %19 = getelementptr inbounds nuw i8, ptr %18, i64 16
  %20 = load <4 x i32>, ptr %18, align 4, !tbaa !5
  %21 = load <4 x i32>, ptr %19, align 4, !tbaa !5
  %22 = mul nsw <4 x i32> %20, %13
  %23 = mul nsw <4 x i32> %21, %13
  %24 = add <4 x i32> %22, %16
  %25 = add <4 x i32> %23, %17
  %26 = add nuw i64 %15, 8
  %27 = icmp eq i64 %26, %11
  br i1 %27, label %28, label %14, !llvm.loop !9

28:                                               ; preds = %14
  %29 = add <4 x i32> %25, %24
  %30 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %29)
  %31 = icmp eq i64 %11, %8
  br i1 %31, label %35, label %32

32:                                               ; preds = %5, %28
  %33 = phi i64 [ 0, %5 ], [ %11, %28 ]
  %34 = phi i32 [ 0, %5 ], [ %30, %28 ]
  br label %37

35:                                               ; preds = %37, %28, %3
  %36 = phi i32 [ 0, %3 ], [ %30, %28 ], [ %43, %37 ]
  ret i32 %36

37:                                               ; preds = %32, %37
  %38 = phi i64 [ %44, %37 ], [ %33, %32 ]
  %39 = phi i32 [ %43, %37 ], [ %34, %32 ]
  %40 = getelementptr inbounds nuw i32, ptr %0, i64 %38
  %41 = load i32, ptr %40, align 4, !tbaa !5
  %42 = mul nsw i32 %41, %7
  %43 = add nsw i32 %42, %39
  %44 = add nuw nsw i64 %38, 1
  %45 = icmp eq i64 %44, %8
  br i1 %45, label %35, label %37, !llvm.loop !13
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @nested_squares(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = icmp sgt i32 %2, 0
  br i1 %4, label %5, label %18

5:                                                ; preds = %3
  %6 = shl i32 %0, 2
  %7 = xor i32 %1, %0
  %8 = add i32 %7, %6
  %9 = add nsw i32 %2, -1
  %10 = mul i32 %8, %9
  %11 = shl i32 %0, 3
  %12 = add i32 %10, %11
  %13 = shl i32 %7, 1
  %14 = add i32 %12, %13
  %15 = mul i32 %14, %9
  %16 = add i32 %7, %15
  %17 = add i32 %16, %6
  br label %18

18:                                               ; preds = %5, %3
  %19 = phi i32 [ 0, %3 ], [ %17, %5 ]
  ret i32 %19
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @sometimes(ptr noundef readonly captures(none) %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %36

5:                                                ; preds = %3
  %6 = mul nsw i32 %2, %2
  %7 = zext nneg i32 %1 to i64
  %8 = icmp ult i32 %1, 8
  br i1 %8, label %33, label %9

9:                                                ; preds = %5
  %10 = and i64 %7, 2147483640
  %11 = insertelement <4 x i32> poison, i32 %6, i64 0
  %12 = shufflevector <4 x i32> %11, <4 x i32> poison, <4 x i32> zeroinitializer
  br label %13

13:                                               ; preds = %13, %9
  %14 = phi i64 [ 0, %9 ], [ %27, %13 ]
  %15 = phi <4 x i32> [ zeroinitializer, %9 ], [ %25, %13 ]
  %16 = phi <4 x i32> [ zeroinitializer, %9 ], [ %26, %13 ]
  %17 = getelementptr inbounds nuw i32, ptr %0, i64 %14
  %18 = getelementptr inbounds nuw i8, ptr %17, i64 16
  %19 = load <4 x i32>, ptr %17, align 4, !tbaa !5
  %20 = load <4 x i32>, ptr %18, align 4, !tbaa !5
  %21 = icmp sgt <4 x i32> %19, zeroinitializer
  %22 = icmp sgt <4 x i32> %20, zeroinitializer
  %23 = select <4 x i1> %21, <4 x i32> %12, <4 x i32> zeroinitializer
  %24 = select <4 x i1> %22, <4 x i32> %12, <4 x i32> zeroinitializer
  %25 = add <4 x i32> %23, %15
  %26 = add <4 x i32> %24, %16
  %27 = add nuw i64 %14, 8
  %28 = icmp eq i64 %27, %10
  br i1 %28, label %29, label %13, !llvm.loop !14

29:                                               ; preds = %13
  %30 = add <4 x i32> %26, %25
  %31 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %30)
  %32 = icmp eq i64 %10, %7
  br i1 %32, label %36, label %33

33:                                               ; preds = %5, %29
  %34 = phi i64 [ 0, %5 ], [ %10, %29 ]
  %35 = phi i32 [ 0, %5 ], [ %31, %29 ]
  br label %38

36:                                               ; preds = %38, %29, %3
  %37 = phi i32 [ 0, %3 ], [ %31, %29 ], [ %45, %38 ]
  ret i32 %37

38:                                               ; preds = %33, %38
  %39 = phi i64 [ %46, %38 ], [ %34, %33 ]
  %40 = phi i32 [ %45, %38 ], [ %35, %33 ]
  %41 = getelementptr inbounds nuw i32, ptr %0, i64 %39
  %42 = load i32, ptr %41, align 4, !tbaa !5
  %43 = icmp sgt i32 %42, 0
  %44 = select i1 %43, i32 %6, i32 0
  %45 = add nuw nsw i32 %44, %40
  %46 = add nuw nsw i64 %39, 1
  %47 = icmp eq i64 %46, %7
  br i1 %47, label %36, label %38, !llvm.loop !15
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef i32 @guarded_divide(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = icmp sgt i32 %2, 0
  br i1 %4, label %5, label %8

5:                                                ; preds = %3
  %6 = sdiv i32 %0, %1
  %7 = mul i32 %6, %2
  br label %8

8:                                                ; preds = %5, %3
  %9 = phi i32 [ 0, %3 ], [ %7, %5 ]
  ret i32 %9
}

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local i32 @carried_first(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = icmp sgt i32 %0, 0
  br i1 %3, label %4, label %30

4:                                                ; preds = %2
  %5 = add nsw i32 %1, 1
  %6 = icmp eq i32 %0, 1
  br i1 %6, label %30, label %7

7:                                                ; preds = %4
  %8 = add nsw i32 %0, -1
  %9 = icmp ult i32 %0, 9
  br i1 %9, label %27, label %10

10:                                               ; preds = %7
  %11 = and i32 %8, -8
  %12 = or disjoint i32 %11, 1
  %13 = insertelement <4 x i32> poison, i32 %5, i64 0
  %14 = shufflevector <4 x i32> %13, <4 x i32> poison, <4 x i32> zeroinitializer
  br label %15

15:                                               ; preds = %15, %10
  %16 = phi i32 [ 0, %10 ], [ %21, %15 ]
  %17 = phi <4 x i32> [ zeroinitializer, %10 ], [ %19, %15 ]
  %18 = phi <4 x i32> [ zeroinitializer, %10 ], [ %20, %15 ]
  %19 = add <4 x i32> %14, %17
  %20 = add <4 x i32> %14, %18
  %21 = add nuw i32 %16, 8
  %22 = icmp eq i32 %21, %11
  br i1 %22, label %23, label %15, !llvm.loop !16

23:                                               ; preds = %15
  %24 = add <4 x i32> %20, %19
  %25 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %24)
  %26 = icmp eq i32 %8, %11
  br i1 %26, label %30, label %27

27:                                               ; preds = %7, %23
  %28 = phi i32 [ 1, %7 ], [ %12, %23 ]
  %29 = phi i32 [ 0, %7 ], [ %25, %23 ]
  br label %32

30:                                               ; preds = %32, %23, %4, %2
  %31 = phi i32 [ 0, %2 ], [ 0, %4 ], [ %25, %23 ], [ %35, %32 ]
  ret i32 %31

32:                                               ; preds = %27, %32
  %33 = phi i32 [ %36, %32 ], [ %28, %27 ]
  %34 = phi i32 [ %35, %32 ], [ %29, %27 ]
  %35 = add nsw i32 %5, %34
  %36 = add nuw nsw i32 %33, 1
  %37 = icmp eq i32 %36, %0
  br i1 %37, label %30, label %32, !llvm.loop !18
}

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local i32 @jumped_into(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = and i32 %0, 1
  %4 = mul nsw i32 %1, 5
  br label %5, !llvm.loop !19

5:                                                ; preds = %2, %9
  %6 = phi i32 [ %10, %9 ], [ 0, %2 ]
  %7 = phi i32 [ %11, %9 ], [ %3, %2 ]
  %8 = icmp slt i32 %7, %0
  br i1 %8, label %9, label %12

9:                                                ; preds = %5
  %10 = add nsw i32 %6, %4
  %11 = add nuw nsw i32 %7, 1
  br label %5, !llvm.loop !19

12:                                               ; preds = %5
  ret i32 %6
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.vector.reduce.add.v4i32(<4 x i32>) #3

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree norecurse nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

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
!9 = distinct !{!9, !10, !11, !12}
!10 = !{!"llvm.loop.mustprogress"}
!11 = !{!"llvm.loop.isvectorized", i32 1}
!12 = !{!"llvm.loop.unroll.runtime.disable"}
!13 = distinct !{!13, !10, !12, !11}
!14 = distinct !{!14, !10, !11, !12}
!15 = distinct !{!15, !10, !12, !11}
!16 = distinct !{!16, !10, !17, !11, !12}
!17 = !{!"llvm.loop.peeled.count", i32 1}
!18 = distinct !{!18, !10, !17, !12, !11}
!19 = distinct !{!19, !10}
