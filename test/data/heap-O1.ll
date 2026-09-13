; ModuleID = 'test/c/heap.c'
source_filename = "test/c/heap.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@watched_heap = external local_unnamed_addr global ptr, align 8

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 1, 0) i32 @filled_then_read(i32 noundef %0) local_unnamed_addr #0 {
  %2 = shl i32 %0, 1
  %3 = or disjoint i32 %2, 1
  ret i32 %3
}

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite)
declare void @free(ptr allocptr noundef captures(none)) local_unnamed_addr #2

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef i32 @other_element(i32 noundef returned %0) local_unnamed_addr #0 {
  ret i32 %0
}

; Function Attrs: mustprogress nounwind willreturn memory(readwrite, argmem: none) uwtable
define dso_local i32 @somewhere_in_it(i32 noundef %0, i32 noundef %1) local_unnamed_addr #3 {
  %3 = tail call noalias dereferenceable_or_null(16) ptr @malloc(i64 noundef 16) #10
  store i32 %0, ptr %3, align 4, !tbaa !5
  %4 = and i32 %1, 3
  %5 = zext nneg i32 %4 to i64
  %6 = getelementptr inbounds nuw i32, ptr %3, i64 %5
  store i32 0, ptr %6, align 4, !tbaa !5
  %7 = load i32, ptr %3, align 4, !tbaa !5
  tail call void @free(ptr noundef %3) #11
  ret i32 %7
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 1, 0) i32 @two_buffers(i32 noundef %0) local_unnamed_addr #0 {
  %2 = shl i32 %0, 1
  %3 = or disjoint i32 %2, 1
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) uwtable
define dso_local noundef i32 @through_a_parameter(ptr noundef writeonly captures(none) initializes((0, 4)) %0, i32 noundef returned %1) local_unnamed_addr #4 {
  store i32 0, ptr %0, align 4, !tbaa !5
  ret i32 %1
}

; Function Attrs: nounwind uwtable
define dso_local i32 @around_a_call(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call noalias dereferenceable_or_null(16) ptr @malloc(i64 noundef 16) #10
  store i32 %0, ptr %2, align 4, !tbaa !5
  store ptr %2, ptr @watched_heap, align 8, !tbaa !9
  tail call void @sink() #11
  %3 = load i32, ptr %2, align 4, !tbaa !5
  store ptr null, ptr @watched_heap, align 8, !tbaa !9
  tail call void @free(ptr noundef %2) #11
  ret i32 %3
}

declare void @sink() local_unnamed_addr #6

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local i32 @allocated_each_turn(i32 noundef %0) local_unnamed_addr #7 {
  %2 = icmp sgt i32 %0, 0
  br i1 %2, label %5, label %3

3:                                                ; preds = %5, %1
  %4 = phi i32 [ 0, %1 ], [ %9, %5 ]
  ret i32 %4

5:                                                ; preds = %1, %5
  %6 = phi i32 [ %9, %5 ], [ 0, %1 ]
  %7 = phi i32 [ %10, %5 ], [ 0, %1 ]
  %8 = shl i32 %6, 1
  %9 = add i32 %8, %7
  %10 = add nuw nsw i32 %7, 1
  %11 = icmp eq i32 %10, %0
  br i1 %11, label %3, label %5, !llvm.loop !12
}

; Function Attrs: nounwind memory(readwrite, argmem: none) uwtable
define dso_local i32 @carried_along(i32 noundef %0) local_unnamed_addr #8 {
  %2 = tail call noalias dereferenceable_or_null(64) ptr @malloc(i64 noundef 64) #10
  store i32 1, ptr %2, align 4, !tbaa !5
  %3 = tail call i32 @llvm.smin.i32(i32 %0, i32 16)
  %4 = icmp sgt i32 %0, 1
  br i1 %4, label %5, label %8

5:                                                ; preds = %1
  %6 = zext nneg i32 %3 to i64
  %7 = load i32, ptr %2, align 4
  br label %12

8:                                                ; preds = %12, %1
  %9 = icmp sgt i32 %0, 0
  br i1 %9, label %10, label %20

10:                                               ; preds = %8
  %11 = zext nneg i32 %3 to i64
  br label %22

12:                                               ; preds = %5, %12
  %13 = phi i32 [ %7, %5 ], [ %17, %12 ]
  %14 = phi i64 [ 1, %5 ], [ %18, %12 ]
  %15 = getelementptr i32, ptr %2, i64 %14
  %16 = trunc nuw nsw i64 %14 to i32
  %17 = add nsw i32 %13, %16
  store i32 %17, ptr %15, align 4, !tbaa !5
  %18 = add nuw nsw i64 %14, 1
  %19 = icmp eq i64 %18, %6
  br i1 %19, label %8, label %12, !llvm.loop !15

20:                                               ; preds = %22, %8
  %21 = phi i32 [ 0, %8 ], [ %27, %22 ]
  tail call void @free(ptr noundef %2) #11
  ret i32 %21

22:                                               ; preds = %10, %22
  %23 = phi i64 [ 0, %10 ], [ %28, %22 ]
  %24 = phi i32 [ 0, %10 ], [ %27, %22 ]
  %25 = getelementptr inbounds nuw i32, ptr %2, i64 %23
  %26 = load i32, ptr %25, align 4, !tbaa !5
  %27 = add nsw i32 %26, %24
  %28 = add nuw nsw i64 %23, 1
  %29 = icmp eq i64 %28, %11
  br i1 %29, label %20, label %22, !llvm.loop !16
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #9

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite) "alloc-family"="malloc" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nounwind willreturn memory(readwrite, argmem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #7 = { nofree norecurse nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #8 = { nounwind memory(readwrite, argmem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #9 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #10 = { nounwind allocsize(0) }
attributes #11 = { nounwind }

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
!9 = !{!10, !10, i64 0}
!10 = !{!"p1 int", !11, i64 0}
!11 = !{!"any pointer", !7, i64 0}
!12 = distinct !{!12, !13, !14}
!13 = !{!"llvm.loop.mustprogress"}
!14 = !{!"llvm.loop.unroll.disable"}
!15 = distinct !{!15, !13, !14}
!16 = distinct !{!16, !13, !14}
