; ModuleID = 'test/c/tail.c'
source_filename = "test/c/tail.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nofree nosync nounwind memory(none) uwtable
define dso_local i32 @gcd_of(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  br label %3

3:                                                ; preds = %7, %2
  %4 = phi i32 [ %0, %2 ], [ %5, %7 ]
  %5 = phi i32 [ %1, %2 ], [ %8, %7 ]
  %6 = icmp eq i32 %5, 0
  br i1 %6, label %9, label %7

7:                                                ; preds = %3
  %8 = srem i32 %4, %5
  br label %3

9:                                                ; preds = %3
  ret i32 %4
}

; Function Attrs: nofree nosync nounwind memory(none) uwtable
define dso_local i32 @alternate(i32 noundef %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  br label %4

4:                                                ; preds = %12, %3
  %5 = phi i32 [ %0, %3 ], [ %6, %12 ]
  %6 = phi i32 [ %1, %3 ], [ %5, %12 ]
  %7 = phi i32 [ %2, %3 ], [ %13, %12 ]
  %8 = icmp eq i32 %7, 0
  br i1 %8, label %9, label %12

9:                                                ; preds = %4
  %10 = mul nsw i32 %5, 10
  %11 = add nsw i32 %10, %6
  ret i32 %11

12:                                               ; preds = %4
  %13 = add nsw i32 %7, -1
  br label %4
}

; Function Attrs: nofree nosync nounwind memory(none) uwtable
define dso_local i32 @steps(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  br label %3

3:                                                ; preds = %7, %2
  %4 = phi i32 [ %0, %2 ], [ %12, %7 ]
  %5 = phi i32 [ %1, %2 ], [ %14, %7 ]
  %6 = icmp slt i32 %4, 1
  br i1 %6, label %15, label %7

7:                                                ; preds = %3
  %8 = and i32 %4, 1
  %9 = icmp eq i32 %8, 0
  %10 = lshr exact i32 %4, 1
  %11 = add nsw i32 %4, -1
  %12 = select i1 %9, i32 %10, i32 %11
  %13 = sub i32 %5, %8
  %14 = add i32 %13, 2
  br label %3

15:                                               ; preds = %3
  ret i32 %5
}

; Function Attrs: nofree nosync nounwind memory(argmem: readwrite) uwtable
define dso_local void @walk_down(ptr noundef captures(none) %0, i32 noundef %1) local_unnamed_addr #1 {
  br label %3

3:                                                ; preds = %6, %2
  %4 = phi i32 [ %1, %2 ], [ %9, %6 ]
  %5 = icmp eq i32 %4, 0
  br i1 %5, label %10, label %6

6:                                                ; preds = %3
  %7 = load i32, ptr %0, align 4, !tbaa !5
  %8 = add nsw i32 %7, %4
  store i32 %8, ptr %0, align 4, !tbaa !5
  %9 = add nsw i32 %4, -1
  br label %3

10:                                               ; preds = %3
  ret void
}

; Function Attrs: nofree nosync nounwind memory(none) uwtable
define dso_local i32 @buffered(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = alloca [4 x i32], align 16
  call void @llvm.lifetime.start.p0(i64 16, ptr nonnull %3) #5
  %4 = icmp slt i32 %0, 1
  br i1 %4, label %20, label %13

5:                                                ; preds = %13
  %6 = add nsw i32 %0, -1
  %7 = and i32 %0, 3
  %8 = zext nneg i32 %7 to i64
  %9 = getelementptr inbounds nuw [4 x i32], ptr %3, i64 0, i64 %8
  %10 = load i32, ptr %9, align 4, !tbaa !5
  %11 = add nsw i32 %10, %1
  %12 = tail call i32 @buffered(i32 noundef %6, i32 noundef %11)
  br label %20

13:                                               ; preds = %2, %13
  %14 = phi i64 [ %18, %13 ], [ 0, %2 ]
  %15 = getelementptr inbounds nuw [4 x i32], ptr %3, i64 0, i64 %14
  %16 = trunc i64 %14 to i32
  %17 = add i32 %0, %16
  store i32 %17, ptr %15, align 4, !tbaa !5
  %18 = add nuw nsw i64 %14, 1
  %19 = icmp eq i64 %18, 4
  br i1 %19, label %5, label %13, !llvm.loop !9

20:                                               ; preds = %2, %5
  %21 = phi i32 [ %12, %5 ], [ %1, %2 ]
  call void @llvm.lifetime.end.p0(i64 16, ptr nonnull %3) #5
  ret i32 %21
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #2

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #2

; Function Attrs: nofree nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @via_local(i32 noundef %0, ptr noundef readonly captures(address_is_null) %1) local_unnamed_addr #3 {
  %3 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %3) #5
  %4 = mul nsw i32 %0, 3
  store i32 %4, ptr %3, align 4, !tbaa !5
  %5 = icmp eq i32 %0, 0
  br i1 %5, label %6, label %10

6:                                                ; preds = %2
  %7 = icmp eq ptr %1, null
  br i1 %7, label %13, label %8

8:                                                ; preds = %6
  %9 = load i32, ptr %1, align 4, !tbaa !5
  br label %13

10:                                               ; preds = %2
  %11 = add nsw i32 %0, -1
  %12 = call i32 @via_local(i32 noundef %11, ptr noundef nonnull %3)
  br label %13

13:                                               ; preds = %8, %6, %10
  %14 = phi i32 [ %12, %10 ], [ %9, %8 ], [ -1, %6 ]
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %3) #5
  ret i32 %14
}

; Function Attrs: nofree nosync nounwind memory(none) uwtable
define dso_local range(i32 1, -2147483648) i32 @product_to(i32 noundef %0) local_unnamed_addr #0 {
  br label %2

2:                                                ; preds = %6, %1
  %3 = phi i32 [ 1, %1 ], [ %8, %6 ]
  %4 = phi i32 [ %0, %1 ], [ %7, %6 ]
  %5 = icmp slt i32 %4, 2
  br i1 %5, label %9, label %6

6:                                                ; preds = %2
  %7 = add nsw i32 %4, -1
  %8 = mul nuw nsw i32 %3, %4
  br label %2

9:                                                ; preds = %2
  %10 = mul nuw nsw i32 %3, 1
  ret i32 %10
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable
define dso_local range(i32 -2147483647, -2147483648) i32 @forwards(i32 noundef %0) local_unnamed_addr #4 {
  %2 = add nsw i32 %0, 1
  ret i32 %2
}

; Function Attrs: nofree nosync nounwind memory(none) uwtable
define dso_local range(i32 10, 21) i32 @bounced(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call fastcc i32 @ping(i32 noundef %0)
  ret i32 %2
}

; Function Attrs: nofree nosync nounwind memory(none) uwtable
define internal fastcc range(i32 10, 21) i32 @ping(i32 noundef %0) unnamed_addr #0 {
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
  %8 = phi i32 [ 10, %2 ], [ 20, %6 ]
  ret i32 %8
}

; Function Attrs: nofree nosync nounwind memory(argmem: read) uwtable
define dso_local i32 @skipping(ptr noundef readonly captures(none) %0, i32 noundef %1, i32 noundef %2) local_unnamed_addr #3 {
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
  %15 = load i32, ptr %14, align 4, !tbaa !5
  %16 = icmp sgt i32 %15, 0
  br i1 %16, label %17, label %21

17:                                               ; preds = %11
  %18 = add nsw i32 %15, %13
  %19 = add nuw nsw i64 %12, 1
  %20 = icmp eq i64 %19, %10
  br i1 %20, label %23, label %11, !llvm.loop !12

21:                                               ; preds = %11
  %22 = trunc nuw nsw i64 %12 to i32
  br label %23

23:                                               ; preds = %21, %17, %4
  %24 = phi i32 [ %7, %4 ], [ %13, %21 ], [ %18, %17 ]
  %25 = phi i32 [ 0, %4 ], [ %22, %21 ], [ %6, %17 ]
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

34:                                               ; preds = %23
  ret i32 %24
}

attributes #0 = { nofree nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nofree nosync nounwind memory(argmem: readwrite) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { nofree nosync nounwind memory(argmem: read) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }

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
!9 = distinct !{!9, !10, !11}
!10 = !{!"llvm.loop.mustprogress"}
!11 = !{!"llvm.loop.unroll.disable"}
!12 = distinct !{!12, !10, !11}
