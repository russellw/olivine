; ModuleID = 'test/c/memops.c'
source_filename = "test/c/memops.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.__va_list_tag = type { i32, i32, ptr, ptr }

; Function Attrs: mustprogress nofree nounwind willreturn uwtable
define dso_local noalias noundef ptr @duplicate(ptr noundef readonly captures(none) %0, i64 noundef %1) local_unnamed_addr #0 {
  %3 = tail call noalias ptr @malloc(i64 noundef %1) #11
  %4 = icmp eq ptr %3, null
  br i1 %4, label %6, label %5

5:                                                ; preds = %2
  tail call void @llvm.memcpy.p0.p0.i64(ptr nonnull align 1 %3, ptr align 1 %0, i64 %1, i1 false)
  br label %6

6:                                                ; preds = %5, %2
  ret ptr %3
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @malloc(i64 noundef) local_unnamed_addr #2

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) uwtable
define dso_local void @clear(ptr noundef writeonly captures(none) %0, i64 noundef %1) local_unnamed_addr #4 {
  tail call void @llvm.memset.p0.i64(ptr align 1 %0, i8 0, i64 %1, i1 false)
  ret void
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #5

; Function Attrs: mustprogress nounwind willreturn memory(argmem: readwrite, inaccessiblemem: readwrite) uwtable
define dso_local void @release(ptr noundef captures(none) %0) local_unnamed_addr #6 {
  tail call void @free(ptr noundef %0) #12
  ret void
}

; Function Attrs: mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite)
declare void @free(ptr allocptr noundef captures(none)) local_unnamed_addr #7

; Function Attrs: nounwind uwtable
define dso_local i32 @apply(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #8 {
  %3 = tail call i32 %0(i32 noundef %1) #12
  ret i32 %3
}

; Function Attrs: nofree norecurse nosync nounwind uwtable
define dso_local i32 @total(i32 noundef %0, ...) local_unnamed_addr #9 {
  %2 = alloca [1 x %struct.__va_list_tag], align 16
  call void @llvm.lifetime.start.p0(i64 24, ptr nonnull %2) #12
  call void @llvm.va_start.p0(ptr nonnull %2)
  %3 = icmp sgt i32 %0, 0
  br i1 %3, label %4, label %32

4:                                                ; preds = %1
  %5 = load i32, ptr %2, align 16
  %6 = getelementptr inbounds nuw i8, ptr %2, i64 8
  %7 = getelementptr inbounds nuw i8, ptr %2, i64 16
  %8 = load ptr, ptr %7, align 16
  %9 = load ptr, ptr %6, align 8
  %10 = and i32 %0, 1
  %11 = icmp eq i32 %0, 1
  br i1 %11, label %14, label %12

12:                                               ; preds = %4
  %13 = and i32 %0, 2147483646
  br label %34

14:                                               ; preds = %59, %4
  %15 = phi i32 [ poison, %4 ], [ %64, %59 ]
  %16 = phi ptr [ %9, %4 ], [ %60, %59 ]
  %17 = phi i32 [ 0, %4 ], [ %64, %59 ]
  %18 = phi i32 [ %5, %4 ], [ %61, %59 ]
  %19 = icmp eq i32 %10, 0
  br i1 %19, label %32, label %20

20:                                               ; preds = %14
  %21 = icmp ult i32 %18, 41
  br i1 %21, label %24, label %22

22:                                               ; preds = %20
  %23 = getelementptr i8, ptr %16, i64 8
  store ptr %23, ptr %6, align 8
  br label %28

24:                                               ; preds = %20
  %25 = zext nneg i32 %18 to i64
  %26 = getelementptr i8, ptr %8, i64 %25
  %27 = add nuw nsw i32 %18, 8
  store i32 %27, ptr %2, align 16
  br label %28

28:                                               ; preds = %24, %22
  %29 = phi ptr [ %26, %24 ], [ %16, %22 ]
  %30 = load i32, ptr %29, align 4, !tbaa !5
  %31 = add nsw i32 %30, %17
  br label %32

32:                                               ; preds = %28, %14, %1
  %33 = phi i32 [ 0, %1 ], [ %15, %14 ], [ %31, %28 ]
  call void @llvm.va_end.p0(ptr nonnull %2)
  call void @llvm.lifetime.end.p0(i64 24, ptr nonnull %2) #12
  ret i32 %33

34:                                               ; preds = %59, %12
  %35 = phi ptr [ %9, %12 ], [ %60, %59 ]
  %36 = phi i32 [ 0, %12 ], [ %64, %59 ]
  %37 = phi i32 [ %5, %12 ], [ %61, %59 ]
  %38 = phi i32 [ 0, %12 ], [ %65, %59 ]
  %39 = icmp ult i32 %37, 41
  br i1 %39, label %40, label %44

40:                                               ; preds = %34
  %41 = zext nneg i32 %37 to i64
  %42 = getelementptr i8, ptr %8, i64 %41
  %43 = add nuw nsw i32 %37, 8
  store i32 %43, ptr %2, align 16
  br label %46

44:                                               ; preds = %34
  %45 = getelementptr i8, ptr %35, i64 8
  store ptr %45, ptr %6, align 8
  br label %46

46:                                               ; preds = %44, %40
  %47 = phi ptr [ %35, %40 ], [ %45, %44 ]
  %48 = phi i32 [ %43, %40 ], [ %37, %44 ]
  %49 = phi ptr [ %42, %40 ], [ %35, %44 ]
  %50 = load i32, ptr %49, align 4, !tbaa !5
  %51 = add nsw i32 %50, %36
  %52 = icmp ult i32 %48, 41
  br i1 %52, label %55, label %53

53:                                               ; preds = %46
  %54 = getelementptr i8, ptr %47, i64 8
  store ptr %54, ptr %6, align 8
  br label %59

55:                                               ; preds = %46
  %56 = zext nneg i32 %48 to i64
  %57 = getelementptr i8, ptr %8, i64 %56
  %58 = add nuw nsw i32 %48, 8
  store i32 %58, ptr %2, align 16
  br label %59

59:                                               ; preds = %55, %53
  %60 = phi ptr [ %47, %55 ], [ %54, %53 ]
  %61 = phi i32 [ %58, %55 ], [ %48, %53 ]
  %62 = phi ptr [ %57, %55 ], [ %47, %53 ]
  %63 = load i32, ptr %62, align 4, !tbaa !5
  %64 = add nsw i32 %63, %51
  %65 = add i32 %38, 2
  %66 = icmp eq i32 %65, %13
  br i1 %66, label %14, label %34, !llvm.loop !9
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_start.p0(ptr) #10

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn
declare void @llvm.va_end.p0(ptr) #10

attributes #0 = { mustprogress nofree nounwind willreturn uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized") allocsize(0) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #6 = { mustprogress nounwind willreturn memory(argmem: readwrite, inaccessiblemem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #7 = { mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite) "alloc-family"="malloc" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #8 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #9 = { nofree norecurse nosync nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #10 = { mustprogress nocallback nofree nosync nounwind willreturn }
attributes #11 = { nounwind allocsize(0) }
attributes #12 = { nounwind }

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
!9 = distinct !{!9, !10}
!10 = !{!"llvm.loop.mustprogress"}
