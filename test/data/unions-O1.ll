; ModuleID = 'test/c/unions.c'
source_filename = "test/c/unions.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef i32 @punned(float noundef %0) local_unnamed_addr #0 {
  %2 = bitcast float %0 to i32
  ret i32 %2
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef range(i32 0, 256) i32 @low_byte(i32 noundef %0) local_unnamed_addr #0 {
  %2 = and i32 %0, 255
  ret i32 %2
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 0, 8) i32 @get_kind(i32 %0) local_unnamed_addr #0 {
  %2 = and i32 %0, 7
  ret i32 %2
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 -2048, 2048) i32 @get_delta(i32 %0) local_unnamed_addr #0 {
  %2 = trunc i32 %0 to i16
  %3 = ashr i16 %2, 4
  %4 = sext i16 %3 to i32
  ret i32 %4
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @set_live(i32 %0, i1 noundef zeroext %1) local_unnamed_addr #0 {
  %3 = select i1 %1, i32 8, i32 0
  %4 = and i32 %0, -9
  %5 = or disjoint i32 %3, %4
  ret i32 %5
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define dso_local i32 @tight_n(ptr noundef readonly captures(none) %0) local_unnamed_addr #1 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 1
  %3 = load i32, ptr %2, align 1, !tbaa !5
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define dso_local signext i16 @tight_s(ptr noundef readonly captures(none) %0) local_unnamed_addr #1 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 5
  %3 = load i16, ptr %2, align 1, !tbaa !11
  ret i16 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef i32 @next_colour(i32 noundef %0) local_unnamed_addr #0 {
  %2 = icmp eq i32 %0, 8
  %3 = add i32 %0, 1
  %4 = select i1 %2, i32 0, i32 %3
  ret i32 %4
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef zeroext i1 @truthy(i32 noundef %0) local_unnamed_addr #0 {
  %2 = icmp ne i32 %0, 0
  ret i1 %2
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 21.1.8 (6ubuntu1)"}
!5 = !{!6, !9, i64 1}
!6 = !{!"tight", !7, i64 0, !9, i64 1, !10, i64 5}
!7 = !{!"omnipotent char", !8, i64 0}
!8 = !{!"Simple C/C++ TBAA"}
!9 = !{!"int", !7, i64 0}
!10 = !{!"short", !7, i64 0}
!11 = !{!6, !10, i64 5}
