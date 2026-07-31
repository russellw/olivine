; ModuleID = 'test/c/assume.c'
source_filename = "test/c/assume.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read, inaccessiblemem: write) uwtable
define dso_local i32 @sum_aligned(ptr noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  call void @llvm.assume(i1 true) [ "align"(ptr %0, i64 16) ]
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

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write)
declare void @llvm.assume(i1 noundef) #1

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @sum_plain(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #2 {
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

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read, inaccessiblemem: write) uwtable
define dso_local i32 @sum_each(ptr noundef %0, i32 noundef %1) local_unnamed_addr #0 {
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
  call void @llvm.assume(i1 true) [ "align"(ptr %11, i64 4) ]
  %12 = load i32, ptr %11, align 4, !tbaa !5
  %13 = add nsw i32 %12, %10
  %14 = add nuw nsw i64 %9, 1
  %15 = icmp eq i64 %14, %5
  br i1 %15, label %6, label %8, !llvm.loop !13
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: readwrite, inaccessiblemem: write) uwtable
define dso_local void @scale_aligned(ptr noundef %0, ptr noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #3 {
  call void @llvm.assume(i1 true) [ "align"(ptr %0, i64 16) ]
  call void @llvm.assume(i1 true) [ "align"(ptr %1, i64 16) ]
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
  br i1 %16, label %8, label %9, !llvm.loop !14
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read, inaccessiblemem: write) uwtable
define dso_local i32 @dot_aligned(ptr noundef %0, ptr noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  call void @llvm.assume(i1 true) [ "align"(ptr %0, i64 16) ]
  call void @llvm.assume(i1 true) [ "align"(ptr %1, i64 16) ]
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
  br i1 %19, label %7, label %9, !llvm.loop !15
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(inaccessiblemem: write) uwtable
define dso_local range(i32 0, 1073741824) i32 @halved(i32 noundef %0) local_unnamed_addr #4 {
  %2 = icmp sgt i32 %0, 0
  tail call void @llvm.assume(i1 %2)
  %3 = lshr i32 %0, 1
  ret i32 %3
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read, inaccessiblemem: write) uwtable
define dso_local i32 @through_call(ptr noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  call void @llvm.assume(i1 true) [ "align"(ptr %0, i64 16) ]
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %14

4:                                                ; preds = %2
  %5 = zext nneg i32 %1 to i64
  br label %6

6:                                                ; preds = %6, %4
  %7 = phi i64 [ 0, %4 ], [ %12, %6 ]
  %8 = phi i32 [ 0, %4 ], [ %11, %6 ]
  %9 = getelementptr inbounds nuw i32, ptr %0, i64 %7
  %10 = load i32, ptr %9, align 4, !tbaa !5
  %11 = add nsw i32 %10, %8
  %12 = add nuw nsw i64 %7, 1
  %13 = icmp eq i64 %12, %5
  br i1 %13, label %14, label %6, !llvm.loop !12

14:                                               ; preds = %6, %2
  %15 = phi i32 [ 0, %2 ], [ %11, %6 ]
  call void @llvm.assume(i1 true) [ "align"(ptr %0, i64 16) ]
  br i1 %3, label %16, label %26

16:                                               ; preds = %14
  %17 = zext nneg i32 %1 to i64
  br label %18

18:                                               ; preds = %18, %16
  %19 = phi i64 [ 0, %16 ], [ %24, %18 ]
  %20 = phi i32 [ 0, %16 ], [ %23, %18 ]
  %21 = getelementptr inbounds nuw i32, ptr %0, i64 %19
  %22 = load i32, ptr %21, align 4, !tbaa !5
  %23 = add nsw i32 %22, %20
  %24 = add nuw nsw i64 %19, 1
  %25 = icmp eq i64 %24, %17
  br i1 %25, label %26, label %18, !llvm.loop !9

26:                                               ; preds = %18, %14
  %27 = phi i32 [ 0, %14 ], [ %23, %18 ]
  %28 = add nsw i32 %27, %15
  ret i32 %28
}

; Function Attrs: nounwind memory(readwrite, argmem: none) uwtable
define dso_local i32 @local_aligned(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call noalias align 16 dereferenceable_or_null(256) ptr @aligned_alloc(i64 noundef 16, i64 noundef 256) #8
  %3 = icmp eq ptr %2, null
  br i1 %3, label %21, label %4

4:                                                ; preds = %1
  call void @llvm.assume(i1 true) [ "align"(ptr %2, i64 16) ]
  br label %5

5:                                                ; preds = %4, %5
  %6 = phi i64 [ 0, %4 ], [ %10, %5 ]
  %7 = getelementptr inbounds nuw i32, ptr %2, i64 %6
  %8 = trunc i64 %6 to i32
  %9 = mul i32 %0, %8
  store i32 %9, ptr %7, align 4, !tbaa !5
  %10 = add nuw nsw i64 %6, 1
  %11 = icmp eq i64 %10, 64
  br i1 %11, label %13, label %5, !llvm.loop !16

12:                                               ; preds = %13
  tail call void @free(ptr noundef %2) #9
  br label %21

13:                                               ; preds = %5, %13
  %14 = phi i64 [ %19, %13 ], [ 0, %5 ]
  %15 = phi i32 [ %18, %13 ], [ 0, %5 ]
  %16 = getelementptr inbounds nuw i32, ptr %2, i64 %14
  %17 = load i32, ptr %16, align 4, !tbaa !5
  %18 = add nsw i32 %17, %15
  %19 = add nuw nsw i64 %14, 1
  %20 = icmp eq i64 %19, 64
  br i1 %20, label %12, label %13, !llvm.loop !17

21:                                               ; preds = %1, %12
  %22 = phi i32 [ %18, %12 ], [ 0, %1 ]
  ret i32 %22
}

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized,aligned") allocsize(1) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @aligned_alloc(i64 allocalign noundef, i64 noundef) local_unnamed_addr #6

; Function Attrs: mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite)
declare void @free(ptr allocptr noundef captures(none)) local_unnamed_addr #7

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: read, inaccessiblemem: write) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }
attributes #2 = { nofree norecurse nosync nounwind memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree norecurse nosync nounwind memory(argmem: readwrite, inaccessiblemem: write) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind willreturn memory(inaccessiblemem: write) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind memory(readwrite, argmem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized,aligned") allocsize(1) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #7 = { mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite) "alloc-family"="malloc" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #8 = { nounwind allocsize(1) }
attributes #9 = { nounwind }

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
