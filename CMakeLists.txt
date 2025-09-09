# CMakeLists.txt for CSI project

cmake_minimum_required(VERSION 3.21)
project(CSI LANGUAGES CXX)
add_compile_options(/utf-8)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(QT_QML_GENERATE_QMLLS_INI ON)
set(QT_FEATURE_vulkan OFF CACHE BOOL "" FORCE)

find_package(Qt6 6.2 REQUIRED
    COMPONENTS
        Core
        Quick
        Gui
        Widgets
        Qml
        Network
        QuickLayouts
        QuickControls2
        Multimedia
        QuickEffects
)
qt_standard_project_setup()
qt_policy(SET QTP0001 NEW)

# 编译目标
qt_add_executable(${PROJECT_NAME}
    main.cpp
    src/backend.cpp
)
target_compile_definitions(${PROJECT_NAME} PRIVATE QT_QML_DEBUG)

# IDE 头文件支持 （不参与编译）
target_sources(${PROJECT_NAME} PRIVATE
    includes/backend.h
)
target_include_directories(${PROJECT_NAME} PRIVATE "includes")

# csi
qt_add_qml_module(${PROJECT_NAME}
    URI csi
    VERSION 1.0
    QML_FILES
        # MAIN
        Main.qml
        # ELEMENT
        res/qml/element/NiceDialog.qml
        res/qml/element/ShadowFrame.qml
        res/qml/element/Theme.qml
        res/qml/element/Tooltip.qml
    SOURCES 
        includes/backend.h src/backend.cpp
)
# respkg
qt_add_resources(${PROJECT_NAME} "respkg"
    PREFIX ""
    FILES 
        # SVG
        res/icon/main/construction.svg
        res/icon/message/checked.svg
        res/icon/message/error.svg
        res/icon/message/info.svg
        res/icon/message/warning.svg
        res/icon/window/restore.svg
        res/icon/window/max.svg
        res/icon/window/min.svg
        res/icon/window/close.svg
        # WAV
        res/audio/startup.wav
        # QML
        res/qml/pages/StartPage.qml
        res/qml/pages/SettingsPage.qml
        # TTF
        res/font/AiDianFengYaHei.ttf
        # PNG
        res/image/shadow@q0.png
)

set_target_properties(${PROJECT_NAME}
    PROPERTIES
        WIN32_EXECUTABLE TRUE
)

target_link_libraries(${PROJECT_NAME}
    PUBLIC
        Qt6::Core
        Qt6::Quick
        Qt6::Gui
        Qt6::Widgets
        Qt6::Qml
        Qt6::Network
        Qt6::QuickLayouts
        Qt6::QuickControls2
        Qt6::Multimedia
        Qt6::QuickEffects
)
