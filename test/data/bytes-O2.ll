; ModuleID = 'test/c/bytes.c'
source_filename = "test/c/bytes.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable
define dso_local void @scale_apart(ptr noalias noundef writeonly captures(none) %0, ptr noalias noundef readonly captures(none) %1, i32 noundef %2, ptr noalias noundef readonly captures(none) %3) local_unnamed_addr #0 {
  %5 = icmp sgt i32 %2, 0
  br i1 %5, label %6, label %30

6:                                                ; preds = %4
  %7 = load i32, ptr %3, align 4, !tbaa !5
  %8 = zext nneg i32 %2 to i64
  %9 = icmp ult i32 %2, 8
  br i1 %9, label %28, label %10

10:                                               ; preds = %6
  %11 = and i64 %8, 2147483640
  %12 = insertelement <4 x i32> poison, i32 %7, i64 0
  %13 = shufflevector <4 x i32> %12, <4 x i32> poison, <4 x i32> zeroinitializer
  br label %14

14:                                               ; preds = %14, %10
  %15 = phi i64 [ 0, %10 ], [ %24, %14 ]
  %16 = getelementptr inbounds nuw i32, ptr %1, i64 %15
  %17 = getelementptr inbounds nuw i8, ptr %16, i64 16
  %18 = load <4 x i32>, ptr %16, align 4, !tbaa !5
  %19 = load <4 x i32>, ptr %17, align 4, !tbaa !5
  %20 = mul nsw <4 x i32> %13, %18
  %21 = mul nsw <4 x i32> %13, %19
  %22 = getelementptr inbounds nuw i32, ptr %0, i64 %15
  %23 = getelementptr inbounds nuw i8, ptr %22, i64 16
  store <4 x i32> %20, ptr %22, align 4, !tbaa !5
  store <4 x i32> %21, ptr %23, align 4, !tbaa !5
  %24 = add nuw i64 %15, 8
  %25 = icmp eq i64 %24, %11
  br i1 %25, label %26, label %14, !llvm.loop !9

26:                                               ; preds = %14
  %27 = icmp eq i64 %11, %8
  br i1 %27, label %30, label %28

28:                                               ; preds = %6, %26
  %29 = phi i64 [ 0, %6 ], [ %11, %26 ]
  br label %31

30:                                               ; preds = %31, %26, %4
  ret void

31:                                               ; preds = %28, %31
  %32 = phi i64 [ %37, %31 ], [ %29, %28 ]
  %33 = getelementptr inbounds nuw i32, ptr %1, i64 %32
  %34 = load i32, ptr %33, align 4, !tbaa !5
  %35 = mul nsw i32 %7, %34
  %36 = getelementptr inbounds nuw i32, ptr %0, i64 %32
  store i32 %35, ptr %36, align 4, !tbaa !5
  %37 = add nuw nsw i64 %32, 1
  %38 = icmp eq i64 %37, %8
  br i1 %38, label %30, label %31, !llvm.loop !13
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable
define dso_local void @scale_together(ptr noundef writeonly captures(none) %0, ptr noundef readonly captures(none) %1, i32 noundef %2, ptr noundef readonly captures(none) %3) local_unnamed_addr #0 {
  %5 = icmp sgt i32 %2, 0
  br i1 %5, label %6, label %59

6:                                                ; preds = %4
  %7 = zext nneg i32 %2 to i64
  %8 = icmp ult i32 %2, 16
  br i1 %8, label %40, label %9

9:                                                ; preds = %6
  %10 = shl nuw nsw i64 %7, 2
  %11 = getelementptr i8, ptr %0, i64 %10
  %12 = getelementptr i8, ptr %1, i64 %10
  %13 = getelementptr i8, ptr %3, i64 4
  %14 = icmp ult ptr %0, %12
  %15 = icmp ult ptr %1, %11
  %16 = and i1 %14, %15
  %17 = icmp ult ptr %0, %13
  %18 = icmp ult ptr %3, %11
  %19 = and i1 %17, %18
  %20 = or i1 %16, %19
  br i1 %20, label %40, label %21

21:                                               ; preds = %9
  %22 = and i64 %7, 2147483640
  %23 = load i32, ptr %3, align 4, !tbaa !5, !alias.scope !14
  %24 = insertelement <4 x i32> poison, i32 %23, i64 0
  %25 = shufflevector <4 x i32> %24, <4 x i32> poison, <4 x i32> zeroinitializer
  br label %26

26:                                               ; preds = %26, %21
  %27 = phi i64 [ 0, %21 ], [ %36, %26 ]
  %28 = getelementptr inbounds nuw i32, ptr %1, i64 %27
  %29 = getelementptr inbounds nuw i8, ptr %28, i64 16
  %30 = load <4 x i32>, ptr %28, align 4, !tbaa !5, !alias.scope !17
  %31 = load <4 x i32>, ptr %29, align 4, !tbaa !5, !alias.scope !17
  %32 = mul nsw <4 x i32> %25, %30
  %33 = mul nsw <4 x i32> %25, %31
  %34 = getelementptr inbounds nuw i32, ptr %0, i64 %27
  %35 = getelementptr inbounds nuw i8, ptr %34, i64 16
  store <4 x i32> %32, ptr %34, align 4, !tbaa !5, !alias.scope !19, !noalias !21
  store <4 x i32> %33, ptr %35, align 4, !tbaa !5, !alias.scope !19, !noalias !21
  %36 = add nuw i64 %27, 8
  %37 = icmp eq i64 %36, %22
  br i1 %37, label %38, label %26, !llvm.loop !22

38:                                               ; preds = %26
  %39 = icmp eq i64 %22, %7
  br i1 %39, label %59, label %40

40:                                               ; preds = %9, %6, %38
  %41 = phi i64 [ 0, %9 ], [ 0, %6 ], [ %22, %38 ]
  %42 = and i64 %7, 3
  %43 = icmp eq i64 %42, 0
  br i1 %43, label %55, label %44

44:                                               ; preds = %40, %44
  %45 = phi i64 [ %52, %44 ], [ %41, %40 ]
  %46 = phi i64 [ %53, %44 ], [ 0, %40 ]
  %47 = getelementptr inbounds nuw i32, ptr %1, i64 %45
  %48 = load i32, ptr %47, align 4, !tbaa !5
  %49 = load i32, ptr %3, align 4, !tbaa !5
  %50 = mul nsw i32 %49, %48
  %51 = getelementptr inbounds nuw i32, ptr %0, i64 %45
  store i32 %50, ptr %51, align 4, !tbaa !5
  %52 = add nuw nsw i64 %45, 1
  %53 = add i64 %46, 1
  %54 = icmp eq i64 %53, %42
  br i1 %54, label %55, label %44, !llvm.loop !23

55:                                               ; preds = %44, %40
  %56 = phi i64 [ %41, %40 ], [ %52, %44 ]
  %57 = sub nsw i64 %41, %7
  %58 = icmp ugt i64 %57, -4
  br i1 %58, label %59, label %60

59:                                               ; preds = %55, %60, %38, %4
  ret void

60:                                               ; preds = %55, %60
  %61 = phi i64 [ %85, %60 ], [ %56, %55 ]
  %62 = getelementptr inbounds nuw i32, ptr %1, i64 %61
  %63 = load i32, ptr %62, align 4, !tbaa !5
  %64 = load i32, ptr %3, align 4, !tbaa !5
  %65 = mul nsw i32 %64, %63
  %66 = getelementptr inbounds nuw i32, ptr %0, i64 %61
  store i32 %65, ptr %66, align 4, !tbaa !5
  %67 = add nuw nsw i64 %61, 1
  %68 = getelementptr inbounds nuw i32, ptr %1, i64 %67
  %69 = load i32, ptr %68, align 4, !tbaa !5
  %70 = load i32, ptr %3, align 4, !tbaa !5
  %71 = mul nsw i32 %70, %69
  %72 = getelementptr inbounds nuw i32, ptr %0, i64 %67
  store i32 %71, ptr %72, align 4, !tbaa !5
  %73 = add nuw nsw i64 %61, 2
  %74 = getelementptr inbounds nuw i32, ptr %1, i64 %73
  %75 = load i32, ptr %74, align 4, !tbaa !5
  %76 = load i32, ptr %3, align 4, !tbaa !5
  %77 = mul nsw i32 %76, %75
  %78 = getelementptr inbounds nuw i32, ptr %0, i64 %73
  store i32 %77, ptr %78, align 4, !tbaa !5
  %79 = add nuw nsw i64 %61, 3
  %80 = getelementptr inbounds nuw i32, ptr %1, i64 %79
  %81 = load i32, ptr %80, align 4, !tbaa !5
  %82 = load i32, ptr %3, align 4, !tbaa !5
  %83 = mul nsw i32 %82, %81
  %84 = getelementptr inbounds nuw i32, ptr %0, i64 %79
  store i32 %83, ptr %84, align 4, !tbaa !5
  %85 = add nuw nsw i64 %61, 4
  %86 = icmp eq i64 %85, %7
  br i1 %86, label %59, label %60, !llvm.loop !25
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @checksum(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #1 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %30

4:                                                ; preds = %2
  %5 = zext nneg i32 %1 to i64
  %6 = and i64 %5, 3
  %7 = icmp ult i32 %1, 4
  br i1 %7, label %13, label %8

8:                                                ; preds = %4
  %9 = and i64 %5, 2147483644
  %10 = getelementptr inbounds i8, ptr %0, i64 1
  %11 = getelementptr inbounds i8, ptr %0, i64 2
  %12 = getelementptr inbounds i8, ptr %0, i64 3
  br label %32

13:                                               ; preds = %32, %4
  %14 = phi i32 [ poison, %4 ], [ %55, %32 ]
  %15 = phi i64 [ 0, %4 ], [ %56, %32 ]
  %16 = phi i32 [ 0, %4 ], [ %55, %32 ]
  %17 = icmp eq i64 %6, 0
  br i1 %17, label %30, label %18

18:                                               ; preds = %13, %18
  %19 = phi i64 [ %27, %18 ], [ %15, %13 ]
  %20 = phi i32 [ %26, %18 ], [ %16, %13 ]
  %21 = phi i64 [ %28, %18 ], [ 0, %13 ]
  %22 = mul i32 %20, 31
  %23 = getelementptr inbounds nuw i8, ptr %0, i64 %19
  %24 = load i8, ptr %23, align 1, !tbaa !26
  %25 = zext i8 %24 to i32
  %26 = add i32 %22, %25
  %27 = add nuw nsw i64 %19, 1
  %28 = add i64 %21, 1
  %29 = icmp eq i64 %28, %6
  br i1 %29, label %30, label %18, !llvm.loop !27

30:                                               ; preds = %13, %18, %2
  %31 = phi i32 [ 0, %2 ], [ %14, %13 ], [ %26, %18 ]
  ret i32 %31

32:                                               ; preds = %32, %8
  %33 = phi i64 [ 0, %8 ], [ %56, %32 ]
  %34 = phi i32 [ 0, %8 ], [ %55, %32 ]
  %35 = phi i64 [ 0, %8 ], [ %57, %32 ]
  %36 = mul i32 %34, 31
  %37 = getelementptr inbounds nuw i8, ptr %0, i64 %33
  %38 = load i8, ptr %37, align 1, !tbaa !26
  %39 = zext i8 %38 to i32
  %40 = add i32 %36, %39
  %41 = mul i32 %40, 31
  %42 = getelementptr inbounds i8, ptr %10, i64 %33
  %43 = load i8, ptr %42, align 1, !tbaa !26
  %44 = zext i8 %43 to i32
  %45 = add i32 %41, %44
  %46 = mul i32 %45, 31
  %47 = getelementptr inbounds i8, ptr %11, i64 %33
  %48 = load i8, ptr %47, align 1, !tbaa !26
  %49 = zext i8 %48 to i32
  %50 = add i32 %46, %49
  %51 = mul i32 %50, 31
  %52 = getelementptr inbounds i8, ptr %12, i64 %33
  %53 = load i8, ptr %52, align 1, !tbaa !26
  %54 = zext i8 %53 to i32
  %55 = add i32 %51, %54
  %56 = add nuw nsw i64 %33, 4
  %57 = add i64 %35, 4
  %58 = icmp eq i64 %57, %9
  br i1 %58, label %13, label %32, !llvm.loop !28
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local range(i32 -255, 256) i32 @span(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #1 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %41

4:                                                ; preds = %2
  %5 = zext nneg i32 %1 to i64
  %6 = icmp ult i32 %1, 8
  br i1 %6, label %33, label %7

7:                                                ; preds = %4
  %8 = and i64 %5, 2147483640
  br label %9

9:                                                ; preds = %9, %7
  %10 = phi i64 [ 0, %7 ], [ %25, %9 ]
  %11 = phi <4 x i32> [ splat (i32 -128), %7 ], [ %23, %9 ]
  %12 = phi <4 x i32> [ splat (i32 -128), %7 ], [ %24, %9 ]
  %13 = phi <4 x i32> [ splat (i32 127), %7 ], [ %21, %9 ]
  %14 = phi <4 x i32> [ splat (i32 127), %7 ], [ %22, %9 ]
  %15 = getelementptr inbounds nuw i8, ptr %0, i64 %10
  %16 = getelementptr inbounds nuw i8, ptr %15, i64 4
  %17 = load <4 x i8>, ptr %15, align 1, !tbaa !26
  %18 = load <4 x i8>, ptr %16, align 1, !tbaa !26
  %19 = sext <4 x i8> %17 to <4 x i32>
  %20 = sext <4 x i8> %18 to <4 x i32>
  %21 = tail call <4 x i32> @llvm.smin.v4i32(<4 x i32> %13, <4 x i32> %19)
  %22 = tail call <4 x i32> @llvm.smin.v4i32(<4 x i32> %14, <4 x i32> %20)
  %23 = tail call <4 x i32> @llvm.smax.v4i32(<4 x i32> %11, <4 x i32> %19)
  %24 = tail call <4 x i32> @llvm.smax.v4i32(<4 x i32> %12, <4 x i32> %20)
  %25 = add nuw i64 %10, 8
  %26 = icmp eq i64 %25, %8
  br i1 %26, label %27, label %9, !llvm.loop !29

27:                                               ; preds = %9
  %28 = tail call <4 x i32> @llvm.smax.v4i32(<4 x i32> %23, <4 x i32> %24)
  %29 = tail call i32 @llvm.vector.reduce.smax.v4i32(<4 x i32> %28)
  %30 = tail call <4 x i32> @llvm.smin.v4i32(<4 x i32> %21, <4 x i32> %22)
  %31 = tail call i32 @llvm.vector.reduce.smin.v4i32(<4 x i32> %30)
  %32 = icmp eq i64 %8, %5
  br i1 %32, label %37, label %33

33:                                               ; preds = %4, %27
  %34 = phi i64 [ 0, %4 ], [ %8, %27 ]
  %35 = phi i32 [ -128, %4 ], [ %29, %27 ]
  %36 = phi i32 [ 127, %4 ], [ %31, %27 ]
  br label %43

37:                                               ; preds = %43, %27
  %38 = phi i32 [ %31, %27 ], [ %50, %43 ]
  %39 = phi i32 [ %29, %27 ], [ %51, %43 ]
  %40 = sub nsw i32 %39, %38
  br label %41

41:                                               ; preds = %37, %2
  %42 = phi i32 [ -255, %2 ], [ %40, %37 ]
  ret i32 %42

43:                                               ; preds = %33, %43
  %44 = phi i64 [ %52, %43 ], [ %34, %33 ]
  %45 = phi i32 [ %51, %43 ], [ %35, %33 ]
  %46 = phi i32 [ %50, %43 ], [ %36, %33 ]
  %47 = getelementptr inbounds nuw i8, ptr %0, i64 %44
  %48 = load i8, ptr %47, align 1, !tbaa !26
  %49 = sext i8 %48 to i32
  %50 = tail call i32 @llvm.smin.i32(i32 %46, i32 %49)
  %51 = tail call i32 @llvm.smax.i32(i32 %45, i32 %49)
  %52 = add nuw nsw i64 %44, 1
  %53 = icmp eq i64 %52, %5
  br i1 %53, label %37, label %43, !llvm.loop !30
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef zeroext i8 @low_bits(i32 noundef %0) local_unnamed_addr #2 {
  %2 = lshr i32 %0, 3
  %3 = trunc i32 %2 to i8
  ret i8 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef signext i16 @folded_down(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = add i32 %1, 1
  %4 = mul i32 %3, %0
  %5 = trunc i32 %4 to i16
  ret i16 %5
}

; Function Attrs: mustprogress nofree norecurse nounwind willreturn memory(argmem: read) uwtable
define dso_local i32 @length(ptr noundef readonly captures(none) %0) local_unnamed_addr #3 {
  %2 = tail call i64 @strlen(ptr noundef nonnull dereferenceable(1) %0)
  %3 = trunc i64 %2 to i32
  ret i32 %3
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable
define dso_local void @copy_bytes(ptr noalias noundef writeonly captures(none) %0, ptr noalias noundef readonly captures(none) %1) local_unnamed_addr #0 {
  br label %3

3:                                                ; preds = %3, %2
  %4 = phi ptr [ %0, %2 ], [ %8, %3 ]
  %5 = phi ptr [ %1, %2 ], [ %6, %3 ]
  %6 = getelementptr inbounds nuw i8, ptr %5, i64 1
  %7 = load i8, ptr %5, align 1, !tbaa !26
  %8 = getelementptr inbounds nuw i8, ptr %4, i64 1
  store i8 %7, ptr %4, align 1, !tbaa !26
  %9 = icmp eq i8 %7, 0
  br i1 %9, label %10, label %3, !llvm.loop !31

10:                                               ; preds = %3
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #4

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smax.i32(i32, i32) #4

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: read)
declare i64 @strlen(ptr captures(none)) local_unnamed_addr #5

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare <4 x i32> @llvm.smin.v4i32(<4 x i32>, <4 x i32>) #4

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare <4 x i32> @llvm.smax.v4i32(<4 x i32>, <4 x i32>) #4

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.vector.reduce.smax.v4i32(<4 x i32>) #4

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.vector.reduce.smin.v4i32(<4 x i32>) #4

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree norecurse nosync nounwind memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nounwind willreturn memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nocallback nofree nounwind willreturn memory(argmem: read) }

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
!14 = !{!15}
!15 = distinct !{!15, !16}
!16 = distinct !{!16, !"LVerDomain"}
!17 = !{!18}
!18 = distinct !{!18, !16}
!19 = !{!20}
!20 = distinct !{!20, !16}
!21 = !{!18, !15}
!22 = distinct !{!22, !10, !11, !12}
!23 = distinct !{!23, !24}
!24 = !{!"llvm.loop.unroll.disable"}
!25 = distinct !{!25, !10, !11}
!26 = !{!7, !7, i64 0}
!27 = distinct !{!27, !24}
!28 = distinct !{!28, !10}
!29 = distinct !{!29, !10, !11, !12}
!30 = distinct !{!30, !10, !12, !11}
!31 = distinct !{!31, !10}
