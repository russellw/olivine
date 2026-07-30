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

; Function Attrs: mustprogress noinline optnone uwtable
define dso_local i32 @caught_value(i32 noundef %0) #0 personality ptr @__gxx_personality_v0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  %7 = load i32, ptr %3, align 4
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
  %19 = load ptr, ptr %4, align 8
  %20 = call ptr @__cxa_begin_catch(ptr %19) #5
  %21 = load i32, ptr %20, align 4
  store i32 %21, ptr %6, align 4
  %22 = load i32, ptr %6, align 4
  %23 = sub nsw i32 %22, 1
  store i32 %23, ptr %2, align 4
  call void @__cxa_end_catch() #5
  br label %25

24:                                               ; No predecessors!
  call void @llvm.trap()
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

; Function Attrs: mustprogress noinline optnone uwtable
define internal noundef i32 @_ZL9may_throwi(i32 noundef %0) #0 {
  %2 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  %3 = load i32, ptr %2, align 4
  %4 = icmp slt i32 %3, 0
  br i1 %4, label %5, label %8

5:                                                ; preds = %1
  %6 = call ptr @__cxa_allocate_exception(i64 4) #5
  %7 = load i32, ptr %2, align 4
  store i32 %7, ptr %6, align 16
  call void @__cxa_throw(ptr %6, ptr @_ZTIi, ptr null) #6
  unreachable

8:                                                ; preds = %1
  %9 = load i32, ptr %2, align 4
  %10 = mul nsw i32 %9, 2
  ret i32 %10
}

declare i32 @__gxx_personality_v0(...)

; Function Attrs: nounwind memory(none)
declare i32 @llvm.eh.typeid.for.p0(ptr) #1

declare ptr @__cxa_begin_catch(ptr)

declare void @__cxa_end_catch()

; Function Attrs: cold noreturn nounwind memory(inaccessiblemem: write)
declare void @llvm.trap() #2

; Function Attrs: mustprogress noinline optnone uwtable
define dso_local i32 @caught_anything(i32 noundef %0) #0 personality ptr @__gxx_personality_v0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  %6 = load i32, ptr %3, align 4
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
  call void @llvm.trap()
  unreachable

17:                                               ; preds = %13, %8
  %18 = load i32, ptr %2, align 4
  ret i32 %18
}

; Function Attrs: mustprogress noinline optnone uwtable
define dso_local i32 @cleanup_on_both(i32 noundef %0) #0 personality ptr @__gxx_personality_v0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca %struct.Tracker, align 1
  %5 = alloca ptr, align 8
  %6 = alloca i32, align 4
  %7 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  invoke void @_ZN7TrackerC2Ev(ptr noundef nonnull align 1 dereferenceable(1) %4)
          to label %8 unwind label %12

8:                                                ; preds = %1
  %9 = load i32, ptr %3, align 4
  %10 = invoke noundef i32 @_ZL9may_throwi(i32 noundef %9)
          to label %11 unwind label %16

11:                                               ; preds = %8
  store i32 %10, ptr %2, align 4
  call void @_ZN7TrackerD2Ev(ptr noundef nonnull align 1 dereferenceable(1) %4) #5
  br label %30

12:                                               ; preds = %1
  %13 = landingpad { ptr, i32 }
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
  %21 = load i32, ptr %6, align 4
  %22 = call i32 @llvm.eh.typeid.for.p0(ptr @_ZTIi) #5
  %23 = icmp eq i32 %21, %22
  br i1 %23, label %24, label %32

24:                                               ; preds = %20
  %25 = load ptr, ptr %5, align 8
  %26 = call ptr @__cxa_begin_catch(ptr %25) #5
  %27 = load i32, ptr %26, align 4
  store i32 %27, ptr %7, align 4
  %28 = load i32, ptr %7, align 4
  store i32 %28, ptr %2, align 4
  call void @__cxa_end_catch() #5
  br label %30

29:                                               ; No predecessors!
  call void @llvm.trap()
  unreachable

30:                                               ; preds = %24, %11
  %31 = load i32, ptr %2, align 4
  ret i32 %31

32:                                               ; preds = %20
  %33 = load ptr, ptr %5, align 8
  %34 = load i32, ptr %6, align 4
  %35 = insertvalue { ptr, i32 } poison, ptr %33, 0
  %36 = insertvalue { ptr, i32 } %35, i32 %34, 1
  resume { ptr, i32 } %36
}

; Function Attrs: mustprogress noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN7TrackerC2Ev(ptr noundef nonnull align 1 dereferenceable(1) %0) unnamed_addr #3 comdat align 2 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  ret void
}

; Function Attrs: mustprogress noinline nounwind optnone uwtable
define linkonce_odr dso_local void @_ZN7TrackerD2Ev(ptr noundef nonnull align 1 dereferenceable(1) %0) unnamed_addr #3 comdat align 2 {
  %2 = alloca ptr, align 8
  store ptr %0, ptr %2, align 8
  %3 = load ptr, ptr %2, align 8
  %4 = load i32, ptr @cleanups_run, align 4
  %5 = add nsw i32 %4, 1
  store i32 %5, ptr @cleanups_run, align 4
  ret void
}

; Function Attrs: mustprogress noinline optnone uwtable
define dso_local i32 @passed_on(i32 noundef %0) #0 personality ptr @__gxx_personality_v0 {
  %2 = alloca i32, align 4
  %3 = alloca i32, align 4
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  store i32 %0, ptr %3, align 4
  %7 = load i32, ptr %3, align 4
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
  %19 = load ptr, ptr %4, align 8
  %20 = call ptr @__cxa_begin_catch(ptr %19) #5
  %21 = load i32, ptr %20, align 4
  store i32 %21, ptr %6, align 4
  %22 = load i32, ptr %6, align 4
  %23 = mul nsw i32 %22, 3
  store i32 %23, ptr %2, align 4
  call void @__cxa_end_catch() #5
  br label %25

24:                                               ; No predecessors!
  call void @llvm.trap()
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

; Function Attrs: mustprogress noinline optnone uwtable
define internal noundef i32 @_ZL10rethrowingi(i32 noundef %0) #0 personality ptr @__gxx_personality_v0 {
  %2 = alloca i32, align 4
  %3 = alloca %struct.Tracker, align 1
  %4 = alloca ptr, align 8
  %5 = alloca i32, align 4
  store i32 %0, ptr %2, align 4
  invoke void @_ZN7TrackerC2Ev(ptr noundef nonnull align 1 dereferenceable(1) %3)
          to label %6 unwind label %10

6:                                                ; preds = %1
  %7 = load i32, ptr %2, align 4
  %8 = invoke noundef i32 @_ZL9may_throwi(i32 noundef %7)
          to label %9 unwind label %14

9:                                                ; preds = %6
  call void @_ZN7TrackerD2Ev(ptr noundef nonnull align 1 dereferenceable(1) %3) #5
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
  %19 = load ptr, ptr %4, align 8
  %20 = call ptr @__cxa_begin_catch(ptr %19) #5
  invoke void @__cxa_rethrow() #6
          to label %35 unwind label %21

21:                                               ; preds = %18
  %22 = landingpad { ptr, i32 }
          cleanup
  %23 = extractvalue { ptr, i32 } %22, 0
  store ptr %23, ptr %4, align 8
  %24 = extractvalue { ptr, i32 } %22, 1
  store i32 %24, ptr %5, align 4
  invoke void @__cxa_end_catch()
          to label %25 unwind label %32

25:                                               ; preds = %21
  br label %27

26:                                               ; No predecessors!
  call void @llvm.trap()
  unreachable

27:                                               ; preds = %25
  %28 = load ptr, ptr %4, align 8
  %29 = load i32, ptr %5, align 4
  %30 = insertvalue { ptr, i32 } poison, ptr %28, 0
  %31 = insertvalue { ptr, i32 } %30, i32 %29, 1
  resume { ptr, i32 } %31

32:                                               ; preds = %21
  %33 = landingpad { ptr, i32 }
          catch ptr null
  %34 = extractvalue { ptr, i32 } %33, 0
  call void @__clang_call_terminate(ptr %34) #7
  unreachable

35:                                               ; preds = %18
  unreachable
}

; Function Attrs: mustprogress noinline optnone uwtable
define dso_local i32 @summed(ptr noundef %0, i32 noundef %1) #0 personality ptr @__gxx_personality_v0 {
  %3 = alloca ptr, align 8
  %4 = alloca i32, align 4
  %5 = alloca i32, align 4
  %6 = alloca i32, align 4
  %7 = alloca ptr, align 8
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  store ptr %0, ptr %3, align 8
  store i32 %1, ptr %4, align 4
  store i32 0, ptr %5, align 4
  store i32 0, ptr %6, align 4
  br label %10

10:                                               ; preds = %40, %2
  %11 = load i32, ptr %6, align 4
  %12 = load i32, ptr %4, align 4
  %13 = icmp slt i32 %11, %12
  br i1 %13, label %14, label %43

14:                                               ; preds = %10
  %15 = load ptr, ptr %3, align 8
  %16 = load i32, ptr %6, align 4
  %17 = sext i32 %16 to i64
  %18 = getelementptr inbounds i32, ptr %15, i64 %17
  %19 = load i32, ptr %18, align 4
  %20 = invoke noundef i32 @_ZL9may_throwi(i32 noundef %19)
          to label %21 unwind label %24

21:                                               ; preds = %14
  %22 = load i32, ptr %5, align 4
  %23 = add nsw i32 %22, %20
  store i32 %23, ptr %5, align 4
  br label %39

24:                                               ; preds = %14
  %25 = landingpad { ptr, i32 }
          catch ptr @_ZTIi
  %26 = extractvalue { ptr, i32 } %25, 0
  store ptr %26, ptr %7, align 8
  %27 = extractvalue { ptr, i32 } %25, 1
  store i32 %27, ptr %8, align 4
  br label %28

28:                                               ; preds = %24
  %29 = load i32, ptr %8, align 4
  %30 = call i32 @llvm.eh.typeid.for.p0(ptr @_ZTIi) #5
  %31 = icmp eq i32 %29, %30
  br i1 %31, label %32, label %45

32:                                               ; preds = %28
  %33 = load ptr, ptr %7, align 8
  %34 = call ptr @__cxa_begin_catch(ptr %33) #5
  %35 = load i32, ptr %34, align 4
  store i32 %35, ptr %9, align 4
  %36 = load i32, ptr %9, align 4
  %37 = load i32, ptr %5, align 4
  %38 = sub nsw i32 %37, %36
  store i32 %38, ptr %5, align 4
  call void @__cxa_end_catch() #5
  br label %39

39:                                               ; preds = %32, %21
  br label %40

40:                                               ; preds = %39
  %41 = load i32, ptr %6, align 4
  %42 = add nsw i32 %41, 1
  store i32 %42, ptr %6, align 4
  br label %10, !llvm.loop !6

43:                                               ; preds = %10
  %44 = load i32, ptr %5, align 4
  ret i32 %44

45:                                               ; preds = %28
  %46 = load ptr, ptr %7, align 8
  %47 = load i32, ptr %8, align 4
  %48 = insertvalue { ptr, i32 } poison, ptr %46, 0
  %49 = insertvalue { ptr, i32 } %48, i32 %47, 1
  resume { ptr, i32 } %49
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

attributes #0 = { mustprogress noinline optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { nounwind memory(none) }
attributes #2 = { cold noreturn nounwind memory(inaccessiblemem: write) }
attributes #3 = { mustprogress noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { noinline noreturn nounwind uwtable "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cmov,+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind }
attributes #6 = { noreturn }
attributes #7 = { noreturn nounwind }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 2}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Ubuntu clang version 21.1.8 (6ubuntu1)"}
!6 = distinct !{!6, !7}
!7 = !{!"llvm.loop.mustprogress"}
