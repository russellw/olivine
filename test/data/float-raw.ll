; ModuleID = 'test/c/float.c'
source_filename = "test/c/float.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nounwind uwtable
define dso_local double @add(double noundef %0, double noundef %1) #0 {
  %3 = alloca double, align 8
  %4 = alloca double, align 8
  store double %0, ptr %3, align 8, !tbaa !5
  store double %1, ptr %4, align 8, !tbaa !5
  %5 = load double, ptr %3, align 8, !tbaa !5
  %6 = load double, ptr %4, align 8, !tbaa !5
  %7 = fadd double %5, %6
  ret double %7
}

; Function Attrs: nounwind uwtable
define dso_local float @fadd(float noundef %0, float noundef %1) #0 {
  %3 = alloca float, align 4
  %4 = alloca float, align 4
  store float %0, ptr %3, align 4, !tbaa !9
  store float %1, ptr %4, align 4, !tbaa !9
  %5 = load float, ptr %3, align 4, !tbaa !9
  %6 = load float, ptr %4, align 4, !tbaa !9
  %7 = fadd float %5, %6
  ret float %7
}

; Function Attrs: nounwind uwtable
define dso_local double @divide(double noundef %0, double noundef %1) #0 {
  %3 = alloca double, align 8
  %4 = alloca double, align 8
  store double %0, ptr %3, align 8, !tbaa !5
  store double %1, ptr %4, align 8, !tbaa !5
  %5 = load double, ptr %3, align 8, !tbaa !5
  %6 = load double, ptr %4, align 8, !tbaa !5
  %7 = fdiv double %5, %6
  ret double %7
}

; Function Attrs: nounwind uwtable
define dso_local i32 @ordered(double noundef %0, double noundef %1) #0 {
  %3 = alloca double, align 8
  %4 = alloca double, align 8
  store double %0, ptr %3, align 8, !tbaa !5
  store double %1, ptr %4, align 8, !tbaa !5
  %5 = load double, ptr %3, align 8, !tbaa !5
  %6 = load double, ptr %4, align 8, !tbaa !5
  %7 = fcmp olt double %5, %6
  %8 = zext i1 %7 to i32
  ret i32 %8
}

; Function Attrs: nounwind uwtable
define dso_local i32 @equal(float noundef %0, float noundef %1) #0 {
  %3 = alloca float, align 4
  %4 = alloca float, align 4
  store float %0, ptr %3, align 4, !tbaa !9
  store float %1, ptr %4, align 4, !tbaa !9
  %5 = load float, ptr %3, align 4, !tbaa !9
  %6 = load float, ptr %4, align 4, !tbaa !9
  %7 = fcmp oeq float %5, %6
  %8 = zext i1 %7 to i32
  ret i32 %8
}

; Function Attrs: nounwind uwtable
define dso_local double @to_double(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !11
  %3 = load i32, ptr %2, align 4, !tbaa !11
  %4 = sitofp i32 %3 to double
  ret double %4
}

; Function Attrs: nounwind uwtable
define dso_local i32 @to_int(double noundef %0) #0 {
  %2 = alloca double, align 8
  store double %0, ptr %2, align 8, !tbaa !5
  %3 = load double, ptr %2, align 8, !tbaa !5
  %4 = fptosi double %3 to i32
  ret i32 %4
}

; Function Attrs: nounwind uwtable
define dso_local float @demote(double noundef %0) #0 {
  %2 = alloca double, align 8
  store double %0, ptr %2, align 8, !tbaa !5
  %3 = load double, ptr %2, align 8, !tbaa !5
  %4 = fptrunc double %3 to float
  ret float %4
}

; Function Attrs: nounwind uwtable
define dso_local double @negate(double noundef %0) #0 {
  %2 = alloca double, align 8
  store double %0, ptr %2, align 8, !tbaa !5
  %3 = load double, ptr %2, align 8, !tbaa !5
  %4 = fneg double %3
  ret double %4
}

attributes #0 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

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
!9 = !{!10, !10, i64 0}
!10 = !{!"float", !7, i64 0}
!11 = !{!12, !12, i64 0}
!12 = !{!"int", !7, i64 0}
