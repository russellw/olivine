; ModuleID = 'test/c/unroll.c'
source_filename = "test/c/unroll.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @total4(ptr noundef readonly captures(none) %0) local_unnamed_addr #0 {
  br label %3

2:                                                ; preds = %3
  ret i32 %8

3:                                                ; preds = %1, %3
  %4 = phi i64 [ 0, %1 ], [ %9, %3 ]
  %5 = phi i32 [ 0, %1 ], [ %8, %3 ]
  %6 = getelementptr inbounds nuw i32, ptr %0, i64 %4
  %7 = load i32, ptr %6, align 4, !tbaa !5
  %8 = add nsw i32 %7, %5
  %9 = add nuw nsw i64 %4, 1
  %10 = icmp eq i64 %9, 4
  br i1 %10, label %2, label %3, !llvm.loop !9
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @total_n(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #0 {
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
  br i1 %15, label %6, label %8, !llvm.loop !12
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @every_third(ptr noundef readonly captures(none) %0) local_unnamed_addr #0 {
  br label %3

2:                                                ; preds = %3
  ret i32 %8

3:                                                ; preds = %1, %3
  %4 = phi i64 [ 0, %1 ], [ %9, %3 ]
  %5 = phi i32 [ 0, %1 ], [ %8, %3 ]
  %6 = getelementptr inbounds nuw i32, ptr %0, i64 %4
  %7 = load i32, ptr %6, align 4, !tbaa !5
  %8 = add nsw i32 %7, %5
  %9 = add nuw nsw i64 %4, 3
  %10 = icmp samesign ult i64 %4, 9
  br i1 %10, label %3, label %2, !llvm.loop !13
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @count_back(ptr noundef readonly captures(none) %0) local_unnamed_addr #0 {
  %2 = getelementptr i8, ptr %0, i64 -4
  br label %4

3:                                                ; preds = %4
  ret i32 %9

4:                                                ; preds = %1, %4
  %5 = phi i64 [ 4, %1 ], [ %10, %4 ]
  %6 = phi i32 [ 0, %1 ], [ %9, %4 ]
  %7 = getelementptr i32, ptr %2, i64 %5
  %8 = load i32, ptr %7, align 4, !tbaa !5
  %9 = add nsw i32 %8, %6
  %10 = add nsw i64 %5, -1
  %11 = icmp samesign ugt i64 %5, 1
  br i1 %11, label %4, label %3, !llvm.loop !14
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: write) uwtable
define dso_local void @fill4(ptr noundef writeonly captures(none) %0, i32 noundef %1) local_unnamed_addr #1 {
  br label %4

3:                                                ; preds = %4
  ret void

4:                                                ; preds = %2, %4
  %5 = phi i64 [ 0, %2 ], [ %9, %4 ]
  %6 = getelementptr inbounds nuw i32, ptr %0, i64 %5
  %7 = trunc i64 %5 to i32
  %8 = add i32 %1, %7
  store i32 %8, ptr %6, align 4, !tbaa !5
  %9 = add nuw nsw i64 %5, 1
  %10 = icmp eq i64 %9, 4
  br i1 %10, label %3, label %4, !llvm.loop !15
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @total64(ptr noundef readonly captures(none) %0) local_unnamed_addr #0 {
  br label %3

2:                                                ; preds = %3
  ret i32 %8

3:                                                ; preds = %1, %3
  %4 = phi i64 [ 0, %1 ], [ %9, %3 ]
  %5 = phi i32 [ 0, %1 ], [ %8, %3 ]
  %6 = getelementptr inbounds nuw i32, ptr %0, i64 %4
  %7 = load i32, ptr %6, align 4, !tbaa !5
  %8 = add nsw i32 %7, %5
  %9 = add nuw nsw i64 %4, 1
  %10 = icmp eq i64 %9, 64
  br i1 %10, label %2, label %3, !llvm.loop !16
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @wide4(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #0 {
  br label %4

3:                                                ; preds = %4
  ret i32 %17

4:                                                ; preds = %2, %4
  %5 = phi i64 [ 0, %2 ], [ %18, %4 ]
  %6 = phi i32 [ 0, %2 ], [ %17, %4 ]
  %7 = getelementptr inbounds nuw i32, ptr %0, i64 %5
  %8 = load i32, ptr %7, align 4, !tbaa !5
  %9 = mul nsw i32 %8, %1
  %10 = add nsw i32 %9, %8
  %11 = mul nsw i32 %10, %10
  %12 = sub nsw i32 %11, %9
  %13 = mul nsw i32 %12, %1
  %14 = add nsw i32 %13, %11
  %15 = mul nsw i32 %14, %14
  %16 = sub i32 %6, %13
  %17 = add i32 %16, %15
  %18 = add nuw nsw i64 %5, 1
  %19 = icmp eq i64 %18, 4
  br i1 %19, label %3, label %4, !llvm.loop !17
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local range(i32 0, -2147483648) i32 @alternating(ptr noundef readonly captures(none) %0) local_unnamed_addr #0 {
  br label %3

2:                                                ; preds = %3
  ret i32 %9

3:                                                ; preds = %1, %3
  %4 = phi i64 [ 0, %1 ], [ %10, %3 ]
  %5 = phi i32 [ 0, %1 ], [ %9, %3 ]
  %6 = getelementptr inbounds nuw i32, ptr %0, i64 %4
  %7 = load i32, ptr %6, align 4, !tbaa !5
  %8 = tail call i32 @llvm.abs.i32(i32 %7, i1 false)
  %9 = add i32 %8, %5
  %10 = add nuw nsw i64 %4, 1
  %11 = icmp eq i64 %10, 6
  br i1 %11, label %2, label %3, !llvm.loop !18
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @until_zero(ptr noundef readonly captures(none) %0) local_unnamed_addr #0 {
  %2 = load i32, ptr %0, align 4, !tbaa !5
  %3 = icmp eq i32 %2, 0
  br i1 %3, label %13, label %4

4:                                                ; preds = %1, %4
  %5 = phi i64 [ %9, %4 ], [ 0, %1 ]
  %6 = phi i32 [ %11, %4 ], [ %2, %1 ]
  %7 = phi i32 [ %8, %4 ], [ 0, %1 ]
  %8 = add nsw i32 %6, %7
  %9 = add nuw nsw i64 %5, 1
  %10 = getelementptr inbounds nuw i32, ptr %0, i64 %9
  %11 = load i32, ptr %10, align 4, !tbaa !5
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %4, !llvm.loop !19

13:                                               ; preds = %4, %1
  %14 = phi i32 [ 0, %1 ], [ %8, %4 ]
  ret i32 %14
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @grid(ptr noundef readonly captures(none) %0) local_unnamed_addr #0 {
  br label %2

2:                                                ; preds = %1, %8
  %3 = phi i64 [ 0, %1 ], [ %9, %8 ]
  %4 = phi i32 [ 0, %1 ], [ %16, %8 ]
  %5 = mul nuw nsw i64 %3, 12
  %6 = getelementptr inbounds i8, ptr %0, i64 %5
  br label %11

7:                                                ; preds = %8
  ret i32 %16

8:                                                ; preds = %11
  %9 = add nuw nsw i64 %3, 1
  %10 = icmp eq i64 %9, 3
  br i1 %10, label %7, label %2, !llvm.loop !20

11:                                               ; preds = %2, %11
  %12 = phi i64 [ 0, %2 ], [ %17, %11 ]
  %13 = phi i32 [ %4, %2 ], [ %16, %11 ]
  %14 = getelementptr inbounds i32, ptr %6, i64 %12
  %15 = load i32, ptr %14, align 4, !tbaa !5
  %16 = add nsw i32 %15, %13
  %17 = add nuw nsw i64 %12, 1
  %18 = icmp eq i64 %17, 3
  br i1 %18, label %8, label %11, !llvm.loop !21
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @first_negative(ptr noundef readonly captures(none) %0) local_unnamed_addr #0 {
  br label %2

2:                                                ; preds = %1, %7
  %3 = phi i64 [ 0, %1 ], [ %8, %7 ]
  %4 = getelementptr inbounds nuw i32, ptr %0, i64 %3
  %5 = load i32, ptr %4, align 4, !tbaa !5
  %6 = icmp slt i32 %5, 0
  br i1 %6, label %10, label %7

7:                                                ; preds = %2
  %8 = add nuw nsw i64 %3, 1
  %9 = icmp eq i64 %8, 4
  br i1 %9, label %12, label %2, !llvm.loop !22

10:                                               ; preds = %2
  %11 = trunc nuw nsw i64 %3 to i32
  br label %12

12:                                               ; preds = %7, %10
  %13 = phi i32 [ %11, %10 ], [ -1, %7 ]
  ret i32 %13
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.abs.i32(i32, i1 immarg) #2

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree norecurse nosync nounwind memory(argmem: write) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

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
!18 = distinct !{!18, !10, !11}
!19 = distinct !{!19, !10, !11}
!20 = distinct !{!20, !10, !11}
!21 = distinct !{!21, !10, !11}
!22 = distinct !{!22, !10, !11}
