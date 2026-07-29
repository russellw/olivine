; ModuleID = 'test/c/escape.c'
source_filename = "test/c/escape.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 2, 1) i32 @through_pointer(i32 noundef %0) local_unnamed_addr #0 {
  %2 = shl i32 %0, 1
  %3 = add i32 %2, 2
  ret i32 %3
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nofree norecurse nounwind memory(inaccessiblemem: readwrite) uwtable
define dso_local i32 @volatile_local(i32 noundef %0) local_unnamed_addr #2 {
  %2 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2)
  store volatile i32 %0, ptr %2, align 4, !tbaa !5
  %3 = load volatile i32, ptr %2, align 4, !tbaa !5
  %4 = add nsw i32 %3, 1
  store volatile i32 %4, ptr %2, align 4, !tbaa !5
  %5 = load volatile i32, ptr %2, align 4, !tbaa !5
  %6 = load volatile i32, ptr %2, align 4, !tbaa !5
  %7 = add nsw i32 %6, %5
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2)
  ret i32 %7
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef i32 @addressed_pair(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @llvm.smin.i32(i32 %0, i32 %1)
  ret i32 %3
}

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local i64 @counted(i32 noundef %0) local_unnamed_addr #3 {
  %2 = zext i32 %0 to i64
  %3 = alloca i32, i64 %2, align 16
  %4 = icmp sgt i32 %0, 0
  br i1 %4, label %5, label %7

5:                                                ; preds = %1
  %6 = zext nneg i32 %0 to i64
  br label %11

7:                                                ; preds = %11, %1
  %8 = icmp sgt i32 %0, 0
  br i1 %8, label %9, label %19

9:                                                ; preds = %7
  %10 = zext nneg i32 %0 to i64
  br label %21

11:                                               ; preds = %5, %11
  %12 = phi i64 [ 0, %5 ], [ %17, %11 ]
  %13 = mul nuw nsw i64 %12, %12
  %14 = trunc nuw i64 %13 to i32
  %15 = sub nsw i32 %14, %0
  %16 = getelementptr inbounds nuw i32, ptr %3, i64 %12
  store i32 %15, ptr %16, align 4, !tbaa !5
  %17 = add nuw nsw i64 %12, 1
  %18 = icmp eq i64 %17, %6
  br i1 %18, label %7, label %11, !llvm.loop !9

19:                                               ; preds = %21, %7
  %20 = phi i64 [ 0, %7 ], [ %27, %21 ]
  ret i64 %20

21:                                               ; preds = %9, %21
  %22 = phi i64 [ 0, %9 ], [ %28, %21 ]
  %23 = phi i64 [ 0, %9 ], [ %27, %21 ]
  %24 = getelementptr inbounds nuw i32, ptr %3, i64 %22
  %25 = load i32, ptr %24, align 4, !tbaa !5
  %26 = sext i32 %25 to i64
  %27 = add nsw i64 %23, %26
  %28 = add nuw nsw i64 %22, 1
  %29 = icmp eq i64 %28, %10
  br i1 %29, label %19, label %21, !llvm.loop !12
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef i32 @only_stored(i32 noundef returned %0) local_unnamed_addr #0 {
  ret i32 %0
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #4

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nofree norecurse nounwind memory(inaccessiblemem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree norecurse nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

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
