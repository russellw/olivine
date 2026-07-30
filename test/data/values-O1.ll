; ModuleID = 'test/c/values.c'
source_filename = "test/c/values.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.box = type { i32, i32, i32, i32, i32 }

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local { double, double } @scaled(double %0, double %1, double noundef %2) local_unnamed_addr #0 {
  %4 = fmul double %0, %2
  %5 = fmul double %1, %2
  %6 = insertvalue { double, double } poison, double %4, 0
  %7 = insertvalue { double, double } %6, double %5, 1
  ret { double, double } %7
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local double @dot(double %0, double %1, double %2, double %3) local_unnamed_addr #0 {
  %5 = fmul double %1, %3
  %6 = tail call double @llvm.fmuladd.f64(double %0, double %2, double %5)
  ret double %6
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #1

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local double @sum_scaled(double %0, double %1, double noundef %2) local_unnamed_addr #0 {
  %4 = fmul double %0, %2
  %5 = fmul double %1, %2
  %6 = fadd double %4, %5
  ret double %6
}

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local double @travelled(double %0, double %1, i32 noundef %2) local_unnamed_addr #2 {
  %4 = icmp sgt i32 %2, 0
  br i1 %4, label %9, label %7

5:                                                ; preds = %9
  %6 = fadd double %13, %14
  br label %7

7:                                                ; preds = %5, %3
  %8 = phi double [ 0.000000e+00, %3 ], [ %6, %5 ]
  ret double %8

9:                                                ; preds = %3, %9
  %10 = phi i32 [ %15, %9 ], [ 0, %3 ]
  %11 = phi double [ %14, %9 ], [ 0.000000e+00, %3 ]
  %12 = phi double [ %13, %9 ], [ 0.000000e+00, %3 ]
  %13 = tail call double @llvm.fmuladd.f64(double %0, double 2.000000e+00, double %12)
  %14 = tail call double @llvm.fmuladd.f64(double %1, double 2.000000e+00, double %11)
  %15 = add nuw nsw i32 %10, 1
  %16 = icmp eq i32 %15, %2
  br i1 %16, label %5, label %9, !llvm.loop !5
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) uwtable
define dso_local void @spread(ptr dead_on_unwind noalias writable writeonly sret(%struct.box) align 4 captures(none) initializes((0, 20)) %0, i32 noundef %1) local_unnamed_addr #3 {
  store i32 %1, ptr %0, align 4, !tbaa !8
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 4
  %4 = add nsw i32 %1, 1
  store i32 %4, ptr %3, align 4, !tbaa !13
  %5 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %6 = add nsw i32 %1, 2
  store i32 %6, ptr %5, align 4, !tbaa !14
  %7 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %8 = add nsw i32 %1, 3
  store i32 %8, ptr %7, align 4, !tbaa !15
  %9 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %10 = add nsw i32 %1, 4
  store i32 %10, ptr %9, align 4, !tbaa !16
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define dso_local i32 @fifth(ptr noundef readonly byval(%struct.box) align 8 captures(none) %0) local_unnamed_addr #4 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %3 = load i32, ptr %2, align 8, !tbaa !16
  ret i32 %3
}

; Function Attrs: nounwind uwtable
define dso_local { double, double } @turned(double noundef %0, double noundef %1, double noundef %2, double noundef %3) local_unnamed_addr #5 {
  %5 = fmul double %0, %2
  %6 = fmul double %1, %3
  %7 = fmul double %0, %3
  %8 = fmul double %1, %2
  %9 = fsub double %5, %6
  %10 = fadd double %8, %7
  %11 = fcmp uno double %9, 0.000000e+00
  br i1 %11, label %12, label %18, !prof !17

12:                                               ; preds = %4
  %13 = fcmp uno double %10, 0.000000e+00
  br i1 %13, label %14, label %18, !prof !17

14:                                               ; preds = %12
  %15 = tail call { double, double } @__muldc3(double noundef %0, double noundef %1, double noundef %2, double noundef %3) #6
  %16 = extractvalue { double, double } %15, 0
  %17 = extractvalue { double, double } %15, 1
  br label %18

18:                                               ; preds = %14, %12, %4
  %19 = phi double [ %9, %4 ], [ %9, %12 ], [ %16, %14 ]
  %20 = phi double [ %10, %4 ], [ %10, %12 ], [ %17, %14 ]
  %21 = insertvalue { double, double } poison, double %19, 0
  %22 = insertvalue { double, double } %21, double %20, 1
  ret { double, double } %22
}

declare { double, double } @__muldc3(double, double, double, double) local_unnamed_addr

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nofree norecurse nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { nounwind }

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
!8 = !{!9, !10, i64 0}
!9 = !{!"box", !10, i64 0, !10, i64 4, !10, i64 8, !10, i64 12, !10, i64 16}
!10 = !{!"int", !11, i64 0}
!11 = !{!"omnipotent char", !12, i64 0}
!12 = !{!"Simple C/C++ TBAA"}
!13 = !{!9, !10, i64 4}
!14 = !{!9, !10, i64 8}
!15 = !{!9, !10, i64 12}
!16 = !{!9, !10, i64 16}
!17 = !{!"branch_weights", i32 1, i32 1048575}
