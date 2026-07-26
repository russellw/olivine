; ModuleID = 'test/c/loop.c'
source_filename = "test/c/loop.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @sum(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %28

4:                                                ; preds = %2
  %5 = zext nneg i32 %1 to i64
  %6 = icmp ult i32 %1, 8
  br i1 %6, label %25, label %7

7:                                                ; preds = %4
  %8 = and i64 %5, 2147483640
  br label %9

9:                                                ; preds = %9, %7
  %10 = phi i64 [ 0, %7 ], [ %19, %9 ]
  %11 = phi <4 x i32> [ zeroinitializer, %7 ], [ %17, %9 ]
  %12 = phi <4 x i32> [ zeroinitializer, %7 ], [ %18, %9 ]
  %13 = getelementptr inbounds nuw i32, ptr %0, i64 %10
  %14 = getelementptr inbounds nuw i8, ptr %13, i64 16
  %15 = load <4 x i32>, ptr %13, align 4, !tbaa !5
  %16 = load <4 x i32>, ptr %14, align 4, !tbaa !5
  %17 = add <4 x i32> %15, %11
  %18 = add <4 x i32> %16, %12
  %19 = add nuw i64 %10, 8
  %20 = icmp eq i64 %19, %8
  br i1 %20, label %21, label %9, !llvm.loop !9

21:                                               ; preds = %9
  %22 = add <4 x i32> %18, %17
  %23 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %22)
  %24 = icmp eq i64 %8, %5
  br i1 %24, label %28, label %25

25:                                               ; preds = %4, %21
  %26 = phi i64 [ 0, %4 ], [ %8, %21 ]
  %27 = phi i32 [ 0, %4 ], [ %23, %21 ]
  br label %30

28:                                               ; preds = %30, %21, %2
  %29 = phi i32 [ 0, %2 ], [ %23, %21 ], [ %35, %30 ]
  ret i32 %29

30:                                               ; preds = %25, %30
  %31 = phi i64 [ %36, %30 ], [ %26, %25 ]
  %32 = phi i32 [ %35, %30 ], [ %27, %25 ]
  %33 = getelementptr inbounds nuw i32, ptr %0, i64 %31
  %34 = load i32, ptr %33, align 4, !tbaa !5
  %35 = add nsw i32 %34, %32
  %36 = add nuw nsw i64 %31, 1
  %37 = icmp eq i64 %36, %5
  br i1 %37, label %28, label %30, !llvm.loop !13
}

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local i32 @count_down(i32 noundef %0) local_unnamed_addr #1 {
  %2 = icmp sgt i32 %0, 1
  br i1 %2, label %3, label %14

3:                                                ; preds = %1, %3
  %4 = phi i32 [ %11, %3 ], [ 0, %1 ]
  %5 = phi i32 [ %12, %3 ], [ %0, %1 ]
  %6 = and i32 %5, 1
  %7 = icmp eq i32 %6, 0
  %8 = lshr exact i32 %5, 1
  %9 = mul nuw nsw i32 %5, 3
  %10 = add nuw nsw i32 %9, 1
  %11 = add nuw nsw i32 %4, 1
  %12 = select i1 %7, i32 %8, i32 %10
  %13 = icmp samesign ugt i32 %12, 1
  br i1 %13, label %3, label %14

14:                                               ; preds = %3, %1
  %15 = phi i32 [ 0, %1 ], [ %11, %3 ]
  ret i32 %15
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: write) uwtable
define dso_local void @fill(ptr noundef writeonly captures(none) %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #2 {
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %22

5:                                                ; preds = %3
  %6 = zext nneg i32 %1 to i64
  %7 = icmp ult i32 %1, 8
  br i1 %7, label %20, label %8

8:                                                ; preds = %5
  %9 = and i64 %6, 2147483640
  %10 = insertelement <4 x i32> poison, i32 %2, i64 0
  %11 = shufflevector <4 x i32> %10, <4 x i32> poison, <4 x i32> zeroinitializer
  br label %12

12:                                               ; preds = %12, %8
  %13 = phi i64 [ 0, %8 ], [ %16, %12 ]
  %14 = getelementptr inbounds nuw i32, ptr %0, i64 %13
  %15 = getelementptr inbounds nuw i8, ptr %14, i64 16
  store <4 x i32> %11, ptr %14, align 4, !tbaa !5
  store <4 x i32> %11, ptr %15, align 4, !tbaa !5
  %16 = add nuw i64 %13, 8
  %17 = icmp eq i64 %16, %9
  br i1 %17, label %18, label %12, !llvm.loop !14

18:                                               ; preds = %12
  %19 = icmp eq i64 %9, %6
  br i1 %19, label %22, label %20

20:                                               ; preds = %5, %18
  %21 = phi i64 [ 0, %5 ], [ %9, %18 ]
  br label %23

22:                                               ; preds = %23, %18, %3
  ret void

23:                                               ; preds = %20, %23
  %24 = phi i64 [ %26, %23 ], [ %21, %20 ]
  %25 = getelementptr inbounds nuw i32, ptr %0, i64 %24
  store i32 %2, ptr %25, align 4, !tbaa !5
  %26 = add nuw nsw i64 %24, 1
  %27 = icmp eq i64 %26, %6
  br i1 %27, label %22, label %23, !llvm.loop !15
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.vector.reduce.add.v4i32(<4 x i32>) #3

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree norecurse nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree norecurse nosync nounwind memory(argmem: write) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
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
