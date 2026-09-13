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
  br i1 %2, label %3, label %22

3:                                                ; preds = %1
  %4 = and i32 %0, 7
  %5 = icmp ult i32 %0, 8
  br i1 %5, label %8, label %6

6:                                                ; preds = %3
  %7 = and i32 %0, 2147483640
  br label %24

8:                                                ; preds = %24, %3
  %9 = phi i32 [ poison, %3 ], [ %50, %24 ]
  %10 = phi i32 [ 0, %3 ], [ %50, %24 ]
  %11 = phi i32 [ 0, %3 ], [ %51, %24 ]
  %12 = icmp eq i32 %4, 0
  br i1 %12, label %22, label %13

13:                                               ; preds = %8, %13
  %14 = phi i32 [ %18, %13 ], [ %10, %8 ]
  %15 = phi i32 [ %19, %13 ], [ %11, %8 ]
  %16 = phi i32 [ %20, %13 ], [ 0, %8 ]
  %17 = shl i32 %14, 1
  %18 = add i32 %17, %15
  %19 = add nuw nsw i32 %15, 1
  %20 = add i32 %16, 1
  %21 = icmp eq i32 %20, %4
  br i1 %21, label %22, label %13, !llvm.loop !12

22:                                               ; preds = %8, %13, %1
  %23 = phi i32 [ 0, %1 ], [ %9, %8 ], [ %18, %13 ]
  ret i32 %23

24:                                               ; preds = %24, %6
  %25 = phi i32 [ 0, %6 ], [ %50, %24 ]
  %26 = phi i32 [ 0, %6 ], [ %51, %24 ]
  %27 = phi i32 [ 0, %6 ], [ %52, %24 ]
  %28 = or disjoint i32 %26, 1
  %29 = shl i32 %25, 2
  %30 = shl nuw i32 %26, 1
  %31 = add i32 %29, %30
  %32 = add i32 %31, %28
  %33 = or disjoint i32 %26, 3
  %34 = shl i32 %32, 2
  %35 = shl nuw i32 %26, 1
  %36 = or disjoint i32 %35, 4
  %37 = add i32 %34, %36
  %38 = add i32 %37, %33
  %39 = or disjoint i32 %26, 5
  %40 = shl i32 %38, 2
  %41 = shl nuw i32 %26, 1
  %42 = or disjoint i32 %41, 8
  %43 = add i32 %40, %42
  %44 = add i32 %43, %39
  %45 = or disjoint i32 %26, 7
  %46 = shl i32 %44, 2
  %47 = shl nuw i32 %26, 1
  %48 = or disjoint i32 %47, 12
  %49 = add i32 %46, %48
  %50 = add i32 %49, %45
  %51 = add nuw nsw i32 %26, 8
  %52 = add i32 %27, 8
  %53 = icmp eq i32 %52, %7
  br i1 %53, label %8, label %24, !llvm.loop !14
}

; Function Attrs: nounwind memory(readwrite, argmem: none) uwtable
define dso_local i32 @carried_along(i32 noundef %0) local_unnamed_addr #8 {
  %2 = tail call noalias dereferenceable_or_null(64) ptr @malloc(i64 noundef 64) #10
  store i32 1, ptr %2, align 4, !tbaa !5
  %3 = tail call i32 @llvm.smin.i32(i32 %0, i32 16)
  %4 = icmp sgt i32 %0, 1
  br i1 %4, label %5, label %14

5:                                                ; preds = %1
  %6 = zext nneg i32 %3 to i64
  %7 = load i32, ptr %2, align 4
  %8 = add nsw i64 %6, -1
  %9 = and i64 %8, 3
  %10 = add nsw i32 %3, -2
  %11 = icmp ult i32 %10, 3
  br i1 %11, label %16, label %12

12:                                               ; preds = %5
  %13 = and i64 %8, -4
  br label %54

14:                                               ; preds = %1
  %15 = icmp eq i32 %0, 1
  br i1 %15, label %30, label %76

16:                                               ; preds = %54, %5
  %17 = phi i32 [ %7, %5 ], [ %72, %54 ]
  %18 = phi i64 [ 1, %5 ], [ %73, %54 ]
  %19 = icmp eq i64 %9, 0
  br i1 %19, label %30, label %20

20:                                               ; preds = %16, %20
  %21 = phi i32 [ %26, %20 ], [ %17, %16 ]
  %22 = phi i64 [ %27, %20 ], [ %18, %16 ]
  %23 = phi i64 [ %28, %20 ], [ 0, %16 ]
  %24 = getelementptr i32, ptr %2, i64 %22
  %25 = trunc nuw nsw i64 %22 to i32
  %26 = add nsw i32 %21, %25
  store i32 %26, ptr %24, align 4, !tbaa !5
  %27 = add nuw nsw i64 %22, 1
  %28 = add i64 %23, 1
  %29 = icmp eq i64 %28, %9
  br i1 %29, label %30, label %20, !llvm.loop !16

30:                                               ; preds = %16, %20, %14
  %31 = zext nneg i32 %3 to i64
  %32 = icmp ult i32 %3, 8
  br i1 %32, label %51, label %33

33:                                               ; preds = %30
  %34 = and i64 %31, 2147483640
  br label %35

35:                                               ; preds = %35, %33
  %36 = phi i64 [ 0, %33 ], [ %45, %35 ]
  %37 = phi <4 x i32> [ zeroinitializer, %33 ], [ %43, %35 ]
  %38 = phi <4 x i32> [ zeroinitializer, %33 ], [ %44, %35 ]
  %39 = getelementptr inbounds nuw i32, ptr %2, i64 %36
  %40 = getelementptr inbounds nuw i8, ptr %39, i64 16
  %41 = load <4 x i32>, ptr %39, align 4, !tbaa !5
  %42 = load <4 x i32>, ptr %40, align 4, !tbaa !5
  %43 = add <4 x i32> %41, %37
  %44 = add <4 x i32> %42, %38
  %45 = add nuw i64 %36, 8
  %46 = icmp eq i64 %45, %34
  br i1 %46, label %47, label %35, !llvm.loop !17

47:                                               ; preds = %35
  %48 = add <4 x i32> %44, %43
  %49 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %48)
  %50 = icmp eq i64 %34, %31
  br i1 %50, label %76, label %51

51:                                               ; preds = %30, %47
  %52 = phi i64 [ 0, %30 ], [ %34, %47 ]
  %53 = phi i32 [ 0, %30 ], [ %49, %47 ]
  br label %78

54:                                               ; preds = %54, %12
  %55 = phi i32 [ %7, %12 ], [ %72, %54 ]
  %56 = phi i64 [ 1, %12 ], [ %73, %54 ]
  %57 = phi i64 [ 0, %12 ], [ %74, %54 ]
  %58 = getelementptr i32, ptr %2, i64 %56
  %59 = trunc nuw nsw i64 %56 to i32
  %60 = add nsw i32 %55, %59
  store i32 %60, ptr %58, align 4, !tbaa !5
  %61 = add nuw nsw i64 %56, 1
  %62 = getelementptr i32, ptr %2, i64 %61
  %63 = trunc nuw nsw i64 %61 to i32
  %64 = add nsw i32 %60, %63
  store i32 %64, ptr %62, align 4, !tbaa !5
  %65 = add nuw nsw i64 %56, 2
  %66 = getelementptr i32, ptr %2, i64 %65
  %67 = trunc nuw nsw i64 %65 to i32
  %68 = add nsw i32 %64, %67
  store i32 %68, ptr %66, align 4, !tbaa !5
  %69 = add nuw nsw i64 %56, 3
  %70 = getelementptr i32, ptr %2, i64 %69
  %71 = trunc nuw nsw i64 %69 to i32
  %72 = add nsw i32 %68, %71
  store i32 %72, ptr %70, align 4, !tbaa !5
  %73 = add nuw nsw i64 %56, 4
  %74 = add i64 %57, 4
  %75 = icmp eq i64 %74, %13
  br i1 %75, label %16, label %54, !llvm.loop !20

76:                                               ; preds = %78, %47, %14
  %77 = phi i32 [ 0, %14 ], [ %49, %47 ], [ %83, %78 ]
  tail call void @free(ptr noundef nonnull %2) #11
  ret i32 %77

78:                                               ; preds = %51, %78
  %79 = phi i64 [ %84, %78 ], [ %52, %51 ]
  %80 = phi i32 [ %83, %78 ], [ %53, %51 ]
  %81 = getelementptr inbounds nuw i32, ptr %2, i64 %79
  %82 = load i32, ptr %81, align 4, !tbaa !5
  %83 = add nsw i32 %82, %80
  %84 = add nuw nsw i64 %79, 1
  %85 = icmp eq i64 %84, %31
  br i1 %85, label %76, label %78, !llvm.loop !21
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #9

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.vector.reduce.add.v4i32(<4 x i32>) #9

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
!12 = distinct !{!12, !13}
!13 = !{!"llvm.loop.unroll.disable"}
!14 = distinct !{!14, !15}
!15 = !{!"llvm.loop.mustprogress"}
!16 = distinct !{!16, !13}
!17 = distinct !{!17, !15, !18, !19}
!18 = !{!"llvm.loop.isvectorized", i32 1}
!19 = !{!"llvm.loop.unroll.runtime.disable"}
!20 = distinct !{!20, !15}
!21 = distinct !{!21, !15, !19, !18}
