; ModuleID = 'test/c/except.cpp'
source_filename = "test/c/except.cpp"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%struct.Tracker = type { i8 }

$_ZN7TrackerC2Ev = comdat any

$_ZN7TrackerD2Ev = comdat any

$__clang_call_terminate = comdat any

@cleanups_run = dso_local global i32 0, align 4
@_ZTIi = external constant ptr

; Function Attrs: mustprogress uwtable
define dso_local i32 @caught_value(i32 noundef %0) #0 personality ptr @__gxx_personality_v0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  %7 = load i32, ptr %3, align 4, !tbaa !5
  %8 = invoke noundef i32 @_ZL9may_throwi(i32 noundef %7)
          to label %9 unwind label %10

9:                                                ; preds = %1
  store i32 %8, ptr %2, align 4
  br label %25

10:                                               ; preds = %1
  %11 = landingpad { ptr, i32 }
          catch ptr @_ZTIi
  %12 = extractvalue { ptr, i32 } %11, 0
  store ptr %12, ptr %4, align 8
  %13 = extractvalue { ptr, i32 } %11, 1
  store i32 %13, ptr %5, align 4
  br label %14

14:                                               ; preds = %10
  %15 = load i32, ptr %5, align 4
  %16 = call i32 @llvm.eh.typeid.for.p0(ptr @_ZTIi) #5
  %17 = icmp eq i32 %15, %16
  br i1 %17, label %18, label %27

18:                                               ; preds = %14
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #5
  %19 = load ptr, ptr %4, align 8
  %20 = call ptr @__cxa_begin_catch(ptr %19) #5
  %21 = load i32, ptr %20, align 4, !tbaa !5
  store i32 %21, ptr %6, align 4, !tbaa !5
  %22 = load i32, ptr %6, align 4, !tbaa !5
  %23 = sub nsw i32 %22, 1
  store i32 %23, ptr %2, align 4
  call void @__cxa_end_catch() #5
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #5
  br label %25

24:                                               ; No predecessors!
  unreachable

25:                                               ; preds = %18, %9
  %26 = load i32, ptr %2, align 4
  ret i32 %26

27:                                               ; preds = %14
  %28 = load ptr, ptr %4, align 8
  %29 = load i32, ptr %5, align 4
  %30 = insertvalue { ptr, i32 } poison, ptr %28, 0
  %31 = insertvalue { ptr, i32 } %30, i32 %29, 1
  resume { ptr, i32 } %31
}

; Function Attrs: mustprogress uwtable
define internal noundef i32 @_ZL9may_throwi(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  %3 = load i32, ptr %2, align 4, !tbaa !5
  %4 = icmp slt i32 %3, 0
  br i1 %4, label %5, label %8

5:                                                ; preds = %1
  %6 = call ptr @__cxa_allocate_exception(i64 4) #5
  %7 = load i32, ptr %2, align 4, !tbaa !5
  store i32 %7, ptr %6, align 16, !tbaa !5
  call void @__cxa_throw(ptr %6, ptr @_ZTIi, ptr null) #6
  unreachable

8:                                                ; preds = %1
  %9 = load i32, ptr %2, align 4, !tbaa !5
  %10 = mul nsw i32 %9, 2
  ret i32 %10
}

declare i32 @__gxx_personality_v0(...)

; Function Attrs: nounwind memory(none)
declare i32 @llvm.eh.typeid.for.p0(ptr) #1

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(i64 immarg, ptr captures(none)) #2

declare ptr @__cxa_begin_catch(ptr)

declare void @__cxa_end_catch()

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(i64 immarg, ptr captures(none)) #2

; Function Attrs: mustprogress uwtable
define dso_local i32 @caught_anything(i32 noundef %0) #0 personality ptr @__gxx_personality_v0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  %6 = load i32, ptr %3, align 4, !tbaa !5
  %7 = invoke noundef i32 @_ZL9may_throwi(i32 noundef %6)
          to label %8 unwind label %9

8:                                                ; preds = %1
  store i32 %7, ptr %2, align 4
  br label %17

9:                                                ; preds = %1
  %10 = landingpad { ptr, i32 }
          catch ptr null
  %11 = extractvalue { ptr, i32 } %10, 0
  store ptr %11, ptr %4, align 8
  %12 = extractvalue { ptr, i32 } %10, 1
  store i32 %12, ptr %5, align 4
  br label %13

13:                                               ; preds = %9
  %14 = load ptr, ptr %4, align 8
  %15 = call ptr @__cxa_begin_catch(ptr %14) #5
  store i32 -1, ptr %2, align 4
  call void @__cxa_end_catch()
  br label %17

16:                                               ; No predecessors!
  unreachable

17:                                               ; preds = %13, %8
  %18 = load i32, ptr %2, align 4
  ret i32 %18
}

; Function Attrs: mustprogress uwtable
define dso_local i32 @cleanup_on_both(i32 noundef %0) #0 personality ptr @__gxx_personality_v0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca %struct.Tracker, align 1
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 1, ptr %4) #5
  invoke void @_ZN7TrackerC2Ev(ptr noundef nonnull align 1 dereferenceable(1) %4)
          to label %8 unwind label %12

8:                                                ; preds = %1
  %9 = load i32, ptr %3, align 4, !tbaa !5
  %10 = invoke noundef i32 @_ZL9may_throwi(i32 noundef %9)
          to label %11 unwind label %16

11:                                               ; preds = %8
  store i32 %10, ptr %2, align 4
  call void @_ZN7TrackerD2Ev(ptr noundef nonnull align 1 dereferenceable(1) %4) #5
  call void @llvm.lifetime.end.p0(i64 1, ptr %4) #5
  br label %31

12:                                               ; preds = %1
  %13 = landingpad { ptr, i32 }
          cleanup
          catch ptr @_ZTIi
  %14 = extractvalue { ptr, i32 } %13, 0
  store ptr %14, ptr %5, align 8
  %15 = extractvalue { ptr, i32 } %13, 1
  store i32 %15, ptr %6, align 4
  br label %20

16:                                               ; preds = %8
  %17 = landingpad { ptr, i32 }
          cleanup
          catch ptr @_ZTIi
  %18 = extractvalue { ptr, i32 } %17, 0
  store ptr %18, ptr %5, align 8
  %19 = extractvalue { ptr, i32 } %17, 1
  store i32 %19, ptr %6, align 4
  call void @_ZN7TrackerD2Ev(ptr noundef nonnull align 1 dereferenceable(1) %4) #5
  br label %20

20:                                               ; preds = %16, %12
  call void @llvm.lifetime.end.p0(i64 1, ptr %4) #5
  br label %21

21:                                               ; preds = %20
  %22 = load i32, ptr %6, align 4
  %23 = call i32 @llvm.eh.typeid.for.p0(ptr @_ZTIi) #5
  %24 = icmp eq i32 %22, %23
  br i1 %24, label %25, label %33

25:                                               ; preds = %21
  call void @llvm.lifetime.start.p0(i64 4, ptr %7) #5
  %26 = load ptr, ptr %5, align 8
  %27 = call ptr @__cxa_begin_catch(ptr %26) #5
  %28 = load i32, ptr %27, align 4, !tbaa !5
  store i32 %28, ptr %7, align 4, !tbaa !5
  %29 = load i32, ptr %7, align 4, !tbaa !5
  store i32 %29, ptr %2, align 4
  call void @__cxa_end_catch() #5
  call void @llvm.lifetime.end.p0(i64 4, ptr %7) #5
  br label %31

30:                                               ; No predecessors!
  unreachable

31:                                               ; preds = %25, %11
  %32 = load i32, ptr %2, align 4
  ret i32 %32

33:                                               ; preds = %21
  %34 = load ptr, ptr %5, align 8
  %35 = load i32, ptr %6, align 4
  %36 = insertvalue { ptr, i32 } poison, ptr %34, 0
  %37 = insertvalue { ptr, i32 } %36, i32 %35, 1
  resume { ptr, i32 } %37
}

; Function Attrs: mustprogress nounwind uwtable
define linkonce_odr dso_local void @_ZN7TrackerC2Ev(ptr noundef nonnull align 1 dereferenceable(1) %0) unnamed_addr #3 comdat align 2 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8, !tbaa !9
  %3 = load ptr, ptr %2, align 8
  ret void
}

; Function Attrs: mustprogress nounwind uwtable
define linkonce_odr dso_local void @_ZN7TrackerD2Ev(ptr noundef nonnull align 1 dereferenceable(1) %0) unnamed_addr #3 comdat align 2 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8, !tbaa !9
  %3 = load ptr, ptr %2, align 8
  %4 = load i32, ptr @cleanups_run, align 4, !tbaa !5
  %5 = add nsw i32 %4, 1
  store i32 %5, ptr @cleanups_run, align 4, !tbaa !5
  ret void
}

; Function Attrs: mustprogress uwtable
define dso_local i32 @passed_on(i32 noundef %0) #0 personality ptr @__gxx_personality_v0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 %0, ptr %3, align 4, !tbaa !5
  %7 = load i32, ptr %3, align 4, !tbaa !5
  %8 = invoke noundef i32 @_ZL10rethrowingi(i32 noundef %7)
          to label %9 unwind label %10

9:                                                ; preds = %1
  store i32 %8, ptr %2, align 4
  br label %25

10:                                               ; preds = %1
  %11 = landingpad { ptr, i32 }
          catch ptr @_ZTIi
  %12 = extractvalue { ptr, i32 } %11, 0
  store ptr %12, ptr %4, align 8
  %13 = extractvalue { ptr, i32 } %11, 1
  store i32 %13, ptr %5, align 4
  br label %14

14:                                               ; preds = %10
  %15 = load i32, ptr %5, align 4
  %16 = call i32 @llvm.eh.typeid.for.p0(ptr @_ZTIi) #5
  %17 = icmp eq i32 %15, %16
  br i1 %17, label %18, label %27

18:                                               ; preds = %14
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #5
  %19 = load ptr, ptr %4, align 8
  %20 = call ptr @__cxa_begin_catch(ptr %19) #5
  %21 = load i32, ptr %20, align 4, !tbaa !5
  store i32 %21, ptr %6, align 4, !tbaa !5
  %22 = load i32, ptr %6, align 4, !tbaa !5
  %23 = mul nsw i32 %22, 3
  store i32 %23, ptr %2, align 4
  call void @__cxa_end_catch() #5
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #5
  br label %25

24:                                               ; No predecessors!
  unreachable

25:                                               ; preds = %18, %9
  %26 = load i32, ptr %2, align 4
  ret i32 %26

27:                                               ; preds = %14
  %28 = load ptr, ptr %4, align 8
  %29 = load i32, ptr %5, align 4
  %30 = insertvalue { ptr, i32 } poison, ptr %28, 0
  %31 = insertvalue { ptr, i32 } %30, i32 %29, 1
  resume { ptr, i32 } %31
}

; Function Attrs: mustprogress uwtable
define internal noundef i32 @_ZL10rethrowingi(i32 noundef %0) #0 personality ptr @__gxx_personality_v0 {
  %2 = alloca i32, align 4
  %3 = alloca %struct.Tracker, align 1
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  store i32 %0, ptr %2, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 1, ptr %3) #5
  invoke void @_ZN7TrackerC2Ev(ptr noundef nonnull align 1 dereferenceable(1) %3)
          to label %6 unwind label %10

6:                                                ; preds = %1
  %7 = load i32, ptr %2, align 4, !tbaa !5
  %8 = invoke noundef i32 @_ZL9may_throwi(i32 noundef %7)
          to label %9 unwind label %14

9:                                                ; preds = %6
  call void @_ZN7TrackerD2Ev(ptr noundef nonnull align 1 dereferenceable(1) %3) #5
  call void @llvm.lifetime.end.p0(i64 1, ptr %3) #5
  ret i32 %8

10:                                               ; preds = %1
  %11 = landingpad { ptr, i32 }
          catch ptr null
  %12 = extractvalue { ptr, i32 } %11, 0
  store ptr %12, ptr %4, align 8
  %13 = extractvalue { ptr, i32 } %11, 1
  store i32 %13, ptr %5, align 4
  br label %18

14:                                               ; preds = %6
  %15 = landingpad { ptr, i32 }
          catch ptr null
  %16 = extractvalue { ptr, i32 } %15, 0
  store ptr %16, ptr %4, align 8
  %17 = extractvalue { ptr, i32 } %15, 1
  store i32 %17, ptr %5, align 4
  call void @_ZN7TrackerD2Ev(ptr noundef nonnull align 1 dereferenceable(1) %3) #5
  br label %18

18:                                               ; preds = %14, %10
  call void @llvm.lifetime.end.p0(i64 1, ptr %3) #5
  br label %19

19:                                               ; preds = %18
  %20 = load ptr, ptr %4, align 8
  %21 = call ptr @__cxa_begin_catch(ptr %20) #5
  invoke void @__cxa_rethrow() #6
          to label %36 unwind label %22

22:                                               ; preds = %19
  %23 = landingpad { ptr, i32 }
          cleanup
  %24 = extractvalue { ptr, i32 } %23, 0
  store ptr %24, ptr %4, align 8
  %25 = extractvalue { ptr, i32 } %23, 1
  store i32 %25, ptr %5, align 4
  invoke void @__cxa_end_catch()
          to label %26 unwind label %33

26:                                               ; preds = %22
  br label %28

27:                                               ; No predecessors!
  unreachable

28:                                               ; preds = %26
  %29 = load ptr, ptr %4, align 8
  %30 = load i32, ptr %5, align 4
  %31 = insertvalue { ptr, i32 } poison, ptr %29, 0
  %32 = insertvalue { ptr, i32 } %31, i32 %30, 1
  resume { ptr, i32 } %32

33:                                               ; preds = %22
  %34 = landingpad { ptr, i32 }
          catch ptr null
  %35 = extractvalue { ptr, i32 } %34, 0
  call void @__clang_call_terminate(ptr %35) #7
  unreachable

36:                                               ; preds = %19
  unreachable
}

; Function Attrs: mustprogress uwtable
define dso_local i32 @summed(ptr noundef %0, i32 noundef %1) #0 personality ptr @__gxx_personality_v0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  store ptr %0, ptr %3, align 8, !tbaa !12
  store i32 %1, ptr %4, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %5) #5
  store i32 0, ptr %5, align 4, !tbaa !5
  call void @llvm.lifetime.start.p0(i64 4, ptr %6) #5
  store i32 0, ptr %6, align 4, !tbaa !5
  br label %10

10:                                               ; preds = %41, %2
  %11 = load i32, ptr %6, align 4, !tbaa !5
  %12 = load i32, ptr %4, align 4, !tbaa !5
  %13 = icmp slt i32 %11, %12
  br i1 %13, label %15, label %14

14:                                               ; preds = %10
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #5
  br label %45

15:                                               ; preds = %10
  %16 = load ptr, ptr %3, align 8, !tbaa !12
  %17 = load i32, ptr %6, align 4, !tbaa !5
  %18 = sext i32 %17 to i64
  %19 = getelementptr inbounds i32, ptr %16, i64 %18
  %20 = load i32, ptr %19, align 4, !tbaa !5
  %21 = invoke noundef i32 @_ZL9may_throwi(i32 noundef %20)
          to label %22 unwind label %25

22:                                               ; preds = %15
  %23 = load i32, ptr %5, align 4, !tbaa !5
  %24 = add nsw i32 %23, %21
  store i32 %24, ptr %5, align 4, !tbaa !5
  br label %40

25:                                               ; preds = %15
  %26 = landingpad { ptr, i32 }
          cleanup
          catch ptr @_ZTIi
  %27 = extractvalue { ptr, i32 } %26, 0
  store ptr %27, ptr %7, align 8
  %28 = extractvalue { ptr, i32 } %26, 1
  store i32 %28, ptr %8, align 4
  br label %29

29:                                               ; preds = %25
  %30 = load i32, ptr %8, align 4
  %31 = call i32 @llvm.eh.typeid.for.p0(ptr @_ZTIi) #5
  %32 = icmp eq i32 %30, %31
  br i1 %32, label %33, label %44

33:                                               ; preds = %29
  call void @llvm.lifetime.start.p0(i64 4, ptr %9) #5
  %34 = load ptr, ptr %7, align 8
  %35 = call ptr @__cxa_begin_catch(ptr %34) #5
  %36 = load i32, ptr %35, align 4, !tbaa !5
  store i32 %36, ptr %9, align 4, !tbaa !5
  %37 = load i32, ptr %9, align 4, !tbaa !5
  %38 = load i32, ptr %5, align 4, !tbaa !5
  %39 = sub nsw i32 %38, %37
  store i32 %39, ptr %5, align 4, !tbaa !5
  call void @__cxa_end_catch() #5
  call void @llvm.lifetime.end.p0(i64 4, ptr %9) #5
  br label %40

40:                                               ; preds = %33, %22
  br label %41

41:                                               ; preds = %40
  %42 = load i32, ptr %6, align 4, !tbaa !5
  %43 = add nsw i32 %42, 1
  store i32 %43, ptr %6, align 4, !tbaa !5
  br label %10, !llvm.loop !14

44:                                               ; preds = %29
  call void @llvm.lifetime.end.p0(i64 4, ptr %6) #5
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #5
  br label %47

45:                                               ; preds = %14
  %46 = load i32, ptr %5, align 4, !tbaa !5
  call void @llvm.lifetime.end.p0(i64 4, ptr %5) #5
  ret i32 %46

47:                                               ; preds = %44
  %48 = load ptr, ptr %7, align 8
  %49 = load i32, ptr %8, align 4
  %50 = insertvalue { ptr, i32 } poison, ptr %48, 0
  %51 = insertvalue { ptr, i32 } %50, i32 %49, 1
  resume { ptr, i32 } %51
}

declare ptr @__cxa_allocate_exception(i64)

declare void @__cxa_throw(ptr, ptr, ptr)

declare void @__cxa_rethrow()

; Function Attrs: noinline noreturn nounwind uwtable
define linkonce_odr hidden void @__clang_call_terminate(ptr noundef %0) #4 comdat {
  %2 = call ptr @__cxa_begin_catch(ptr %0) #5
  call void @_ZSt9terminatev() #7
  unreachable
}

declare void @_ZSt9terminatev()

attributes #0 = { mustprogress uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind memory(none) }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { mustprogress nounwind uwtable "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { noinline noreturn nounwind uwtable "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }
attributes #6 = { noreturn }
attributes #7 = { noreturn nounwind }

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
!8 = !{!"Simple C++ TBAA"}
!9 = !{!10, !10, i64 0}
!10 = !{!"p1 _ZTS7Tracker", !11, i64 0}
!11 = !{!"any pointer", !7, i64 0}
!12 = !{!13, !13, i64 0}
!13 = !{!"p1 int", !11, i64 0}
!14 = distinct !{!14, !15, !16}
!15 = !{!"llvm.loop.mustprogress"}
!16 = !{!"llvm.loop.unroll.disable"}
