; ModuleID = 'test/c/tail.c'
source_filename = "test/c/tail.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local i32 @gcd_of(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp eq i32 %1, 0
  br i1 %3, label %9, label %4

4:                                                ; preds = %2, %4
  %5 = phi i32 [ %7, %4 ], [ %1, %2 ]
  %6 = phi i32 [ %5, %4 ], [ %0, %2 ]
  %7 = srem i32 %6, %5
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %9, label %4

9:                                                ; preds = %4, %2
  %10 = phi i32 [ %0, %2 ], [ %5, %4 ]
  ret i32 %10
}

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local i32 @alternate(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = add i32 %2, 1
  %5 = and i32 %4, 7
  %6 = and i32 %2, 7
  %7 = icmp eq i32 %6, 7
  br i1 %7, label %16, label %8

8:                                                ; preds = %3, %8
  %9 = phi i32 [ %10, %8 ], [ %0, %3 ]
  %10 = phi i32 [ %9, %8 ], [ %1, %3 ]
  %11 = phi i32 [ %13, %8 ], [ %2, %3 ]
  %12 = phi i32 [ %14, %8 ], [ 0, %3 ]
  %13 = add nsw i32 %11, -1
  %14 = add i32 %12, 1
  %15 = icmp eq i32 %14, %5
  br i1 %15, label %16, label %8, !llvm.loop !5

16:                                               ; preds = %8, %3
  %17 = phi i32 [ poison, %3 ], [ %9, %8 ]
  %18 = phi i32 [ poison, %3 ], [ %10, %8 ]
  %19 = phi i32 [ %0, %3 ], [ %10, %8 ]
  %20 = phi i32 [ %1, %3 ], [ %9, %8 ]
  %21 = phi i32 [ %2, %3 ], [ %13, %8 ]
  %22 = icmp ult i32 %2, 7
  br i1 %22, label %27, label %23

23:                                               ; preds = %16, %23
  %24 = phi i32 [ %26, %23 ], [ %21, %16 ]
  %25 = icmp eq i32 %24, 7
  %26 = add nsw i32 %24, -8
  br i1 %25, label %27, label %23

27:                                               ; preds = %23, %16
  %28 = phi i32 [ %17, %16 ], [ %20, %23 ]
  %29 = phi i32 [ %18, %16 ], [ %19, %23 ]
  %30 = mul nsw i32 %28, 10
  %31 = add nsw i32 %30, %29
  ret i32 %31
}

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local i32 @steps(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp slt i32 %0, 1
  br i1 %3, label %15, label %4

4:                                                ; preds = %2, %4
  %5 = phi i32 [ %13, %4 ], [ %1, %2 ]
  %6 = phi i32 [ %11, %4 ], [ %0, %2 ]
  %7 = and i32 %6, 1
  %8 = icmp eq i32 %7, 0
  %9 = add nsw i32 %6, -1
  %10 = lshr exact i32 %6, 1
  %11 = select i1 %8, i32 %10, i32 %9
  %12 = sub i32 %5, %7
  %13 = add i32 %12, 2
  %14 = icmp slt i32 %11, 1
  br i1 %14, label %15, label %4

15:                                               ; preds = %4, %2
  %16 = phi i32 [ %1, %2 ], [ %13, %4 ]
  ret i32 %16
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite) uwtable
define dso_local void @walk_down(ptr noundef captures(none) %0, i32 noundef %1) local_unnamed_addr #1 {
  %3 = icmp eq i32 %1, 0
  br i1 %3, label %17, label %4

4:                                                ; preds = %2
  %5 = load i32, ptr %0, align 4, !tbaa !7
  %6 = add i32 %5, %1
  %7 = add i32 %1, -1
  %8 = mul i32 %7, %7
  %9 = add i32 %6, %8
  %10 = zext i32 %7 to i33
  %11 = add i32 %1, -2
  %12 = zext i32 %11 to i33
  %13 = mul i33 %10, %12
  %14 = lshr i33 %13, 1
  %15 = trunc nuw i33 %14 to i32
  %16 = sub i32 %9, %15
  store i32 %16, ptr %0, align 4, !tbaa !7
  br label %17

17:                                               ; preds = %4, %2
  ret void
}

; Function Attrs: nofree nosync nounwind memory(none) uwtable
define dso_local i32 @buffered(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = alloca [4 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #8
  %4 = icmp slt i32 %0, 1
  br i1 %4, label %19, label %5

5:                                                ; preds = %2
  store i32 %0, ptr %3, align 16, !tbaa !7
  %6 = add nuw i32 %0, 1
  %7 = getelementptr inbounds nuw i8, ptr %3, i64 4
  store i32 %6, ptr %7, align 4, !tbaa !7
  %8 = add nuw i32 %0, 2
  %9 = getelementptr inbounds nuw i8, ptr %3, i64 8
  store i32 %8, ptr %9, align 8, !tbaa !7
  %10 = add nuw i32 %0, 3
  %11 = getelementptr inbounds nuw i8, ptr %3, i64 12
  store i32 %10, ptr %11, align 4, !tbaa !7
  %12 = add nsw i32 %0, -1
  %13 = and i32 %0, 3
  %14 = zext nneg i32 %13 to i64
  %15 = getelementptr inbounds nuw [4 x i32], ptr %3, i64 0, i64 %14
  %16 = load i32, ptr %15, align 4, !tbaa !7
  %17 = add nsw i32 %16, %1
  %18 = tail call i32 @buffered(i32 noundef %12, i32 noundef %17)
  br label %19

19:                                               ; preds = %2, %5
  %20 = phi i32 [ %18, %5 ], [ %1, %2 ]
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #8
  ret i32 %20
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #3

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #3

; Function Attrs: nofree nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @via_local(i32 noundef %0, ptr noundef readonly captures(address_is_null) %1) local_unnamed_addr #4 {
  %3 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #8
  %4 = mul nsw i32 %0, 3
  store i32 %4, ptr %3, align 4, !tbaa !7
  %5 = icmp eq i32 %0, 0
  br i1 %5, label %6, label %10

6:                                                ; preds = %2
  %7 = icmp eq ptr %1, null
  br i1 %7, label %13, label %8

8:                                                ; preds = %6
  %9 = load i32, ptr %1, align 4, !tbaa !7
  br label %13

10:                                               ; preds = %2
  %11 = add nsw i32 %0, -1
  %12 = call i32 @via_local(i32 noundef %11, ptr noundef nonnull %3)
  br label %13

13:                                               ; preds = %8, %6, %10
  %14 = phi i32 [ %12, %10 ], [ %9, %8 ], [ -1, %6 ]
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #8
  ret i32 %14
}

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local range(i32 1, -2147483648) i32 @product_to(i32 noundef %0) local_unnamed_addr #0 {
  %2 = icmp slt i32 %0, 2
  br i1 %2, label %36, label %3

3:                                                ; preds = %1
  %4 = add nsw i32 %0, -1
  %5 = icmp ult i32 %0, 9
  br i1 %5, label %27, label %6

6:                                                ; preds = %3
  %7 = and i32 %4, -8
  %8 = sub i32 %0, %7
  %9 = insertelement <4 x i32> poison, i32 %0, i64 0
  %10 = shufflevector <4 x i32> %9, <4 x i32> poison, <4 x i32> zeroinitializer
  %11 = add nsw <4 x i32> %10, <i32 0, i32 -1, i32 -2, i32 -3>
  br label %12

12:                                               ; preds = %12, %6
  %13 = phi i32 [ 0, %6 ], [ %20, %12 ]
  %14 = phi <4 x i32> [ %11, %6 ], [ %21, %12 ]
  %15 = phi <4 x i32> [ splat (i32 1), %6 ], [ %18, %12 ]
  %16 = phi <4 x i32> [ splat (i32 1), %6 ], [ %19, %12 ]
  %17 = add <4 x i32> %14, splat (i32 -4)
  %18 = mul <4 x i32> %14, %15
  %19 = mul <4 x i32> %17, %16
  %20 = add nuw i32 %13, 8
  %21 = add <4 x i32> %14, splat (i32 -8)
  %22 = icmp eq i32 %20, %7
  br i1 %22, label %23, label %12, !llvm.loop !11

23:                                               ; preds = %12
  %24 = mul <4 x i32> %19, %18
  %25 = tail call i32 @llvm.vector.reduce.mul.v4i32(<4 x i32> %24)
  %26 = icmp eq i32 %4, %7
  br i1 %26, label %36, label %27

27:                                               ; preds = %3, %23
  %28 = phi i32 [ %0, %3 ], [ %8, %23 ]
  %29 = phi i32 [ 1, %3 ], [ %25, %23 ]
  br label %30

30:                                               ; preds = %27, %30
  %31 = phi i32 [ %33, %30 ], [ %28, %27 ]
  %32 = phi i32 [ %34, %30 ], [ %29, %27 ]
  %33 = add nsw i32 %31, -1
  %34 = mul nuw nsw i32 %31, %32
  %35 = icmp samesign ult i32 %31, 3
  br i1 %35, label %36, label %30, !llvm.loop !14

36:                                               ; preds = %30, %23, %1
  %37 = phi i32 [ 1, %1 ], [ %25, %23 ], [ %34, %30 ]
  ret i32 %37
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 -2147483647, -2147483648) i32 @forwards(i32 noundef %0) local_unnamed_addr #5 {
  %2 = add nsw i32 %0, 1
  ret i32 %2
}

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local range(i32 10, 21) i32 @bounced(i32 noundef %0) local_unnamed_addr #0 {
  br label %2

2:                                                ; preds = %4, %1
  %3 = phi i32 [ %0, %1 ], [ %5, %4 ]
  switch i32 %3, label %4 [
    i32 0, label %7
    i32 1, label %6
  ]

4:                                                ; preds = %2
  %5 = add nsw i32 %3, -2
  br label %2

6:                                                ; preds = %2
  br label %7

7:                                                ; preds = %2, %6
  %8 = phi i32 [ 20, %6 ], [ 10, %2 ]
  ret i32 %8
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @skipping(ptr noundef readonly captures(none) %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #6 {
  br label %4

4:                                                ; preds = %27, %3
  %5 = phi ptr [ %0, %3 ], [ %30, %27 ]
  %6 = phi i32 [ %1, %3 ], [ %32, %27 ]
  %7 = phi i32 [ %2, %3 ], [ %33, %27 ]
  %8 = icmp sgt i32 %6, 0
  br i1 %8, label %9, label %23

9:                                                ; preds = %4
  %10 = zext nneg i32 %6 to i64
  br label %11

11:                                               ; preds = %9, %17
  %12 = phi i64 [ 0, %9 ], [ %19, %17 ]
  %13 = phi i32 [ %7, %9 ], [ %18, %17 ]
  %14 = getelementptr inbounds nuw i32, ptr %5, i64 %12
  %15 = load i32, ptr %14, align 4, !tbaa !7
  %16 = icmp sgt i32 %15, 0
  br i1 %16, label %17, label %21

17:                                               ; preds = %11
  %18 = add nsw i32 %15, %13
  %19 = add nuw nsw i64 %12, 1
  %20 = icmp eq i64 %19, %10
  br i1 %20, label %34, label %11, !llvm.loop !15

21:                                               ; preds = %11
  %22 = trunc nuw nsw i64 %12 to i32
  br label %23

23:                                               ; preds = %21, %4
  %24 = phi i32 [ %7, %4 ], [ %13, %21 ]
  %25 = phi i32 [ 0, %4 ], [ %22, %21 ]
  %26 = icmp eq i32 %25, %6
  br i1 %26, label %34, label %27

27:                                               ; preds = %23
  %28 = zext nneg i32 %25 to i64
  %29 = getelementptr inbounds nuw i32, ptr %5, i64 %28
  %30 = getelementptr inbounds nuw i8, ptr %29, i64 4
  %31 = xor i32 %25, -1
  %32 = add i32 %6, %31
  %33 = add nsw i32 %24, -1
  br label %4

34:                                               ; preds = %23, %17
  %35 = phi i32 [ %18, %17 ], [ %24, %23 ]
  ret i32 %35
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.vector.reduce.mul.v4i32(<4 x i32>) #7

attributes #0 = { nofree norecurse nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree norecurse nosync nounwind willreturn memory(argmem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { nofree nosync nounwind memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { nofree norecurse nosync nounwind memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #7 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #8 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 21.1.8 (6ubuntu1)"}
!5 = distinct !{!5, !6}
!6 = !{!"llvm.loop.unroll.disable"}
!7 = !{!8, !8, i64 0}
!8 = !{!"int", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = distinct !{!11, !12, !13}
!12 = !{!"llvm.loop.isvectorized", i32 1}
!13 = !{!"llvm.loop.unroll.runtime.disable"}
!14 = distinct !{!14, !13, !12}
!15 = distinct !{!15, !16}
!16 = !{!"llvm.loop.mustprogress"}
