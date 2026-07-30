; ModuleID = 'test/c/reload.c'
source_filename = "test/c/reload.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define dso_local i32 @square_b(ptr noundef readonly captures(none) %0) local_unnamed_addr #0 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 4
  %3 = load i32, ptr %2, align 4, !tbaa !5
  %4 = mul nsw i32 %3, %3
  ret i32 %4
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) uwtable
define dso_local noundef i32 @written_then_read(ptr noundef writeonly captures(none) initializes((4, 8)) %0, i32 noundef returned %1) local_unnamed_addr #1 {
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 4
  store i32 %1, ptr %3, align 4, !tbaa !5
  ret i32 %1
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 -2147483645, -2147483648) i32 @separate_slots(i32 noundef %0) local_unnamed_addr #2 {
  %2 = shl i32 %0, 1
  %3 = add i32 %2, 5
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite) uwtable
define dso_local range(i32 -2147483648, 2147483647) i32 @both_ways(ptr noundef captures(none) initializes((0, 4)) %0) local_unnamed_addr #3 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 4
  %3 = load i32, ptr %2, align 4, !tbaa !5
  store i32 7, ptr %0, align 4, !tbaa !10
  %4 = shl nsw i32 %3, 1
  ret i32 %4
}

; Function Attrs: nounwind uwtable
define dso_local i32 @around_call(ptr noundef readonly captures(none) %0) local_unnamed_addr #4 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 4
  %3 = load i32, ptr %2, align 4, !tbaa !5
  tail call void @sink() #8
  %4 = load i32, ptr %2, align 4, !tbaa !5
  %5 = add nsw i32 %4, %3
  ret i32 %5
}

declare void @sink() local_unnamed_addr #5

; Function Attrs: nounwind uwtable
define dso_local range(i32 2, 1) i32 @confined_across_call(i32 noundef %0) local_unnamed_addr #4 {
  tail call void @sink() #8
  %2 = shl i32 %0, 1
  %3 = add i32 %2, 2
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite) uwtable
define dso_local i32 @through_the_store(ptr noundef readonly captures(none) %0, ptr noundef writeonly captures(none) initializes((4, 8)) %1) local_unnamed_addr #3 {
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 4
  %4 = load i32, ptr %3, align 4, !tbaa !5
  %5 = getelementptr inbounds nuw i8, ptr %1, i64 4
  store i32 100, ptr %5, align 4, !tbaa !5
  %6 = load i32, ptr %3, align 4, !tbaa !5
  %7 = add nsw i32 %6, %4
  ret i32 %7
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define dso_local i32 @repeated(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 4
  %4 = load i32, ptr %3, align 4, !tbaa !5
  %5 = tail call i32 @llvm.smax.i32(i32 %1, i32 0)
  %6 = add nuw i32 %5, 1
  %7 = mul i32 %4, %6
  ret i32 %7
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable
define dso_local i32 @accumulated(ptr noundef readonly captures(none) %0, ptr noundef writeonly captures(none) %1, i32 noundef %2) local_unnamed_addr #6 {
  %4 = icmp sgt i32 %2, 0
  br i1 %4, label %5, label %52

5:                                                ; preds = %3
  %6 = getelementptr inbounds nuw i8, ptr %0, i64 4
  %7 = icmp ult i32 %2, 8
  br i1 %7, label %32, label %8

8:                                                ; preds = %5
  %9 = getelementptr i8, ptr %1, i64 4
  %10 = getelementptr i8, ptr %0, i64 8
  %11 = icmp ult ptr %1, %10
  %12 = icmp ult ptr %6, %9
  %13 = and i1 %11, %12
  br i1 %13, label %32, label %14

14:                                               ; preds = %8
  %15 = and i32 %2, 2147483640
  %16 = load i32, ptr %6, align 4, !tbaa !5, !alias.scope !11
  %17 = insertelement <4 x i32> poison, i32 %16, i64 0
  %18 = shufflevector <4 x i32> %17, <4 x i32> poison, <4 x i32> zeroinitializer
  br label %19

19:                                               ; preds = %19, %14
  %20 = phi i32 [ 0, %14 ], [ %26, %19 ]
  %21 = phi <4 x i32> [ zeroinitializer, %14 ], [ %24, %19 ]
  %22 = phi <4 x i32> [ zeroinitializer, %14 ], [ %25, %19 ]
  %23 = or disjoint i32 %20, 7
  %24 = add <4 x i32> %18, %21
  %25 = add <4 x i32> %18, %22
  %26 = add nuw i32 %20, 8
  %27 = icmp eq i32 %26, %15
  br i1 %27, label %28, label %19, !llvm.loop !14

28:                                               ; preds = %19
  store i32 %23, ptr %1, align 4, !tbaa !18, !alias.scope !19, !noalias !11
  %29 = add <4 x i32> %25, %24
  %30 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %29)
  %31 = icmp eq i32 %2, %15
  br i1 %31, label %52, label %32

32:                                               ; preds = %8, %5, %28
  %33 = phi i32 [ 0, %8 ], [ 0, %5 ], [ %15, %28 ]
  %34 = phi i32 [ 0, %8 ], [ 0, %5 ], [ %30, %28 ]
  %35 = and i32 %2, 3
  %36 = icmp eq i32 %35, 0
  br i1 %36, label %46, label %37

37:                                               ; preds = %32, %37
  %38 = phi i32 [ %43, %37 ], [ %33, %32 ]
  %39 = phi i32 [ %42, %37 ], [ %34, %32 ]
  %40 = phi i32 [ %44, %37 ], [ 0, %32 ]
  store i32 %38, ptr %1, align 4, !tbaa !18
  %41 = load i32, ptr %6, align 4, !tbaa !5
  %42 = add nsw i32 %41, %39
  %43 = add nuw nsw i32 %38, 1
  %44 = add i32 %40, 1
  %45 = icmp eq i32 %44, %35
  br i1 %45, label %46, label %37, !llvm.loop !21

46:                                               ; preds = %37, %32
  %47 = phi i32 [ poison, %32 ], [ %42, %37 ]
  %48 = phi i32 [ %33, %32 ], [ %43, %37 ]
  %49 = phi i32 [ %34, %32 ], [ %42, %37 ]
  %50 = sub nsw i32 %33, %2
  %51 = icmp ugt i32 %50, -4
  br i1 %51, label %52, label %54

52:                                               ; preds = %46, %54, %28, %3
  %53 = phi i32 [ 0, %3 ], [ %30, %28 ], [ %47, %46 ], [ %67, %54 ]
  ret i32 %53

54:                                               ; preds = %46, %54
  %55 = phi i32 [ %68, %54 ], [ %48, %46 ]
  %56 = phi i32 [ %67, %54 ], [ %49, %46 ]
  store i32 %55, ptr %1, align 4, !tbaa !18
  %57 = load i32, ptr %6, align 4, !tbaa !5
  %58 = add nsw i32 %57, %56
  %59 = add nuw nsw i32 %55, 1
  store i32 %59, ptr %1, align 4, !tbaa !18
  %60 = load i32, ptr %6, align 4, !tbaa !5
  %61 = add nsw i32 %60, %58
  %62 = add nuw nsw i32 %55, 2
  store i32 %62, ptr %1, align 4, !tbaa !18
  %63 = load i32, ptr %6, align 4, !tbaa !5
  %64 = add nsw i32 %63, %61
  %65 = add nuw nsw i32 %55, 3
  store i32 %65, ptr %1, align 4, !tbaa !18
  %66 = load i32, ptr %6, align 4, !tbaa !5
  %67 = add nsw i32 %66, %64
  %68 = add nuw nsw i32 %55, 4
  %69 = icmp eq i32 %68, %2
  br i1 %69, label %52, label %54, !llvm.loop !23
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #7

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.vector.reduce.add.v4i32(<4 x i32>) #7

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #7 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #8 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 21.1.8 (6ubuntu1)"}
!5 = !{!6, !7, i64 4}
!6 = !{!"pair", !7, i64 0, !7, i64 4}
!7 = !{!"int", !8, i64 0}
!8 = !{!"omnipotent char", !9, i64 0}
!9 = !{!"Simple C/C++ TBAA"}
!10 = !{!6, !7, i64 0}
!11 = !{!12}
!12 = distinct !{!12, !13}
!13 = distinct !{!13, !"LVerDomain"}
!14 = distinct !{!14, !15, !16, !17}
!15 = !{!"llvm.loop.mustprogress"}
!16 = !{!"llvm.loop.isvectorized", i32 1}
!17 = !{!"llvm.loop.unroll.runtime.disable"}
!18 = !{!7, !7, i64 0}
!19 = !{!20}
!20 = distinct !{!20, !13}
!21 = distinct !{!21, !22}
!22 = !{!"llvm.loop.unroll.disable"}
!23 = distinct !{!23, !15, !16}
