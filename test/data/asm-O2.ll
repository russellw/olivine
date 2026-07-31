; ModuleID = 'test/c/asm.c'
source_filename = "test/c/asm.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

; Function Attrs: nofree nosync nounwind memory(none) uwtable
define dso_local i32 @swapped(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 asm "bswapl $0", "=r,0,~{dirflag},~{fpsr},~{flags}"(i32 %0) #3, !srcloc !5
  ret i32 %2
}

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #1

; Function Attrs: nofree nosync nounwind memory(none) uwtable
define dso_local i32 @swapped_twice(i32 noundef %0) local_unnamed_addr #0 {
  %2 = tail call i32 asm "bswapl $0", "=r,0,~{dirflag},~{fpsr},~{flags}"(i32 %0) #3, !srcloc !6
  %3 = tail call i32 asm "bswapl $0", "=r,0,~{dirflag},~{fpsr},~{flags}"(i32 %2) #3, !srcloc !7
  %4 = add nsw i32 %3, %2
  ret i32 %4
}

; Function Attrs: nounwind uwtable
define dso_local i32 @reread(ptr noundef readonly captures(none) %0) local_unnamed_addr #2 {
  %2 = load i32, ptr %0, align 4, !tbaa !8
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !12
  %3 = load i32, ptr %0, align 4, !tbaa !8
  %4 = mul nsw i32 %2, 100
  %5 = add nsw i32 %3, %4
  ret i32 %5
}

; Function Attrs: nounwind uwtable
define dso_local i32 @barrier_sum(ptr noundef readonly captures(none) %0, i32 noundef %1, ptr noundef readonly captures(none) %2) local_unnamed_addr #2 {
  %4 = icmp sgt i32 %1, 0
  br i1 %4, label %5, label %7

5:                                                ; preds = %3
  %6 = zext nneg i32 %1 to i64
  br label %9

7:                                                ; preds = %9, %3
  %8 = phi i32 [ 0, %3 ], [ %16, %9 ]
  ret i32 %8

9:                                                ; preds = %5, %9
  %10 = phi i64 [ 0, %5 ], [ %17, %9 ]
  %11 = phi i32 [ 0, %5 ], [ %16, %9 ]
  %12 = getelementptr inbounds nuw i32, ptr %0, i64 %10
  %13 = load i32, ptr %12, align 4, !tbaa !8
  %14 = load i32, ptr %2, align 4, !tbaa !8
  %15 = mul nsw i32 %14, %13
  %16 = add nsw i32 %15, %11
  tail call void asm sideeffect "", "~{memory},~{dirflag},~{fpsr},~{flags}"() #4, !srcloc !13
  %17 = add nuw nsw i64 %10, 1
  %18 = icmp eq i64 %17, %6
  br i1 %18, label %7, label %9, !llvm.loop !14
}

; Function Attrs: nounwind uwtable
define dso_local i32 @through_slot(i32 noundef %0) local_unnamed_addr #2 {
  %2 = alloca i32, align 4
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #4
  store i32 %0, ptr %2, align 4, !tbaa !8
  call void asm sideeffect "addl $$7, $0", "=*m,*m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i32) %2, ptr nonnull elementtype(i32) %2) #4, !srcloc !16
  %3 = load i32, ptr %2, align 4, !tbaa !8
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #4
  ret i32 %3
}

; Function Attrs: nofree nosync nounwind memory(none) uwtable
define dso_local i32 @hidden(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = add nsw i32 %1, %0
  %4 = shl nsw i32 %3, 1
  %5 = tail call i32 asm "", "=r,0,~{dirflag},~{fpsr},~{flags}"(i32 %4) #3, !srcloc !17
  ret i32 %5
}

; Function Attrs: nofree nosync nounwind memory(none) uwtable
define dso_local i32 @each_time(i32 noundef %0, i32 noundef %1) local_unnamed_addr #0 {
  %3 = icmp sgt i32 %1, 0
  br i1 %3, label %4, label %8

4:                                                ; preds = %2
  %5 = tail call i32 asm "bswapl $0", "=r,0,~{dirflag},~{fpsr},~{flags}"(i32 %0) #3, !srcloc !18
  %6 = ashr i32 %5, 24
  %7 = mul i32 %6, %1
  br label %8

8:                                                ; preds = %4, %2
  %9 = phi i32 [ 0, %2 ], [ %7, %4 ]
  ret i32 %9
}

; Function Attrs: nounwind uwtable
define dso_local i32 @both_kinds(i32 noundef %0) local_unnamed_addr #2 {
  %2 = alloca i32, align 4
  %3 = mul nsw i32 %0, 3
  call void @llvm.lifetime.start.p0(i64 4, ptr nonnull %2) #4
  store i32 %0, ptr %2, align 4, !tbaa !8
  call void asm sideeffect "addl $$1, $0", "=*m,*m,~{dirflag},~{fpsr},~{flags}"(ptr nonnull elementtype(i32) %2, ptr nonnull elementtype(i32) %2) #4, !srcloc !19
  %4 = load i32, ptr %2, align 4, !tbaa !8
  %5 = add nsw i32 %4, %3
  call void @llvm.lifetime.end.p0(i64 4, ptr nonnull %2) #4
  ret i32 %5
}

attributes #0 = { nofree nosync nounwind memory(none) uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { mustprogress nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #2 = { nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #3 = { nounwind memory(none) }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{!"Ubuntu clang version 21.1.8 (6ubuntu1)"}
!5 = !{i64 1081}
!6 = !{i64 1382}
!7 = !{i64 1425}
!8 = !{!9, !9, i64 0}
!9 = !{!"int", !10, i64 0}
!10 = !{!"omnipotent char", !11, i64 0}
!11 = !{!"Simple C/C++ TBAA"}
!12 = !{i64 1681}
!13 = !{i64 2069}
!14 = distinct !{!14, !15}
!15 = !{!"llvm.loop.mustprogress"}
!16 = !{i64 2279}
!17 = !{i64 2594}
!18 = !{i64 3395}
!19 = !{i64 3686}
