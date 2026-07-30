; ModuleID = 'test/c/bytes.c'
source_filename = "test/c/bytes.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable
define dso_local void @scale_apart(ptr noalias noundef writeonly captures(none) %0, ptr noalias noundef readonly captures(none) %1, i32 noundef %2, ptr noalias noundef readonly captures(none) %3) local_unnamed_addr #0 {
  %5 = icmp sgt i32 %2, 0
  br i1 %5, label %6, label %9

6:                                                ; preds = %4
  %7 = load i32, ptr %3, align 4, !tbaa !5
  %8 = zext nneg i32 %2 to i64
  br label %10

9:                                                ; preds = %10, %4
  ret void

10:                                               ; preds = %6, %10
  %11 = phi i64 [ 0, %6 ], [ %16, %10 ]
  %12 = getelementptr inbounds nuw i32, ptr %1, i64 %11
  %13 = load i32, ptr %12, align 4, !tbaa !5
  %14 = mul nsw i32 %7, %13
  %15 = getelementptr inbounds nuw i32, ptr %0, i64 %11
  store i32 %14, ptr %15, align 4, !tbaa !5
  %16 = add nuw nsw i64 %11, 1
  %17 = icmp eq i64 %16, %8
  br i1 %17, label %9, label %10, !llvm.loop !9
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable
define dso_local void @scale_together(ptr noundef writeonly captures(none) %0, ptr noundef readonly captures(none) %1, i32 noundef %2, ptr noundef readonly captures(none) %3) local_unnamed_addr #0 {
  %5 = icmp sgt i32 %2, 0
  br i1 %5, label %6, label %8

6:                                                ; preds = %4
  %7 = zext nneg i32 %2 to i64
  br label %9

8:                                                ; preds = %9, %4
  ret void

9:                                                ; preds = %6, %9
  %10 = phi i64 [ 0, %6 ], [ %16, %9 ]
  %11 = getelementptr inbounds nuw i32, ptr %1, i64 %10
  %12 = load i32, ptr %11, align 4, !tbaa !5
  %13 = load i32, ptr %3, align 4, !tbaa !5
  %14 = mul nsw i32 %13, %12
  %15 = getelementptr inbounds nuw i32, ptr %0, i64 %10
  store i32 %14, ptr %15, align 4, !tbaa !5
  %16 = add nuw nsw i64 %10, 1
  %17 = icmp eq i64 %16, %7
  br i1 %17, label %8, label %9, !llvm.loop !12
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @checksum(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #1 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %6

4:                                                ; preds = %2
  %5 = zext nneg i32 %1 to i64
  br label %8

6:                                                ; preds = %8, %2
  %7 = phi i32 [ 0, %2 ], [ %15, %8 ]
  ret i32 %7

8:                                                ; preds = %4, %8
  %9 = phi i64 [ 0, %4 ], [ %16, %8 ]
  %10 = phi i32 [ 0, %4 ], [ %15, %8 ]
  %11 = mul i32 %10, 31
  %12 = getelementptr inbounds nuw i8, ptr %0, i64 %9
  %13 = load i8, ptr %12, align 1, !tbaa !13
  %14 = zext i8 %13 to i32
  %15 = add i32 %11, %14
  %16 = add nuw nsw i64 %9, 1
  %17 = icmp eq i64 %16, %5
  br i1 %17, label %6, label %8, !llvm.loop !14
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local range(i32 -255, 256) i32 @span(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #1 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %8

4:                                                ; preds = %2
  %5 = zext nneg i32 %1 to i64
  br label %10

6:                                                ; preds = %10
  %7 = sub nsw i32 %18, %17
  br label %8

8:                                                ; preds = %6, %2
  %9 = phi i32 [ -255, %2 ], [ %7, %6 ]
  ret i32 %9

10:                                               ; preds = %4, %10
  %11 = phi i64 [ 0, %4 ], [ %19, %10 ]
  %12 = phi i32 [ -128, %4 ], [ %18, %10 ]
  %13 = phi i32 [ 127, %4 ], [ %17, %10 ]
  %14 = getelementptr inbounds nuw i8, ptr %0, i64 %11
  %15 = load i8, ptr %14, align 1, !tbaa !13
  %16 = sext i8 %15 to i32
  %17 = tail call i32 @llvm.smin.i32(i32 %13, i32 %16)
  %18 = tail call i32 @llvm.smax.i32(i32 %12, i32 %16)
  %19 = add nuw nsw i64 %11, 1
  %20 = icmp eq i64 %19, %5
  br i1 %20, label %6, label %10, !llvm.loop !15
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef zeroext i8 @low_bits(i32 noundef %0) local_unnamed_addr #2 {
  %2 = lshr i32 %0, 3
  %3 = trunc i32 %2 to i8
  ret i8 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef signext i16 @folded_down(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = add i32 %1, 1
  %4 = mul i32 %3, %0
  %5 = trunc i32 %4 to i16
  ret i16 %5
}

; Function Attrs: mustprogress nofree norecurse nounwind willreturn memory(argmem: read) uwtable
define dso_local i32 @length(ptr noundef readonly captures(none) %0) local_unnamed_addr #3 {
  %2 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %0)
  %3 = trunc i64 %2 to i32
  ret i32 %3
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable
define dso_local void @copy_bytes(ptr noalias noundef writeonly captures(none) %0, ptr noalias noundef readonly captures(none) %1) local_unnamed_addr #0 {
  br label %3

3:                                                ; preds = %3, %2
  %4 = phi ptr [ %0, %2 ], [ %8, %3 ]
  %5 = phi ptr [ %1, %2 ], [ %6, %3 ]
  %6 = getelementptr inbounds nuw i8, ptr %5, i64 1
  %7 = load i8, ptr %5, align 1, !tbaa !13
  %8 = getelementptr inbounds nuw i8, ptr %4, i64 1
  store i8 %7, ptr %4, align 1, !tbaa !13
  %9 = icmp eq i8 %7, 0
  br i1 %9, label %10, label %3, !llvm.loop !16

10:                                               ; preds = %3
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #4

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #4

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: read)
declare i64 @strlen(ptr captures(none)) local_unnamed_addr #5

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree norecurse nosync nounwind memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nounwind willreturn memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nocallback nofree nounwind willreturn memory(argmem: read) }

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
!13 = !{!7, !7, i64 0}
!14 = distinct !{!14, !10, !11}
!15 = distinct !{!15, !10, !11}
!16 = distinct !{!16, !10, !11}
