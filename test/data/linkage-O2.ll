; ModuleID = 'test/c/linkage.c'
source_filename = "test/c/linkage.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@weak_count = weak dso_local local_unnamed_addr global i32 3, align 4
@version = internal constant [12 x i8] c"olivine 0.1\00", align 1
@tentative = dso_local local_unnamed_addr global i32 0, align 4
@llvm.compiler.used = appending global [2 x ptr] [ptr @kept_by_attribute, ptr @version], section "llvm.metadata"

@aliased_answer = dso_local alias i32 (), ptr @real_answer

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef i32 @real_answer() #0 {
  ret i32 42
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define hidden range(i32 -2147483647, -2147483648) i32 @hidden_helper(i32 noundef %0) local_unnamed_addr #0 {
  %2 = add nsw i32 %0, 1
  ret i32 %2
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define internal i32 @kept_by_attribute(i32 noundef %0) #0 {
  %2 = mul nsw i32 %0, 3
  ret i32 %2
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef i32 @never_inlined(i32 noundef %0) local_unnamed_addr #1 {
  %2 = xor i32 %0, 90
  ret i32 %2
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(read, argmem: none, inaccessiblemem: none) uwtable
define dso_local i32 @uses_them(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add nsw i32 %0, 1
  %3 = tail call i32 @never_inlined(i32 noundef %0)
  %4 = add nsw i32 %2, %3
  %5 = load i32, ptr @weak_count, align 4, !tbaa !5
  %6 = add nsw i32 %4, %5
  %7 = load i32, ptr @tentative, align 4, !tbaa !5
  %8 = add nsw i32 %6, %7
  ret i32 %8
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind willreturn memory(read, argmem: none, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

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
