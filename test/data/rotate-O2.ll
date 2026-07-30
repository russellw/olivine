; ModuleID = 'test/c/rotate.c'
source_filename = "test/c/rotate.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@ticket = internal unnamed_addr global i32 0, align 4

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @scale_all(ptr noundef readonly captures(none) %0, i32 noundef %1, ptr noundef readonly captures(none) %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %34

5:                                                ; preds = %3
  %6 = load i32, ptr %2, align 4, !tbaa !5
  %7 = zext nneg i32 %1 to i64
  %8 = icmp ult i32 %1, 8
  br i1 %8, label %31, label %9

9:                                                ; preds = %5
  %10 = and i64 %7, 2147483640
  %11 = insertelement <4 x i32> poison, i32 %6, i64 0
  %12 = shufflevector <4 x i32> %11, <4 x i32> poison, <4 x i32> zeroinitializer
  br label %13

13:                                               ; preds = %13, %9
  %14 = phi i64 [ 0, %9 ], [ %25, %13 ]
  %15 = phi <4 x i32> [ zeroinitializer, %9 ], [ %23, %13 ]
  %16 = phi <4 x i32> [ zeroinitializer, %9 ], [ %24, %13 ]
  %17 = getelementptr inbounds nuw i32, ptr %0, i64 %14
  %18 = getelementptr inbounds nuw i8, ptr %17, i64 16
  %19 = load <4 x i32>, ptr %17, align 4, !tbaa !5
  %20 = load <4 x i32>, ptr %18, align 4, !tbaa !5
  %21 = mul nsw <4 x i32> %12, %19
  %22 = mul nsw <4 x i32> %12, %20
  %23 = add <4 x i32> %21, %15
  %24 = add <4 x i32> %22, %16
  %25 = add nuw i64 %14, 8
  %26 = icmp eq i64 %25, %10
  br i1 %26, label %27, label %13, !llvm.loop !9

27:                                               ; preds = %13
  %28 = add <4 x i32> %24, %23
  %29 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %28)
  %30 = icmp eq i64 %10, %7
  br i1 %30, label %34, label %31

31:                                               ; preds = %5, %27
  %32 = phi i64 [ 0, %5 ], [ %10, %27 ]
  %33 = phi i32 [ 0, %5 ], [ %29, %27 ]
  br label %36

34:                                               ; preds = %36, %27, %3
  %35 = phi i32 [ 0, %3 ], [ %29, %27 ], [ %42, %36 ]
  ret i32 %35

36:                                               ; preds = %31, %36
  %37 = phi i64 [ %43, %36 ], [ %32, %31 ]
  %38 = phi i32 [ %42, %36 ], [ %33, %31 ]
  %39 = getelementptr inbounds nuw i32, ptr %0, i64 %37
  %40 = load i32, ptr %39, align 4, !tbaa !5
  %41 = mul nsw i32 %6, %40
  %42 = add nsw i32 %41, %38
  %43 = add nuw nsw i64 %37, 1
  %44 = icmp eq i64 %43, %7
  br i1 %44, label %34, label %36, !llvm.loop !13
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(read, argmem: none, inaccessiblemem: none) uwtable
define dso_local i32 @tickets_taken() local_unnamed_addr #1 {
  %1 = load i32, ptr @ticket, align 4, !tbaa !5
  ret i32 %1
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable
define dso_local void @reset_tickets() local_unnamed_addr #2 {
  store i32 0, ptr @ticket, align 4, !tbaa !5
  ret void
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable
define dso_local i32 @consume(i32 noundef %0) local_unnamed_addr #3 {
  %2 = load i32, ptr @ticket, align 4, !tbaa !5
  %3 = tail call i32 @llvm.smax.i32(i32 %2, i32 %0)
  %4 = sub i32 %3, %2
  %5 = add i32 %2, 1
  %6 = mul i32 %4, %5
  %7 = xor i32 %2, -1
  %8 = add i32 %3, %7
  %9 = zext i32 %8 to i33
  %10 = zext i32 %4 to i33
  %11 = mul i33 %9, %10
  %12 = lshr i33 %11, 1
  %13 = trunc nuw i33 %12 to i32
  %14 = add i32 %6, %13
  %15 = add i32 %3, 1
  store i32 %15, ptr @ticket, align 4, !tbaa !5
  ret i32 %14
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 1, 1431655767) i32 @countdown(i32 noundef %0) local_unnamed_addr #4 {
  %2 = add i32 %0, 2
  %3 = tail call i32 @llvm.smin.i32(i32 %0, i32 3)
  %4 = sub i32 %2, %3
  %5 = udiv i32 %4, 3
  %6 = add nuw nsw i32 %5, 1
  ret i32 %6
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #5

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #5

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.vector.reduce.add.v4i32(<4 x i32>) #5

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree norecurse nosync nounwind willreturn memory(read, argmem: none, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

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
