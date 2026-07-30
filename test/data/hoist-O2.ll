; ModuleID = 'test/c/hoist.c'
source_filename = "test/c/hoist.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@scale = internal unnamed_addr global i32 3, align 4

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @scaled_sum(ptr noundef readonly captures(none) %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %35

5:                                                ; preds = %3
  %6 = mul nsw i32 %2, %2
  %7 = add nuw nsw i32 %6, 3
  %8 = zext nneg i32 %1 to i64
  %9 = icmp ult i32 %1, 8
  br i1 %9, label %32, label %10

10:                                               ; preds = %5
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
  %22 = mul nsw <4 x i32> %20, %13
  %23 = mul nsw <4 x i32> %21, %13
  %24 = add <4 x i32> %22, %16
  %25 = add <4 x i32> %23, %17
  %26 = add nuw i64 %15, 8
  %27 = icmp eq i64 %26, %11
  br i1 %27, label %28, label %14, !llvm.loop !9

28:                                               ; preds = %14
  %29 = add <4 x i32> %25, %24
  %30 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %29)
  %31 = icmp eq i64 %11, %8
  br i1 %31, label %35, label %32

32:                                               ; preds = %5, %28
  %33 = phi i64 [ 0, %5 ], [ %11, %28 ]
  %34 = phi i32 [ 0, %5 ], [ %30, %28 ]
  br label %37

35:                                               ; preds = %37, %28, %3
  %36 = phi i32 [ 0, %3 ], [ %30, %28 ], [ %43, %37 ]
  ret i32 %36

37:                                               ; preds = %32, %37
  %38 = phi i64 [ %44, %37 ], [ %33, %32 ]
  %39 = phi i32 [ %43, %37 ], [ %34, %32 ]
  %40 = getelementptr inbounds nuw i32, ptr %0, i64 %38
  %41 = load i32, ptr %40, align 4, !tbaa !5
  %42 = mul nsw i32 %41, %7
  %43 = add nsw i32 %42, %39
  %44 = add nuw nsw i64 %38, 1
  %45 = icmp eq i64 %44, %8
  br i1 %45, label %35, label %37, !llvm.loop !13
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local i32 @nested_squares(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = icmp sgt i32 %2, 0
  br i1 %4, label %5, label %18

5:                                                ; preds = %3
  %6 = shl i32 %0, 2
  %7 = xor i32 %1, %0
  %8 = add i32 %7, %6
  %9 = add nsw i32 %2, -1
  %10 = mul i32 %8, %9
  %11 = shl i32 %0, 3
  %12 = add i32 %10, %11
  %13 = shl i32 %7, 1
  %14 = add i32 %12, %13
  %15 = mul i32 %14, %9
  %16 = add i32 %7, %15
  %17 = add i32 %16, %6
  br label %18

18:                                               ; preds = %5, %3
  %19 = phi i32 [ 0, %3 ], [ %17, %5 ]
  ret i32 %19
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @sometimes(ptr noundef readonly captures(none) %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %36

5:                                                ; preds = %3
  %6 = mul nsw i32 %2, %2
  %7 = zext nneg i32 %1 to i64
  %8 = icmp ult i32 %1, 8
  br i1 %8, label %33, label %9

9:                                                ; preds = %5
  %10 = and i64 %7, 2147483640
  %11 = insertelement <4 x i32> poison, i32 %6, i64 0
  %12 = shufflevector <4 x i32> %11, <4 x i32> poison, <4 x i32> zeroinitializer
  br label %13

13:                                               ; preds = %13, %9
  %14 = phi i64 [ 0, %9 ], [ %27, %13 ]
  %15 = phi <4 x i32> [ zeroinitializer, %9 ], [ %25, %13 ]
  %16 = phi <4 x i32> [ zeroinitializer, %9 ], [ %26, %13 ]
  %17 = getelementptr inbounds nuw i32, ptr %0, i64 %14
  %18 = getelementptr inbounds nuw i8, ptr %17, i64 16
  %19 = load <4 x i32>, ptr %17, align 4, !tbaa !5
  %20 = load <4 x i32>, ptr %18, align 4, !tbaa !5
  %21 = icmp sgt <4 x i32> %19, zeroinitializer
  %22 = icmp sgt <4 x i32> %20, zeroinitializer
  %23 = select <4 x i1> %21, <4 x i32> %12, <4 x i32> zeroinitializer
  %24 = select <4 x i1> %22, <4 x i32> %12, <4 x i32> zeroinitializer
  %25 = add <4 x i32> %23, %15
  %26 = add <4 x i32> %24, %16
  %27 = add nuw i64 %14, 8
  %28 = icmp eq i64 %27, %10
  br i1 %28, label %29, label %13, !llvm.loop !14

29:                                               ; preds = %13
  %30 = add <4 x i32> %26, %25
  %31 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %30)
  %32 = icmp eq i64 %10, %7
  br i1 %32, label %36, label %33

33:                                               ; preds = %5, %29
  %34 = phi i64 [ 0, %5 ], [ %10, %29 ]
  %35 = phi i32 [ 0, %5 ], [ %31, %29 ]
  br label %38

36:                                               ; preds = %38, %29, %3
  %37 = phi i32 [ 0, %3 ], [ %31, %29 ], [ %45, %38 ]
  ret i32 %37

38:                                               ; preds = %33, %38
  %39 = phi i64 [ %46, %38 ], [ %34, %33 ]
  %40 = phi i32 [ %45, %38 ], [ %35, %33 ]
  %41 = getelementptr inbounds nuw i32, ptr %0, i64 %39
  %42 = load i32, ptr %41, align 4, !tbaa !5
  %43 = icmp sgt i32 %42, 0
  %44 = select i1 %43, i32 %6, i32 0
  %45 = add nuw nsw i32 %44, %40
  %46 = add nuw nsw i64 %39, 1
  %47 = icmp eq i64 %46, %7
  br i1 %47, label %36, label %38, !llvm.loop !15
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef i32 @guarded_divide(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #1 {
  %4 = icmp sgt i32 %2, 0
  br i1 %4, label %5, label %8

5:                                                ; preds = %3
  %6 = sdiv i32 %0, %1
  %7 = mul i32 %6, %2
  br label %8

8:                                                ; preds = %5, %3
  %9 = phi i32 [ 0, %3 ], [ %7, %5 ]
  ret i32 %9
}

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local i32 @carried_first(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = icmp sgt i32 %0, 0
  br i1 %3, label %4, label %30

4:                                                ; preds = %2
  %5 = add nsw i32 %1, 1
  %6 = icmp eq i32 %0, 1
  br i1 %6, label %30, label %7

7:                                                ; preds = %4
  %8 = add nsw i32 %0, -1
  %9 = icmp ult i32 %0, 9
  br i1 %9, label %27, label %10

10:                                               ; preds = %7
  %11 = and i32 %8, -8
  %12 = or disjoint i32 %11, 1
  %13 = insertelement <4 x i32> poison, i32 %5, i64 0
  %14 = shufflevector <4 x i32> %13, <4 x i32> poison, <4 x i32> zeroinitializer
  br label %15

15:                                               ; preds = %15, %10
  %16 = phi i32 [ 0, %10 ], [ %21, %15 ]
  %17 = phi <4 x i32> [ zeroinitializer, %10 ], [ %19, %15 ]
  %18 = phi <4 x i32> [ zeroinitializer, %10 ], [ %20, %15 ]
  %19 = add <4 x i32> %14, %17
  %20 = add <4 x i32> %14, %18
  %21 = add nuw i32 %16, 8
  %22 = icmp eq i32 %21, %11
  br i1 %22, label %23, label %15, !llvm.loop !16

23:                                               ; preds = %15
  %24 = add <4 x i32> %20, %19
  %25 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %24)
  %26 = icmp eq i32 %8, %11
  br i1 %26, label %30, label %27

27:                                               ; preds = %7, %23
  %28 = phi i32 [ 1, %7 ], [ %12, %23 ]
  %29 = phi i32 [ 0, %7 ], [ %25, %23 ]
  br label %32

30:                                               ; preds = %32, %23, %4, %2
  %31 = phi i32 [ 0, %2 ], [ 0, %4 ], [ %25, %23 ], [ %35, %32 ]
  ret i32 %31

32:                                               ; preds = %27, %32
  %33 = phi i32 [ %36, %32 ], [ %28, %27 ]
  %34 = phi i32 [ %35, %32 ], [ %29, %27 ]
  %35 = add nsw i32 %5, %34
  %36 = add nuw nsw i32 %33, 1
  %37 = icmp eq i32 %36, %0
  br i1 %37, label %30, label %32, !llvm.loop !18
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(read, argmem: none, inaccessiblemem: none) uwtable
define dso_local i32 @scale_now() local_unnamed_addr #3 {
  %1 = load i32, ptr @scale, align 4, !tbaa !5
  ret i32 %1
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable
define dso_local void @set_scale(i32 noundef %0) local_unnamed_addr #4 {
  store i32 %0, ptr @scale, align 4, !tbaa !5
  ret void
}

; Function Attrs: nofree norecurse nosync nounwind memory(read, inaccessiblemem: none) uwtable
define dso_local i32 @scaled_by_symbol(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #5 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %33

4:                                                ; preds = %2
  %5 = load i32, ptr @scale, align 4, !tbaa !5
  %6 = zext nneg i32 %1 to i64
  %7 = icmp ult i32 %1, 8
  br i1 %7, label %30, label %8

8:                                                ; preds = %4
  %9 = and i64 %6, 2147483640
  %10 = insertelement <4 x i32> poison, i32 %5, i64 0
  %11 = shufflevector <4 x i32> %10, <4 x i32> poison, <4 x i32> zeroinitializer
  br label %12

12:                                               ; preds = %12, %8
  %13 = phi i64 [ 0, %8 ], [ %24, %12 ]
  %14 = phi <4 x i32> [ zeroinitializer, %8 ], [ %22, %12 ]
  %15 = phi <4 x i32> [ zeroinitializer, %8 ], [ %23, %12 ]
  %16 = getelementptr inbounds nuw i32, ptr %0, i64 %13
  %17 = getelementptr inbounds nuw i8, ptr %16, i64 16
  %18 = load <4 x i32>, ptr %16, align 4, !tbaa !5
  %19 = load <4 x i32>, ptr %17, align 4, !tbaa !5
  %20 = mul nsw <4 x i32> %11, %18
  %21 = mul nsw <4 x i32> %11, %19
  %22 = add <4 x i32> %20, %14
  %23 = add <4 x i32> %21, %15
  %24 = add nuw i64 %13, 8
  %25 = icmp eq i64 %24, %9
  br i1 %25, label %26, label %12, !llvm.loop !19

26:                                               ; preds = %12
  %27 = add <4 x i32> %23, %22
  %28 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %27)
  %29 = icmp eq i64 %9, %6
  br i1 %29, label %33, label %30

30:                                               ; preds = %4, %26
  %31 = phi i64 [ 0, %4 ], [ %9, %26 ]
  %32 = phi i32 [ 0, %4 ], [ %28, %26 ]
  br label %35

33:                                               ; preds = %35, %26, %2
  %34 = phi i32 [ 0, %2 ], [ %28, %26 ], [ %41, %35 ]
  ret i32 %34

35:                                               ; preds = %30, %35
  %36 = phi i64 [ %42, %35 ], [ %31, %30 ]
  %37 = phi i32 [ %41, %35 ], [ %32, %30 ]
  %38 = getelementptr inbounds nuw i32, ptr %0, i64 %36
  %39 = load i32, ptr %38, align 4, !tbaa !5
  %40 = mul nsw i32 %5, %39
  %41 = add nsw i32 %40, %37
  %42 = add nuw nsw i64 %36, 1
  %43 = icmp eq i64 %42, %6
  br i1 %43, label %33, label %35, !llvm.loop !20
}

; Function Attrs: nofree norecurse nosync nounwind memory(read, argmem: readwrite, inaccessiblemem: none) uwtable
define dso_local i32 @bumping(ptr noundef captures(none) %0, i32 noundef %1) local_unnamed_addr #6 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %37

4:                                                ; preds = %2
  %5 = load i32, ptr %0, align 4, !tbaa !5
  %6 = icmp ult i32 %1, 8
  br i1 %6, label %31, label %7

7:                                                ; preds = %4
  %8 = and i32 %1, 2147483640
  %9 = insertelement <4 x i32> <i32 poison, i32 0, i32 0, i32 0>, i32 %5, i64 0
  %10 = load i32, ptr @scale, align 4, !tbaa !5
  %11 = insertelement <4 x i32> poison, i32 %10, i64 0
  %12 = shufflevector <4 x i32> %11, <4 x i32> poison, <4 x i32> zeroinitializer
  br label %13

13:                                               ; preds = %13, %7
  %14 = phi i32 [ 0, %7 ], [ %23, %13 ]
  %15 = phi <4 x i32> [ %9, %7 ], [ %21, %13 ]
  %16 = phi <4 x i32> [ zeroinitializer, %7 ], [ %22, %13 ]
  %17 = phi <4 x i32> [ zeroinitializer, %7 ], [ %19, %13 ]
  %18 = phi <4 x i32> [ zeroinitializer, %7 ], [ %20, %13 ]
  %19 = add <4 x i32> %12, %17
  %20 = add <4 x i32> %12, %18
  %21 = add <4 x i32> %15, splat (i32 1)
  %22 = add <4 x i32> %16, splat (i32 1)
  %23 = add nuw i32 %14, 8
  %24 = icmp eq i32 %23, %8
  br i1 %24, label %25, label %13, !llvm.loop !21

25:                                               ; preds = %13
  %26 = add <4 x i32> %22, %21
  %27 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %26)
  %28 = add <4 x i32> %20, %19
  %29 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %28)
  store i32 %27, ptr %0, align 4, !tbaa !5
  %30 = icmp eq i32 %1, %8
  br i1 %30, label %37, label %31

31:                                               ; preds = %4, %25
  %32 = phi i32 [ %5, %4 ], [ %27, %25 ]
  %33 = phi i32 [ 0, %4 ], [ %8, %25 ]
  %34 = phi i32 [ 0, %4 ], [ %29, %25 ]
  %35 = load i32, ptr @scale, align 4, !tbaa !5
  br label %39

36:                                               ; preds = %39
  store i32 %44, ptr %0, align 4, !tbaa !5
  br label %37

37:                                               ; preds = %36, %25, %2
  %38 = phi i32 [ 0, %2 ], [ %29, %25 ], [ %43, %36 ]
  ret i32 %38

39:                                               ; preds = %31, %39
  %40 = phi i32 [ %44, %39 ], [ %32, %31 ]
  %41 = phi i32 [ %45, %39 ], [ %33, %31 ]
  %42 = phi i32 [ %43, %39 ], [ %34, %31 ]
  %43 = add nsw i32 %35, %42
  %44 = add nsw i32 %40, 1
  %45 = add nuw nsw i32 %41, 1
  %46 = icmp eq i32 %45, %1
  br i1 %46, label %36, label %39, !llvm.loop !22
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable
define dso_local i32 @bumping_symbol(i32 noundef %0) local_unnamed_addr #7 {
  %2 = icmp sgt i32 %0, 0
  br i1 %2, label %3, label %17

3:                                                ; preds = %1
  %4 = load i32, ptr @scale, align 4, !tbaa !5
  %5 = add nsw i32 %0, -1
  %6 = add i32 %4, 1
  %7 = mul i32 %5, %6
  %8 = add i32 %4, %7
  %9 = zext nneg i32 %5 to i33
  %10 = add nsw i32 %0, -2
  %11 = zext i32 %10 to i33
  %12 = mul i33 %9, %11
  %13 = lshr i33 %12, 1
  %14 = trunc nuw i33 %13 to i32
  %15 = add i32 %8, %14
  %16 = add i32 %4, %0
  store i32 %16, ptr @scale, align 4, !tbaa !5
  br label %17

17:                                               ; preds = %3, %1
  %18 = phi i32 [ 0, %1 ], [ %15, %3 ]
  ret i32 %18
}

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local i32 @jumped_into(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = and i32 %0, 1
  %4 = mul nsw i32 %1, 5
  br label %5, !llvm.loop !23

5:                                                ; preds = %2, %9
  %6 = phi i32 [ %10, %9 ], [ 0, %2 ]
  %7 = phi i32 [ %11, %9 ], [ %3, %2 ]
  %8 = icmp slt i32 %7, %0
  br i1 %8, label %9, label %12

9:                                                ; preds = %5
  %10 = add nsw i32 %6, %4
  %11 = add nuw nsw i32 %7, 1
  br label %5, !llvm.loop !23

12:                                               ; preds = %5
  ret i32 %6
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.vector.reduce.add.v4i32(<4 x i32>) #8

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree norecurse nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { mustprogress nofree norecurse nosync nounwind willreturn memory(read, argmem: none, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind willreturn memory(write, argmem: none, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nofree norecurse nosync nounwind memory(read, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { nofree norecurse nosync nounwind memory(read, argmem: readwrite, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #7 = { mustprogress nofree norecurse nosync nounwind willreturn memory(readwrite, argmem: none, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #8 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

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
!16 = distinct !{!16, !10, !17, !11, !12}
!17 = !{!"llvm.loop.peeled.count", i32 1}
!18 = distinct !{!18, !10, !17, !12, !11}
!19 = distinct !{!19, !10, !11, !12}
!20 = distinct !{!20, !10, !12, !11}
!21 = distinct !{!21, !10, !11, !12}
!22 = distinct !{!22, !10, !12, !11}
!23 = distinct !{!23, !10}
