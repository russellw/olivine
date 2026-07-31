; ModuleID = 'test/c/values.c'
source_filename = "test/c/values.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.point = type { double, double }
%struct.box = type { i32, i32, i32, i32, i32 }

; Function Attrs: nounwind uwtable
define dso_local { double, double } @scaled(double %0, double %1, double noundef %2) #0 {
  %4 = alloca %struct.point, align 8
  %5 = alloca %struct.point, align 8
  %6 = alloca double, align 8
  %7 = getelementptr inbounds nuw { double, double }, ptr %5, i32 0, i32 0
  store double %0, ptr %7, align 8
  %8 = getelementptr inbounds nuw { double, double }, ptr %5, i32 0, i32 1
  store double %1, ptr %8, align 8
  store double %2, ptr %6, align 8, !tbaa !5
  %9 = getelementptr inbounds nuw %struct.point, ptr %4, i32 0, i32 0
  %10 = getelementptr inbounds nuw %struct.point, ptr %5, i32 0, i32 0
  %11 = load double, ptr %10, align 8, !tbaa !9
  %12 = load double, ptr %6, align 8, !tbaa !5
  %13 = fmul double %11, %12
  store double %13, ptr %9, align 8, !tbaa !9
  %14 = getelementptr inbounds nuw %struct.point, ptr %4, i32 0, i32 1
  %15 = getelementptr inbounds nuw %struct.point, ptr %5, i32 0, i32 1
  %16 = load double, ptr %15, align 8, !tbaa !11
  %17 = load double, ptr %6, align 8, !tbaa !5
  %18 = fmul double %16, %17
  store double %18, ptr %14, align 8, !tbaa !11
  %19 = load { double, double }, ptr %4, align 8
  ret { double, double } %19
}

; Function Attrs: nounwind uwtable
define dso_local double @dot(double %0, double %1, double %2, double %3) #0 {
  %5 = alloca %struct.point, align 8
  %6 = alloca %struct.point, align 8
  %7 = getelementptr inbounds nuw { double, double }, ptr %5, i32 0, i32 0
  store double %0, ptr %7, align 8
  %8 = getelementptr inbounds nuw { double, double }, ptr %5, i32 0, i32 1
  store double %1, ptr %8, align 8
  %9 = getelementptr inbounds nuw { double, double }, ptr %6, i32 0, i32 0
  store double %2, ptr %9, align 8
  %10 = getelementptr inbounds nuw { double, double }, ptr %6, i32 0, i32 1
  store double %3, ptr %10, align 8
  %11 = getelementptr inbounds nuw %struct.point, ptr %5, i32 0, i32 0
  %12 = load double, ptr %11, align 8, !tbaa !9
  %13 = getelementptr inbounds nuw %struct.point, ptr %6, i32 0, i32 0
  %14 = load double, ptr %13, align 8, !tbaa !9
  %15 = getelementptr inbounds nuw %struct.point, ptr %5, i32 0, i32 1
  %16 = load double, ptr %15, align 8, !tbaa !11
  %17 = getelementptr inbounds nuw %struct.point, ptr %6, i32 0, i32 1
  %18 = load double, ptr %17, align 8, !tbaa !11
  %19 = fmul double %16, %18
  %20 = call double @llvm.fmuladd.f64(double %12, double %14, double %19)
  ret double %20
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fmuladd.f64(double, double, double) #1

; Function Attrs: nounwind uwtable
define dso_local double @sum_scaled(double %0, double %1, double noundef %2) #0 {
  %4 = alloca %struct.point, align 8
  %5 = alloca double, align 8
  %6 = alloca %struct.point, align 8
  %7 = getelementptr inbounds nuw { double, double }, ptr %4, i32 0, i32 0
  store double %0, ptr %7, align 8
  %8 = getelementptr inbounds nuw { double, double }, ptr %4, i32 0, i32 1
  store double %1, ptr %8, align 8
  store double %2, ptr %5, align 8, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 16, ptr %6) #4
  %9 = load double, ptr %5, align 8, !tbaa !5
  %10 = getelementptr inbounds nuw { double, double }, ptr %4, i32 0, i32 0
  %11 = load double, ptr %10, align 8
  %12 = getelementptr inbounds nuw { double, double }, ptr %4, i32 0, i32 1
  %13 = load double, ptr %12, align 8
  %14 = call { double, double } @scaled(double %11, double %13, double noundef %9)
  %15 = getelementptr inbounds nuw { double, double }, ptr %6, i32 0, i32 0
  %16 = extractvalue { double, double } %14, 0
  store double %16, ptr %15, align 8
  %17 = getelementptr inbounds nuw { double, double }, ptr %6, i32 0, i32 1
  %18 = extractvalue { double, double } %14, 1
  store double %18, ptr %17, align 8
  %19 = getelementptr inbounds nuw %struct.point, ptr %6, i32 0, i32 0
  %20 = load double, ptr %19, align 8, !tbaa !9
  %21 = getelementptr inbounds nuw %struct.point, ptr %6, i32 0, i32 1
  %22 = load double, ptr %21, align 8, !tbaa !11
  %23 = fadd double %20, %22
  call void @llvm.lifetime.end.p0(i64 16, ptr %6) #4
  ret double %23
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #2

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #2

; Function Attrs: nounwind uwtable
define dso_local double @travelled(double %0, double %1, i32 noundef %2) #0 {
  %4 = alloca %struct.point, align 8
  %5 = alloca i32, align 4
  %6 = alloca %struct.point, align 8
  %7 = alloca i32, align 4
  %8 = getelementptr inbounds nuw { double, double }, ptr %4, i32 0, i32 0
  store double %0, ptr %8, align 8
  %9 = getelementptr inbounds nuw { double, double }, ptr %4, i32 0, i32 1
  store double %1, ptr %9, align 8
  store i32 %2, ptr %5, align 4, !tbaa !12
  call void @llvm.lifetime.start.p0(i64 16, ptr %6) #4
  call void @llvm.memset.p0.i64(ptr align 8 %6, i8 0, i64 16, i1 false)
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #4
  store i32 0, ptr %7, align 4, !tbaa !12
  br label %10

10:                                               ; preds = %28, %3
  %11 = load i32, ptr %7, align 4, !tbaa !12
  %12 = load i32, ptr %5, align 4, !tbaa !12
  %13 = icmp slt i32 %11, %12
  br i1 %13, label %15, label %14

14:                                               ; preds = %10
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #4
  br label %31

15:                                               ; preds = %10
  %16 = getelementptr inbounds nuw %struct.point, ptr %6, i32 0, i32 0
  %17 = load double, ptr %16, align 8, !tbaa !9
  %18 = getelementptr inbounds nuw %struct.point, ptr %4, i32 0, i32 0
  %19 = load double, ptr %18, align 8, !tbaa !9
  %20 = call double @llvm.fmuladd.f64(double %19, double 2.000000e+00, double %17)
  %21 = getelementptr inbounds nuw %struct.point, ptr %6, i32 0, i32 0
  store double %20, ptr %21, align 8, !tbaa !9
  %22 = getelementptr inbounds nuw %struct.point, ptr %6, i32 0, i32 1
  %23 = load double, ptr %22, align 8, !tbaa !11
  %24 = getelementptr inbounds nuw %struct.point, ptr %4, i32 0, i32 1
  %25 = load double, ptr %24, align 8, !tbaa !11
  %26 = call double @llvm.fmuladd.f64(double %25, double 2.000000e+00, double %23)
  %27 = getelementptr inbounds nuw %struct.point, ptr %6, i32 0, i32 1
  store double %26, ptr %27, align 8, !tbaa !11
  br label %28

28:                                               ; preds = %15
  %29 = load i32, ptr %7, align 4, !tbaa !12
  %30 = add nsw i32 %29, 1
  store i32 %30, ptr %7, align 4, !tbaa !12
  br label %10, !llvm.loop !14

31:                                               ; preds = %14
  %32 = getelementptr inbounds nuw %struct.point, ptr %6, i32 0, i32 0
  %33 = load double, ptr %32, align 8, !tbaa !9
  %34 = getelementptr inbounds nuw %struct.point, ptr %6, i32 0, i32 1
  %35 = load double, ptr %34, align 8, !tbaa !11
  %36 = fadd double %33, %35
  call void @llvm.lifetime.end.p0(i64 16, ptr %6) #4
  ret double %36
}

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #3

; Function Attrs: nounwind uwtable
define dso_local void @spread(ptr dead_on_unwind noalias writable sret(%struct.box) align 4 %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  store i32 %1, ptr %3, align 4, !tbaa !12
  %4 = getelementptr inbounds nuw %struct.box, ptr %0, i32 0, i32 0
  %5 = load i32, ptr %3, align 4, !tbaa !12
  store i32 %5, ptr %4, align 4, !tbaa !17
  %6 = getelementptr inbounds nuw %struct.box, ptr %0, i32 0, i32 1
  %7 = load i32, ptr %3, align 4, !tbaa !12
  %8 = add nsw i32 %7, 1
  store i32 %8, ptr %6, align 4, !tbaa !19
  %9 = getelementptr inbounds nuw %struct.box, ptr %0, i32 0, i32 2
  %10 = load i32, ptr %3, align 4, !tbaa !12
  %11 = add nsw i32 %10, 2
  store i32 %11, ptr %9, align 4, !tbaa !20
  %12 = getelementptr inbounds nuw %struct.box, ptr %0, i32 0, i32 3
  %13 = load i32, ptr %3, align 4, !tbaa !12
  %14 = add nsw i32 %13, 3
  store i32 %14, ptr %12, align 4, !tbaa !21
  %15 = getelementptr inbounds nuw %struct.box, ptr %0, i32 0, i32 4
  %16 = load i32, ptr %3, align 4, !tbaa !12
  %17 = add nsw i32 %16, 4
  store i32 %17, ptr %15, align 4, !tbaa !22
  ret void
}

; Function Attrs: nounwind uwtable
define dso_local i32 @fifth(ptr noundef byval(%struct.box) align 8 %0) #0 {
  %2 = getelementptr inbounds nuw %struct.box, ptr %0, i32 0, i32 4
  %3 = load i32, ptr %2, align 8, !tbaa !22
  ret i32 %3
}

; Function Attrs: nounwind uwtable
define dso_local { double, double } @turned(double noundef %0, double noundef %1, double noundef %2, double noundef %3) #0 {
  %5 = alloca { double, double }, align 8
  %6 = alloca { double, double }, align 8
  %7 = alloca { double, double }, align 8
  %8 = getelementptr inbounds nuw { double, double }, ptr %6, i32 0, i32 0
  store double %0, ptr %8, align 8
  %9 = getelementptr inbounds nuw { double, double }, ptr %6, i32 0, i32 1
  store double %1, ptr %9, align 8
  %10 = getelementptr inbounds nuw { double, double }, ptr %7, i32 0, i32 0
  store double %2, ptr %10, align 8
  %11 = getelementptr inbounds nuw { double, double }, ptr %7, i32 0, i32 1
  store double %3, ptr %11, align 8
  %12 = getelementptr inbounds nuw { double, double }, ptr %6, i32 0, i32 0
  %13 = load double, ptr %12, align 8
  %14 = getelementptr inbounds nuw { double, double }, ptr %6, i32 0, i32 1
  %15 = load double, ptr %14, align 8
  %16 = getelementptr inbounds nuw { double, double }, ptr %7, i32 0, i32 0
  %17 = load double, ptr %16, align 8
  %18 = getelementptr inbounds nuw { double, double }, ptr %7, i32 0, i32 1
  %19 = load double, ptr %18, align 8
  %20 = fmul double %13, %17
  %21 = fmul double %15, %19
  %22 = fmul double %13, %19
  %23 = fmul double %15, %17
  %24 = fsub double %20, %21
  %25 = fadd double %22, %23
  %26 = fcmp uno double %24, %24
  br i1 %26, label %27, label %33, !prof !23

27:                                               ; preds = %4
  %28 = fcmp uno double %25, %25
  br i1 %28, label %29, label %33, !prof !23

29:                                               ; preds = %27
  %30 = call { double, double } @__muldc3(double noundef %13, double noundef %15, double noundef %17, double noundef %19) #4
  %31 = extractvalue { double, double } %30, 0
  %32 = extractvalue { double, double } %30, 1
  br label %33

33:                                               ; preds = %29, %27, %4
  %34 = phi double [ %24, %4 ], [ %24, %27 ], [ %31, %29 ]
  %35 = phi double [ %25, %4 ], [ %25, %27 ], [ %32, %29 ]
  %36 = getelementptr inbounds nuw { double, double }, ptr %5, i32 0, i32 0
  %37 = getelementptr inbounds nuw { double, double }, ptr %5, i32 0, i32 1
  store double %34, ptr %36, align 8
  store double %35, ptr %37, align 8
  %38 = load { double, double }, ptr %5, align 8
  ret { double, double } %38
}

declare { double, double } @__muldc3(double, double, double, double)

attributes #0 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 21.1.8 (6ubuntu1)"}
!5 = !{!6, !6, i64 0}
!6 = !{!"double", !7, i64 0}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = !{!10, !6, i64 0}
!10 = !{!"point", !6, i64 0, !6, i64 8}
!11 = !{!10, !6, i64 8}
!12 = !{!13, !13, i64 0}
!13 = !{!"int", !7, i64 0}
!14 = distinct !{!14, !15, !16}
!15 = !{!"llvm.loop.mustprogress"}
!16 = !{!"llvm.loop.unroll.disable"}
!17 = !{!18, !13, i64 0}
!18 = !{!"box", !13, i64 0, !13, i64 4, !13, i64 8, !13, i64 12, !13, i64 16}
!19 = !{!18, !13, i64 4}
!20 = !{!18, !13, i64 8}
!21 = !{!18, !13, i64 12}
!22 = !{!18, !13, i64 16}
!23 = !{!"branch_weights", i32 1, i32 1048575}
