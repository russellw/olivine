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
  br i1 %4, label %5, label %36

5:                                                ; preds = %3
  %6 = and i32 %2, 3
  %7 = icmp ult i32 %2, 4
  br i1 %7, label %18, label %8

8:                                                ; preds = %5
  %9 = and i32 %2, 2147483644
  %10 = insertelement <2 x double> poison, double %1, i64 0
  %11 = insertelement <2 x double> %10, double %0, i64 1
  %12 = insertelement <2 x double> poison, double %1, i64 0
  %13 = insertelement <2 x double> %12, double %0, i64 1
  %14 = insertelement <2 x double> poison, double %1, i64 0
  %15 = insertelement <2 x double> %14, double %0, i64 1
  %16 = insertelement <2 x double> poison, double %1, i64 0
  %17 = insertelement <2 x double> %16, double %0, i64 1
  br label %38

18:                                               ; preds = %38, %5
  %19 = phi <2 x double> [ poison, %5 ], [ %44, %38 ]
  %20 = phi <2 x double> [ zeroinitializer, %5 ], [ %44, %38 ]
  %21 = icmp eq i32 %6, 0
  br i1 %21, label %31, label %22

22:                                               ; preds = %18
  %23 = insertelement <2 x double> poison, double %1, i64 0
  %24 = insertelement <2 x double> %23, double %0, i64 1
  br label %25

25:                                               ; preds = %25, %22
  %26 = phi <2 x double> [ %28, %25 ], [ %20, %22 ]
  %27 = phi i32 [ %29, %25 ], [ 0, %22 ]
  %28 = tail call <2 x double> @llvm.fmuladd.v2f64(<2 x double> %24, <2 x double> splat (double 2.000000e+00), <2 x double> %26)
  %29 = add i32 %27, 1
  %30 = icmp eq i32 %29, %6
  br i1 %30, label %31, label %25, !llvm.loop !5

31:                                               ; preds = %25, %18
  %32 = phi <2 x double> [ %19, %18 ], [ %28, %25 ]
  %33 = shufflevector <2 x double> %32, <2 x double> poison, <2 x i32> <i32 1, i32 poison>
  %34 = fadd <2 x double> %33, %32
  %35 = extractelement <2 x double> %34, i64 0
  br label %36

36:                                               ; preds = %31, %3
  %37 = phi double [ 0.000000e+00, %3 ], [ %35, %31 ]
  ret double %37

38:                                               ; preds = %38, %8
  %39 = phi <2 x double> [ zeroinitializer, %8 ], [ %44, %38 ]
  %40 = phi i32 [ 0, %8 ], [ %45, %38 ]
  %41 = tail call <2 x double> @llvm.fmuladd.v2f64(<2 x double> %11, <2 x double> splat (double 2.000000e+00), <2 x double> %39)
  %42 = tail call <2 x double> @llvm.fmuladd.v2f64(<2 x double> %13, <2 x double> splat (double 2.000000e+00), <2 x double> %41)
  %43 = tail call <2 x double> @llvm.fmuladd.v2f64(<2 x double> %15, <2 x double> splat (double 2.000000e+00), <2 x double> %42)
  %44 = tail call <2 x double> @llvm.fmuladd.v2f64(<2 x double> %17, <2 x double> splat (double 2.000000e+00), <2 x double> %43)
  %45 = add i32 %40, 4
  %46 = icmp eq i32 %45, %9
  br i1 %46, label %18, label %38, !llvm.loop !7
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) uwtable
define dso_local void @spread(ptr dead_on_unwind noalias writable writeonly sret(%struct.box) align 4 captures(none) initializes((0, 20)) %0, i32 noundef %1) local_unnamed_addr #3 {
  store i32 %1, ptr %0, align 4, !tbaa !9
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 4
  %4 = insertelement <4 x i32> poison, i32 %1, i64 0
  %5 = shufflevector <4 x i32> %4, <4 x i32> poison, <4 x i32> zeroinitializer
  %6 = add nsw <4 x i32> %5, <i32 1, i32 2, i32 3, i32 4>
  store <4 x i32> %6, ptr %3, align 4, !tbaa !14
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define dso_local i32 @fifth(ptr noundef readonly byval(%struct.box) align 8 captures(none) %0) local_unnamed_addr #4 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %3 = load i32, ptr %2, align 8, !tbaa !15
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
  br i1 %11, label %12, label %18, !prof !16

12:                                               ; preds = %4
  %13 = fcmp uno double %10, 0.000000e+00
  br i1 %13, label %14, label %18, !prof !16

14:                                               ; preds = %12
  %15 = tail call { double, double } @__muldc3(double noundef %0, double noundef %1, double noundef %2, double noundef %3) #7
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

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare <2 x double> @llvm.fmuladd.v2f64(<2 x double>, <2 x double>, <2 x double>) #6

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nofree norecurse nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #7 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 21.1.8 (6ubuntu1)"}
!5 = distinct !{!5, !6}
!6 = !{!"llvm.loop.unroll.disable"}
!7 = distinct !{!7, !8}
!8 = !{!"llvm.loop.mustprogress"}
!9 = !{!10, !11, i64 0}
!10 = !{!"box", !11, i64 0, !11, i64 4, !11, i64 8, !11, i64 12, !11, i64 16}
!11 = !{!"int", !12, i64 0}
!12 = !{!"omnipotent char", !13, i64 0}
!13 = !{!"Simple C/C++ TBAA"}
!14 = !{!11, !11, i64 0}
!15 = !{!10, !11, i64 16}
!16 = !{!"branch_weights", i32 1, i32 1048575}
