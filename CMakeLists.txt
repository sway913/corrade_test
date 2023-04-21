cmake_minimum_required(VERSION 3.13)

#
# Project setup
#
project(corrade_test
  VERSION 1.0.0
  LANGUAGES CXX)

list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/CMakeModules")

# Use folders for nice tree in Visual Studio and XCode
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

#
# Build options
#
include(StandardSettings)

#
# Compiler setup
#
include(SetupCompileFlags)

# set flags for all targets
setup_compile_flags()

message(STATUS "Compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "Compiler flags: '${${PROJECT_NAME}_COMPILE_FLAGS}'")
message(STATUS "Linker flags: '${${PROJECT_NAME}_LINK_FLAGS}'")
message(STATUS "Preprocesor defines: '${${PROJECT_NAME}_DEFINES}'")
message(STATUS "Clang-tidy property: '${${PROJECT_NAME}_OPT_CLANG_TIDY_PROPERTIES}'")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")


#
# Targets
#

# Add Corrade as a subproject
add_subdirectory(third_party)

# LIBQVE library
add_subdirectory(src)

