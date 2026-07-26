; ModuleID = 'test/c/globals.c'
source_filename = "test/c/globals.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@counter = dso_local global i32 0, align 4
@limit = dso_local local_unnamed_addr constant i32 42, align 4
@message = dso_local local_unnamed_addr global [8 x i8] c"olivine\00", align 1
@.str = private unnamed_addr constant [8 x i8] c"literal\00", align 1
@pointer_to_literal = dso_local local_unnamed_addr global ptr @.str, align 8
@table = dso_local global [5 x i32] [i32 1, i32 2, i32 3, i32 4, i32 5], align 16
@.str.1 = private unnamed_addr constant [4 x i8] c"two\00", align 1
@paired = dso_local local_unnamed_addr global { i32, [4 x i8], ptr } { i32 1, [4 x i8] zeroinitializer, ptr @.str.1 }, align 8
@address_of_counter = dso_local local_unnamed_addr global ptr @counter, align 8
@interior = dso_local local_unnamed_addr global ptr getelementptr inbounds nuw (i8, ptr @table, i64 8), align 8
@zeroed = dso_local local_unnamed_addr global [4 x double] zeroinitializer, align 16

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable
define dso_local range(i32 -2147483640, -2147483648) i32 @bump() local_unnamed_addr #0 {
  %1 = load i32, ptr @counter, align 4, !tbaa !5
  %2 = add nsw i32 %1, 1
  store i32 %2, ptr @counter, align 4, !tbaa !5
  %3 = add nsw i32 %1, 8
  ret i32 %3
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

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
