; ModuleID = 'test/c/stride.c'
source_filename = "test/c/stride.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @stride_walk(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #0 {
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

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @stride_dot(ptr noundef readonly captures(none) %0, ptr noundef readonly captures(none) %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %2, 0
  br i1 %4, label %5, label %35

5:                                                ; preds = %3
  %6 = zext nneg i32 %2 to i64
  %7 = icmp ult i32 %2, 8
  br i1 %7, label %32, label %8

8:                                                ; preds = %5
  %9 = and i64 %6, 2147483640
  br label %10

10:                                               ; preds = %10, %8
  %11 = phi i64 [ 0, %8 ], [ %26, %10 ]
  %12 = phi <4 x i32> [ zeroinitializer, %8 ], [ %24, %10 ]
  %13 = phi <4 x i32> [ zeroinitializer, %8 ], [ %25, %10 ]
  %14 = getelementptr inbounds nuw i32, ptr %0, i64 %11
  %15 = getelementptr inbounds nuw i8, ptr %14, i64 16
  %16 = load <4 x i32>, ptr %14, align 4, !tbaa !5
  %17 = load <4 x i32>, ptr %15, align 4, !tbaa !5
  %18 = getelementptr inbounds nuw i32, ptr %1, i64 %11
  %19 = getelementptr inbounds nuw i8, ptr %18, i64 16
  %20 = load <4 x i32>, ptr %18, align 4, !tbaa !5
  %21 = load <4 x i32>, ptr %19, align 4, !tbaa !5
  %22 = mul nsw <4 x i32> %20, %16
  %23 = mul nsw <4 x i32> %21, %17
  %24 = add <4 x i32> %22, %12
  %25 = add <4 x i32> %23, %13
  %26 = add nuw i64 %11, 8
  %27 = icmp eq i64 %26, %9
  br i1 %27, label %28, label %10, !llvm.loop !14

28:                                               ; preds = %10
  %29 = add <4 x i32> %25, %24
  %30 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %29)
  %31 = icmp eq i64 %9, %6
  br i1 %31, label %35, label %32

32:                                               ; preds = %5, %28
  %33 = phi i64 [ 0, %5 ], [ %9, %28 ]
  %34 = phi i32 [ 0, %5 ], [ %30, %28 ]
  br label %37

35:                                               ; preds = %37, %28, %3
  %36 = phi i32 [ 0, %3 ], [ %30, %28 ], [ %45, %37 ]
  ret i32 %36

37:                                               ; preds = %32, %37
  %38 = phi i64 [ %46, %37 ], [ %33, %32 ]
  %39 = phi i32 [ %45, %37 ], [ %34, %32 ]
  %40 = getelementptr inbounds nuw i32, ptr %0, i64 %38
  %41 = load i32, ptr %40, align 4, !tbaa !5
  %42 = getelementptr inbounds nuw i32, ptr %1, i64 %38
  %43 = load i32, ptr %42, align 4, !tbaa !5
  %44 = mul nsw i32 %43, %41
  %45 = add nsw i32 %44, %39
  %46 = add nuw nsw i64 %38, 1
  %47 = icmp eq i64 %46, %6
  br i1 %47, label %35, label %37, !llvm.loop !15
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @stride_third(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %62

4:                                                ; preds = %2
  %5 = zext nneg i32 %1 to i64
  %6 = icmp ult i32 %1, 25
  br i1 %6, label %59, label %7

7:                                                ; preds = %4
  %8 = add nsw i64 %5, -1
  %9 = udiv i64 %8, 3
  %10 = add nuw nsw i64 %9, 1
  %11 = and i64 %10, 7
  %12 = icmp eq i64 %11, 0
  %13 = select i1 %12, i64 8, i64 %11
  %14 = sub nsw i64 %10, %13
  %15 = mul i64 %14, 3
  %16 = getelementptr i8, ptr %0, i64 12
  %17 = getelementptr i8, ptr %0, i64 24
  %18 = getelementptr i8, ptr %0, i64 36
  %19 = getelementptr i8, ptr %0, i64 48
  %20 = getelementptr i8, ptr %0, i64 60
  %21 = getelementptr i8, ptr %0, i64 72
  %22 = getelementptr i8, ptr %0, i64 84
  br label %23

23:                                               ; preds = %23, %7
  %24 = phi i64 [ 0, %7 ], [ %54, %23 ]
  %25 = phi <4 x i32> [ zeroinitializer, %7 ], [ %52, %23 ]
  %26 = phi <4 x i32> [ zeroinitializer, %7 ], [ %53, %23 ]
  %27 = mul i64 %24, 3
  %28 = getelementptr inbounds nuw i32, ptr %0, i64 %27
  %29 = getelementptr i32, ptr %16, i64 %27
  %30 = getelementptr i32, ptr %17, i64 %27
  %31 = getelementptr i32, ptr %18, i64 %27
  %32 = getelementptr i32, ptr %19, i64 %27
  %33 = getelementptr i32, ptr %20, i64 %27
  %34 = getelementptr i32, ptr %21, i64 %27
  %35 = getelementptr i32, ptr %22, i64 %27
  %36 = load i32, ptr %28, align 4, !tbaa !5
  %37 = load i32, ptr %29, align 4, !tbaa !5
  %38 = load i32, ptr %30, align 4, !tbaa !5
  %39 = load i32, ptr %31, align 4, !tbaa !5
  %40 = insertelement <4 x i32> poison, i32 %36, i64 0
  %41 = insertelement <4 x i32> %40, i32 %37, i64 1
  %42 = insertelement <4 x i32> %41, i32 %38, i64 2
  %43 = insertelement <4 x i32> %42, i32 %39, i64 3
  %44 = load i32, ptr %32, align 4, !tbaa !5
  %45 = load i32, ptr %33, align 4, !tbaa !5
  %46 = load i32, ptr %34, align 4, !tbaa !5
  %47 = load i32, ptr %35, align 4, !tbaa !5
  %48 = insertelement <4 x i32> poison, i32 %44, i64 0
  %49 = insertelement <4 x i32> %48, i32 %45, i64 1
  %50 = insertelement <4 x i32> %49, i32 %46, i64 2
  %51 = insertelement <4 x i32> %50, i32 %47, i64 3
  %52 = add <4 x i32> %43, %25
  %53 = add <4 x i32> %51, %26
  %54 = add nuw i64 %24, 8
  %55 = icmp eq i64 %54, %14
  br i1 %55, label %56, label %23, !llvm.loop !16

56:                                               ; preds = %23
  %57 = add <4 x i32> %53, %52
  %58 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %57)
  br label %59

59:                                               ; preds = %4, %56
  %60 = phi i64 [ 0, %4 ], [ %15, %56 ]
  %61 = phi i32 [ 0, %4 ], [ %58, %56 ]
  br label %64

62:                                               ; preds = %64, %2
  %63 = phi i32 [ 0, %2 ], [ %69, %64 ]
  ret i32 %63

64:                                               ; preds = %59, %64
  %65 = phi i64 [ %70, %64 ], [ %60, %59 ]
  %66 = phi i32 [ %69, %64 ], [ %61, %59 ]
  %67 = getelementptr inbounds nuw i32, ptr %0, i64 %65
  %68 = load i32, ptr %67, align 4, !tbaa !5
  %69 = add nsw i32 %68, %66
  %70 = add nuw nsw i64 %65, 3
  %71 = icmp samesign ult i64 %70, %5
  br i1 %71, label %64, label %62, !llvm.loop !17
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @backwards(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %34

4:                                                ; preds = %2
  %5 = zext nneg i32 %1 to i64
  %6 = icmp ult i32 %1, 8
  br i1 %6, label %31, label %7

7:                                                ; preds = %4
  %8 = and i64 %5, 2147483640
  %9 = and i64 %5, 7
  %10 = getelementptr i32, ptr %0, i64 %5
  br label %11

11:                                               ; preds = %11, %7
  %12 = phi i64 [ 0, %7 ], [ %25, %11 ]
  %13 = phi <4 x i32> [ zeroinitializer, %7 ], [ %23, %11 ]
  %14 = phi <4 x i32> [ zeroinitializer, %7 ], [ %24, %11 ]
  %15 = xor i64 %12, -1
  %16 = getelementptr i32, ptr %10, i64 %15
  %17 = getelementptr inbounds i8, ptr %16, i64 -12
  %18 = getelementptr inbounds i8, ptr %16, i64 -28
  %19 = load <4 x i32>, ptr %17, align 4, !tbaa !5
  %20 = shufflevector <4 x i32> %19, <4 x i32> poison, <4 x i32> <i32 3, i32 2, i32 1, i32 0>
  %21 = load <4 x i32>, ptr %18, align 4, !tbaa !5
  %22 = shufflevector <4 x i32> %21, <4 x i32> poison, <4 x i32> <i32 3, i32 2, i32 1, i32 0>
  %23 = add <4 x i32> %20, %13
  %24 = add <4 x i32> %22, %14
  %25 = add nuw i64 %12, 8
  %26 = icmp eq i64 %25, %8
  br i1 %26, label %27, label %11, !llvm.loop !18

27:                                               ; preds = %11
  %28 = add <4 x i32> %24, %23
  %29 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %28)
  %30 = icmp eq i64 %8, %5
  br i1 %30, label %34, label %31

31:                                               ; preds = %4, %27
  %32 = phi i64 [ %5, %4 ], [ %9, %27 ]
  %33 = phi i32 [ 0, %4 ], [ %29, %27 ]
  br label %36

34:                                               ; preds = %36, %27, %2
  %35 = phi i32 [ 0, %2 ], [ %29, %27 ], [ %42, %36 ]
  ret i32 %35

36:                                               ; preds = %31, %36
  %37 = phi i64 [ %39, %36 ], [ %32, %31 ]
  %38 = phi i32 [ %42, %36 ], [ %33, %31 ]
  %39 = add nsw i64 %37, -1
  %40 = getelementptr inbounds nuw i32, ptr %0, i64 %39
  %41 = load i32, ptr %40, align 4, !tbaa !5
  %42 = add nsw i32 %41, %38
  %43 = icmp samesign ugt i64 %37, 1
  br i1 %43, label %36, label %34, !llvm.loop !19
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable
define dso_local void @scale(ptr noundef writeonly captures(none) %0, ptr noundef readonly captures(none) %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #1 {
  %5 = icmp sgt i32 %2, 0
  br i1 %5, label %6, label %50

6:                                                ; preds = %4
  %7 = ptrtoint ptr %0 to i64
  %8 = ptrtoint ptr %1 to i64
  %9 = zext nneg i32 %2 to i64
  %10 = icmp ult i32 %2, 8
  %11 = sub i64 %7, %8
  %12 = icmp ult i64 %11, 32
  %13 = or i1 %10, %12
  br i1 %13, label %32, label %14

14:                                               ; preds = %6
  %15 = and i64 %9, 2147483640
  %16 = insertelement <4 x i32> poison, i32 %3, i64 0
  %17 = shufflevector <4 x i32> %16, <4 x i32> poison, <4 x i32> zeroinitializer
  br label %18

18:                                               ; preds = %18, %14
  %19 = phi i64 [ 0, %14 ], [ %28, %18 ]
  %20 = getelementptr inbounds nuw i32, ptr %1, i64 %19
  %21 = getelementptr inbounds nuw i8, ptr %20, i64 16
  %22 = load <4 x i32>, ptr %20, align 4, !tbaa !5
  %23 = load <4 x i32>, ptr %21, align 4, !tbaa !5
  %24 = mul nsw <4 x i32> %22, %17
  %25 = mul nsw <4 x i32> %23, %17
  %26 = getelementptr inbounds nuw i32, ptr %0, i64 %19
  %27 = getelementptr inbounds nuw i8, ptr %26, i64 16
  store <4 x i32> %24, ptr %26, align 4, !tbaa !5
  store <4 x i32> %25, ptr %27, align 4, !tbaa !5
  %28 = add nuw i64 %19, 8
  %29 = icmp eq i64 %28, %15
  br i1 %29, label %30, label %18, !llvm.loop !20

30:                                               ; preds = %18
  %31 = icmp eq i64 %15, %9
  br i1 %31, label %50, label %32

32:                                               ; preds = %6, %30
  %33 = phi i64 [ 0, %6 ], [ %15, %30 ]
  %34 = and i64 %9, 3
  %35 = icmp eq i64 %34, 0
  br i1 %35, label %46, label %36

36:                                               ; preds = %32, %36
  %37 = phi i64 [ %43, %36 ], [ %33, %32 ]
  %38 = phi i64 [ %44, %36 ], [ 0, %32 ]
  %39 = getelementptr inbounds nuw i32, ptr %1, i64 %37
  %40 = load i32, ptr %39, align 4, !tbaa !5
  %41 = mul nsw i32 %40, %3
  %42 = getelementptr inbounds nuw i32, ptr %0, i64 %37
  store i32 %41, ptr %42, align 4, !tbaa !5
  %43 = add nuw nsw i64 %37, 1
  %44 = add i64 %38, 1
  %45 = icmp eq i64 %44, %34
  br i1 %45, label %46, label %36, !llvm.loop !21

46:                                               ; preds = %36, %32
  %47 = phi i64 [ %33, %32 ], [ %43, %36 ]
  %48 = sub nsw i64 %33, %9
  %49 = icmp ugt i64 %48, -4
  br i1 %49, label %50, label %51

50:                                               ; preds = %46, %51, %30, %4
  ret void

51:                                               ; preds = %46, %51
  %52 = phi i64 [ %72, %51 ], [ %47, %46 ]
  %53 = getelementptr inbounds nuw i32, ptr %1, i64 %52
  %54 = load i32, ptr %53, align 4, !tbaa !5
  %55 = mul nsw i32 %54, %3
  %56 = getelementptr inbounds nuw i32, ptr %0, i64 %52
  store i32 %55, ptr %56, align 4, !tbaa !5
  %57 = add nuw nsw i64 %52, 1
  %58 = getelementptr inbounds nuw i32, ptr %1, i64 %57
  %59 = load i32, ptr %58, align 4, !tbaa !5
  %60 = mul nsw i32 %59, %3
  %61 = getelementptr inbounds nuw i32, ptr %0, i64 %57
  store i32 %60, ptr %61, align 4, !tbaa !5
  %62 = add nuw nsw i64 %52, 2
  %63 = getelementptr inbounds nuw i32, ptr %1, i64 %62
  %64 = load i32, ptr %63, align 4, !tbaa !5
  %65 = mul nsw i32 %64, %3
  %66 = getelementptr inbounds nuw i32, ptr %0, i64 %62
  store i32 %65, ptr %66, align 4, !tbaa !5
  %67 = add nuw nsw i64 %52, 3
  %68 = getelementptr inbounds nuw i32, ptr %1, i64 %67
  %69 = load i32, ptr %68, align 4, !tbaa !5
  %70 = mul nsw i32 %69, %3
  %71 = getelementptr inbounds nuw i32, ptr %0, i64 %67
  store i32 %70, ptr %71, align 4, !tbaa !5
  %72 = add nuw nsw i64 %52, 4
  %73 = icmp eq i64 %72, %9
  br i1 %73, label %50, label %51, !llvm.loop !23
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @stride_weighted(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %37

4:                                                ; preds = %2
  %5 = zext nneg i32 %1 to i64
  %6 = icmp ult i32 %1, 8
  br i1 %6, label %34, label %7

7:                                                ; preds = %4
  %8 = and i64 %5, 2147483640
  br label %9

9:                                                ; preds = %9, %7
  %10 = phi i64 [ 0, %7 ], [ %27, %9 ]
  %11 = phi <4 x i32> [ zeroinitializer, %7 ], [ %25, %9 ]
  %12 = phi <4 x i32> [ zeroinitializer, %7 ], [ %26, %9 ]
  %13 = phi <4 x i32> [ <i32 0, i32 1, i32 2, i32 3>, %7 ], [ %28, %9 ]
  %14 = getelementptr inbounds nuw i32, ptr %0, i64 %10
  %15 = getelementptr inbounds nuw i8, ptr %14, i64 16
  %16 = load <4 x i32>, ptr %14, align 4, !tbaa !5
  %17 = load <4 x i32>, ptr %15, align 4, !tbaa !5
  %18 = mul nsw <4 x i32> %16, splat (i32 5)
  %19 = mul nsw <4 x i32> %17, splat (i32 5)
  %20 = mul <4 x i32> %13, splat (i32 7)
  %21 = mul <4 x i32> %13, splat (i32 7)
  %22 = add <4 x i32> %21, splat (i32 28)
  %23 = add <4 x i32> %20, %11
  %24 = add <4 x i32> %22, %12
  %25 = add <4 x i32> %23, %18
  %26 = add <4 x i32> %24, %19
  %27 = add nuw i64 %10, 8
  %28 = add <4 x i32> %13, splat (i32 8)
  %29 = icmp eq i64 %27, %8
  br i1 %29, label %30, label %9, !llvm.loop !24

30:                                               ; preds = %9
  %31 = add <4 x i32> %26, %25
  %32 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %31)
  %33 = icmp eq i64 %8, %5
  br i1 %33, label %37, label %34

34:                                               ; preds = %4, %30
  %35 = phi i64 [ 0, %4 ], [ %8, %30 ]
  %36 = phi i32 [ 0, %4 ], [ %32, %30 ]
  br label %39

37:                                               ; preds = %39, %30, %2
  %38 = phi i32 [ 0, %2 ], [ %32, %30 ], [ %48, %39 ]
  ret i32 %38

39:                                               ; preds = %34, %39
  %40 = phi i64 [ %49, %39 ], [ %35, %34 ]
  %41 = phi i32 [ %48, %39 ], [ %36, %34 ]
  %42 = getelementptr inbounds nuw i32, ptr %0, i64 %40
  %43 = load i32, ptr %42, align 4, !tbaa !5
  %44 = mul nsw i32 %43, 5
  %45 = trunc i64 %40 to i32
  %46 = mul i32 %45, 7
  %47 = add i32 %46, %41
  %48 = add i32 %47, %44
  %49 = add nuw nsw i64 %40, 1
  %50 = icmp eq i64 %49, %5
  br i1 %50, label %37, label %39, !llvm.loop !25
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @stride_unsigned(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp eq i32 %1, 0
  br i1 %3, label %28, label %4

4:                                                ; preds = %2
  %5 = zext i32 %1 to i64
  %6 = icmp ult i32 %1, 8
  br i1 %6, label %25, label %7

7:                                                ; preds = %4
  %8 = and i64 %5, 4294967288
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
  br i1 %20, label %21, label %9, !llvm.loop !26

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
  %35 = add i32 %34, %32
  %36 = add nuw nsw i64 %31, 1
  %37 = icmp eq i64 %36, %5
  br i1 %37, label %28, label %30, !llvm.loop !27
}

; Function Attrs: nofree norecurse nosync nounwind memory(read, inaccessiblemem: none) uwtable
define dso_local i32 @through_handle(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #2 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %29

4:                                                ; preds = %2
  %5 = load ptr, ptr %0, align 8, !tbaa !28
  %6 = zext nneg i32 %1 to i64
  %7 = icmp ult i32 %1, 8
  br i1 %7, label %26, label %8

8:                                                ; preds = %4
  %9 = and i64 %6, 2147483640
  br label %10

10:                                               ; preds = %10, %8
  %11 = phi i64 [ 0, %8 ], [ %20, %10 ]
  %12 = phi <4 x i32> [ zeroinitializer, %8 ], [ %18, %10 ]
  %13 = phi <4 x i32> [ zeroinitializer, %8 ], [ %19, %10 ]
  %14 = getelementptr inbounds nuw i32, ptr %5, i64 %11
  %15 = getelementptr inbounds nuw i8, ptr %14, i64 16
  %16 = load <4 x i32>, ptr %14, align 4, !tbaa !5
  %17 = load <4 x i32>, ptr %15, align 4, !tbaa !5
  %18 = add <4 x i32> %16, %12
  %19 = add <4 x i32> %17, %13
  %20 = add nuw i64 %11, 8
  %21 = icmp eq i64 %20, %9
  br i1 %21, label %22, label %10, !llvm.loop !31

22:                                               ; preds = %10
  %23 = add <4 x i32> %19, %18
  %24 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %23)
  %25 = icmp eq i64 %9, %6
  br i1 %25, label %29, label %26

26:                                               ; preds = %4, %22
  %27 = phi i64 [ 0, %4 ], [ %9, %22 ]
  %28 = phi i32 [ 0, %4 ], [ %24, %22 ]
  br label %31

29:                                               ; preds = %31, %22, %2
  %30 = phi i32 [ 0, %2 ], [ %24, %22 ], [ %36, %31 ]
  ret i32 %30

31:                                               ; preds = %26, %31
  %32 = phi i64 [ %37, %31 ], [ %27, %26 ]
  %33 = phi i32 [ %36, %31 ], [ %28, %26 ]
  %34 = getelementptr inbounds nuw i32, ptr %5, i64 %32
  %35 = load i32, ptr %34, align 4, !tbaa !5
  %36 = add nsw i32 %35, %33
  %37 = add nuw nsw i64 %32, 1
  %38 = icmp eq i64 %37, %6
  br i1 %38, label %29, label %31, !llvm.loop !32
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @gathered(ptr noundef readonly captures(none) %0, ptr noundef readonly captures(none) %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %2, 0
  br i1 %4, label %5, label %32

5:                                                ; preds = %3
  %6 = zext nneg i32 %2 to i64
  %7 = and i64 %6, 3
  %8 = icmp ult i32 %2, 4
  br i1 %8, label %14, label %9

9:                                                ; preds = %5
  %10 = and i64 %6, 2147483644
  %11 = getelementptr inbounds i8, ptr %1, i64 4
  %12 = getelementptr inbounds i8, ptr %1, i64 8
  %13 = getelementptr inbounds i8, ptr %1, i64 12
  br label %34

14:                                               ; preds = %34, %5
  %15 = phi i32 [ poison, %5 ], [ %61, %34 ]
  %16 = phi i64 [ 0, %5 ], [ %62, %34 ]
  %17 = phi i32 [ 0, %5 ], [ %61, %34 ]
  %18 = icmp eq i64 %7, 0
  br i1 %18, label %32, label %19

19:                                               ; preds = %14, %19
  %20 = phi i64 [ %29, %19 ], [ %16, %14 ]
  %21 = phi i32 [ %28, %19 ], [ %17, %14 ]
  %22 = phi i64 [ %30, %19 ], [ 0, %14 ]
  %23 = getelementptr inbounds nuw i32, ptr %1, i64 %20
  %24 = load i32, ptr %23, align 4, !tbaa !5
  %25 = sext i32 %24 to i64
  %26 = getelementptr inbounds i32, ptr %0, i64 %25
  %27 = load i32, ptr %26, align 4, !tbaa !5
  %28 = add nsw i32 %27, %21
  %29 = add nuw nsw i64 %20, 1
  %30 = add i64 %22, 1
  %31 = icmp eq i64 %30, %7
  br i1 %31, label %32, label %19, !llvm.loop !33

32:                                               ; preds = %14, %19, %3
  %33 = phi i32 [ 0, %3 ], [ %15, %14 ], [ %28, %19 ]
  ret i32 %33

34:                                               ; preds = %34, %9
  %35 = phi i64 [ 0, %9 ], [ %62, %34 ]
  %36 = phi i32 [ 0, %9 ], [ %61, %34 ]
  %37 = phi i64 [ 0, %9 ], [ %63, %34 ]
  %38 = getelementptr inbounds nuw i32, ptr %1, i64 %35
  %39 = load i32, ptr %38, align 4, !tbaa !5
  %40 = sext i32 %39 to i64
  %41 = getelementptr inbounds i32, ptr %0, i64 %40
  %42 = load i32, ptr %41, align 4, !tbaa !5
  %43 = add nsw i32 %42, %36
  %44 = getelementptr inbounds i32, ptr %11, i64 %35
  %45 = load i32, ptr %44, align 4, !tbaa !5
  %46 = sext i32 %45 to i64
  %47 = getelementptr inbounds i32, ptr %0, i64 %46
  %48 = load i32, ptr %47, align 4, !tbaa !5
  %49 = add nsw i32 %48, %43
  %50 = getelementptr inbounds i32, ptr %12, i64 %35
  %51 = load i32, ptr %50, align 4, !tbaa !5
  %52 = sext i32 %51 to i64
  %53 = getelementptr inbounds i32, ptr %0, i64 %52
  %54 = load i32, ptr %53, align 4, !tbaa !5
  %55 = add nsw i32 %54, %49
  %56 = getelementptr inbounds i32, ptr %13, i64 %35
  %57 = load i32, ptr %56, align 4, !tbaa !5
  %58 = sext i32 %57 to i64
  %59 = getelementptr inbounds i32, ptr %0, i64 %58
  %60 = load i32, ptr %59, align 4, !tbaa !5
  %61 = add nsw i32 %60, %55
  %62 = add nuw nsw i64 %35, 4
  %63 = add i64 %37, 4
  %64 = icmp eq i64 %63, %10
  br i1 %64, label %14, label %34, !llvm.loop !34
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @grid_total(ptr noundef readonly captures(none) %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %39

5:                                                ; preds = %3
  %6 = icmp sgt i32 %2, 0
  %7 = zext nneg i32 %1 to i64
  %8 = zext i32 %2 to i64
  %9 = icmp ult i32 %2, 8
  %10 = and i64 %8, 2147483640
  %11 = icmp eq i64 %10, %8
  br label %12

12:                                               ; preds = %5, %41
  %13 = phi i64 [ 0, %5 ], [ %43, %41 ]
  %14 = phi i32 [ 0, %5 ], [ %42, %41 ]
  br i1 %6, label %15, label %41

15:                                               ; preds = %12
  %16 = shl i64 %13, 3
  %17 = and i64 %16, 4294967288
  %18 = getelementptr inbounds nuw i32, ptr %0, i64 %17
  br i1 %9, label %36, label %19

19:                                               ; preds = %15
  %20 = insertelement <4 x i32> <i32 poison, i32 0, i32 0, i32 0>, i32 %14, i64 0
  br label %21

21:                                               ; preds = %21, %19
  %22 = phi i64 [ 0, %19 ], [ %31, %21 ]
  %23 = phi <4 x i32> [ %20, %19 ], [ %29, %21 ]
  %24 = phi <4 x i32> [ zeroinitializer, %19 ], [ %30, %21 ]
  %25 = getelementptr inbounds nuw i32, ptr %18, i64 %22
  %26 = getelementptr inbounds nuw i8, ptr %25, i64 16
  %27 = load <4 x i32>, ptr %25, align 4, !tbaa !5
  %28 = load <4 x i32>, ptr %26, align 4, !tbaa !5
  %29 = add <4 x i32> %27, %23
  %30 = add <4 x i32> %28, %24
  %31 = add nuw i64 %22, 8
  %32 = icmp eq i64 %31, %10
  br i1 %32, label %33, label %21, !llvm.loop !35

33:                                               ; preds = %21
  %34 = add <4 x i32> %30, %29
  %35 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %34)
  br i1 %11, label %41, label %36

36:                                               ; preds = %15, %33
  %37 = phi i64 [ 0, %15 ], [ %10, %33 ]
  %38 = phi i32 [ %14, %15 ], [ %35, %33 ]
  br label %45

39:                                               ; preds = %41, %3
  %40 = phi i32 [ 0, %3 ], [ %42, %41 ]
  ret i32 %40

41:                                               ; preds = %45, %33, %12
  %42 = phi i32 [ %14, %12 ], [ %35, %33 ], [ %50, %45 ]
  %43 = add nuw nsw i64 %13, 1
  %44 = icmp eq i64 %43, %7
  br i1 %44, label %39, label %12, !llvm.loop !36

45:                                               ; preds = %36, %45
  %46 = phi i64 [ %51, %45 ], [ %37, %36 ]
  %47 = phi i32 [ %50, %45 ], [ %38, %36 ]
  %48 = getelementptr inbounds nuw i32, ptr %18, i64 %46
  %49 = load i32, ptr %48, align 4, !tbaa !5
  %50 = add nsw i32 %49, %47
  %51 = add nuw nsw i64 %46, 1
  %52 = icmp eq i64 %51, %8
  br i1 %52, label %41, label %45, !llvm.loop !37
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.vector.reduce.add.v4i32(<4 x i32>) #3

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree norecurse nosync nounwind memory(argmem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { nofree norecurse nosync nounwind memory(read, inaccessiblemem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
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
!14 = distinct !{!14, !10, !11, !12}
!15 = distinct !{!15, !10, !12, !11}
!16 = distinct !{!16, !10, !11, !12}
!17 = distinct !{!17, !10, !12, !11}
!18 = distinct !{!18, !10, !11, !12}
!19 = distinct !{!19, !10, !12, !11}
!20 = distinct !{!20, !10, !11, !12}
!21 = distinct !{!21, !22}
!22 = !{!"llvm.loop.unroll.disable"}
!23 = distinct !{!23, !10, !11}
!24 = distinct !{!24, !10, !11, !12}
!25 = distinct !{!25, !10, !12, !11}
!26 = distinct !{!26, !10, !11, !12}
!27 = distinct !{!27, !10, !12, !11}
!28 = !{!29, !29, i64 0}
!29 = !{!"p1 int", !30, i64 0}
!30 = !{!"any pointer", !7, i64 0}
!31 = distinct !{!31, !10, !11, !12}
!32 = distinct !{!32, !10, !12, !11}
!33 = distinct !{!33, !22}
!34 = distinct !{!34, !10}
!35 = distinct !{!35, !10, !11, !12}
!36 = distinct !{!36, !10}
!37 = distinct !{!37, !10, !12, !11}
