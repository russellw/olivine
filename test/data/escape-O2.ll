; ModuleID = 'test/c/escape.c'
source_filename = "test/c/escape.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 2, 1) i32 @through_pointer(i32 noundef %0) local_unnamed_addr #0 {
  %2 = shl i32 %0, 1
  %3 = add i32 %2, 2
  ret i32 %3
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nofree norecurse nounwind memory(inaccessiblemem: readwrite) uwtable
define dso_local i32 @volatile_local(i32 noundef %0) local_unnamed_addr #2 {
  %2 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2)
  store volatile i32 %0, ptr %2, align 4, !tbaa !5
  %3 = load volatile i32, ptr %2, align 4, !tbaa !5
  %4 = add nsw i32 %3, 1
  store volatile i32 %4, ptr %2, align 4, !tbaa !5
  %5 = load volatile i32, ptr %2, align 4, !tbaa !5
  %6 = load volatile i32, ptr %2, align 4, !tbaa !5
  %7 = add nsw i32 %6, %5
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2)
  ret i32 %7
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef i32 @addressed_pair(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @llvm.smin.i32(i32 %0, i32 %1)
  ret i32 %3
}

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local i64 @counted(i32 noundef %0) local_unnamed_addr #3 {
  %2 = zext i32 %0 to i64
  %3 = alloca i32, i64 %2, align 16
  %4 = icmp sgt i32 %0, 0
  br i1 %4, label %5, label %58

5:                                                ; preds = %1
  %6 = icmp ult i32 %0, 4
  br i1 %6, label %23, label %7

7:                                                ; preds = %5
  %8 = and i64 %2, 2147483644
  %9 = insertelement <4 x i32> poison, i32 %0, i64 0
  %10 = shufflevector <4 x i32> %9, <4 x i32> poison, <4 x i32> zeroinitializer
  br label %11

11:                                               ; preds = %11, %7
  %12 = phi i64 [ 0, %7 ], [ %18, %11 ]
  %13 = phi <4 x i64> [ <i64 0, i64 1, i64 2, i64 3>, %7 ], [ %19, %11 ]
  %14 = mul nuw nsw <4 x i64> %13, %13
  %15 = trunc nuw <4 x i64> %14 to <4 x i32>
  %16 = sub nsw <4 x i32> %15, %10
  %17 = getelementptr inbounds nuw i32, ptr %3, i64 %12
  store <4 x i32> %16, ptr %17, align 16, !tbaa !5
  %18 = add nuw i64 %12, 4
  %19 = add <4 x i64> %13, splat (i64 4)
  %20 = icmp eq i64 %18, %8
  br i1 %20, label %21, label %11, !llvm.loop !9

21:                                               ; preds = %11
  %22 = icmp eq i64 %8, %2
  br i1 %22, label %33, label %23

23:                                               ; preds = %5, %21
  %24 = phi i64 [ 0, %5 ], [ %8, %21 ]
  br label %25

25:                                               ; preds = %23, %25
  %26 = phi i64 [ %31, %25 ], [ %24, %23 ]
  %27 = mul nuw nsw i64 %26, %26
  %28 = trunc nuw i64 %27 to i32
  %29 = sub nsw i32 %28, %0
  %30 = getelementptr inbounds nuw i32, ptr %3, i64 %26
  store i32 %29, ptr %30, align 4, !tbaa !5
  %31 = add nuw nsw i64 %26, 1
  %32 = icmp eq i64 %31, %2
  br i1 %32, label %33, label %25, !llvm.loop !13

33:                                               ; preds = %25, %21
  %34 = icmp ult i32 %0, 4
  br i1 %34, label %55, label %35

35:                                               ; preds = %33
  %36 = and i64 %2, 2147483644
  br label %37

37:                                               ; preds = %37, %35
  %38 = phi i64 [ 0, %35 ], [ %49, %37 ]
  %39 = phi <2 x i64> [ zeroinitializer, %35 ], [ %47, %37 ]
  %40 = phi <2 x i64> [ zeroinitializer, %35 ], [ %48, %37 ]
  %41 = getelementptr inbounds nuw i32, ptr %3, i64 %38
  %42 = getelementptr inbounds nuw i8, ptr %41, i64 8
  %43 = load <2 x i32>, ptr %41, align 16, !tbaa !5
  %44 = load <2 x i32>, ptr %42, align 8, !tbaa !5
  %45 = sext <2 x i32> %43 to <2 x i64>
  %46 = sext <2 x i32> %44 to <2 x i64>
  %47 = add <2 x i64> %39, %45
  %48 = add <2 x i64> %40, %46
  %49 = add nuw i64 %38, 4
  %50 = icmp eq i64 %49, %36
  br i1 %50, label %51, label %37, !llvm.loop !14

51:                                               ; preds = %37
  %52 = add <2 x i64> %48, %47
  %53 = tail call i64 @llvm.vector.reduce.add.v2i64(<2 x i64> %52)
  %54 = icmp eq i64 %36, %2
  br i1 %54, label %58, label %55

55:                                               ; preds = %33, %51
  %56 = phi i64 [ 0, %33 ], [ %36, %51 ]
  %57 = phi i64 [ 0, %33 ], [ %53, %51 ]
  br label %60

58:                                               ; preds = %60, %51, %1
  %59 = phi i64 [ 0, %1 ], [ %53, %51 ], [ %66, %60 ]
  ret i64 %59

60:                                               ; preds = %55, %60
  %61 = phi i64 [ %67, %60 ], [ %56, %55 ]
  %62 = phi i64 [ %66, %60 ], [ %57, %55 ]
  %63 = getelementptr inbounds nuw i32, ptr %3, i64 %61
  %64 = load i32, ptr %63, align 4, !tbaa !5
  %65 = sext i32 %64 to i64
  %66 = add nsw i64 %62, %65
  %67 = add nuw nsw i64 %61, 1
  %68 = icmp eq i64 %67, %2
  br i1 %68, label %58, label %60, !llvm.loop !15
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef i32 @only_stored(i32 noundef returned %0) local_unnamed_addr #0 {
  ret i32 %0
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.smin.i32(i32, i32) #4

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i64 @llvm.vector.reduce.add.v2i64(<2 x i64>) #4

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nofree norecurse nounwind memory(inaccessiblemem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree norecurse nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

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
!14 = distinct !{!14, !10, !11, !12}
!15 = distinct !{!15, !10, !12, !11}
