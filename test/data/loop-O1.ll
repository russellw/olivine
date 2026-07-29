; ModuleID = 'test/c/loop.c'
source_filename = "test/c/loop.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @sum(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #0 {
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

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local i32 @count_down(i32 noundef %0) local_unnamed_addr #1 {
  %2 = icmp sgt i32 %0, 1
  br i1 %2, label %3, label %14

3:                                                ; preds = %1, %3
  %4 = phi i32 [ %12, %3 ], [ 0, %1 ]
  %5 = phi i32 [ %11, %3 ], [ %0, %1 ]
  %6 = and i32 %5, 1
  %7 = icmp eq i32 %6, 0
  %8 = lshr exact i32 %5, 1
  %9 = mul nuw nsw i32 %5, 3
  %10 = add nuw nsw i32 %9, 1
  %11 = select i1 %7, i32 %8, i32 %10
  %12 = add nuw nsw i32 %4, 1
  %13 = icmp samesign ugt i32 %11, 1
  br i1 %13, label %3, label %14, !llvm.loop !12

14:                                               ; preds = %3, %1
  %15 = phi i32 [ 0, %1 ], [ %12, %3 ]
  ret i32 %15
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: write) uwtable
define dso_local void @fill(ptr noundef writeonly captures(none) %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #2 {
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %7

5:                                                ; preds = %3
  %6 = zext nneg i32 %1 to i64
  br label %8

7:                                                ; preds = %8, %3
  ret void

8:                                                ; preds = %5, %8
  %9 = phi i64 [ 0, %5 ], [ %11, %8 ]
  %10 = getelementptr inbounds nuw i32, ptr %0, i64 %9
  store i32 %2, ptr %10, align 4, !tbaa !5
  %11 = add nuw nsw i64 %9, 1
  %12 = icmp eq i64 %11, %6
  br i1 %12, label %7, label %8, !llvm.loop !13
}

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree norecurse nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree norecurse nosync nounwind memory(argmem: write) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

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
