; ModuleID = 'test/c/stride.c'
source_filename = "test/c/stride.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @stride_walk(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %6

4:                                                ; preds = %2
  %5 = zext nneg i32 %1 to i64
  br label %8

6:                                                ; preds = %8, %2
  %7 = phi i32 [ 0, %2 ], [ %13, %8 ]
  ret i32 %7

8:                                                ; preds = %4, %8
  %9 = phi i64 [ 0, %4 ], [ %14, %8 ]
  %10 = phi i32 [ 0, %4 ], [ %13, %8 ]
  %11 = getelementptr inbounds nuw i32, ptr %0, i64 %9
  %12 = load i32, ptr %11, align 4, !tbaa !5
  %13 = add nsw i32 %12, %10
  %14 = add nuw nsw i64 %9, 1
  %15 = icmp eq i64 %14, %5
  br i1 %15, label %6, label %8, !llvm.loop !9
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @stride_dot(ptr noundef readonly captures(none) %0, ptr noundef readonly captures(none) %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %2, 0
  br i1 %4, label %5, label %7

5:                                                ; preds = %3
  %6 = zext nneg i32 %2 to i64
  br label %9

7:                                                ; preds = %9, %3
  %8 = phi i32 [ 0, %3 ], [ %17, %9 ]
  ret i32 %8

9:                                                ; preds = %5, %9
  %10 = phi i64 [ 0, %5 ], [ %18, %9 ]
  %11 = phi i32 [ 0, %5 ], [ %17, %9 ]
  %12 = getelementptr inbounds nuw i32, ptr %0, i64 %10
  %13 = load i32, ptr %12, align 4, !tbaa !5
  %14 = getelementptr inbounds nuw i32, ptr %1, i64 %10
  %15 = load i32, ptr %14, align 4, !tbaa !5
  %16 = mul nsw i32 %15, %13
  %17 = add nsw i32 %16, %11
  %18 = add nuw nsw i64 %10, 1
  %19 = icmp eq i64 %18, %6
  br i1 %19, label %7, label %9, !llvm.loop !12
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @stride_third(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %6

4:                                                ; preds = %2
  %5 = zext nneg i32 %1 to i64
  br label %8

6:                                                ; preds = %8, %2
  %7 = phi i32 [ 0, %2 ], [ %13, %8 ]
  ret i32 %7

8:                                                ; preds = %4, %8
  %9 = phi i64 [ 0, %4 ], [ %14, %8 ]
  %10 = phi i32 [ 0, %4 ], [ %13, %8 ]
  %11 = getelementptr inbounds nuw i32, ptr %0, i64 %9
  %12 = load i32, ptr %11, align 4, !tbaa !5
  %13 = add nsw i32 %12, %10
  %14 = add nuw nsw i64 %9, 3
  %15 = icmp samesign ult i64 %14, %5
  br i1 %15, label %8, label %6, !llvm.loop !13
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @backwards(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %6

4:                                                ; preds = %2
  %5 = zext nneg i32 %1 to i64
  br label %8

6:                                                ; preds = %8, %2
  %7 = phi i32 [ 0, %2 ], [ %14, %8 ]
  ret i32 %7

8:                                                ; preds = %4, %8
  %9 = phi i64 [ %5, %4 ], [ %11, %8 ]
  %10 = phi i32 [ 0, %4 ], [ %14, %8 ]
  %11 = add nsw i64 %9, -1
  %12 = getelementptr inbounds nuw i32, ptr %0, i64 %11
  %13 = load i32, ptr %12, align 4, !tbaa !5
  %14 = add nsw i32 %13, %10
  %15 = icmp sgt i64 %9, 1
  br i1 %15, label %8, label %6, !llvm.loop !14
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable
define dso_local void @scale(ptr noundef writeonly captures(none) %0, ptr noundef readonly captures(none) %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #1 {
  %5 = icmp sgt i32 %2, 0
  br i1 %5, label %6, label %8

6:                                                ; preds = %4
  %7 = zext nneg i32 %2 to i64
  br label %9

8:                                                ; preds = %9, %4
  ret void

9:                                                ; preds = %6, %9
  %10 = phi i64 [ 0, %6 ], [ %15, %9 ]
  %11 = getelementptr inbounds nuw i32, ptr %1, i64 %10
  %12 = load i32, ptr %11, align 4, !tbaa !5
  %13 = mul nsw i32 %12, %3
  %14 = getelementptr inbounds nuw i32, ptr %0, i64 %10
  store i32 %13, ptr %14, align 4, !tbaa !5
  %15 = add nuw nsw i64 %10, 1
  %16 = icmp eq i64 %15, %7
  br i1 %16, label %8, label %9, !llvm.loop !15
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @stride_weighted(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %6

4:                                                ; preds = %2
  %5 = zext nneg i32 %1 to i64
  br label %8

6:                                                ; preds = %8, %2
  %7 = phi i32 [ 0, %2 ], [ %17, %8 ]
  ret i32 %7

8:                                                ; preds = %4, %8
  %9 = phi i64 [ 0, %4 ], [ %18, %8 ]
  %10 = phi i32 [ 0, %4 ], [ %17, %8 ]
  %11 = getelementptr inbounds nuw i32, ptr %0, i64 %9
  %12 = load i32, ptr %11, align 4, !tbaa !5
  %13 = mul nsw i32 %12, 5
  %14 = trunc i64 %9 to i32
  %15 = mul i32 %14, 7
  %16 = add i32 %15, %10
  %17 = add i32 %16, %13
  %18 = add nuw nsw i64 %9, 1
  %19 = icmp eq i64 %18, %5
  br i1 %19, label %6, label %8, !llvm.loop !16
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @stride_unsigned(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp eq i32 %1, 0
  br i1 %3, label %6, label %4

4:                                                ; preds = %2
  %5 = zext i32 %1 to i64
  br label %8

6:                                                ; preds = %8, %2
  %7 = phi i32 [ 0, %2 ], [ %13, %8 ]
  ret i32 %7

8:                                                ; preds = %4, %8
  %9 = phi i64 [ 0, %4 ], [ %14, %8 ]
  %10 = phi i32 [ 0, %4 ], [ %13, %8 ]
  %11 = getelementptr inbounds nuw i32, ptr %0, i64 %9
  %12 = load i32, ptr %11, align 4, !tbaa !5
  %13 = add i32 %12, %10
  %14 = add nuw nsw i64 %9, 1
  %15 = icmp eq i64 %14, %5
  br i1 %15, label %6, label %8, !llvm.loop !17
}

; Function Attrs: nofree norecurse nosync nounwind memory(read, inaccessiblemem: none) uwtable
define dso_local i32 @through_handle(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %7

4:                                                ; preds = %2
  %5 = load ptr, ptr %0, align 8, !tbaa !18
  %6 = zext nneg i32 %1 to i64
  br label %9

7:                                                ; preds = %9, %2
  %8 = phi i32 [ 0, %2 ], [ %14, %9 ]
  ret i32 %8

9:                                                ; preds = %4, %9
  %10 = phi i64 [ 0, %4 ], [ %15, %9 ]
  %11 = phi i32 [ 0, %4 ], [ %14, %9 ]
  %12 = getelementptr inbounds nuw i32, ptr %5, i64 %10
  %13 = load i32, ptr %12, align 4, !tbaa !5
  %14 = add nsw i32 %13, %11
  %15 = add nuw nsw i64 %10, 1
  %16 = icmp eq i64 %15, %6
  br i1 %16, label %7, label %9, !llvm.loop !21
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @gathered(ptr noundef readonly captures(none) %0, ptr noundef readonly captures(none) %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %2, 0
  br i1 %4, label %5, label %7

5:                                                ; preds = %3
  %6 = zext nneg i32 %2 to i64
  br label %9

7:                                                ; preds = %9, %3
  %8 = phi i32 [ 0, %3 ], [ %17, %9 ]
  ret i32 %8

9:                                                ; preds = %5, %9
  %10 = phi i64 [ 0, %5 ], [ %18, %9 ]
  %11 = phi i32 [ 0, %5 ], [ %17, %9 ]
  %12 = getelementptr inbounds nuw i32, ptr %1, i64 %10
  %13 = load i32, ptr %12, align 4, !tbaa !5
  %14 = sext i32 %13 to i64
  %15 = getelementptr inbounds i32, ptr %0, i64 %14
  %16 = load i32, ptr %15, align 4, !tbaa !5
  %17 = add nsw i32 %16, %11
  %18 = add nuw nsw i64 %10, 1
  %19 = icmp eq i64 %18, %6
  br i1 %19, label %7, label %9, !llvm.loop !22
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @grid_total(ptr noundef readonly captures(none) %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %16

5:                                                ; preds = %3
  %6 = icmp sgt i32 %2, 0
  %7 = zext nneg i32 %1 to i64
  %8 = zext nneg i32 %2 to i64
  br label %9

9:                                                ; preds = %5, %18
  %10 = phi i64 [ 0, %5 ], [ %20, %18 ]
  %11 = phi i32 [ 0, %5 ], [ %19, %18 ]
  br i1 %6, label %12, label %18

12:                                               ; preds = %9
  %13 = shl i64 %10, 3
  %14 = and i64 %13, 4294967288
  %15 = getelementptr inbounds i32, ptr %0, i64 %14
  br label %22

16:                                               ; preds = %18, %3
  %17 = phi i32 [ 0, %3 ], [ %19, %18 ]
  ret i32 %17

18:                                               ; preds = %22, %9
  %19 = phi i32 [ %11, %9 ], [ %27, %22 ]
  %20 = add nuw nsw i64 %10, 1
  %21 = icmp eq i64 %20, %7
  br i1 %21, label %16, label %9, !llvm.loop !23

22:                                               ; preds = %12, %22
  %23 = phi i64 [ 0, %12 ], [ %28, %22 ]
  %24 = phi i32 [ %11, %12 ], [ %27, %22 ]
  %25 = getelementptr inbounds i32, ptr %15, i64 %23
  %26 = load i32, ptr %25, align 4, !tbaa !5
  %27 = add nsw i32 %26, %24
  %28 = add nuw nsw i64 %23, 1
  %29 = icmp eq i64 %28, %8
  br i1 %29, label %18, label %22, !llvm.loop !24
}

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree norecurse nosync nounwind memory(read, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

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
!9 = distinct !{!9, !10, !11}
!10 = !{!"llvm.loop.mustprogress"}
!11 = !{!"llvm.loop.unroll.disable"}
!12 = distinct !{!12, !10, !11}
!13 = distinct !{!13, !10, !11}
!14 = distinct !{!14, !10, !11}
!15 = distinct !{!15, !10, !11}
!16 = distinct !{!16, !10, !11}
!17 = distinct !{!17, !10, !11}
!18 = !{!19, !19, i64 0}
!19 = !{!"p1 int", !20, i64 0}
!20 = !{!"any pointer", !7, i64 0}
!21 = distinct !{!21, !10, !11}
!22 = distinct !{!22, !10, !11}
!23 = distinct !{!23, !10, !11}
!24 = distinct !{!24, !10, !11}
