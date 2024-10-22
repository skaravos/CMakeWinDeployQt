# CMake - WinDeployQt

This cmake module can be used to automatically bundle all required `Qt`
runtime dlls when building and installing your cmake project on Windows.

This module uses the `windeployqt.exe` tool provided with Windows installations
of `Qt`, so it is a no-op on Linux or MacOS.

## Features

- Easy syntax for invoking `windeployqt.exe` in your CMake file
- Works with both Qt 5 and Qt 6
- Sets up CMake install rules that integrate windeployqt properly with CPack

## Acknowledgements

The original idea for this module comes from [nitroshare](https://github.com/nitroshare/nitroshare-desktop/blob/f4feebef29d9d3985d1699ab36f0fac59d3df7da/cmake/DeployQt.cmake).

## Why use this?

Qt's licensing model prevents non-enterprise customers from statically linking
to any Qt libraries. This means that most projects typically dynamically link
against the Qt dlls.

When running an executable that was dynamically linked all of the required
`.dll`s need to be available to the runtime linker. These can be located
anywhere on the system (provided they are accessible on the `PATH`), but are
most commonly located in the same directory as the executable itself.
If these `.dll`s cannot be located, the executable will not work.

This means that when deploying your Qt program, it is important that you
include all the `Qt` `.dll`s that are necessary to run your program.
(commonly: `QtCore.dll`, `QtWidgets.dll`, `QtGui.dll`)

This is a very common deployment problem for Windows, so Qt provides a
convenient tool `windeployqt.exe`. This tool automatically determines all the
required Qt dlls for a given executable, and copies them to a given directory.

This of course, was designed to be done manually on the command-line after
installing your application, just before deploying it to another PC.
However, manual build steps are tedious and make deployment less reproducible.

This cmake module solves this problem by automatically invoking
`windeployqt.exe` during both the cmake build and install steps, removing the
burden from the user and making it much easier to deploy a working application.

## Usage - CMake

To start using this module you only need to copy the `WinDeployQt.cmake`
file into your project directory (or add it as a git submodule!) and include it
by adding the following line to your project's `CMakeLists.txt`.

```cmake
include("${PROJECT_SOURCE_DIR}/path/to/WinDeployQt.cmake")
```

This will import three functions into your cmake file:

1. `windeployqt5()`
    - For CMake targets linked to `Qt5` libraries (invokes windeployqt.exe)

        ```cmake
        windeployqt5(
            TARGET target          # cmake target linked to Qt shared libraries
            [DIRECTORY directory]  # installation directory
            [COMPONENT component]  # installation component
            [VERBOSE]              # run windeployqt with --verbose=1
            [ARGS args...]         # additional args passed to windeployqt.exe
        )
        ```

2. `windeployqt6()`
    - For CMake targets linked to `Qt6` libraries (invokes windeployqt6.exe)

        ```cmake
        windeployqt6(
            TARGET target          # cmake target linked to Qt shared libraries
            [DIRECTORY directory]  # installation directory
            [COMPONENT component]  # installation component
            [VERBOSE]              # run windeployqt6 with --verbose=1
            [ARGS args...]         # additional args passed to windeployqt6.exe
        )
        ```

3. `windeployqt()`
    - Invokes `windeployqt.exe` with the `--version` parameter and calls
      either `windeployqt5()` or `windeployqt6()` based on the result.
    - This function is provided for convenience in projects that still support
      building with Qt5 or Qt6.

        ```cmake
        windeployqt(
            args...                # args passed to windeployqt5 or windeployqt6
            [WINDEPLOYQT5 args...] # arguments only passed to windeployqt5()
            [WINDEPLOYQT6 args...] # arguments only passed to windeployqt6()
        )
        ```

See the comments above each function definition in the `WinDeployQt.cmake` file
for details on each function parameter.

## Usage - Minimum Reproducible Example

An example [CMakeLists.txt](./example/CMakeLists.txt) is provided to show basic usage.

To build the example, you'll need to have Qt 5 or Qt 6 installed.

### Building the Example

1. cd into example directory

    ```cmd
    cd C:/projects/CMakeWinDeployQt/example
    ```

1. configure the project with cmake

    - For Qt5

      *NOTE: Qt5_DIR is the location of `Qt5Config.cmake` in your Qt install dir*

      ```sh
      cmake -S. -B_build -DCMAKE_INSTALL_PREFIX=_install -DQt5_DIR=C:/Qt/5.15.12/lib/cmake/Qt5
      ```

    - For Qt6

      *NOTE: Qt6_DIR is the location of `Qt6Config.cmake` in your Qt install dir*

      ```cmd
      cmake -S. -B_build -DCMAKE_INSTALL_PREFIX=_install -DUSE_QT6=TRUE -DQt6_DIR=C:/Qt/6.6.1/lib/cmake/Qt6
      ```

1. build the project

    *NOTE: in the _build/Release directory you should see that the `QtCore.dll` was deployed*

    ```cmd
    cmake --build _build --config Release
    ```

1. install the project

    *NOTE: in the _install/ directory you should see that the `QtCore.dll` was deployed*

    ```cmd
    cmake --install _build --config Release
    ```
