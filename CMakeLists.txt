# CMakeLists.txt for CSI project
cmake_minimum_required(VERSION 3.22)
project(CSI LANGUAGES CXX)

# 确保使用 UTF-8 编码，兼容 Clang & GCC
add_compile_options(
    # 使用生成器表达式，兼容多配置生成器
    $<$<CXX_COMPILER_ID:MSVC>:/utf-8>
    $<$<OR:$<CXX_COMPILER_ID:GNU>,$<CXX_COMPILER_ID:Clang>>:-finput-charset=UTF-8>
    $<$<OR:$<CXX_COMPILER_ID:GNU>,$<CXX_COMPILER_ID:Clang>>:-fexec-charset=UTF-8>
)

# 设置必要属性
set(CMAKE_CXX_STANDARD 20)          # 使用 C++ 20 标准
set(CMAKE_CXX_STANDARD_REQUIRED ON) # 严格C++版本支持性检查
set(QT_QML_GENERATE_QMLLS_INI ON)   # 生成 .qmlls.ini 以兼容QML语言服务

# 查找需要的包 / 初始化
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
qt_standard_project_setup() # 默认初始化
qt_policy(SET QTP0001 NEW)  # 导入无版本模块支持
qt_policy(SET QTP0004 NEW)  # 强制生成 qmldir 支持

# 编译目标集
set(APP_SOURCES 
    main.cpp
    src/backend.cpp
    src/settings.cpp
)

# Windows 下的程序属性
if(WIN32)
    set(APP_ICON_RC "${CMAKE_CURRENT_SOURCE_DIR}/res/rc/app.rc")
    list(APPEND APP_SOURCES ${APP_ICON_RC})
endif()

# 导入编译目标
qt_add_executable(${PROJECT_NAME} ${APP_SOURCES})

# Debug 下添加Debug预处理宏以兼容调试功能
add_compile_options(
    # 使用生成器表达式，兼容多配置生成器
    $<$<CONFIG:Debug>:QT_QML_DEBUG>
)

# IDE 头文件支持 （不参与编译）
target_sources(${PROJECT_NAME} PRIVATE
    includes/backend.h
    includes/settings.h
)
# 指定头文件搜索目录（重要）
target_include_directories(${PROJECT_NAME} PRIVATE "includes")

# csi - 源文件导入
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
        includes/settings.h src/settings.cpp
)
# respkg - 资源文件导入
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
        res/audio/startup.ogg
        # QML
        res/qml/pages/StartPage.qml
        res/qml/pages/SettingsPage.qml
        # TTF
        res/font/AiDianFengYaHei.ttf
        # PNG
        res/image/shadow@q0.png
)

# Windows 下声明为GUI程序，不弹出控制台（其他平台自动忽略）
set_target_properties(${PROJECT_NAME}
    PROPERTIES
        WIN32_EXECUTABLE TRUE
)

# 导入模块
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
