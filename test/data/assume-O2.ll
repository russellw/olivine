; ModuleID = 'test/c/assume.c'
source_filename = "test/c/assume.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read, inaccessiblemem: write) uwtable
define dso_local i32 @sum_aligned(ptr noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  call void @llvm.assume(i1 true) [ "align"(ptr %0, i64 16) ]
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
  %15 = load <4 x i32>, ptr %13, align 16, !tbaa !5
  %16 = load <4 x i32>, ptr %14, align 16, !tbaa !5
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

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write)
declare void @llvm.assume(i1 noundef) #1

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @sum_plain(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #2 {
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
  br i1 %20, label %21, label %9, !llvm.loop !14

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
  br i1 %37, label %28, label %30, !llvm.loop !15
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read, inaccessiblemem: write) uwtable
define dso_local i32 @sum_each(ptr noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %42

4:                                                ; preds = %2
  %5 = zext nneg i32 %1 to i64
  %6 = icmp ult i32 %1, 8
  br i1 %6, label %39, label %7

7:                                                ; preds = %4
  %8 = and i64 %5, 2147483640
  %9 = getelementptr i8, ptr %0, i64 4
  %10 = getelementptr i8, ptr %0, i64 8
  %11 = getelementptr i8, ptr %0, i64 12
  %12 = getelementptr i8, ptr %0, i64 16
  %13 = getelementptr i8, ptr %0, i64 20
  %14 = getelementptr i8, ptr %0, i64 24
  %15 = getelementptr i8, ptr %0, i64 28
  br label %16

16:                                               ; preds = %16, %7
  %17 = phi i64 [ 0, %7 ], [ %33, %16 ]
  %18 = phi <4 x i32> [ zeroinitializer, %7 ], [ %31, %16 ]
  %19 = phi <4 x i32> [ zeroinitializer, %7 ], [ %32, %16 ]
  %20 = getelementptr inbounds nuw i32, ptr %0, i64 %17
  %21 = getelementptr i32, ptr %9, i64 %17
  %22 = getelementptr i32, ptr %10, i64 %17
  %23 = getelementptr i32, ptr %11, i64 %17
  %24 = getelementptr i32, ptr %12, i64 %17
  %25 = getelementptr i32, ptr %13, i64 %17
  %26 = getelementptr i32, ptr %14, i64 %17
  %27 = getelementptr i32, ptr %15, i64 %17
  call void @llvm.assume(i1 true) [ "align"(ptr %20, i64 4) ]
  call void @llvm.assume(i1 true) [ "align"(ptr %21, i64 4) ]
  call void @llvm.assume(i1 true) [ "align"(ptr %22, i64 4) ]
  call void @llvm.assume(i1 true) [ "align"(ptr %23, i64 4) ]
  call void @llvm.assume(i1 true) [ "align"(ptr %24, i64 4) ]
  call void @llvm.assume(i1 true) [ "align"(ptr %25, i64 4) ]
  call void @llvm.assume(i1 true) [ "align"(ptr %26, i64 4) ]
  call void @llvm.assume(i1 true) [ "align"(ptr %27, i64 4) ]
  %28 = getelementptr inbounds nuw i8, ptr %20, i64 16
  %29 = load <4 x i32>, ptr %20, align 4, !tbaa !5
  %30 = load <4 x i32>, ptr %28, align 4, !tbaa !5
  %31 = add <4 x i32> %29, %18
  %32 = add <4 x i32> %30, %19
  %33 = add nuw i64 %17, 8
  %34 = icmp eq i64 %33, %8
  br i1 %34, label %35, label %16, !llvm.loop !16

35:                                               ; preds = %16
  %36 = add <4 x i32> %32, %31
  %37 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %36)
  %38 = icmp eq i64 %8, %5
  br i1 %38, label %42, label %39

39:                                               ; preds = %4, %35
  %40 = phi i64 [ 0, %4 ], [ %8, %35 ]
  %41 = phi i32 [ 0, %4 ], [ %37, %35 ]
  br label %44

42:                                               ; preds = %44, %35, %2
  %43 = phi i32 [ 0, %2 ], [ %37, %35 ], [ %49, %44 ]
  ret i32 %43

44:                                               ; preds = %39, %44
  %45 = phi i64 [ %50, %44 ], [ %40, %39 ]
  %46 = phi i32 [ %49, %44 ], [ %41, %39 ]
  %47 = getelementptr inbounds nuw i32, ptr %0, i64 %45
  call void @llvm.assume(i1 true) [ "align"(ptr %47, i64 4) ]
  %48 = load i32, ptr %47, align 4, !tbaa !5
  %49 = add nsw i32 %48, %46
  %50 = add nuw nsw i64 %45, 1
  %51 = icmp eq i64 %50, %5
  br i1 %51, label %42, label %44, !llvm.loop !17
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: readwrite, inaccessiblemem: write) uwtable
define dso_local void @scale_aligned(ptr noundef %0, ptr noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #3 {
  call void @llvm.assume(i1 true) [ "align"(ptr %0, i64 16) ]
  call void @llvm.assume(i1 true) [ "align"(ptr %1, i64 16) ]
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
  %22 = load <4 x i32>, ptr %20, align 16, !tbaa !5
  %23 = load <4 x i32>, ptr %21, align 16, !tbaa !5
  %24 = mul nsw <4 x i32> %22, %17
  %25 = mul nsw <4 x i32> %23, %17
  %26 = getelementptr inbounds nuw i32, ptr %0, i64 %19
  %27 = getelementptr inbounds nuw i8, ptr %26, i64 16
  store <4 x i32> %24, ptr %26, align 16, !tbaa !5
  store <4 x i32> %25, ptr %27, align 16, !tbaa !5
  %28 = add nuw i64 %19, 8
  %29 = icmp eq i64 %28, %15
  br i1 %29, label %30, label %18, !llvm.loop !18

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
  br i1 %45, label %46, label %36, !llvm.loop !19

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
  br i1 %73, label %50, label %51, !llvm.loop !21
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read, inaccessiblemem: write) uwtable
define dso_local i32 @dot_aligned(ptr noundef %0, ptr noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  call void @llvm.assume(i1 true) [ "align"(ptr %0, i64 16) ]
  call void @llvm.assume(i1 true) [ "align"(ptr %1, i64 16) ]
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
  %16 = load <4 x i32>, ptr %14, align 16, !tbaa !5
  %17 = load <4 x i32>, ptr %15, align 16, !tbaa !5
  %18 = getelementptr inbounds nuw i32, ptr %1, i64 %11
  %19 = getelementptr inbounds nuw i8, ptr %18, i64 16
  %20 = load <4 x i32>, ptr %18, align 16, !tbaa !5
  %21 = load <4 x i32>, ptr %19, align 16, !tbaa !5
  %22 = mul nsw <4 x i32> %20, %16
  %23 = mul nsw <4 x i32> %21, %17
  %24 = add <4 x i32> %22, %12
  %25 = add <4 x i32> %23, %13
  %26 = add nuw i64 %11, 8
  %27 = icmp eq i64 %26, %9
  br i1 %27, label %28, label %10, !llvm.loop !22

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
  br i1 %47, label %35, label %37, !llvm.loop !23
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(inaccessiblemem: write) uwtable
define dso_local range(i32 0, 1073741824) i32 @halved(i32 noundef %0) local_unnamed_addr #4 {
  %2 = icmp sgt i32 %0, 0
  tail call void @llvm.assume(i1 %2)
  %3 = lshr i32 %0, 1
  ret i32 %3
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read, inaccessiblemem: write) uwtable
define dso_local i32 @through_call(ptr noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  call void @llvm.assume(i1 true) [ "align"(ptr %0, i64 16) ]
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %36

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
  %15 = load <4 x i32>, ptr %13, align 16, !tbaa !5
  %16 = load <4 x i32>, ptr %14, align 16, !tbaa !5
  %17 = add <4 x i32> %15, %11
  %18 = add <4 x i32> %16, %12
  %19 = add nuw i64 %10, 8
  %20 = icmp eq i64 %19, %8
  br i1 %20, label %21, label %9, !llvm.loop !24

21:                                               ; preds = %9
  %22 = add <4 x i32> %18, %17
  %23 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %22)
  %24 = icmp eq i64 %8, %5
  br i1 %24, label %37, label %25

25:                                               ; preds = %4, %21
  %26 = phi i64 [ 0, %4 ], [ %8, %21 ]
  %27 = phi i32 [ 0, %4 ], [ %23, %21 ]
  br label %28

28:                                               ; preds = %25, %28
  %29 = phi i64 [ %34, %28 ], [ %26, %25 ]
  %30 = phi i32 [ %33, %28 ], [ %27, %25 ]
  %31 = getelementptr inbounds nuw i32, ptr %0, i64 %29
  %32 = load i32, ptr %31, align 4, !tbaa !5
  %33 = add nsw i32 %32, %30
  %34 = add nuw nsw i64 %29, 1
  %35 = icmp eq i64 %34, %5
  br i1 %35, label %37, label %28, !llvm.loop !25

36:                                               ; preds = %2
  call void @llvm.assume(i1 true) [ "align"(ptr %0, i64 16) ]
  br label %72

37:                                               ; preds = %28, %21
  %38 = phi i32 [ %23, %21 ], [ %33, %28 ]
  call void @llvm.assume(i1 true) [ "align"(ptr %0, i64 16) ]
  %39 = icmp ult i32 %1, 8
  br i1 %39, label %58, label %40

40:                                               ; preds = %37
  %41 = and i64 %5, 2147483640
  br label %42

42:                                               ; preds = %42, %40
  %43 = phi i64 [ 0, %40 ], [ %52, %42 ]
  %44 = phi <4 x i32> [ zeroinitializer, %40 ], [ %50, %42 ]
  %45 = phi <4 x i32> [ zeroinitializer, %40 ], [ %51, %42 ]
  %46 = getelementptr inbounds nuw i32, ptr %0, i64 %43
  %47 = getelementptr inbounds nuw i8, ptr %46, i64 16
  %48 = load <4 x i32>, ptr %46, align 16, !tbaa !5
  %49 = load <4 x i32>, ptr %47, align 16, !tbaa !5
  %50 = add <4 x i32> %48, %44
  %51 = add <4 x i32> %49, %45
  %52 = add nuw i64 %43, 8
  %53 = icmp eq i64 %52, %41
  br i1 %53, label %54, label %42, !llvm.loop !26

54:                                               ; preds = %42
  %55 = add <4 x i32> %51, %50
  %56 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %55)
  %57 = icmp eq i64 %41, %5
  br i1 %57, label %69, label %58

58:                                               ; preds = %37, %54
  %59 = phi i64 [ 0, %37 ], [ %41, %54 ]
  %60 = phi i32 [ 0, %37 ], [ %56, %54 ]
  br label %61

61:                                               ; preds = %58, %61
  %62 = phi i64 [ %67, %61 ], [ %59, %58 ]
  %63 = phi i32 [ %66, %61 ], [ %60, %58 ]
  %64 = getelementptr inbounds nuw i32, ptr %0, i64 %62
  %65 = load i32, ptr %64, align 4, !tbaa !5
  %66 = add nsw i32 %65, %63
  %67 = add nuw nsw i64 %62, 1
  %68 = icmp eq i64 %67, %5
  br i1 %68, label %69, label %61, !llvm.loop !27

69:                                               ; preds = %61, %54
  %70 = phi i32 [ %56, %54 ], [ %66, %61 ]
  %71 = add nsw i32 %70, %38
  br label %72

72:                                               ; preds = %69, %36
  %73 = phi i32 [ 0, %36 ], [ %71, %69 ]
  ret i32 %73
}

; Function Attrs: nounwind memory(readwrite, argmem: none) uwtable
define dso_local i32 @local_aligned(i32 noundef %0) local_unnamed_addr #5 {
  %2 = tail call noalias align 16 dereferenceable_or_null(256) ptr @aligned_alloc(i64 noundef 16, i64 noundef 256) #9
  %3 = icmp eq ptr %2, null
  br i1 %3, label %85, label %4

4:                                                ; preds = %1
  call void @llvm.assume(i1 true) [ "align"(ptr %2, i64 16) ]
  %5 = insertelement <4 x i32> poison, i32 %0, i64 0
  %6 = shufflevector <4 x i32> %5, <4 x i32> poison, <4 x i32> zeroinitializer
  %7 = mul <4 x i32> %6, <i32 0, i32 1, i32 2, i32 3>
  %8 = mul <4 x i32> %6, <i32 4, i32 5, i32 6, i32 7>
  %9 = getelementptr inbounds nuw i8, ptr %2, i64 16
  store <4 x i32> %7, ptr %2, align 16, !tbaa !5
  store <4 x i32> %8, ptr %9, align 16, !tbaa !5
  %10 = getelementptr inbounds nuw i8, ptr %2, i64 32
  %11 = mul <4 x i32> %6, <i32 8, i32 9, i32 10, i32 11>
  %12 = mul <4 x i32> %6, <i32 12, i32 13, i32 14, i32 15>
  %13 = getelementptr inbounds nuw i8, ptr %2, i64 48
  store <4 x i32> %11, ptr %10, align 16, !tbaa !5
  store <4 x i32> %12, ptr %13, align 16, !tbaa !5
  %14 = getelementptr inbounds nuw i8, ptr %2, i64 64
  %15 = mul <4 x i32> %6, <i32 16, i32 17, i32 18, i32 19>
  %16 = mul <4 x i32> %6, <i32 20, i32 21, i32 22, i32 23>
  %17 = getelementptr inbounds nuw i8, ptr %2, i64 80
  store <4 x i32> %15, ptr %14, align 16, !tbaa !5
  store <4 x i32> %16, ptr %17, align 16, !tbaa !5
  %18 = getelementptr inbounds nuw i8, ptr %2, i64 96
  %19 = mul <4 x i32> %6, <i32 24, i32 25, i32 26, i32 27>
  %20 = mul <4 x i32> %6, <i32 28, i32 29, i32 30, i32 31>
  %21 = getelementptr inbounds nuw i8, ptr %2, i64 112
  store <4 x i32> %19, ptr %18, align 16, !tbaa !5
  store <4 x i32> %20, ptr %21, align 16, !tbaa !5
  %22 = getelementptr inbounds nuw i8, ptr %2, i64 128
  %23 = mul <4 x i32> %6, <i32 32, i32 33, i32 34, i32 35>
  %24 = mul <4 x i32> %6, <i32 36, i32 37, i32 38, i32 39>
  %25 = getelementptr inbounds nuw i8, ptr %2, i64 144
  store <4 x i32> %23, ptr %22, align 16, !tbaa !5
  store <4 x i32> %24, ptr %25, align 16, !tbaa !5
  %26 = getelementptr inbounds nuw i8, ptr %2, i64 160
  %27 = mul <4 x i32> %6, <i32 40, i32 41, i32 42, i32 43>
  %28 = mul <4 x i32> %6, <i32 44, i32 45, i32 46, i32 47>
  %29 = getelementptr inbounds nuw i8, ptr %2, i64 176
  store <4 x i32> %27, ptr %26, align 16, !tbaa !5
  store <4 x i32> %28, ptr %29, align 16, !tbaa !5
  %30 = getelementptr inbounds nuw i8, ptr %2, i64 192
  %31 = mul <4 x i32> %6, <i32 48, i32 49, i32 50, i32 51>
  %32 = mul <4 x i32> %6, <i32 52, i32 53, i32 54, i32 55>
  %33 = getelementptr inbounds nuw i8, ptr %2, i64 208
  store <4 x i32> %31, ptr %30, align 16, !tbaa !5
  store <4 x i32> %32, ptr %33, align 16, !tbaa !5
  %34 = getelementptr inbounds nuw i8, ptr %2, i64 224
  %35 = mul <4 x i32> %6, <i32 56, i32 57, i32 58, i32 59>
  %36 = mul <4 x i32> %6, <i32 60, i32 61, i32 62, i32 63>
  %37 = getelementptr inbounds nuw i8, ptr %2, i64 240
  store <4 x i32> %35, ptr %34, align 16, !tbaa !5
  store <4 x i32> %36, ptr %37, align 16, !tbaa !5
  %38 = getelementptr inbounds nuw i8, ptr %2, i64 16
  %39 = load <4 x i32>, ptr %2, align 16, !tbaa !5
  %40 = load <4 x i32>, ptr %38, align 16, !tbaa !5
  %41 = getelementptr inbounds nuw i8, ptr %2, i64 32
  %42 = getelementptr inbounds nuw i8, ptr %2, i64 48
  %43 = load <4 x i32>, ptr %41, align 16, !tbaa !5
  %44 = load <4 x i32>, ptr %42, align 16, !tbaa !5
  %45 = add <4 x i32> %43, %39
  %46 = add <4 x i32> %44, %40
  %47 = getelementptr inbounds nuw i8, ptr %2, i64 64
  %48 = getelementptr inbounds nuw i8, ptr %2, i64 80
  %49 = load <4 x i32>, ptr %47, align 16, !tbaa !5
  %50 = load <4 x i32>, ptr %48, align 16, !tbaa !5
  %51 = add <4 x i32> %49, %45
  %52 = add <4 x i32> %50, %46
  %53 = getelementptr inbounds nuw i8, ptr %2, i64 96
  %54 = getelementptr inbounds nuw i8, ptr %2, i64 112
  %55 = load <4 x i32>, ptr %53, align 16, !tbaa !5
  %56 = load <4 x i32>, ptr %54, align 16, !tbaa !5
  %57 = add <4 x i32> %55, %51
  %58 = add <4 x i32> %56, %52
  %59 = getelementptr inbounds nuw i8, ptr %2, i64 128
  %60 = getelementptr inbounds nuw i8, ptr %2, i64 144
  %61 = load <4 x i32>, ptr %59, align 16, !tbaa !5
  %62 = load <4 x i32>, ptr %60, align 16, !tbaa !5
  %63 = add <4 x i32> %61, %57
  %64 = add <4 x i32> %62, %58
  %65 = getelementptr inbounds nuw i8, ptr %2, i64 160
  %66 = getelementptr inbounds nuw i8, ptr %2, i64 176
  %67 = load <4 x i32>, ptr %65, align 16, !tbaa !5
  %68 = load <4 x i32>, ptr %66, align 16, !tbaa !5
  %69 = add <4 x i32> %67, %63
  %70 = add <4 x i32> %68, %64
  %71 = getelementptr inbounds nuw i8, ptr %2, i64 192
  %72 = getelementptr inbounds nuw i8, ptr %2, i64 208
  %73 = load <4 x i32>, ptr %71, align 16, !tbaa !5
  %74 = load <4 x i32>, ptr %72, align 16, !tbaa !5
  %75 = add <4 x i32> %73, %69
  %76 = add <4 x i32> %74, %70
  %77 = getelementptr inbounds nuw i8, ptr %2, i64 224
  %78 = getelementptr inbounds nuw i8, ptr %2, i64 240
  %79 = load <4 x i32>, ptr %77, align 16, !tbaa !5
  %80 = load <4 x i32>, ptr %78, align 16, !tbaa !5
  %81 = add <4 x i32> %79, %75
  %82 = add <4 x i32> %80, %76
  %83 = add <4 x i32> %82, %81
  %84 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %83)
  tail call void @free(ptr noundef nonnull %2) #10
  br label %85

85:                                               ; preds = %1, %4
  %86 = phi i32 [ %84, %4 ], [ 0, %1 ]
  ret i32 %86
}

; Function Attrs: mustprogress nofree nounwind willreturn allockind("alloc,uninitialized,aligned") allocsize(1) memory(inaccessiblemem: readwrite)
declare noalias noundef ptr @aligned_alloc(i64 allocalign noundef, i64 noundef) local_unnamed_addr #6

; Function Attrs: mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite)
declare void @free(ptr allocptr noundef captures(none)) local_unnamed_addr #7

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.vector.reduce.add.v4i32(<4 x i32>) #8

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: read, inaccessiblemem: write) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }
attributes #2 = { nofree norecurse nosync nounwind memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nofree norecurse nosync nounwind memory(argmem: readwrite, inaccessiblemem: write) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind willreturn memory(inaccessiblemem: write) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind memory(readwrite, argmem: none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { mustprogress nofree nounwind willreturn allockind("alloc,uninitialized,aligned") allocsize(1) memory(inaccessiblemem: readwrite) "alloc-family"="malloc" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #7 = { mustprogress nounwind willreturn allockind("free") memory(argmem: readwrite, inaccessiblemem: readwrite) "alloc-family"="malloc" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #8 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }
attributes #9 = { nounwind allocsize(1) }
attributes #10 = { nounwind }

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
!19 = distinct !{!19, !20}
!20 = !{!"llvm.loop.unroll.disable"}
!21 = distinct !{!21, !10, !11}
!22 = distinct !{!22, !10, !11, !12}
!23 = distinct !{!23, !10, !12, !11}
!24 = distinct !{!24, !10, !11, !12}
!25 = distinct !{!25, !10, !12, !11}
!26 = distinct !{!26, !10, !11, !12}
!27 = distinct !{!27, !10, !12, !11}
