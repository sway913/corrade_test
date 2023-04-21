cmake_minimum_required(VERSION 3.4)
project(third_party)

set(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/../CMakeModules/" ${CMAKE_MODULE_PATH})

set(CMAKE_FOLDER_PREFIX "third_party/")
# Add Corrade as a subproject
add_subdirectory(corrade)
