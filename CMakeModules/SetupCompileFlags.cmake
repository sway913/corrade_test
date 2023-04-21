function(SETUP_COMPILE_FLAGS)
  set(DEFINES "")

  # Option-independent platform discovery
  if(CMAKE_SYSTEM_NAME STREQUAL Emscripten)
    set(${PROJECT_NAME}_TARGET_EMSCRIPTEN 1)

    # It's meaningless to use dynamic libraries with Emscripten
    set(${PROJECT_NAME}_BUILD_STATIC ON)

    # Emscripten doesn't support threads
    set(${PROJECT_NAME}_BUILD_TESTS OFF)
    set(${PROJECT_NAME}_BUILD_EXAMPLES OFF)
    set(${PROJECT_NAME}_BUILD_DOCS OFF)
    message(STATUS "config TARGET_EMSCRIPTEN")
  elseif(UNIX)
    # Both APPLE and UNIX are defined on OSX
    if(APPLE)
      set(${PROJECT_NAME}_TARGET_APPLE 1)

      if(CMAKE_OSX_SYSROOT MATCHES "/iPhoneOS[0-9.]*\\.sdk")
        set(${PROJECT_NAME}_TARGET_IOS 1)
        message(STATUS "config TARGET_IOS")
      elseif(CMAKE_OSX_SYSROOT MATCHES "/iPhoneSimulator[0-9.]*\\.sdk")
        set(${PROJECT_NAME}_TARGET_IOS 1)
        message(STATUS "config TARGET_IOS")
      else()
        message(STATUS "config TARGET_APPLE")
      endif()
    endif()

    # UNIX is also defined on Android
    if(CMAKE_SYSTEM_NAME STREQUAL Android)
      set(${PROJECT_NAME}_TARGET_ANDROID 1)

      # It's too inconvenient to manually load all shared libs using JNI
      set(${PROJECT_NAME}_BUILD_STATIC ON)
      message(STATUS "config TARGET_ANDROID")
    endif()
  elseif(WIN32)
    set(${PROJECT_NAME}_TARGET_WINDOWS 1)
    message(STATUS "config TARGET_WINDOWS")
  endif()

  if(${PROJECT_NAME}_TARGET_WINDOWS STREQUAL 1)
    set(ENV{PKG_CONFIG_PATH} ${PROJECT_SOURCE_DIR}/third_party/prebuild/win/lib/pkgconfig:${CMAKE_INSTALL_PREFIX}:$ENV{PKG_CONFIG_PATH})
  endif()

  if(${PROJECT_NAME}_TARGET_EMSCRIPTEN)
    set(ENV{PKG_CONFIG_PATH} ${PROJECT_SOURCE_DIR}/third_party/prebuild/wasm/lib/pkgconfig:${CMAKE_INSTALL_PREFIX}:$ENV{PKG_CONFIG_PATH})
  endif()

  if(${PROJECT_NAME}_TARGET_ANDROID)
    set(ENV{PKG_CONFIG_PATH} ${PROJECT_SOURCE_DIR}/third_party/prebuild/android/lib/pkgconfig:${CMAKE_INSTALL_PREFIX}:$ENV{PKG_CONFIG_PATH})
  endif()

  # Check compiler version
  if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    # Don't allow to use compilers older than what compatibility mode allows
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "4.8.1")
      message(FATAL_ERROR "Corrade cannot be used with GCC < 4.8.1. Sorry.")
    endif()
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    # Don't allow to use compilers older than what compatibility mode allows
    if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "19.0")
      message(FATAL_ERROR "Corrade cannot be used with MSVC < 2015. Sorry.")
    elseif(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "19.10")
      if(NOT CORRADE_MSVC2015_COMPATIBILITY)
        message(FATAL_ERROR "To use Corrade with MSVC 2015, build it with CORRADE_MSVC2015_COMPATIBILITY enabled")
      endif()
    elseif(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "19.20")
      if(NOT CORRADE_MSVC2017_COMPATIBILITY)
        message(FATAL_ERROR "To use Corrade with MSVC 2017, build it with CORRADE_MSVC2017_COMPATIBILITY enabled")
      endif()
    endif()

    # Don't allow to use compiler newer than what compatibility mode allows
    if(NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS "19.10")
      if(CORRADE_MSVC2015_COMPATIBILITY)
        message(FATAL_ERROR "MSVC >= 2017 cannot be used if Corrade is built with CORRADE_MSVC2015_COMPATIBILITY")
      endif()
    elseif(NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS "19.20")
      if(CORRADE_MSVC2017_COMPATIBILITY)
        message(FATAL_ERROR "MSVC >= 2019 cannot be used if Corrade is built with CORRADE_MSVC2017_COMPATIBILITY")
      endif()
    endif()
  endif()

  if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU" OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    # -Wold-style-cast
    set(WARNINGS "-Wall;-Wextra;-Werror;-Wunreachable-code")

    if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
      set(WARNINGS "${WARNINGS};-Wpedantic;-Wshadow;-Wno-gnu-zero-variadic-macro-arguments")
    else()
      set(WARNINGS "${WARNINGS};-Wshadow=local")

      # GCC 7.x and older doesn't handle variadic macros that well, so enable
      # pedanting warnings only on newer versions to avoid the:
      # > ISO C++11 requires at least one argument for the "..." in a variadic
      # > macro
      # error
      if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 8.0)
        set(WARNINGS "${WARNINGS};-Wpedantic")
      endif()
    endif()
  elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
    set(WARNINGS "/W4;/WX;/EHsc;/permissive-")
  endif()

  if(${PROJECT_NAME}_BUILD_TESTS AND ${PROJECT_NAME}_CODE_COVERAGE)
    if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
      set(COVERAGE_COMPILE_FLAGS ";-g;-fno-inline;-fno-elide-constructors;-fno-inline-small-functions;-fno-default-inline;-fprofile-arcs;-ftest-coverage")
      set(COVERAGE_LINK_FLAGS "-lgcov")
    elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
      set(COVERAGE_COMPILE_FLAGS ";-fprofile-instr-generate;-fcoverage-mapping")
      set(COVERAGE_LINK_FLAGS "-fprofile-instr-generate;-fcoverage-mapping")
    else()
      message(FATAL_ERROR "Code coverage supported only with GCC and Clang compilers")
    endif()
  endif()

  if(${PROJECT_NAME}_CLANG_TIDY AND "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
    set(CLANG_TIDY_PROPERTIES "CXX_CLANG_TIDY;clang-tidy-10")
  endif()

  if(NOT CONFIGURED_ONCE)
    set(
      ${PROJECT_NAME}_COMPILE_FLAGS
      "${WARNINGS}${COVERAGE_COMPILE_FLAGS}"
      CACHE STRING "Flags used by the compiler to build targets"
      FORCE)
    set(
      ${PROJECT_NAME}_LINK_FLAGS
      "${COVERAGE_LINK_FLAGS}"
      CACHE STRING "Flags used by the linker to link targets"
      FORCE)
    set(
      ${PROJECT_NAME}_DEFINES
      "${DEFINES}"
      CACHE STRING "Preprocessor defines"
      FORCE
    )
    set(
      ${PROJECT_NAME}_OPT_CLANG_TIDY_PROPERTIES
      "${CLANG_TIDY_PROPERTIES}"
      CACHE STRING "Properties used to enable clang-tidy when building targets"
      FORCE)
  endif()

  # # GCC/Clang-specific compiler flags
  # if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR(CMAKE_CXX_COMPILER_ID MATCHES "(Apple)?Clang" AND NOT CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC") OR CORRADE_TARGET_EMSCRIPTEN)
  # set(${PROJECT_NAME}_COMPILER_FLAGS
  # "-Wall" "-Wextra"
  # "$<$<STREQUAL:$<TARGET_PROPERTY:LINKER_LANGUAGE>,CXX>:-Wold-style-cast>"
  # "-Winit-self"
  # "-Werror=return-type"
  # "-Wmissing-declarations"

  # # -Wpedantic is since 4.8, until then only -pedantic (which doesn't
  # # have any -Wno-pedantic or a way to disable it for a particular line)
  # "-Wpedantic"

  # # Needs to have both, otherwise Clang's linker on macOS complains that
  # # "direct access in function [...] to global weak symbol [...] means the
  # # weak symbol cannot be overridden at runtime. This was likely caused
  # # by different translation units being compiled with different
  # # visibility settings." See also various google results for the above
  # # message.
  # "-fvisibility=hidden" "-fvisibility-inlines-hidden"

  # # A lot of functionality relies on aliased pointers, such as the whole
  # # StridedArrayView. Given numerous other libraries including stb_image
  # # *and the Linux kernel itself* disable this as well, I see no reason
  # # for needless suffering either. I don't remember strict aliasing to
  # # ever help with optimizing anything, plus it was disabled for the
  # # whole of Magnum since December 2013 already:
  # # https://github.com/mosra/magnum/commit/f373b6518e0b1fa3e4d0ffb19f77e80a8a56484c
  # # So let's just make it official and disable it for everything,
  # # everywhere, forever.
  # "-fno-strict-aliasing")

  # # Some flags are not yet supported everywhere
  # # TODO: do this with check_c_compiler_flags()
  # if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
  # list(APPEND ${PROJECT_NAME}_COMPILER_FLAGS
  # "$<$<STREQUAL:$<TARGET_PROPERTY:LINKER_LANGUAGE>,CXX>:-Wzero-as-null-pointer-constant>"

  # # TODO: enable when this gets to Clang (not in 3.9, but in master
  # # since https://github.com/llvm-mirror/clang/commit/0a022661c797356e9c28e4999b6ec3881361371e)
  # "-Wdouble-promotion")

  # # GCC 4.8 doesn't like when structs are initialized using just {} and
  # # because we use that a lot, the output gets extremely noisy. Disable
  # # the warning altogether there.
  # if(CMAKE_CXX_COMPILER_VERSION VERSION_LESS "5.0")
  # list(APPEND ${PROJECT_NAME}_COMPILER_FLAGS "-Wno-missing-field-initializers")
  # endif()
  # endif()

  # if(CMAKE_CXX_COMPILER_ID MATCHES "(Apple)?Clang" OR CORRADE_TARGET_EMSCRIPTEN)
  # list(APPEND ${PROJECT_NAME}_COMPILER_FLAGS

  # # Clang's -Wmissing-declarations does something else and the
  # # behavior we want is under -Wmissing-prototypes. See
  # # https://llvm.org/bugs/show_bug.cgi?id=16286.
  # "-Wmissing-prototypes"

  # # Fixing it in all places would add too much noise to the code.
  # "-Wno-shorten-64-to-32")

  # list(APPEND CORRADE_PEDANTIC_TEST_COMPILER_OPTIONS

  # # Unlike GCC, -Wunused-function (which is enabled through -Wall)
  # # doesn't fire for member functions, it's controlled separately
  # "-Wunused-member-function"

  # # This is implicitly enabled by the above and causes lots of
  # # warnings for e.g. move constructors, so disabling
  # "-Wno-unneeded-member-function")
  # endif()

  # # MSVC-specific compiler flags
  # elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" OR CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC")
  # set(${PROJECT_NAME}_COMPILER_FLAGS

  # # Enable extra warnings (similar to -Wall)
  # "/W4"

  # # "conditional expression is constant", especially when a template
  # # argument is passed to an if, which happens mainly in tests but
  # # sometimes also in recursive constexpr functions. As I can't use if
  # # constexpr in C++11 code, there's not really much I can do.
  # "/wd4127"

  # # "needs to have dll-interface to be used by clients", as the fix for
  # # that would effectively prevent using STL completely.
  # "/wd4251"

  # # "conversion from '<bigger int type>' to '<smaller int type>'",
  # # "conversion from 'size_t' to '<smaller int type>', possible loss of
  # # data", fixing this would add too much noise. Equivalent to
  # # -Wshorten-64-to-32 on Clang.
  # "/wd4244"
  # "/wd4267"

  # # "structure was padded due to alignment specifier". YES. THAT'S
  # # EXACTLY AS INTENDED.
  # "/wd4324"

  # # "new behavior: elements of array will be default initialized".
  # # YES. YES I KNOW WHAT I'M DOING.
  # "/wd4351"

  # # "previous versions of the compiler did not override when parameters
  # # only differed by const/volatile qualifiers". Okay. So you had bugs.
  # # And?
  # "/wd4373"

  # # "declaration of 'foo' hides class member". I use this a lot in
  # # constructor arguments, `Class(int foo): foo{foo} {}` and adding some
  # # underscores to mitigate this would not be pretty. OTOH, "C4456:
  # # declaration of 'foo' hides previous local declaration" points to a
  # # valid issue that I should get rid of.
  # "/wd4458"

  # # "default constructor could not be generated/can never be
  # # instantiated". Apparently it can.
  # "/wd4510"
  # "/wd4610"

  # # "assignment operator could not be generated". Do I want one? NO I
  # # DON'T.
  # "/wd4512"

  # # "no suitable definition for explicit template instantiation". No. The
  # # problem is apparently that I'm having the definitions in *.cpp file
  # # and instantiating them explicitly. Common practice here.
  # "/wd4661"

  # # "unreachable code". *Every* assertion has return after std::abort().
  # # So?
  # "/wd4702"

  # # "assignment within conditional expression". It's not my problem that
  # # it doesn't get the hint with extra parentheses (`if((a = b))`).
  # "/wd4706"

  # # "forcing value to bool 'true' or 'false' (performance warning)". So
  # # what. I won't wrap everything in bool(). This is a _language feature_,
  # # dammit.
  # "/wd4800"

  # # "dllexport and extern are incompatible on an explicit instantiation".
  # # Why the error is emitted only on classes? Functions are okay with
  # # dllexport extern?!
  # "/wd4910")
  # set(${PROJECT_NAME}_COMPILER_DEFINITIONS

  # # Disabling warning for not using "secure-but-not-standard" STL algos
  # "_CRT_SECURE_NO_WARNINGS" "_SCL_SECURE_NO_WARNINGS")
  # endif()
endfunction()