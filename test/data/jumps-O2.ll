; ModuleID = 'test/c/jumps.c'
source_filename = "test/c/jumps.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

@thread_ops.ops = internal unnamed_addr constant [3 x ptr] [ptr blockaddress(@thread_ops, %4), ptr blockaddress(@thread_ops, %17), ptr blockaddress(@thread_ops, %21)], align 16
@switch.table.falls_through = private unnamed_addr constant [9 x i32] [i32 2, i32 6, i32 14, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 99], align 4
@switch.table.scattered = private unnamed_addr constant [4 x i32] [i32 4, i32 9, i32 2, i32 7], align 4
@switch.table.sparse = private unnamed_addr constant [4 x i32] [i32 2, i32 4, i32 0, i32 8], align 4

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @search(ptr noundef readonly captures(none) %0, i32 noundef %1, i32 noundef %2, i32 noundef %3) local_unnamed_addr #0 {
  %5 = icmp sgt i32 %2, 0
  br i1 %5, label %6, label %30

6:                                                ; preds = %4
  %7 = icmp sgt i32 %1, 0
  %8 = zext i32 %1 to i64
  %9 = zext nneg i32 %2 to i64
  br label %10

10:                                               ; preds = %6, %25
  %11 = phi i64 [ 0, %6 ], [ %26, %25 ]
  br i1 %7, label %12, label %25

12:                                               ; preds = %10
  %13 = mul nuw nsw i64 %11, %8
  br label %17

14:                                               ; preds = %17
  %15 = add nuw nsw i64 %18, 1
  %16 = icmp eq i64 %15, %8
  br i1 %16, label %25, label %17, !llvm.loop !5

17:                                               ; preds = %12, %14
  %18 = phi i64 [ 0, %12 ], [ %15, %14 ]
  %19 = add nuw nsw i64 %18, %13
  %20 = getelementptr inbounds nuw i32, ptr %0, i64 %19
  %21 = load i32, ptr %20, align 4, !tbaa !7
  %22 = icmp sgt i32 %21, -1
  %23 = icmp eq i32 %21, %3
  %24 = and i1 %22, %23
  br i1 %24, label %28, label %14

25:                                               ; preds = %14, %10
  %26 = add nuw nsw i64 %11, 1
  %27 = icmp eq i64 %26, %9
  br i1 %27, label %30, label %10, !llvm.loop !11

28:                                               ; preds = %17
  %29 = trunc nuw i64 %19 to i32
  br label %30

30:                                               ; preds = %25, %28, %4
  %31 = phi i32 [ -1, %4 ], [ %29, %28 ], [ -1, %25 ]
  ret i32 %31
}

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local range(i32 -2147483647, -2147483648) i32 @digits(i32 noundef %0) local_unnamed_addr #1 {
  br label %2

2:                                                ; preds = %2, %1
  %3 = phi i32 [ %0, %1 ], [ %6, %2 ]
  %4 = phi i32 [ 0, %1 ], [ %5, %2 ]
  %5 = add nuw nsw i32 %4, 1
  %6 = udiv i32 %3, 10
  %7 = icmp ult i32 %3, 10
  br i1 %7, label %8, label %2, !llvm.loop !12

8:                                                ; preds = %2
  ret i32 %5
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 -1, 100) i32 @falls_through(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add i32 %0, -1
  %3 = icmp ult i32 %2, 9
  br i1 %3, label %4, label %8

4:                                                ; preds = %1
  %5 = zext nneg i32 %2 to i64
  %6 = getelementptr inbounds nuw [9 x i32], ptr @switch.table.falls_through, i64 0, i64 %5
  %7 = load i32, ptr %6, align 4
  br label %8

8:                                                ; preds = %1, %4
  %9 = phi i32 [ %7, %4 ], [ -1, %1 ]
  ret i32 %9
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @two_exits(ptr noundef readonly captures(none) %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %19

5:                                                ; preds = %3
  %6 = zext nneg i32 %1 to i64
  br label %10

7:                                                ; preds = %10
  %8 = add nuw nsw i64 %11, 1
  %9 = icmp eq i64 %8, %6
  br i1 %9, label %19, label %10, !llvm.loop !13

10:                                               ; preds = %5, %7
  %11 = phi i64 [ 0, %5 ], [ %8, %7 ]
  %12 = phi i32 [ 0, %5 ], [ %15, %7 ]
  %13 = getelementptr inbounds nuw i32, ptr %0, i64 %11
  %14 = load i32, ptr %13, align 4, !tbaa !7
  %15 = add nsw i32 %14, %12
  %16 = icmp sgt i32 %15, %2
  br i1 %16, label %17, label %7

17:                                               ; preds = %10
  %18 = sub nsw i32 0, %15
  br label %19

19:                                               ; preds = %7, %3, %17
  %20 = phi i32 [ %18, %17 ], [ 0, %3 ], [ %15, %7 ]
  ret i32 %20
}

; Function Attrs: nofree norecurse nosync nounwind memory(none) uwtable
define dso_local i32 @nested_while(i32 noundef %0, i32 noundef %1) local_unnamed_addr #1 {
  %3 = icmp sgt i32 %0, 0
  br i1 %3, label %4, label %135

4:                                                ; preds = %2
  %5 = icmp slt i32 %1, 1
  %6 = add i32 %1, -1
  %7 = sub i32 %6, %0
  %8 = icmp ult i32 %0, 8
  br i1 %8, label %53, label %9

9:                                                ; preds = %4
  %10 = and i32 %0, 2147483640
  %11 = add i32 %7, %10
  %12 = and i32 %0, 7
  %13 = insertelement <4 x i1> poison, i1 %5, i64 0
  %14 = shufflevector <4 x i1> %13, <4 x i1> poison, <4 x i32> zeroinitializer
  %15 = insertelement <4 x i32> poison, i32 %6, i64 0
  %16 = shufflevector <4 x i32> %15, <4 x i32> poison, <4 x i32> zeroinitializer
  %17 = insertelement <4 x i32> poison, i32 %1, i64 0
  %18 = shufflevector <4 x i32> %17, <4 x i32> poison, <4 x i32> zeroinitializer
  %19 = insertelement <4 x i32> poison, i32 %7, i64 0
  %20 = shufflevector <4 x i32> %19, <4 x i32> poison, <4 x i32> zeroinitializer
  %21 = add <4 x i32> %20, <i32 0, i32 1, i32 2, i32 3>
  %22 = insertelement <4 x i32> poison, i32 %0, i64 0
  %23 = shufflevector <4 x i32> %22, <4 x i32> poison, <4 x i32> zeroinitializer
  %24 = add nsw <4 x i32> %23, <i32 0, i32 -1, i32 -2, i32 -3>
  br label %25

25:                                               ; preds = %25, %9
  %26 = phi i32 [ 0, %9 ], [ %45, %25 ]
  %27 = phi <4 x i32> [ %21, %9 ], [ %46, %25 ]
  %28 = phi <4 x i32> [ zeroinitializer, %9 ], [ %43, %25 ]
  %29 = phi <4 x i32> [ zeroinitializer, %9 ], [ %44, %25 ]
  %30 = phi <4 x i32> [ %24, %9 ], [ %47, %25 ]
  %31 = add <4 x i32> %27, splat (i32 4)
  %32 = add <4 x i32> %30, splat (i32 -4)
  %33 = icmp eq <4 x i32> %18, %30
  %34 = icmp eq <4 x i32> %18, %32
  %35 = or <4 x i1> %14, %33
  %36 = or <4 x i1> %14, %34
  %37 = tail call <4 x i32> @llvm.umin.v4i32(<4 x i32> %27, <4 x i32> %16)
  %38 = tail call <4 x i32> @llvm.umin.v4i32(<4 x i32> %31, <4 x i32> %16)
  %39 = add <4 x i32> %28, splat (i32 1)
  %40 = add <4 x i32> %29, splat (i32 1)
  %41 = add <4 x i32> %39, %37
  %42 = add <4 x i32> %40, %38
  %43 = select <4 x i1> %35, <4 x i32> %28, <4 x i32> %41
  %44 = select <4 x i1> %36, <4 x i32> %29, <4 x i32> %42
  %45 = add nuw i32 %26, 8
  %46 = add <4 x i32> %27, splat (i32 8)
  %47 = add <4 x i32> %30, splat (i32 -8)
  %48 = icmp eq i32 %45, %10
  br i1 %48, label %49, label %25, !llvm.loop !14

49:                                               ; preds = %25
  %50 = add <4 x i32> %44, %43
  %51 = tail call i32 @llvm.vector.reduce.add.v4i32(<4 x i32> %50)
  %52 = icmp eq i32 %0, %10
  br i1 %52, label %135, label %53

53:                                               ; preds = %49, %4
  %54 = phi i32 [ %7, %4 ], [ %11, %49 ]
  %55 = phi i32 [ 0, %4 ], [ %51, %49 ]
  %56 = phi i32 [ %0, %4 ], [ %12, %49 ]
  %57 = icmp eq i32 %1, %56
  %58 = or i1 %5, %57
  br i1 %58, label %63, label %59

59:                                               ; preds = %53
  %60 = tail call i32 @llvm.umin.i32(i32 %54, i32 %6)
  %61 = add i32 %55, 1
  %62 = add i32 %61, %60
  br label %63

63:                                               ; preds = %59, %53
  %64 = phi i32 [ %55, %53 ], [ %62, %59 ]
  %65 = icmp samesign ugt i32 %56, 1
  %66 = add i32 %54, 1
  br i1 %65, label %67, label %135, !llvm.loop !17

67:                                               ; preds = %63
  %68 = add nsw i32 %56, -1
  %69 = icmp eq i32 %1, %68
  %70 = or i1 %5, %69
  br i1 %70, label %75, label %71

71:                                               ; preds = %67
  %72 = tail call i32 @llvm.umin.i32(i32 %66, i32 %6)
  %73 = add i32 %64, 1
  %74 = add i32 %73, %72
  br label %75

75:                                               ; preds = %71, %67
  %76 = phi i32 [ %64, %67 ], [ %74, %71 ]
  %77 = icmp eq i32 %56, 2
  %78 = add i32 %54, 2
  br i1 %77, label %135, label %79, !llvm.loop !17

79:                                               ; preds = %75
  %80 = add nsw i32 %56, -2
  %81 = icmp eq i32 %1, %80
  %82 = or i1 %5, %81
  br i1 %82, label %87, label %83

83:                                               ; preds = %79
  %84 = tail call i32 @llvm.umin.i32(i32 %78, i32 %6)
  %85 = add i32 %76, 1
  %86 = add i32 %85, %84
  br label %87

87:                                               ; preds = %83, %79
  %88 = phi i32 [ %76, %79 ], [ %86, %83 ]
  %89 = icmp samesign ugt i32 %56, 3
  %90 = add i32 %54, 3
  br i1 %89, label %91, label %135, !llvm.loop !17

91:                                               ; preds = %87
  %92 = add nsw i32 %56, -3
  %93 = icmp eq i32 %1, %92
  %94 = or i1 %5, %93
  br i1 %94, label %99, label %95

95:                                               ; preds = %91
  %96 = tail call i32 @llvm.umin.i32(i32 %90, i32 %6)
  %97 = add i32 %88, 1
  %98 = add i32 %97, %96
  br label %99

99:                                               ; preds = %95, %91
  %100 = phi i32 [ %88, %91 ], [ %98, %95 ]
  %101 = icmp eq i32 %56, 4
  %102 = add i32 %54, 4
  br i1 %101, label %135, label %103, !llvm.loop !17

103:                                              ; preds = %99
  %104 = add nsw i32 %56, -4
  %105 = icmp eq i32 %1, %104
  %106 = or i1 %5, %105
  br i1 %106, label %111, label %107

107:                                              ; preds = %103
  %108 = tail call i32 @llvm.umin.i32(i32 %102, i32 %6)
  %109 = add i32 %100, 1
  %110 = add i32 %109, %108
  br label %111

111:                                              ; preds = %107, %103
  %112 = phi i32 [ %100, %103 ], [ %110, %107 ]
  %113 = icmp samesign ugt i32 %56, 5
  %114 = add i32 %54, 5
  br i1 %113, label %115, label %135, !llvm.loop !17

115:                                              ; preds = %111
  %116 = add nsw i32 %56, -5
  %117 = icmp eq i32 %1, %116
  %118 = or i1 %5, %117
  br i1 %118, label %123, label %119

119:                                              ; preds = %115
  %120 = tail call i32 @llvm.umin.i32(i32 %114, i32 %6)
  %121 = add i32 %112, 1
  %122 = add i32 %121, %120
  br label %123

123:                                              ; preds = %119, %115
  %124 = phi i32 [ %112, %115 ], [ %122, %119 ]
  %125 = icmp eq i32 %56, 7
  %126 = add i32 %54, 6
  br i1 %125, label %127, label %135, !llvm.loop !17

127:                                              ; preds = %123
  %128 = add nsw i32 %56, -6
  %129 = icmp eq i32 %1, %128
  %130 = or i1 %5, %129
  br i1 %130, label %135, label %131

131:                                              ; preds = %127
  %132 = tail call i32 @llvm.umin.i32(i32 %126, i32 %6)
  %133 = add i32 %124, 1
  %134 = add i32 %133, %132
  br label %135

135:                                              ; preds = %63, %75, %87, %99, %111, %123, %131, %127, %49, %2
  %136 = phi i32 [ 0, %2 ], [ %51, %49 ], [ %64, %63 ], [ %76, %75 ], [ %88, %87 ], [ %100, %99 ], [ %112, %111 ], [ %124, %123 ], [ %124, %127 ], [ %134, %131 ]
  ret i32 %136
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 0, 12) i32 @weight(i32 noundef %0) local_unnamed_addr #2 {
  %2 = icmp ult i32 %0, 5
  %3 = shl nsw i32 %0, 1
  %4 = add nsw i32 %3, 3
  %5 = select i1 %2, i32 %4, i32 0
  ret i32 %5
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 0, 2) i32 @in_season(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add i32 %0, -3
  %3 = icmp ult i32 %2, 4
  %4 = zext i1 %3 to i32
  ret i32 %4
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 -1, 41) i32 @step_down(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add i32 %0, -10
  %3 = icmp ult i32 %2, 4
  %4 = mul nsw i32 %2, -10
  %5 = add nsw i32 %4, 40
  %6 = select i1 %3, i32 %5, i32 -1
  ret i32 %6
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 -1, 10) i32 @scattered(i32 noundef %0) local_unnamed_addr #2 {
  %2 = icmp ult i32 %0, 4
  br i1 %2, label %3, label %7

3:                                                ; preds = %1
  %4 = zext nneg i32 %0 to i64
  %5 = getelementptr inbounds nuw [4 x i32], ptr @switch.table.scattered, i64 0, i64 %4
  %6 = load i32, ptr %5, align 4
  br label %7

7:                                                ; preds = %1, %3
  %8 = phi i32 [ %6, %3 ], [ -1, %1 ]
  ret i32 %8
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 0, 9) i32 @sparse(i32 noundef %0) local_unnamed_addr #2 {
  %2 = add i32 %0, -1
  %3 = icmp ult i32 %2, 4
  br i1 %3, label %4, label %8

4:                                                ; preds = %1
  %5 = zext nneg i32 %2 to i64
  %6 = getelementptr inbounds nuw [4 x i32], ptr @switch.table.sparse, i64 0, i64 %5
  %7 = load i32, ptr %6, align 4
  br label %8

8:                                                ; preds = %1, %4
  %9 = phi i32 [ %7, %4 ], [ 0, %1 ]
  ret i32 %9
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 -2147483647, -2147483648) i32 @case_works(i32 noundef %0, i32 noundef %1) local_unnamed_addr #2 {
  switch i32 %0, label %9 [
    i32 0, label %3
    i32 1, label %5
    i32 2, label %7
  ]

3:                                                ; preds = %2
  %4 = add nsw i32 %1, 1
  br label %9

5:                                                ; preds = %2
  %6 = add nsw i32 %1, 2
  br label %9

7:                                                ; preds = %2
  %8 = add nsw i32 %1, 3
  br label %9

9:                                                ; preds = %2, %7, %5, %3
  %10 = phi i32 [ %4, %3 ], [ %6, %5 ], [ %8, %7 ], [ 0, %2 ]
  ret i32 %10
}

; Function Attrs: nofree norecurse nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @thread_ops(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp slt i32 %1, 1
  br i1 %3, label %21, label %23

4:                                                ; preds = %23
  %5 = sext i32 %25 to i64
  %6 = getelementptr inbounds i8, ptr %0, i64 %5
  %7 = load i8, ptr %6, align 1, !tbaa !18
  %8 = zext i8 %7 to i32
  %9 = add nsw i32 %24, %8
  %10 = add nsw i32 %25, 1
  %11 = icmp slt i32 %10, %1
  br i1 %11, label %12, label %21

12:                                               ; preds = %17, %4
  %13 = phi i32 [ %9, %4 ], [ %18, %17 ]
  %14 = phi i32 [ %10, %4 ], [ %19, %17 ]
  %15 = sext i32 %14 to i64
  %16 = getelementptr inbounds i8, ptr %0, i64 %15
  br label %23

17:                                               ; preds = %23
  %18 = shl nsw i32 %24, 1
  %19 = add nsw i32 %25, 1
  %20 = icmp slt i32 %19, %1
  br i1 %20, label %12, label %21

21:                                               ; preds = %23, %17, %4, %2
  %22 = phi i32 [ 0, %2 ], [ %9, %4 ], [ %18, %17 ], [ %24, %23 ]
  ret i32 %22

23:                                               ; preds = %2, %12
  %24 = phi i32 [ %13, %12 ], [ 0, %2 ]
  %25 = phi i32 [ %14, %12 ], [ 0, %2 ]
  %26 = phi ptr [ %16, %12 ], [ %0, %2 ]
  %27 = load i8, ptr %26, align 1, !tbaa !18
  %28 = urem i8 %27, 3
  %29 = zext nneg i8 %28 to i64
  %30 = getelementptr inbounds nuw [3 x ptr], ptr @thread_ops.ops, i64 0, i64 %29
  %31 = load ptr, ptr %30, align 8, !tbaa !19
  indirectbr ptr %31, [label %4, label %17, label %21]
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local noundef range(i32 -1, 2) i32 @jump_over(i32 noundef %0) local_unnamed_addr #2 {
  %2 = icmp slt i32 %0, 1
  %3 = select i1 %2, i32 -1, i32 1
  ret i32 %3
}

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.umin.i32(i32, i32) #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare <4 x i32> @llvm.umin.v4i32(<4 x i32>, <4 x i32>) #3

; Function Attrs: nocallback nofree nosync nounwind speculatable willreturn memory(none)
declare i32 @llvm.vector.reduce.add.v4i32(<4 x i32>) #3

attributes #0 = { nofree norecurse nosync nounwind memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree norecurse nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nocallback nofree nosync nounwind speculatable willreturn memory(none) }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 21.1.8 (6ubuntu1)"}
!5 = distinct !{!5, !6}
!6 = !{!"llvm.loop.mustprogress"}
!7 = !{!8, !8, i64 0}
!8 = !{!"int", !9, i64 0}
!9 = !{!"omnipotent char", !10, i64 0}
!10 = !{!"Simple C/C++ TBAA"}
!11 = distinct !{!11, !6}
!12 = distinct !{!12, !6}
!13 = distinct !{!13, !6}
!14 = distinct !{!14, !6, !15, !16}
!15 = !{!"llvm.loop.isvectorized", i32 1}
!16 = !{!"llvm.loop.unroll.runtime.disable"}
!17 = distinct !{!17, !6, !16, !15}
!18 = !{!9, !9, i64 0}
!19 = !{!20, !20, i64 0}
!20 = !{!"any pointer", !9, i64 0}
