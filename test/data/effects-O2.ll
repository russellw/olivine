; ModuleID = 'test/c/effects.c'
source_filename = "test/c/effects.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

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
  br i1 %5, label %6, label %35

6:                                                ; preds = %4
  %7 = tail call fastcc i32 @mixed(i32 noundef %2, i32 noundef %3)
  %8 = zext nneg i32 %1 to i64
  %9 = icmp ult i32 %1, 8
  br i1 %9, label %32, label %10

10:                                               ; preds = %6
  %11 = and i64 %8, 2147483640
  %12 = insertelement <4 x i32> poison, i32 %7, i64 0
  %13 = shufflevector <4 x i32> %12, <4 x i32> poison, <4 x i32> zeroinitializer
  br label %14

14:                                               ; preds = %14, %10
  %15 = phi i64 [ 0, %10 ], [ %26, %14 ]
  %16 = phi <4 x i32> [ zeroinitializer, %10 ], [ %24, %14 ]
  %17 = phi <4 x i32> [ zeroinitializer, %10 ], [ %25, %14 ]
  %18 = getelementptr inbounds nuw i32, ptr %0, i64 %15
  %19 = getelementptr inbounds nuw i8, ptr %18, i64 16
  %20 = load <4 x i32>, ptr %18, align 4, !tbaa !5
  %21 = load <4 x i32>, ptr %19, align 4, !tbaa !5
  %22 = add <4 x i32> %20, %16
  %23 = add <4 x i32> %21, %17
  %24 = add <4 x i32> %22, %13
  %25 = add <4 x i32> %23, %13
  %26 = add nuw i64 %15, 8
  %27 = icmp eq i64 %26, %11
  br i1 %27, label %28, label %14, !llvm.loop !9

28:                                               ; preds = %14
  %29 = add <4 x i32> %25, %24
  %30 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %29)
  %31 = icmp eq i64 %11, %8
  br i1 %31, label %35, label %32

32:                                               ; preds = %6, %28
  %33 = phi i64 [ 0, %6 ], [ %11, %28 ]
  %34 = phi i32 [ 0, %6 ], [ %30, %28 ]
  br label %37

35:                                               ; preds = %37, %28, %4
  %36 = phi i32 [ 0, %4 ], [ %30, %28 ], [ %43, %37 ]
  ret i32 %36

37:                                               ; preds = %32, %37
  %38 = phi i64 [ %44, %37 ], [ %33, %32 ]
  %39 = phi i32 [ %43, %37 ], [ %34, %32 ]
  %40 = getelementptr inbounds nuw i32, ptr %0, i64 %38
  %41 = load i32, ptr %40, align 4, !tbaa !5
  %42 = add i32 %41, %39
  %43 = add i32 %42, %7
  %44 = add nuw nsw i64 %38, 1
  %45 = icmp eq i64 %44, %8
  br i1 %45, label %35, label %37, !llvm.loop !13
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

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @unused_loop(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %1, %0
  ret i32 %3
}

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) uwtable
define internal fastcc i32 @weigh(i32 noundef %0, i32 noundef %1) unnamed_addr #1 {
  %3 = xor i32 %1, %0
  %4 = mul nsw i32 %3, 3
  %5 = add nsw i32 %1, 1
  %6 = xor i32 %5, %0
  %7 = shl nsw i32 %6, 2
  %8 = add nsw i32 %7, %4
  %9 = add nsw i32 %1, 2
  %10 = xor i32 %9, %0
  %11 = mul nsw i32 %10, 5
  %12 = add nsw i32 %11, %8
  %13 = add nsw i32 %1, 3
  %14 = xor i32 %13, %0
  %15 = mul nsw i32 %14, 6
  %16 = add nsw i32 %15, %12
  %17 = add nsw i32 %1, 4
  %18 = xor i32 %17, %0
  %19 = mul nsw i32 %18, 7
  %20 = add nsw i32 %19, %16
  %21 = add nsw i32 %1, 5
  %22 = xor i32 %21, %0
  %23 = shl nsw i32 %22, 3
  %24 = add nsw i32 %23, %20
  %25 = add nsw i32 %1, 6
  %26 = xor i32 %25, %0
  %27 = mul nsw i32 %26, 9
  %28 = add nsw i32 %27, %24
  %29 = add nsw i32 %1, 7
  %30 = xor i32 %29, %0
  %31 = mul nsw i32 %30, 10
  %32 = add nsw i32 %31, %28
  ret i32 %32
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @loop_of_loops(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
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
  br i1 %5, label %6, label %2

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

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef i32 @unused_recursion(i32 noundef returned %0) local_unnamed_addr #0 {
  ret i32 %0
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.vector.reduce.add.v4i32(<4 x i32>) #10

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
attributes #10 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

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
!9 = distinct !{!9, !10, !11, !12}
!10 = !{!"llvm.loop.mustprogress"}
!11 = !{!"llvm.loop.isvectorized", i32 1}
!12 = !{!"llvm.loop.unroll.runtime.disable"}
!13 = distinct !{!13, !10, !12, !11}
