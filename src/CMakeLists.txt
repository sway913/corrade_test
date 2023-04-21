cmake_minimum_required(VERSION 3.4)
project(src_test)

set(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/../CMakeModules/" ${CMAKE_MODULE_PATH})

# Add Corrade as a subproject
add_subdirectory(pluginmanager_test)
