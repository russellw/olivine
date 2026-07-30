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
  br i1 %4, label %5, label %7

5:                                                ; preds = %3
  %6 = zext nneg i32 %2 to i64
  br label %9

7:                                                ; preds = %9, %3
  %8 = phi i32 [ 0, %3 ], [ %16, %9 ]
  ret i32 %8

9:                                                ; preds = %5, %9
  %10 = phi i64 [ 0, %5 ], [ %17, %9 ]
  %11 = phi i32 [ 0, %5 ], [ %16, %9 ]
  %12 = load atomic i32, ptr %0 monotonic, align 4
  %13 = getelementptr inbounds nuw i32, ptr %1, i64 %10
  %14 = load i32, ptr %13, align 4, !tbaa !8
  %15 = mul nsw i32 %14, %12
  %16 = add nsw i32 %15, %11
  %17 = add nuw nsw i64 %10, 1
  %18 = icmp eq i64 %17, %6
  br i1 %18, label %7, label %9, !llvm.loop !12
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
!5 = distinct !{!5, !6, !7}
!6 = !{!"llvm.loop.mustprogress"}
!7 = !{!"llvm.loop.unroll.disable"}
!8 = !{!9, !9, i64 0}
!9 = !{!"int", !10, i64 0}
!10 = !{!"omnipotent char", !11, i64 0}
!11 = !{!"Simple C/C++ TBAA"}
!12 = distinct !{!12, !6, !7}
