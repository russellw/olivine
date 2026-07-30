; ModuleID = 'test/c/atomics.c'
source_filename = "test/c/atomics.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: mustprogress nofree norecurse nounwind willreturn memory(argmem: readwrite) uwtable
define dso_local i32 @fetched(ptr noundef captures(none) %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = shl nsw i32 %1, 1
  %4 = or disjoint i32 %3, 1
  %5 = atomicrmw add ptr %0, i32 %4 seq_cst, align 4
  %6 = mul nsw i32 %5, 3
  %7 = add nsw i32 %6, %4
  ret i32 %7
}

; Function Attrs: nofree norecurse nounwind memory(argmem: readwrite) uwtable
define dso_local range(i32 0, 2) i32 @raised_to(ptr noundef captures(none) %0, i32 noundef %1) local_unnamed_addr #1 {
  %3 = load atomic i32, ptr %0 seq_cst, align 4
  br label %4

4:                                                ; preds = %7, %2
  %5 = phi i32 [ %3, %2 ], [ %10, %7 ]
  %6 = icmp slt i32 %5, %1
  br i1 %6, label %7, label %11

7:                                                ; preds = %4
  %8 = cmpxchg weak ptr %0, i32 %5, i32 %1 seq_cst seq_cst, align 4
  %9 = extractvalue { i32, i1 } %8, 1
  %10 = extractvalue { i32, i1 } %8, 0
  br i1 %9, label %11, label %4, !llvm.loop !5

11:                                               ; preds = %4, %7
  %12 = phi i32 [ 1, %7 ], [ 0, %4 ]
  ret i32 %12
}

; Function Attrs: nofree norecurse nounwind memory(argmem: readwrite) uwtable
define dso_local i32 @weighted(ptr noundef readonly captures(none) %0, ptr noundef readonly captures(none) %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = icmp sgt i32 %2, 0
  br i1 %4, label %5, label %31

5:                                                ; preds = %3
  %6 = zext nneg i32 %2 to i64
  %7 = and i64 %6, 3
  %8 = icmp ult i32 %2, 4
  br i1 %8, label %14, label %9

9:                                                ; preds = %5
  %10 = and i64 %6, 2147483644
  %11 = getelementptr inbounds i8, ptr %1, i64 4
  %12 = getelementptr inbounds i8, ptr %1, i64 8
  %13 = getelementptr inbounds i8, ptr %1, i64 12
  br label %33

14:                                               ; preds = %33, %5
  %15 = phi i32 [ poison, %5 ], [ %56, %33 ]
  %16 = phi i64 [ 0, %5 ], [ %57, %33 ]
  %17 = phi i32 [ 0, %5 ], [ %56, %33 ]
  %18 = icmp eq i64 %7, 0
  br i1 %18, label %31, label %19

19:                                               ; preds = %14, %19
  %20 = phi i64 [ %28, %19 ], [ %16, %14 ]
  %21 = phi i32 [ %27, %19 ], [ %17, %14 ]
  %22 = phi i64 [ %29, %19 ], [ 0, %14 ]
  %23 = load atomic i32, ptr %0 monotonic, align 4
  %24 = getelementptr inbounds nuw i32, ptr %1, i64 %20
  %25 = load i32, ptr %24, align 4, !tbaa !7
  %26 = mul nsw i32 %25, %23
  %27 = add nsw i32 %26, %21
  %28 = add nuw nsw i64 %20, 1
  %29 = add i64 %22, 1
  %30 = icmp eq i64 %29, %7
  br i1 %30, label %31, label %19, !llvm.loop !11

31:                                               ; preds = %14, %19, %3
  %32 = phi i32 [ 0, %3 ], [ %15, %14 ], [ %27, %19 ]
  ret i32 %32

33:                                               ; preds = %33, %9
  %34 = phi i64 [ 0, %9 ], [ %57, %33 ]
  %35 = phi i32 [ 0, %9 ], [ %56, %33 ]
  %36 = phi i64 [ 0, %9 ], [ %58, %33 ]
  %37 = load atomic i32, ptr %0 monotonic, align 4
  %38 = getelementptr inbounds nuw i32, ptr %1, i64 %34
  %39 = load i32, ptr %38, align 4, !tbaa !7
  %40 = mul nsw i32 %39, %37
  %41 = add nsw i32 %40, %35
  %42 = load atomic i32, ptr %0 monotonic, align 4
  %43 = getelementptr inbounds i32, ptr %11, i64 %34
  %44 = load i32, ptr %43, align 4, !tbaa !7
  %45 = mul nsw i32 %44, %42
  %46 = add nsw i32 %45, %41
  %47 = load atomic i32, ptr %0 monotonic, align 4
  %48 = getelementptr inbounds i32, ptr %12, i64 %34
  %49 = load i32, ptr %48, align 4, !tbaa !7
  %50 = mul nsw i32 %49, %47
  %51 = add nsw i32 %50, %46
  %52 = load atomic i32, ptr %0 monotonic, align 4
  %53 = getelementptr inbounds i32, ptr %13, i64 %34
  %54 = load i32, ptr %53, align 4, !tbaa !7
  %55 = mul nsw i32 %54, %52
  %56 = add nsw i32 %55, %51
  %57 = add nuw nsw i64 %34, 4
  %58 = add i64 %36, 4
  %59 = icmp eq i64 %58, %10
  br i1 %59, label %14, label %33, !llvm.loop !13
}

; Function Attrs: mustprogress nofree norecurse nounwind willreturn uwtable
define dso_local i32 @fenced(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = mul nsw i32 %0, %0
  fence seq_cst
  %4 = mul nsw i32 %1, %1
  %5 = add i32 %1, %0
  %6 = add i32 %5, %3
  %7 = add i32 %6, %4
  ret i32 %7
}

; Function Attrs: mustprogress nofree norecurse nounwind willreturn memory(argmem: readwrite) uwtable
define dso_local range(i32 -2147483648, 2147483647) i32 @published(ptr noundef writeonly captures(none) %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = shl nsw i32 %1, 1
  store atomic i32 %3, ptr %0 seq_cst, align 4
  ret i32 %3
}

attributes #0 = { mustprogress nofree norecurse nounwind willreturn memory(argmem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree norecurse nounwind memory(argmem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nounwind willreturn uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 21.1.8 (6ubuntu1)"}
!5 = distinct !{!5, !6}
!6 = !{!"llvm.loop.mustprogress"}
!7 = !{!8, !8, i64 0}
!8 = !{!"int", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = distinct !{!11, !12}
!12 = !{!"llvm.loop.unroll.disable"}
!13 = distinct !{!13, !6}
