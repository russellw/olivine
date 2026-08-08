; ModuleID = 'test/c/jumps.c'
source_filename = "test/c/jumps.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@thread_ops.ops = internal unnamed_addr constant [3 x ptr] [ptr blockaddress(@thread_ops, %4), ptr blockaddress(@thread_ops, %17), ptr blockaddress(@thread_ops, %21)], align 16
@switch.table.falls_through = private unnamed_addr constant [9 x i32] [i32 2, i32 6, i32 14, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 99], align 4
@switch.table.scattered = private unnamed_addr constant [4 x i32] [i32 4, i32 9, i32 2, i32 7], align 4
@switch.table.sparse = private unnamed_addr constant [4 x i32] [i32 2, i32 4, i32 0, i32 8], align 4

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @search(ptr noundef readonly captures(none) %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = icmp sgt i32 %2, 0
  br i1 %5, label %6, label %35

6:                                                ; preds = %4
  %7 = icmp sgt i32 %1, 0
  %8 = sext i32 %1 to i64
  %9 = zext nneg i32 %2 to i64
  %10 = zext nneg i32 %1 to i64
  br label %11

11:                                               ; preds = %29, %6
  %12 = phi i64 [ 0, %6 ], [ %32, %29 ]
  %13 = phi i32 [ -1, %6 ], [ %31, %29 ]
  br i1 %7, label %14, label %29

14:                                               ; preds = %11
  %15 = mul nuw nsw i64 %12, %8
  br label %19

16:                                               ; preds = %19
  %17 = add nuw nsw i64 %20, 1
  %18 = icmp eq i64 %17, %10
  br i1 %18, label %29, label %19, !llvm.loop !5

19:                                               ; preds = %14, %16
  %20 = phi i64 [ 0, %14 ], [ %17, %16 ]
  %21 = add nuw nsw i64 %20, %15
  %22 = getelementptr inbounds nuw i32, ptr %0, i64 %21
  %23 = load i32, ptr %22, align 4, !tbaa !8
  %24 = icmp sgt i32 %23, -1
  %25 = icmp eq i32 %23, %3
  %26 = and i1 %24, %25
  br i1 %26, label %27, label %16

27:                                               ; preds = %19
  %28 = trunc nsw i64 %21 to i32
  br label %29

29:                                               ; preds = %27, %16, %11
  %30 = phi i1 [ false, %11 ], [ %26, %16 ], [ %26, %27 ]
  %31 = phi i32 [ %13, %11 ], [ %28, %27 ], [ %13, %16 ]
  %32 = add nuw nsw i64 %12, 1
  %33 = icmp eq i64 %32, %9
  %34 = select i1 %30, i1 true, i1 %33
  br i1 %34, label %35, label %11, !llvm.loop !12

35:                                               ; preds = %29, %4
  %36 = phi i32 [ -1, %4 ], [ %31, %29 ]
  ret i32 %36
}

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local range(i32 -2147483647, -2147483648) i32 @digits(i32 noundef %0) local_unnamed_addr #1 {
  br label %2

2:                                                ; preds = %2, %1
  %3 = phi i32 [ %0, %1 ], [ %6, %2 ]
  %4 = phi i32 [ 0, %1 ], [ %5, %2 ]
  %5 = add nuw nsw i32 %4, 1
  %6 = udiv i32 %3, 10
  %7 = icmp ult i32 %3, 10
  br i1 %7, label %8, label %2, !llvm.loop !13

8:                                                ; preds = %2
  ret i32 %5
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 -1, 100) i32 @falls_through(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add i32 %0, -1
  %3 = icmp ult i32 %2, 9
  br i1 %3, label %4, label %8

4:                                                ; preds = %1
  %5 = zext nneg i32 %2 to i64
  %6 = getelementptr inbounds nuw [9 x i32], ptr @switch.table.falls_through, i64 0, i64 %5
  %7 = load i32, ptr %6, align 4
  br label %8

8:                                                ; preds = %1, %4
  %9 = phi i32 [ %7, %4 ], [ -1, %1 ]
  ret i32 %9
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @two_exits(ptr noundef readonly captures(none) %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %19

5:                                                ; preds = %3
  %6 = zext nneg i32 %1 to i64
  br label %10

7:                                                ; preds = %10
  %8 = add nuw nsw i64 %11, 1
  %9 = icmp eq i64 %8, %6
  br i1 %9, label %19, label %10, !llvm.loop !14

10:                                               ; preds = %5, %7
  %11 = phi i64 [ 0, %5 ], [ %8, %7 ]
  %12 = phi i32 [ 0, %5 ], [ %15, %7 ]
  %13 = getelementptr inbounds nuw i32, ptr %0, i64 %11
  %14 = load i32, ptr %13, align 4, !tbaa !8
  %15 = add nsw i32 %14, %12
  %16 = icmp sgt i32 %15, %2
  br i1 %16, label %17, label %7

17:                                               ; preds = %10
  %18 = sub nsw i32 0, %15
  br label %19

19:                                               ; preds = %7, %3, %17
  %20 = phi i32 [ %18, %17 ], [ 0, %3 ], [ %15, %7 ]
  ret i32 %20
}

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local i32 @nested_while(i32 noundef %0, i32 noundef %1) local_unnamed_addr #1 {
  %3 = icmp sgt i32 %0, 0
  br i1 %3, label %4, label %21

4:                                                ; preds = %2
  %5 = icmp slt i32 %1, 1
  %6 = add i32 %1, -1
  %7 = sub i32 %6, %0
  br label %8

8:                                                ; preds = %4, %8
  %9 = phi i32 [ %7, %4 ], [ %20, %8 ]
  %10 = phi i32 [ 0, %4 ], [ %17, %8 ]
  %11 = phi i32 [ %0, %4 ], [ %18, %8 ]
  %12 = tail call i32 @llvm.umin.i32(i32 %9, i32 %6)
  %13 = icmp eq i32 %1, %11
  %14 = or i1 %5, %13
  %15 = add i32 %10, 1
  %16 = add i32 %15, %12
  %17 = select i1 %14, i32 %10, i32 %16
  %18 = add nsw i32 %11, -1
  %19 = icmp sgt i32 %11, 1
  %20 = add i32 %9, 1
  br i1 %19, label %8, label %21, !llvm.loop !15

21:                                               ; preds = %8, %2
  %22 = phi i32 [ 0, %2 ], [ %17, %8 ]
  ret i32 %22
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 0, 12) i32 @weight(i32 noundef %0) local_unnamed_addr #2 {
  %2 = icmp ult i32 %0, 5
  %3 = shl nsw i32 %0, 1
  %4 = add nsw i32 %3, 3
  %5 = select i1 %2, i32 %4, i32 0
  ret i32 %5
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 0, 2) i32 @in_season(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add i32 %0, -3
  %3 = icmp ult i32 %2, 4
  %4 = zext i1 %3 to i32
  ret i32 %4
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 -1, 41) i32 @step_down(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add i32 %0, -10
  %3 = icmp ult i32 %2, 4
  %4 = mul nsw i32 %2, -10
  %5 = add nsw i32 %4, 40
  %6 = select i1 %3, i32 %5, i32 -1
  ret i32 %6
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 -1, 10) i32 @scattered(i32 noundef %0) local_unnamed_addr #2 {
  %2 = icmp ult i32 %0, 4
  br i1 %2, label %3, label %7

3:                                                ; preds = %1
  %4 = zext nneg i32 %0 to i64
  %5 = getelementptr inbounds nuw [4 x i32], ptr @switch.table.scattered, i64 0, i64 %4
  %6 = load i32, ptr %5, align 4
  br label %7

7:                                                ; preds = %1, %3
  %8 = phi i32 [ %6, %3 ], [ -1, %1 ]
  ret i32 %8
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 0, 9) i32 @sparse(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add i32 %0, -1
  %3 = icmp ult i32 %2, 4
  br i1 %3, label %4, label %8

4:                                                ; preds = %1
  %5 = zext nneg i32 %2 to i64
  %6 = getelementptr inbounds nuw [4 x i32], ptr @switch.table.sparse, i64 0, i64 %5
  %7 = load i32, ptr %6, align 4
  br label %8

8:                                                ; preds = %1, %4
  %9 = phi i32 [ %7, %4 ], [ 0, %1 ]
  ret i32 %9
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 -2147483647, -2147483648) i32 @case_works(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  switch i32 %0, label %9 [
    i32 0, label %3
    i32 1, label %5
    i32 2, label %7
  ]

3:                                                ; preds = %2
  %4 = add nsw i32 %1, 1
  br label %9

5:                                                ; preds = %2
  %6 = add nsw i32 %1, 2
  br label %9

7:                                                ; preds = %2
  %8 = add nsw i32 %1, 3
  br label %9

9:                                                ; preds = %2, %7, %5, %3
  %10 = phi i32 [ %4, %3 ], [ %6, %5 ], [ %8, %7 ], [ 0, %2 ]
  ret i32 %10
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @thread_ops(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp slt i32 %1, 1
  br i1 %3, label %21, label %23

4:                                                ; preds = %23
  %5 = sext i32 %25 to i64
  %6 = getelementptr inbounds i8, ptr %0, i64 %5
  %7 = load i8, ptr %6, align 1, !tbaa !16
  %8 = zext i8 %7 to i32
  %9 = add nsw i32 %24, %8
  %10 = add nsw i32 %25, 1
  %11 = icmp slt i32 %10, %1
  br i1 %11, label %12, label %21

12:                                               ; preds = %17, %4
  %13 = phi i32 [ %9, %4 ], [ %18, %17 ]
  %14 = phi i32 [ %10, %4 ], [ %19, %17 ]
  %15 = sext i32 %14 to i64
  %16 = getelementptr inbounds i8, ptr %0, i64 %15
  br label %23

17:                                               ; preds = %23
  %18 = shl nsw i32 %24, 1
  %19 = add nsw i32 %25, 1
  %20 = icmp slt i32 %19, %1
  br i1 %20, label %12, label %21

21:                                               ; preds = %23, %17, %4, %2
  %22 = phi i32 [ 0, %2 ], [ %9, %4 ], [ %18, %17 ], [ %24, %23 ]
  ret i32 %22

23:                                               ; preds = %2, %12
  %24 = phi i32 [ %13, %12 ], [ 0, %2 ]
  %25 = phi i32 [ %14, %12 ], [ 0, %2 ]
  %26 = phi ptr [ %16, %12 ], [ %0, %2 ]
  %27 = load i8, ptr %26, align 1, !tbaa !16
  %28 = urem i8 %27, 3
  %29 = zext nneg i8 %28 to i64
  %30 = getelementptr inbounds nuw [3 x ptr], ptr @thread_ops.ops, i64 0, i64 %29
  %31 = load ptr, ptr %30, align 8, !tbaa !17
  indirectbr ptr %31, [label %4, label %17, label %21]
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef range(i32 -1, 2) i32 @jump_over(i32 noundef %0) local_unnamed_addr #2 {
  br label %2

2:                                                ; preds = %1
  %3 = icmp slt i32 %0, 1
  %4 = select i1 %3, i32 -1, i32 1
  ret i32 %4
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #3

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree norecurse nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 21.1.8 (6ubuntu1)"}
!5 = distinct !{!5, !6, !7}
!6 = !{!"llvm.loop.mustprogress"}
!7 = !{!"llvm.loop.unroll.disable"}
!8 = !{!9, !9, i64 0}
!9 = !{!"int", !10, i64 0}
!10 = !{!"omnipotent char", !11, i64 0}
!11 = !{!"Simple C/C++ TBAA"}
!12 = distinct !{!12, !6, !7}
!13 = distinct !{!13, !6, !7}
!14 = distinct !{!14, !6, !7}
!15 = distinct !{!15, !6, !7}
!16 = !{!10, !10, i64 0}
!17 = !{!18, !18, i64 0}
!18 = !{!"any pointer", !10, i64 0}
