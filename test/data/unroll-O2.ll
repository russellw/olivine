; ModuleID = 'test/c/unroll.c'
source_filename = "test/c/unroll.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define dso_local i32 @total4(ptr noundef readonly captures(none) %0) local_unnamed_addr #0 {
  %2 = load <4 x i32>, ptr %0, align 4, !tbaa !5
  %3 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %2)
  ret i32 %3
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @total_n(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #1 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %28

4:                                                ; preds = %2
  %5 = zext nneg i32 %1 to i64
  %6 = icmp ult i32 %1, 8
  br i1 %6, label %25, label %7

7:                                                ; preds = %4
  %8 = and i64 %5, 2147483640
  br label %9

9:                                                ; preds = %9, %7
  %10 = phi i64 [ 0, %7 ], [ %19, %9 ]
  %11 = phi <4 x i32> [ zeroinitializer, %7 ], [ %17, %9 ]
  %12 = phi <4 x i32> [ zeroinitializer, %7 ], [ %18, %9 ]
  %13 = getelementptr inbounds nuw i32, ptr %0, i64 %10
  %14 = getelementptr inbounds nuw i8, ptr %13, i64 16
  %15 = load <4 x i32>, ptr %13, align 4, !tbaa !5
  %16 = load <4 x i32>, ptr %14, align 4, !tbaa !5
  %17 = add <4 x i32> %15, %11
  %18 = add <4 x i32> %16, %12
  %19 = add nuw i64 %10, 8
  %20 = icmp eq i64 %19, %8
  br i1 %20, label %21, label %9, !llvm.loop !9

21:                                               ; preds = %9
  %22 = add <4 x i32> %18, %17
  %23 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %22)
  %24 = icmp eq i64 %8, %5
  br i1 %24, label %28, label %25

25:                                               ; preds = %4, %21
  %26 = phi i64 [ 0, %4 ], [ %8, %21 ]
  %27 = phi i32 [ 0, %4 ], [ %23, %21 ]
  br label %30

28:                                               ; preds = %30, %21, %2
  %29 = phi i32 [ 0, %2 ], [ %23, %21 ], [ %35, %30 ]
  ret i32 %29

30:                                               ; preds = %25, %30
  %31 = phi i64 [ %36, %30 ], [ %26, %25 ]
  %32 = phi i32 [ %35, %30 ], [ %27, %25 ]
  %33 = getelementptr inbounds nuw i32, ptr %0, i64 %31
  %34 = load i32, ptr %33, align 4, !tbaa !5
  %35 = add nsw i32 %34, %32
  %36 = add nuw nsw i64 %31, 1
  %37 = icmp eq i64 %36, %5
  br i1 %37, label %28, label %30, !llvm.loop !13
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define dso_local i32 @every_third(ptr noundef readonly captures(none) %0) local_unnamed_addr #0 {
  %2 = load i32, ptr %0, align 4, !tbaa !5
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %4 = load i32, ptr %3, align 4, !tbaa !5
  %5 = add nsw i32 %4, %2
  %6 = getelementptr inbounds nuw i8, ptr %0, i64 24
  %7 = load i32, ptr %6, align 4, !tbaa !5
  %8 = add nsw i32 %7, %5
  %9 = getelementptr inbounds nuw i8, ptr %0, i64 36
  %10 = load i32, ptr %9, align 4, !tbaa !5
  %11 = add nsw i32 %10, %8
  ret i32 %11
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define dso_local i32 @count_back(ptr noundef readonly captures(none) %0) local_unnamed_addr #0 {
  %2 = load <4 x i32>, ptr %0, align 4, !tbaa !5
  %3 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %2)
  ret i32 %3
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) uwtable
define dso_local void @fill4(ptr noundef writeonly captures(none) initializes((0, 16)) %0, i32 noundef %1) local_unnamed_addr #2 {
  store i32 %1, ptr %0, align 4, !tbaa !5
  %3 = add i32 %1, 1
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 4
  store i32 %3, ptr %4, align 4, !tbaa !5
  %5 = add i32 %1, 2
  %6 = getelementptr inbounds nuw i8, ptr %0, i64 8
  store i32 %5, ptr %6, align 4, !tbaa !5
  %7 = add i32 %1, 3
  %8 = getelementptr inbounds nuw i8, ptr %0, i64 12
  store i32 %7, ptr %8, align 4, !tbaa !5
  ret void
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @total64(ptr noundef readonly captures(none) %0) local_unnamed_addr #1 {
  %2 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %3 = load <4 x i32>, ptr %0, align 4, !tbaa !5
  %4 = load <4 x i32>, ptr %2, align 4, !tbaa !5
  %5 = getelementptr inbounds nuw i8, ptr %0, i64 32
  %6 = getelementptr inbounds nuw i8, ptr %0, i64 48
  %7 = load <4 x i32>, ptr %5, align 4, !tbaa !5
  %8 = load <4 x i32>, ptr %6, align 4, !tbaa !5
  %9 = add <4 x i32> %7, %3
  %10 = add <4 x i32> %8, %4
  %11 = getelementptr inbounds nuw i8, ptr %0, i64 64
  %12 = getelementptr inbounds nuw i8, ptr %0, i64 80
  %13 = load <4 x i32>, ptr %11, align 4, !tbaa !5
  %14 = load <4 x i32>, ptr %12, align 4, !tbaa !5
  %15 = add <4 x i32> %13, %9
  %16 = add <4 x i32> %14, %10
  %17 = getelementptr inbounds nuw i8, ptr %0, i64 96
  %18 = getelementptr inbounds nuw i8, ptr %0, i64 112
  %19 = load <4 x i32>, ptr %17, align 4, !tbaa !5
  %20 = load <4 x i32>, ptr %18, align 4, !tbaa !5
  %21 = add <4 x i32> %19, %15
  %22 = add <4 x i32> %20, %16
  %23 = getelementptr inbounds nuw i8, ptr %0, i64 128
  %24 = getelementptr inbounds nuw i8, ptr %0, i64 144
  %25 = load <4 x i32>, ptr %23, align 4, !tbaa !5
  %26 = load <4 x i32>, ptr %24, align 4, !tbaa !5
  %27 = add <4 x i32> %25, %21
  %28 = add <4 x i32> %26, %22
  %29 = getelementptr inbounds nuw i8, ptr %0, i64 160
  %30 = getelementptr inbounds nuw i8, ptr %0, i64 176
  %31 = load <4 x i32>, ptr %29, align 4, !tbaa !5
  %32 = load <4 x i32>, ptr %30, align 4, !tbaa !5
  %33 = add <4 x i32> %31, %27
  %34 = add <4 x i32> %32, %28
  %35 = getelementptr inbounds nuw i8, ptr %0, i64 192
  %36 = getelementptr inbounds nuw i8, ptr %0, i64 208
  %37 = load <4 x i32>, ptr %35, align 4, !tbaa !5
  %38 = load <4 x i32>, ptr %36, align 4, !tbaa !5
  %39 = add <4 x i32> %37, %33
  %40 = add <4 x i32> %38, %34
  %41 = getelementptr inbounds nuw i8, ptr %0, i64 224
  %42 = getelementptr inbounds nuw i8, ptr %0, i64 240
  %43 = load <4 x i32>, ptr %41, align 4, !tbaa !5
  %44 = load <4 x i32>, ptr %42, align 4, !tbaa !5
  %45 = add <4 x i32> %43, %39
  %46 = add <4 x i32> %44, %40
  %47 = add <4 x i32> %46, %45
  %48 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %47)
  ret i32 %48
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define dso_local i32 @wide4(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = load i32, ptr %0, align 4, !tbaa !5
  %4 = mul nsw i32 %3, %1
  %5 = add nsw i32 %4, %3
  %6 = mul nsw i32 %5, %5
  %7 = sub nsw i32 %6, %4
  %8 = mul nsw i32 %7, %1
  %9 = add nsw i32 %8, %6
  %10 = mul nsw i32 %9, %9
  %11 = getelementptr inbounds nuw i8, ptr %0, i64 4
  %12 = load i32, ptr %11, align 4, !tbaa !5
  %13 = mul nsw i32 %12, %1
  %14 = add nsw i32 %13, %12
  %15 = mul nsw i32 %14, %14
  %16 = sub nsw i32 %15, %13
  %17 = mul nsw i32 %16, %1
  %18 = add nsw i32 %17, %15
  %19 = mul nsw i32 %18, %18
  %20 = add i32 %8, %17
  %21 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %22 = load i32, ptr %21, align 4, !tbaa !5
  %23 = mul nsw i32 %22, %1
  %24 = add nsw i32 %23, %22
  %25 = mul nsw i32 %24, %24
  %26 = sub nsw i32 %25, %23
  %27 = mul nsw i32 %26, %1
  %28 = add nsw i32 %27, %25
  %29 = mul nsw i32 %28, %28
  %30 = add nuw i32 %10, %19
  %31 = add i32 %20, %27
  %32 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %33 = load i32, ptr %32, align 4, !tbaa !5
  %34 = mul nsw i32 %33, %1
  %35 = add nsw i32 %34, %33
  %36 = mul nsw i32 %35, %35
  %37 = sub nsw i32 %36, %34
  %38 = mul nsw i32 %37, %1
  %39 = add nsw i32 %38, %36
  %40 = mul nsw i32 %39, %39
  %41 = add i32 %30, %29
  %42 = add i32 %31, %38
  %43 = sub i32 %41, %42
  %44 = add i32 %43, %40
  ret i32 %44
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define dso_local range(i32 0, -2147483648) i32 @alternating(ptr noundef readonly captures(none) %0) local_unnamed_addr #0 {
  %2 = load <4 x i32>, ptr %0, align 4, !tbaa !5
  %3 = tail call <4 x i32> @llvm.abs.v4i32(<4 x i32> %2, i1 false)
  %4 = getelementptr inbounds nuw i8, ptr %0, i64 16
  %5 = load i32, ptr %4, align 4, !tbaa !5
  %6 = tail call i32 @llvm.abs.i32(i32 %5, i1 false)
  %7 = getelementptr inbounds nuw i8, ptr %0, i64 20
  %8 = load i32, ptr %7, align 4, !tbaa !5
  %9 = tail call i32 @llvm.abs.i32(i32 %8, i1 false)
  %10 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %3)
  %11 = add i32 %10, %6
  %12 = add i32 %11, %9
  ret i32 %12
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @until_zero(ptr noundef readonly captures(none) %0) local_unnamed_addr #1 {
  %2 = load i32, ptr %0, align 4, !tbaa !5
  %3 = icmp eq i32 %2, 0
  br i1 %3, label %13, label %4

4:                                                ; preds = %1, %4
  %5 = phi i64 [ %9, %4 ], [ 0, %1 ]
  %6 = phi i32 [ %11, %4 ], [ %2, %1 ]
  %7 = phi i32 [ %8, %4 ], [ 0, %1 ]
  %8 = add nsw i32 %6, %7
  %9 = add nuw nsw i64 %5, 1
  %10 = getelementptr inbounds nuw i32, ptr %0, i64 %9
  %11 = load i32, ptr %10, align 4, !tbaa !5
  %12 = icmp eq i32 %11, 0
  br i1 %12, label %13, label %4, !llvm.loop !14

13:                                               ; preds = %4, %1
  %14 = phi i32 [ 0, %1 ], [ %8, %4 ]
  ret i32 %14
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define dso_local i32 @grid(ptr noundef readonly captures(none) %0) local_unnamed_addr #0 {
  %2 = load <8 x i32>, ptr %0, align 4, !tbaa !5
  %3 = getelementptr inbounds nuw i8, ptr %0, i64 32
  %4 = load i32, ptr %3, align 4, !tbaa !5
  %5 = tail call i32 @llvm.vector.reduce.add.v8i32(<8 x i32> %2)
  %6 = add i32 %5, %4
  ret i32 %6
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable
define dso_local range(i32 -1, 4) i32 @first_negative(ptr noundef readonly captures(none) %0) local_unnamed_addr #0 {
  %2 = load i32, ptr %0, align 4, !tbaa !5
  %3 = icmp slt i32 %2, 0
  br i1 %3, label %17, label %4

4:                                                ; preds = %1
  %5 = getelementptr inbounds nuw i8, ptr %0, i64 4
  %6 = load i32, ptr %5, align 4, !tbaa !5
  %7 = icmp slt i32 %6, 0
  br i1 %7, label %17, label %8

8:                                                ; preds = %4
  %9 = getelementptr inbounds nuw i8, ptr %0, i64 8
  %10 = load i32, ptr %9, align 4, !tbaa !5
  %11 = icmp slt i32 %10, 0
  br i1 %11, label %17, label %12

12:                                               ; preds = %8
  %13 = getelementptr inbounds nuw i8, ptr %0, i64 12
  %14 = load i32, ptr %13, align 4, !tbaa !5
  %15 = icmp sgt i32 %14, -1
  %16 = select i1 %15, i32 -1, i32 3
  br label %17

17:                                               ; preds = %12, %8, %4, %1
  %18 = phi i32 [ 0, %1 ], [ 1, %4 ], [ 2, %8 ], [ %16, %12 ]
  ret i32 %18
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.abs.i32(i32, i1 immarg) #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.vector.reduce.add.v4i32(<4 x i32>) #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare <4 x i32> @llvm.abs.v4i32(<4 x i32>, i1 immarg) #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.vector.reduce.add.v8i32(<8 x i32>) #3

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree norecurse nosync nounwind memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: write) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

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
!14 = distinct !{!14, !10}
