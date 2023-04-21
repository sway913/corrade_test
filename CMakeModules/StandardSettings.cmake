#
# Project settings
#
option(${PROJECT_NAME}_BUILD_EXECUTABLE "Build the project as an executable, rather than a library." OFF)
option(${PROJECT_NAME}_USE_ALT_NAMES "Use alternative names for the project, such as naming the include directory all lowercase." ON)
option(${PROJECT_NAME}_USE_BUILD_THIRD_LIBS "Use cmake build third_party library, not use prebuild libs." OFF)
option(${PROJECT_NAME}_BUILD_STATIC "Build static libraries (default are shared)" OFF)

#
# set build module options
#
option(${PROJECT_NAME}_ENABLE_BUILD_MOD_MEDIA "Enable Build media sub module." ON)
option(${PROJECT_NAME}_ENABLE_BUILD_MOD_READER "Enable Build reader module." ON)

if(CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME)
  option(${PROJECT_NAME}_BUILD_EXAMPLES "Build examples." ON)
  option(${PROJECT_NAME}_BUILD_TESTS "Build unit tests." ON)
  option(${PROJECT_NAME}_CODE_COVERAGE "Compute code coverage." OFF)
  option(${PROJECT_NAME}_BUILD_PERFORMANCE_TESTS "Build performance tests." ON)
  option(${PROJECT_NAME}_BUILD_DOCS "Build documentation." OFF)
  option(${PROJECT_NAME}_CLANG_TIDY "Build with clang-tidy" ON)
  option(${PROJECT_NAME}_BUILD_TESTS_LIBBASE "Build libbase tests." OFF)
else()
  option(${PROJECT_NAME}_BUILD_EXAMPLES "Build examples." OFF)
  option(${PROJECT_NAME}_BUILD_TESTS "Build unit tests." OFF)
  option(${PROJECT_NAME}_CODE_COVERAGE "Compute code coverage." OFF)
  option(${PROJECT_NAME}_BUILD_PERFORMANCE_TESTS "Build performance tests." OFF)
  option(${PROJECT_NAME}_BUILD_DOCS "Build documentation." OFF)
  option(${PROJECT_NAME}_CLANG_TIDY "Build with clang-tidy" OFF)
  option(${PROJECT_NAME}_BUILD_TESTS_LIBBASE "Build libbase tests." OFF)
endif()

# Export all symbols when building a shared library
if(BUILD_SHARED_LIBS)
  set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS OFF)
  set(CMAKE_CXX_VISIBILITY_PRESET hidden)
  set(CMAKE_VISIBILITY_INLINES_HIDDEN 1)
endif()

option(${PROJECT_NAME}_ENABLE_CCACHE "Enable the usage of Ccache, in order to speed up rebuild times." ON)
find_program(CCACHE_FOUND ccache)

if(CCACHE_FOUND)
  set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
  set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache)
endif()
