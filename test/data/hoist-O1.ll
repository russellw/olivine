; ModuleID = 'test/c/hoist.c'
source_filename = "test/c/hoist.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@scale = internal unnamed_addr global i32 3, align 4

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @scaled_sum(ptr noundef readonly captures(none) %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %9

5:                                                ; preds = %3
  %6 = mul nsw i32 %2, %2
  %7 = add nuw nsw i32 %6, 3
  %8 = zext nneg i32 %1 to i64
  br label %11

9:                                                ; preds = %11, %3
  %10 = phi i32 [ 0, %3 ], [ %17, %11 ]
  ret i32 %10

11:                                               ; preds = %5, %11
  %12 = phi i64 [ 0, %5 ], [ %18, %11 ]
  %13 = phi i32 [ 0, %5 ], [ %17, %11 ]
  %14 = getelementptr inbounds nuw i32, ptr %0, i64 %12
  %15 = load i32, ptr %14, align 4, !tbaa !5
  %16 = mul nsw i32 %15, %7
  %17 = add nsw i32 %16, %13
  %18 = add nuw nsw i64 %12, 1
  %19 = icmp eq i64 %18, %8
  br i1 %19, label %9, label %11, !llvm.loop !9
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @nested_squares(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = icmp sgt i32 %2, 0
  br i1 %4, label %5, label %18

5:                                                ; preds = %3
  %6 = xor i32 %1, %0
  %7 = shl i32 %0, 2
  %8 = add i32 %6, %7
  %9 = add nsw i32 %2, -1
  %10 = mul i32 %8, %9
  %11 = shl i32 %0, 3
  %12 = add i32 %10, %11
  %13 = shl i32 %6, 1
  %14 = add i32 %12, %13
  %15 = mul i32 %14, %9
  %16 = add i32 %6, %15
  %17 = add i32 %16, %7
  br label %18

18:                                               ; preds = %5, %3
  %19 = phi i32 [ 0, %3 ], [ %17, %5 ]
  ret i32 %19
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @sometimes(ptr noundef readonly captures(none) %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %8

5:                                                ; preds = %3
  %6 = mul nsw i32 %2, %2
  %7 = zext nneg i32 %1 to i64
  br label %10

8:                                                ; preds = %10, %3
  %9 = phi i32 [ 0, %3 ], [ %17, %10 ]
  ret i32 %9

10:                                               ; preds = %5, %10
  %11 = phi i64 [ 0, %5 ], [ %18, %10 ]
  %12 = phi i32 [ 0, %5 ], [ %17, %10 ]
  %13 = getelementptr inbounds nuw i32, ptr %0, i64 %11
  %14 = load i32, ptr %13, align 4, !tbaa !5
  %15 = icmp sgt i32 %14, 0
  %16 = select i1 %15, i32 %6, i32 0
  %17 = add nuw nsw i32 %16, %12
  %18 = add nuw nsw i64 %11, 1
  %19 = icmp eq i64 %18, %7
  br i1 %19, label %8, label %10, !llvm.loop !12
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
  br i1 %3, label %4, label %6

4:                                                ; preds = %2
  %5 = add nsw i32 %1, 1
  br label %8

6:                                                ; preds = %8, %2
  %7 = phi i32 [ 0, %2 ], [ %12, %8 ]
  ret i32 %7

8:                                                ; preds = %4, %8
  %9 = phi i32 [ 0, %4 ], [ %13, %8 ]
  %10 = phi i32 [ 0, %4 ], [ %5, %8 ]
  %11 = phi i32 [ 0, %4 ], [ %12, %8 ]
  %12 = add nsw i32 %10, %11
  %13 = add nuw nsw i32 %9, 1
  %14 = icmp eq i32 %13, %0
  br i1 %14, label %6, label %8, !llvm.loop !13
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(read, argmem: none, inaccessiblemem: none) uwtable
define dso_local i32 @scale_now() local_unnamed_addr #3 {
  %1 = load i32, ptr @scale, align 4, !tbaa !5
  ret i32 %1
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable
define dso_local void @set_scale(i32 noundef %0) local_unnamed_addr #4 {
  store i32 %0, ptr @scale, align 4, !tbaa !5
  ret void
}

; Function Attrs: nofree norecurse nosync nounwind memory(read, inaccessiblemem: none) uwtable
define dso_local i32 @scaled_by_symbol(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #5 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %7

4:                                                ; preds = %2
  %5 = load i32, ptr @scale, align 4, !tbaa !5
  %6 = zext nneg i32 %1 to i64
  br label %9

7:                                                ; preds = %9, %2
  %8 = phi i32 [ 0, %2 ], [ %15, %9 ]
  ret i32 %8

9:                                                ; preds = %4, %9
  %10 = phi i64 [ 0, %4 ], [ %16, %9 ]
  %11 = phi i32 [ 0, %4 ], [ %15, %9 ]
  %12 = getelementptr inbounds nuw i32, ptr %0, i64 %10
  %13 = load i32, ptr %12, align 4, !tbaa !5
  %14 = mul nsw i32 %5, %13
  %15 = add nsw i32 %14, %11
  %16 = add nuw nsw i64 %10, 1
  %17 = icmp eq i64 %16, %6
  br i1 %17, label %7, label %9, !llvm.loop !14
}

; Function Attrs: nofree norecurse nosync nounwind memory(read, argmem: readwrite, inaccessiblemem: none) uwtable
define dso_local i32 @bumping(ptr noundef captures(none) %0, i32 noundef %1) local_unnamed_addr #6 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %8

4:                                                ; preds = %2
  %5 = load i32, ptr @scale, align 4, !tbaa !5
  %6 = load i32, ptr %0, align 4, !tbaa !5
  br label %10

7:                                                ; preds = %10
  store i32 %15, ptr %0, align 4, !tbaa !5
  br label %8

8:                                                ; preds = %7, %2
  %9 = phi i32 [ 0, %2 ], [ %14, %7 ]
  ret i32 %9

10:                                               ; preds = %4, %10
  %11 = phi i32 [ %15, %10 ], [ %6, %4 ]
  %12 = phi i32 [ %16, %10 ], [ 0, %4 ]
  %13 = phi i32 [ %14, %10 ], [ 0, %4 ]
  %14 = add nsw i32 %5, %13
  %15 = add nsw i32 %11, 1
  %16 = add nuw nsw i32 %12, 1
  %17 = icmp eq i32 %16, %1
  br i1 %17, label %7, label %10, !llvm.loop !15
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable
define dso_local i32 @bumping_symbol(i32 noundef %0) local_unnamed_addr #7 {
  %2 = icmp sgt i32 %0, 0
  br i1 %2, label %3, label %17

3:                                                ; preds = %1
  %4 = load i32, ptr @scale, align 4, !tbaa !5
  %5 = add nsw i32 %0, -1
  %6 = add i32 %4, 1
  %7 = mul i32 %5, %6
  %8 = add i32 %4, %7
  %9 = zext i32 %5 to i33
  %10 = add nsw i32 %0, -2
  %11 = zext i32 %10 to i33
  %12 = mul i33 %9, %11
  %13 = lshr i33 %12, 1
  %14 = trunc nuw i33 %13 to i32
  %15 = add i32 %8, %14
  %16 = add i32 %4, %0
  store i32 %16, ptr @scale, align 4, !tbaa !5
  br label %17

17:                                               ; preds = %3, %1
  %18 = phi i32 [ 0, %1 ], [ %15, %3 ]
  ret i32 %18
}

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local i32 @jumped_into(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = and i32 %0, 1
  %4 = mul nsw i32 %1, 5
  br label %5, !llvm.loop !16

5:                                                ; preds = %2, %9
  %6 = phi i32 [ %10, %9 ], [ 0, %2 ]
  %7 = phi i32 [ %11, %9 ], [ %3, %2 ]
  %8 = icmp slt i32 %7, %0
  br i1 %8, label %9, label %12

9:                                                ; preds = %5
  %10 = add nsw i32 %6, %4
  %11 = add nuw nsw i32 %7, 1
  br label %5, !llvm.loop !16

12:                                               ; preds = %5
  ret i32 %6
}

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree norecurse nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind willreturn memory(read, argmem: none, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nofree norecurse nosync nounwind memory(read, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { nofree norecurse nosync nounwind memory(read, argmem: readwrite, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #7 = { mustprogress nofree norecurse nosync nounwind willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

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
