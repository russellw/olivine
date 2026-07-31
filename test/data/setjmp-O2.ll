; ModuleID = 'test/c/setjmp.c'
source_filename = "test/c/setjmp.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.__jmp_buf_tag = type { [8 x i64], i32, %struct.__sigset_t }
%struct.__sigset_t = type { [16 x i64] }

@landings = dso_local local_unnamed_addr global i32 0, align 4
@env = internal global [1 x %struct.__jmp_buf_tag] zeroinitializer, align 16

; Function Attrs: nounwind uwtable
define dso_local i32 @over(ptr noundef readonly captures(none) %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %6

4:                                                ; preds = %2
  %5 = zext nneg i32 %1 to i64
  br label %8

6:                                                ; preds = %18, %2
  %7 = phi i32 [ 0, %2 ], [ %19, %18 ]
  ret i32 %7

8:                                                ; preds = %4, %18
  %9 = phi i64 [ 0, %4 ], [ %20, %18 ]
  %10 = phi i32 [ 0, %4 ], [ %19, %18 ]
  %11 = getelementptr inbounds nuw i32, ptr %0, i64 %9
  %12 = load i32, ptr %11, align 4, !tbaa !5
  %13 = tail call fastcc i32 @guarded(i32 noundef %12)
  %14 = icmp slt i32 %13, 0
  br i1 %14, label %15, label %18

15:                                               ; preds = %8
  %16 = load i32, ptr @landings, align 4, !tbaa !5
  %17 = add nsw i32 %16, 1
  store i32 %17, ptr @landings, align 4, !tbaa !5
  br label %18

18:                                               ; preds = %15, %8
  %19 = add nsw i32 %13, %10
  %20 = add nuw nsw i64 %9, 1
  %21 = icmp eq i64 %20, %5
  br i1 %21, label %6, label %8, !llvm.loop !9
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define internal fastcc range(i32 -2147483648, 3) i32 @guarded(i32 noundef %0) unnamed_addr #0 {
  %2 = call i32 @_setjmp(ptr noundef nonnull @env) #4
  %3 = icmp eq i32 %2, 0
  br i1 %3, label %4, label %7

4:                                                ; preds = %1
  %5 = icmp sgt i32 %0, 2
  br i1 %5, label %6, label %7

6:                                                ; preds = %4
  call void @longjmp(ptr noundef nonnull @env, i32 noundef 1) #5
  unreachable

7:                                                ; preds = %4, %1
  %8 = phi i32 [ -1, %1 ], [ %0, %4 ]
  ret i32 %8
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nounwind uwtable
define dso_local i32 @with_helper(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2)
  store volatile i32 0, ptr %2, align 4, !tbaa !5
  %3 = call i32 @_setjmp(ptr noundef nonnull @env) #4
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %7, label %5

5:                                                ; preds = %1
  %6 = load volatile i32, ptr %2, align 4, !tbaa !5
  br label %15

7:                                                ; preds = %1
  %8 = shl nsw i32 %0, 1
  store volatile i32 %8, ptr %2, align 4, !tbaa !5
  %9 = load volatile i32, ptr %2, align 4, !tbaa !5
  %10 = icmp sgt i32 %9, 8
  br i1 %10, label %11, label %12

11:                                               ; preds = %7
  call void @longjmp(ptr noundef nonnull @env, i32 noundef 1) #5
  unreachable

12:                                               ; preds = %7
  %13 = load volatile i32, ptr %2, align 4, !tbaa !5
  %14 = add nsw i32 %13, 100
  br label %15

15:                                               ; preds = %12, %5
  %16 = phi i32 [ %6, %5 ], [ %14, %12 ]
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2)
  ret i32 %16
}

; Function Attrs: nounwind returns_twice
declare i32 @_setjmp(ptr noundef) local_unnamed_addr #2

; Function Attrs: noreturn nounwind
declare void @longjmp(ptr noundef, i32 noundef) local_unnamed_addr #3

; Function Attrs: nounwind uwtable
define dso_local i32 @depth(i32 noundef %0) local_unnamed_addr #0 {
  %2 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2)
  store volatile i32 0, ptr %2, align 4, !tbaa !5
  %3 = call i32 @_setjmp(ptr noundef nonnull @env) #4
  %4 = icmp eq i32 %3, 0
  br i1 %4, label %5, label %14

5:                                                ; preds = %1, %8
  %6 = load volatile i32, ptr %2, align 4, !tbaa !5
  %7 = icmp slt i32 %6, %0
  br i1 %7, label %8, label %14

8:                                                ; preds = %5
  %9 = load volatile i32, ptr %2, align 4, !tbaa !5
  %10 = add nsw i32 %9, 1
  store volatile i32 %10, ptr %2, align 4, !tbaa !5
  %11 = load volatile i32, ptr %2, align 4, !tbaa !5
  %12 = icmp eq i32 %11, 3
  br i1 %12, label %13, label %5, !llvm.loop !11

13:                                               ; preds = %8
  call void @longjmp(ptr noundef nonnull @env, i32 noundef 1) #5
  unreachable

14:                                               ; preds = %5, %1
  %15 = load volatile i32, ptr %2, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2)
  ret i32 %15
}

attributes #0 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nounwind returns_twice "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { noreturn nounwind "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { nounwind returns_twice }
attributes #5 = { noreturn nounwind }

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
!9 = distinct !{!9, !10}
!10 = !{!"llvm.loop.mustprogress"}
!11 = distinct !{!11, !10}
