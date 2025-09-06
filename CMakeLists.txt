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
        Main.qml
        res/qml/element/NiceDialog.qml
    SOURCES 
        includes/backend.h src/backend.cpp
)
# respkg
qt_add_resources(${PROJECT_NAME} "respkg"
    PREFIX ""
    FILES 
        res/icon/icon.png
        res/icon/wrning.ico
        res/icon/checked.ico
        res/audio/startup.wav
        res/qml/pages/StartPage.qml
        res/qml/pages/SettingsPage.qml
        res/font/AiDianFengYaHeiChangTi.ttf
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
