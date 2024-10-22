#[=============================================================================[
MIT License

Copyright (c) 2024 Stephen Karavos

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#]=============================================================================]
#
# Source:
#   <https://github.com/skaravos/CMakeWinDeployQt>
#
# Acknowlegements:
#   Original idea and concept was taken from nitroshare-desktop's DeployQt.cmake
#   <https://github.com/nitroshare/nitroshare-desktop/blob/f4feebef29d9d3985d1699ab36f0fac59d3df7da/cmake/DeployQt.cmake>
#
cmake_minimum_required(VERSION 3.15)

#[==[

  Sets up commands to automatically call the 'windeployqt.exe' deployment tool.

  This will automatically bundle the Qt runtime dlls into to the target's output
  directory after compilation. It will also automatically bundle the Qt dlls
  into the given directory during the install step.

  This function uses cmake's own functionality for 'installing' the runtime
  files so it should work properly with CPack.

  NOTE: This function only works with windeployqt.exe from Qt5
        For a function that works with Qt6 see: windeployqt6()

  NOTE: On non-windows platforms, this function does nothing

  NOTE: If the provided target is not directly linked to any shared Qt libraries
        this function will fail during build-time with the error:
          "<target> does not seem to be a Qt executable"
        This can happen if you link against static Qt libraries.
        To guard against potential problems, you can wrap the call like so:
          get_target_property(_qt5_type Qt5::Core TYPE)
          if (${_qt5_type} MATCHES "SHARED")
            windeployqt5(TARGET ${PROJECT_NAME})
          endif()

  function signature:

      windeployqt5(TARGET target
        [DIRECTORY directory]
        [COMPONENT component]
        [VERBOSE]
        [ARGS args...]
      )

  required parameters:

    TARGET target
      - Name of a valid existing cmake target, the path to this compiled target
        is passed to windeployqt.exe to compute the Qt5 dependencies.

  optional parameters:

    DIRECTORY directory
      - A custom path to install the dependencies.
      - Must be a relative path (treated as relative to CMAKE_INSTALL_PREFIX)
      - [default: .]

    COMPONENT component
      - Forwarded verbatim to the install rule of the computed dependencies
      - [default: Unspecified]

    VERBOSE
      - If provided, windeployqt6.exe will be run in verbose mode (--verbose 1)

    ARGS args...
      - A list of additional args passed directly to windeployqt.exe

#]==]
function(windeployqt5)
  if (NOT WIN32)
    return()
  endif()

  # --------------------------
  #  locate windeployqt (Qt5)
  # --------------------------

  set(_qt_bin_dir)
  if (TARGET Qt5::qmake)
    get_target_property(_qmake_executable Qt5::qmake IMPORTED_LOCATION)
    get_filename_component(_qt_bin_dir "${_qmake_executable}" DIRECTORY)
  endif()
  find_program(WINDEPLOYQT5_EXE windeployqt HINTS "${_qt_bin_dir}")
  mark_as_advanced(WINDEPLOYQT5_EXE)

  if(NOT WINDEPLOYQT5_EXE)
    message(FATAL_ERROR "windeployqt.exe (Qt5) not found")
  endif()

  # --------------------------
  #  parse arguments
  # --------------------------

  set(_options  VERBOSE)
  set(_args     TARGET DIRECTORY COMPONENT)
  set(_listargs TRANSLATIONS ARGS)
  cmake_parse_arguments(PARSE_ARGV 0 arg "${_options}" "${_args}" "${_listargs}")

  message(STATUS "windeployqt5('${arg_TARGET}')")

  foreach(_arg IN LISTS arg_UNPARSED_ARGUMENTS)
    message(WARNING "Unparsed argument: ${_arg}")
  endforeach()

  # --------------------------
  #  call implementation func
  # --------------------------

  __windeployqt_impl(
    WINDEPLOYQT_EXECUTABLE
      ${WINDEPLOYQT5_EXE}
    QT_BIN_DIR
      ${_qt_bin_dir}
    TARGET
      ${arg_TARGET}
    DIRECTORY
      ${arg_DIRECTORY}
    COMPONENT
      ${arg_COMPONENT}
    VERBOSE
      ${arg_VERBOSE}
    ARGS
      ${arg_ARGS}
  )
  message(STATUS "windeployqt5('${arg_TARGET}') - success")
endfunction()



#[==[
  Sets up commands to automatically call the 'windeployqt6.exe' deployment tool.

  This will automatically bundle the Qt runtime dlls into to the target's output
  directory after compilation. It will also automatically bundle the Qt dlls
  into the given directory during the install step.

  This function uses cmake's own functionality for 'installing' the runtime
  files so it should work properly with CPack.

  NOTE: This function only works with windeployqt6.exe included with Qt6
        For a function that works with Qt5 see: windeployqt5()

  NOTE: On non-windows platforms, this function does nothing

  NOTE: If the provided target is not directly linked to any shared Qt libraries
        this function will fail during build-time with the error:
          "<target> does not seem to be a Qt executable"
        This can happen if you link against static Qt libraries.
        To guard against potential problems, you can wrap the call like so:
          get_target_property(_qt6_type Qt6::Core TYPE)
          if (${_qt6_type} MATCHES "SHARED")
            windeployqt6(TARGET ${PROJECT_NAME})
          endif()

  function signature:

      windeployqt6(TARGET target
        [DIRECTORY directory]
        [COMPONENT component]
        [VERBOSE]
        [ARGS args...]
      )

  required parameters:

    TARGET target
      - Name of a valid existing cmake target, the path to this compiled target
        is passed to windeployqt6.exe to compute the Qt6 dependencies.

  optional parameters:

    DIRECTORY directory
      - A custom path to install the dependencies.
      - Must be a relative path (treated as relative to CMAKE_INSTALL_PREFIX)
      - [default: .]

    COMPONENT component
      - Forwarded verbatim to the install rule of the computed dependencies
      - [default: Unspecified]

    VERBOSE
      - If provided, windeployqt6.exe will be run in verbose mode (--verbose 1)

    ARGS args...
      - A list of additional args passed directly to windeployqt6.exe
#]==]
function(windeployqt6)
  if (NOT WIN32)
    return()
  endif()

  # --------------------------
  #  locate windeployqt6
  # --------------------------

  set(_qt_bin_dir_hints)
  if (TARGET Qt6::qmake)
    get_target_property(_qmake_executable Qt6::qmake IMPORTED_LOCATION)
    get_filename_component(_qt_bin_dir "${_qmake_executable}" DIRECTORY)
    list(APPEND _qt_bin_dir_hints "${_qt_bin_dir}")
  endif()
  find_program(WINDEPLOYQT6_EXE NAMES windeployqt6 windeployqt HINTS "${_qt_bin_dir_hints}")
  mark_as_advanced(WINDEPLOYQT6_EXE)

  if(NOT WINDEPLOYQT6_EXE)
    message(FATAL_ERROR "windeployqt6.exe (Qt6) not found")
  endif()

  # --------------------------
  #  parse arguments
  # --------------------------

  set(_options  VERBOSE)
  set(_args     TARGET DIRECTORY COMPONENT)
  set(_listargs ARGS)
  cmake_parse_arguments(PARSE_ARGV 0 arg "${_options}" "${_args}" "${_listargs}")

  message(STATUS "windeployqt6('${arg_TARGET}')")

  foreach(_arg IN LISTS arg_UNPARSED_ARGUMENTS)
    message(WARNING "Unparsed argument: ${_arg}")
  endforeach()

  # --------------------------
  #  call implementation func
  # --------------------------

  __windeployqt_impl(
    WINDEPLOYQT_EXECUTABLE
      ${WINDEPLOYQT6_EXE}
    QT_BIN_DIR
      ${_qt_bin_dir}
    TARGET
      ${arg_TARGET}
    DIRECTORY
      ${arg_DIRECTORY}
    COMPONENT
      ${arg_COMPONENT}
    VERBOSE
      ${arg_VERBOSE}
    ARGS
      ${arg_ARGS}
  )
  message(STATUS "windeployqt6('${arg_TARGET}') - success")
endfunction()


#[==[
  Versionless wrapper for the windeployqt5() and windeployqt6() functions

  Detects the current version of windeployqt.exe using the --version param and
  then invokes the appropriate versioned function based on the result

  function signature:

      windeployqt(args...
        [WINDEPLOYQT5 args...]
        [WINDEPLOYQT6 args...]
      )

  All args provided to this function are forwarded verbatim to one of the
  abovementioned functions depending on the version of windeployqt.exe that is
  detected. See windeployqt() and/or windeployqt6() for supported arguments.

  NOTE: only supports windeployqt.exe version 5 and version 6

  optional parameters:

    WINDEPLOYQT5 args...
      - Arguments that should be only be forwarded to windeployqt5()

    WINDEPLOYQT6 args...
      - Arguments that should be only be forwarded to windeployqt6()

  example:

    windeployqt(TARGET MyTarget
      DIRECTORY .
      COMPONENT QtLibraries
      ARGS --no-translations
      WINDEPLOYQT5 ARGS --no-angle
      WINDEPLOYQT6 ARGS --skip-plugin-types "generic"
    )
#]==]
function(windeployqt)
  if (NOT WIN32)
    return()
  endif()

  # --------------------------
  #  locate copy of windeployqt.exe
  # --------------------------

  # Try to use any defined qmake target as a location hint
  set(_qt_bin_dir_hints)
  set(_qmake_tgts Qt::qmake Qt5::qmake Qt6::qmake)
  foreach(_tgt IN LISTS _qmake_tgts)
    if (TARGET ${_tgt})
      get_target_property(_qmake_executable ${_tgt} IMPORTED_LOCATION)
      get_filename_component(_qt_bin_dir "${_qmake_executable}" DIRECTORY)
      list(APPEND _qt_bin_dir_hints "${_qt_bin_dir}")
      break()
    endif()
  endforeach()

  find_program(WINDEPLOYQT_EXE windeployqt HINTS "${_qt_bin_dir_hints}")
  mark_as_advanced(WINDEPLOYQT_EXE)

  if(NOT WINDEPLOYQT_EXE)
    message(FATAL_ERROR "windeployqt.exe not found")
  endif()

  # --------------------------
  #  determine version of windeployqt
  # --------------------------

  execute_process(
    COMMAND "${WINDEPLOYQT_EXE}" --version
    OUTPUT_VARIABLE _windeploy_stdout
    ERROR_VARIABLE  _windeploy_stderr
    OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  if (_windeploy_stdout MATCHES [[Qt Deploy Tool ([0-9]+(\.[0-9]+(\.[0-9]+)?)?)]])
    set(_windeploy_version ${CMAKE_MATCH_1})
  elseif (_windeploy_stdout MATCHES [[^([0-9]+(\.[0-9]+(\.[0-9]+)?)?)$]])
    set(_windeploy_version ${CMAKE_MATCH_1})
  else()
    message(FATAL_ERROR "failed to extract the version of windeployqt.exe with --version")
  endif()

  # --------------------------
  #  parse arguments
  # --------------------------

  cmake_parse_arguments(PARSE_ARGV 0 arg "" "" "WINDEPLOYQT5;WINDEPLOYQT6")

  # --------------------------
  #  call appropriate func
  # --------------------------

  if (_windeploy_version VERSION_GREATER_EQUAL "6.0.0")
    windeployqt6(${arg_UNPARSED_ARGUMENTS} ${arg_WINDEPLOYQT6})
  elseif(_windeploy_version VERSION_GREATER_EQUAL "5.0.0")
    windeployqt5(${arg_UNPARSED_ARGUMENTS} ${arg_WINDEPLOYQT5})
  else()
    message(FATAL_ERROR "unsupported version of windeployqt.exe [${_windeploy_version}]")
  endif()
endfunction()


#
# Internal implementation function, do not call directly
#
function(__windeployqt_impl)
  if (NOT WIN32)
    return()
  endif()

  # --------------------------
  #  parse arguments
  # --------------------------

  set(_options)
  set(_args     WINDEPLOYQT_EXECUTABLE QT_BIN_DIR TARGET DIRECTORY COMPONENT VERBOSE)
  set(_listargs ARGS)
  cmake_parse_arguments(PARSE_ARGV 0 arg "${_options}" "${_args}" "${_listargs}")

  message(DEBUG "__windeployqt_impl('${arg_TARGET}')")
  message(DEBUG "  arg_WINDEPLOYQT_EXECUTABLE:[${arg_WINDEPLOYQT_EXECUTABLE}]")
  message(DEBUG "  arg_QT_BIN_DIR:[${arg_QT_BIN_DIR}]")
  message(DEBUG "  arg_TARGET:[${arg_TARGET}]")
  message(DEBUG "  arg_DIRECTORY:[${arg_DIRECTORY}]")
  message(DEBUG "  arg_COMPONENT:[${arg_COMPONENT}]")
  message(DEBUG "  arg_VERBOSE:[${arg_VERBOSE}]")
  message(DEBUG "  arg_ARGS:[${arg_ARGS}]")

  foreach(_arg IN LISTS arg_UNPARSED_ARGUMENTS)
    message(WARNING "unparsed argument: ${_arg}")
  endforeach()

  if (NOT arg_TARGET)
    message(FATAL_ERROR "missing argument: WINDEPLOYQT_EXECUTABLE")
  endif()

  if (NOT arg_TARGET)
    message(FATAL_ERROR "missing argument: TARGET")
  endif()

  if (NOT TARGET "${arg_TARGET}")
    message(FATAL_ERROR "invalid argument: TARGET [${arg_TARGET}] is not a valid target.")
  endif()

  if (arg_DIRECTORY)
    get_filename_component(_dir_absolute "${arg_DIRECTORY}" ABSOLUTE)
    if (_dir_absolute STREQUAL arg_DIRECTORY)
      message(FATAL_ERROR "invalid argument: DIRECTORY can't be an absolute path.")
    endif()
    set(_install_directory "\${CMAKE_INSTALL_PREFIX}/${arg_DIRECTORY}")
  else()
    set(_install_directory "\${CMAKE_INSTALL_PREFIX}")
  endif()

  if (arg_COMPONENT)
    set(_install_component "${arg_COMPONENT}")
  else()
    set(_install_component "Unspecified")
  endif()

  if (arg_QT_BIN_DIR)
    set(_qt_bin_dir "${arg_QT_BIN_DIR}")
  else()
    get_filename_component(_qt_bin_dir "${arg_WINDEPLOYQT_EXECUTABLE}" DIRECTORY)
  endif()

  if (arg_VERBOSE)
    set(_arg_verbose --verbose 1)
  else()
    set(_arg_verbose --verbose 0)
  endif()

  # --------------------------
  #  add command to deploy qt dependencies in build directory
  # --------------------------

  # runs windeployqt immediately after build
  add_custom_command(TARGET "${arg_TARGET}" POST_BUILD
    COMMAND "${CMAKE_COMMAND}" -E
      env PATH="${_qt_bin_dir}" "${arg_WINDEPLOYQT_EXECUTABLE}"
        --no-compiler-runtime
        ${_arg_verbose}
        ${arg_ARGS}
        "$<TARGET_FILE:${arg_TARGET}>"
    COMMENT "Deploying Qt to build directory with ${arg_WINDEPLOYQT_EXECUTABLE} ..."
  )

  # --------------------------
  #  add command to deploy qt dependencies in install directory
  # --------------------------

  if (CMAKE_INSTALL_MESSAGE MATCHES "^LAZY$|^ALWAYS$|^NEVER$")
    set(_install_message "MESSAGE_${CMAKE_INSTALL_MESSAGE}")
  endif()

  # runs windeployqt during installation
  install(CODE "
    execute_process(
      COMMAND \"${CMAKE_COMMAND}\" -E
        env PATH=\"${_qt_bin_dir}\"
        \"${arg_WINDEPLOYQT_EXECUTABLE}\"
          --dry-run
          --no-compiler-runtime
          ${_arg_verbose}
          ${arg_ARGS}
          --list mapping
          \"$<TARGET_FILE:${arg_TARGET}>\"
      OUTPUT_VARIABLE __windeploy_output
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
    string(REGEX REPLACE [[;]] [[\\\\\\\\;]] __output_list \"\${__windeploy_output}\")
    string(REGEX REPLACE \"\\n\" [[;]]  __output_list \"\${__output_list}\")
    list(FILTER __output_list INCLUDE REGEX [[^\".*\"$]])
    foreach (__line IN LISTS __output_list)
      if (__line MATCHES [[^\"(.*)\" +\"(.*)\"\$]])
        set(__src_file \${CMAKE_MATCH_1})
        message(DEBUG \"  src: \${__src_file}\")
        set(__dst_file \${CMAKE_MATCH_2})
        message(DEBUG \"  dst: \${__dst_file}\")
        get_filename_component(__dst_dir \${__dst_file} DIRECTORY)
        file(INSTALL \${__src_file}
          DESTINATION \"${_install_directory}/\${__dst_dir}\"
          FOLLOW_SYMLINK_CHAIN
          ${_install_message}
        )
      endif()
    endforeach()
    unset(__windeploy_output)
    unset(__output_list)
    unset(__line)
    unset(__src_file)
    unset(__dst_file)
    unset(__dst_dir)
"
    COMPONENT ${_install_component}
  )

  message(VERBOSE "__windeployqt_impl('${arg_TARGET}') - success")
endfunction()
