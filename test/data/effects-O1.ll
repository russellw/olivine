; ModuleID = 'test/c/effects.c'
source_filename = "test/c/effects.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@held = internal unnamed_addr global [8 x i32] zeroinitializer, align 16
@written_total = dso_local local_unnamed_addr global i32 0, align 4

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 -2147483648, 2147483647) i32 @twice_over(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call fastcc i32 @mixed(i32 noundef %0, i32 noundef %1)
  %4 = shl nsw i32 %3, 1
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) uwtable
define internal fastcc i32 @mixed(i32 noundef %0, i32 noundef %1) unnamed_addr #1 {
  %3 = xor i32 %1, %0
  %4 = ashr i32 %1, 1
  %5 = shl nsw i32 %3, 1
  %6 = sub i32 %5, %4
  ret i32 %6
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define dso_local i32 @across_call(ptr noundef readonly captures(none) %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #2 {
  %4 = load i32, ptr %0, align 4, !tbaa !5
  %5 = tail call fastcc i32 @mixed(i32 noundef %1, i32 noundef %2)
  %6 = shl nsw i32 %4, 1
  %7 = add nsw i32 %6, %5
  ret i32 %7
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @in_loop(ptr noundef readonly captures(none) %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #3 {
  %5 = icmp sgt i32 %1, 0
  br i1 %5, label %6, label %9

6:                                                ; preds = %4
  %7 = tail call fastcc i32 @mixed(i32 noundef %2, i32 noundef %3)
  %8 = zext nneg i32 %1 to i64
  br label %11

9:                                                ; preds = %11, %4
  %10 = phi i32 [ 0, %4 ], [ %17, %11 ]
  ret i32 %10

11:                                               ; preds = %6, %11
  %12 = phi i64 [ 0, %6 ], [ %18, %11 ]
  %13 = phi i32 [ 0, %6 ], [ %17, %11 ]
  %14 = getelementptr inbounds nuw i32, ptr %0, i64 %12
  %15 = load i32, ptr %14, align 4, !tbaa !5
  %16 = add i32 %15, %13
  %17 = add i32 %16, %7
  %18 = add nuw nsw i64 %12, 1
  %19 = icmp eq i64 %18, %8
  br i1 %19, label %9, label %11, !llvm.loop !9
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @unused_result(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %1, %0
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(readwrite, inaccessiblemem: none) uwtable
define dso_local i32 @writer_twice(i32 noundef %0) local_unnamed_addr #4 {
  %2 = tail call fastcc i32 @record(i32 noundef %0)
  %3 = tail call fastcc i32 @record(i32 noundef %0)
  %4 = add nsw i32 %3, %2
  ret i32 %4
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable
define internal fastcc i32 @record(i32 noundef %0) unnamed_addr #5 {
  %2 = load i32, ptr @written_total, align 4, !tbaa !5
  %3 = add nsw i32 %2, %0
  store i32 %3, ptr @written_total, align 4, !tbaa !5
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(readwrite, inaccessiblemem: none) uwtable
define dso_local i32 @across_writer(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #4 {
  %3 = load i32, ptr %0, align 4, !tbaa !5
  %4 = tail call fastcc i32 @record(i32 noundef %1)
  %5 = load i32, ptr %0, align 4, !tbaa !5
  %6 = add nsw i32 %5, %3
  ret i32 %6
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(readwrite, inaccessiblemem: none) uwtable
define dso_local noundef i32 @unused_writer(i32 noundef returned %0) local_unnamed_addr #4 {
  %2 = tail call fastcc i32 @record(i32 noundef %0)
  ret i32 %0
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define dso_local range(i32 -2147483648, 2147483647) i32 @reader_twice(ptr noundef readonly captures(none) %0) local_unnamed_addr #2 {
  %2 = tail call fastcc i32 @first_two(ptr noundef %0)
  %3 = shl nsw i32 %2, 1
  ret i32 %3
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define internal fastcc i32 @first_two(ptr noundef readonly captures(none) %0) unnamed_addr #6 {
  %2 = load i32, ptr %0, align 4, !tbaa !5
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 4
  %4 = load i32, ptr %3, align 4, !tbaa !5
  %5 = add nsw i32 %4, %2
  ret i32 %5
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite) uwtable
define dso_local i32 @reader_across_write(ptr noundef captures(none) %0, i32 noundef %1) local_unnamed_addr #7 {
  %3 = tail call fastcc i32 @first_two(ptr noundef %0)
  store i32 %1, ptr %0, align 4, !tbaa !5
  %4 = tail call fastcc i32 @first_two(ptr noundef nonnull %0)
  %5 = add nsw i32 %4, %3
  ret i32 %5
}

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local i32 @unused_loop(i32 noundef %0, i32 noundef %1) local_unnamed_addr #8 {
  %3 = tail call fastcc i32 @weigh(i32 noundef %0, i32 noundef %1)
  %4 = add nsw i32 %1, %0
  ret i32 %4
}

; Function Attrs: nofree noinline norecurse nosync nounwind memory(none) uwtable
define internal fastcc i32 @weigh(i32 noundef %0, i32 noundef %1) unnamed_addr #9 {
  br label %4

3:                                                ; preds = %4
  ret i32 %11

4:                                                ; preds = %2, %4
  %5 = phi i32 [ 0, %2 ], [ %12, %4 ]
  %6 = phi i32 [ 0, %2 ], [ %11, %4 ]
  %7 = add nsw i32 %5, %1
  %8 = xor i32 %7, %0
  %9 = add nuw nsw i32 %5, 3
  %10 = mul nsw i32 %8, %9
  %11 = add nsw i32 %10, %6
  %12 = add nuw nsw i32 %5, 1
  %13 = icmp eq i32 %12, 8
  br i1 %13, label %3, label %4, !llvm.loop !12
}

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local i32 @loop_of_loops(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #8 {
  %4 = icmp sgt i32 %0, 0
  br i1 %4, label %5, label %8

5:                                                ; preds = %3
  %6 = tail call fastcc i32 @weigh(i32 noundef %1, i32 noundef %2)
  %7 = mul i32 %6, %0
  br label %8

8:                                                ; preds = %5, %3
  %9 = phi i32 [ 0, %3 ], [ %7, %5 ]
  ret i32 %9
}

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local noundef i32 @unused_spin(i32 noundef returned %0) local_unnamed_addr #8 {
  %2 = tail call fastcc i32 @settle(i32 noundef %0)
  ret i32 %0
}

; Function Attrs: nofree noinline norecurse nosync nounwind memory(none) uwtable
define internal fastcc range(i32 101, -2147483648) i32 @settle(i32 noundef %0) unnamed_addr #9 {
  br label %2

2:                                                ; preds = %2, %1
  %3 = phi i32 [ 0, %1 ], [ %4, %2 ]
  %4 = add nsw i32 %3, %0
  %5 = icmp sgt i32 %4, 100
  br i1 %5, label %6, label %2, !llvm.loop !13

6:                                                ; preds = %2
  ret i32 %4
}

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local range(i32 0, -2147483648) i32 @loop_of_spins(i32 noundef %0, i32 noundef %1) local_unnamed_addr #8 {
  %3 = icmp sgt i32 %0, 0
  br i1 %3, label %4, label %7

4:                                                ; preds = %2
  %5 = tail call fastcc i32 @settle(i32 noundef %1)
  %6 = mul i32 %5, %0
  br label %7

7:                                                ; preds = %4, %2
  %8 = phi i32 [ 0, %2 ], [ %6, %4 ]
  ret i32 %8
}

; Function Attrs: nofree nosync nounwind memory(none) uwtable
define dso_local noundef i32 @unused_recursion(i32 noundef returned %0) local_unnamed_addr #10 {
  %2 = tail call fastcc i32 @chain(i32 noundef %0)
  ret i32 %0
}

; Function Attrs: nofree noinline nosync nounwind memory(none) uwtable
define internal fastcc range(i32 0, -2147483648) i32 @chain(i32 noundef %0) unnamed_addr #11 {
  br label %2

2:                                                ; preds = %6, %1
  %3 = phi i32 [ 0, %1 ], [ %8, %6 ]
  %4 = phi i32 [ %0, %1 ], [ %7, %6 ]
  %5 = icmp slt i32 %4, 1
  br i1 %5, label %9, label %6

6:                                                ; preds = %2
  %7 = add nsw i32 %4, -1
  %8 = add nuw nsw i32 %3, %4
  br label %2

9:                                                ; preds = %2
  %10 = add nuw nsw i32 %3, 0
  ret i32 %10
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable
define dso_local noundef i32 @seen_across_copy() local_unnamed_addr #12 {
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) @held, i8 0, i64 32, i1 false)
  ret i32 0
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable
define dso_local noundef i32 @seen_across_set() local_unnamed_addr #12 {
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) @held, i8 0, i64 32, i1 false)
  ret i32 0
}

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: write)
declare void @llvm.memset.p0.i64(ptr writeonly captures(none), i8, i64, i1 immarg) #13

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable
define dso_local i32 @copied_into() local_unnamed_addr #14 {
  %1 = load i32, ptr @held, align 16, !tbaa !5
  tail call void @llvm.memset.p0.i64(ptr noundef nonnull align 16 dereferenceable(32) @held, i8 0, i64 32, i1 false)
  ret i32 %1
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree norecurse nosync nounwind memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind willreturn memory(readwrite, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #7 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #8 = { nofree norecurse nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #9 = { nofree noinline norecurse nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #10 = { nofree nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #11 = { nofree noinline nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #12 = { mustprogress nofree norecurse nosync nounwind willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #13 = { mustprogress nocallback nofree nounwind willreturn memory(argmem: write) }
attributes #14 = { mustprogress nofree norecurse nosync nounwind willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }

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
!9 = distinct !{!9, !10, !11}
!10 = !{!"llvm.loop.mustprogress"}
!11 = !{!"llvm.loop.unroll.disable"}
!12 = distinct !{!12, !10, !11}
!13 = distinct !{!13, !11}
