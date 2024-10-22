cmake_minimum_required(VERSION 3.15)

project(HelloQt VERSION 1.0.0 LANGUAGES CXX)

option(USE_QT6 "use qt6 instead of qt5" OFF)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# ---
#  find either Qt5 or Qt6
# ---

if (USE_QT6)
  set(_qt_package_name "Qt6")
else()
  set(_qt_package_name "Qt5")
endif()

find_package(${_qt_package_name}
  REQUIRED
  COMPONENTS Core
  HINTS "$ENV{QTDIR}" "$ENV{QT}"
)
message(STATUS "Found ${_qt_package_name}")

# ---
#  declare main target
# ---

add_executable(${PROJECT_NAME} main.cpp)

target_link_libraries(${PROJECT_NAME} PRIVATE ${_qt_package_name}::Core)

# ---
#  include & call the WinDeployQt module
# ---

include(${PROJECT_SOURCE_DIR}/../WinDeployQt.cmake)

# basic versionless invokation (should work for both Qt5 and Qt6)
windeployqt(
  TARGET ${PROJECT_NAME} # <-- deploy dependencies for this target
  DIRECTORY bin          # <-- install qt .dlls into a 'bin' subdirectory
  ARGS
    "--no-translations"  # <-- pass these args directly to windeployqt.exe
)

# ---
#  setup install rules
# ---

install(
  TARGETS ${PROJECT_NAME}
  DESTINATION bin
)
