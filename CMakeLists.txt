# SPDX-FileCopyrightText: 2026 Eike Hein <hein@kde.org>
# SPDX-License-Identifier: BSD-2-Clause

cmake_minimum_required(VERSION 3.28)
project(zirq VERSION 0.3.1 LANGUAGES C CXX)

if(APPLE)
    enable_language(OBJCXX)
endif()

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(QT_MIN_VERSION 6.11)
set(KF_MIN_VERSION 6.29)
set(KWI_DISPLAY_NAME "Zirq")
set(KWI_APP_ID "com.elashri.zirq")
set(KWI_ORGANIZATION_DOMAIN "elashri.com")
set(KWI_EXECUTABLE "zirq")
set(KWI_PROJECT_LICENSE "GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL")

find_package(ECM ${KF_MIN_VERSION} REQUIRED NO_MODULE)
list(APPEND CMAKE_MODULE_PATH ${ECM_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(KDEInstallDirs6)
include(KDECMakeSettings NO_POLICY_SCOPE)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(ECMFindQmlModule)
include(ECMSetupVersion)
include(ECMQmlModule)
include(ECMGenerateQDoc)
include(GenerateExportHeader)
include(FeatureSummary)

option(BUILD_APP "Build the Zirq application" ON)
if(APPLE)
    set(_kwi_kpart_default OFF)
else()
    set(_kwi_kpart_default ON)
endif()
option(BUILD_KPART "Build the Zirq terminal KPart" ${_kwi_kpart_default})

if(BUILD_TESTING)
    enable_testing()
    find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS Test QuickTest)
    include(ECMAddTests)
    set(KWI_TEST_DATA_DIR "${PROJECT_BINARY_DIR}/autotest-data")
endif()

find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS
    Core Gui GuiPrivate Quick Qml QmlIntegration QuickControls2 Concurrent DBus Network
    ShaderTools)
find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS
    CoreAddons Config GuiAddons I18n Kirigami Pty)

if(BUILD_APP OR BUILD_KPART)
    find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS Widgets Svg)
    find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS KIO Notifications WindowSystem ColorScheme)
    find_package(KF6KirigamiAddons 1.11 REQUIRED)
endif()

if(BUILD_APP)
    find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS DBusAddons)
    find_package(KF6KirigamiAppComponents 1.1 REQUIRED)
endif()

if(APPLE AND BUILD_APP)
    find_package(KF6BreezeIcons ${KF_MIN_VERSION} REQUIRED)
    find_package(KF6IconThemes ${KF_MIN_VERSION} REQUIRED)
endif()

if(BUILD_KPART)
    find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS QuickWidgets)
    find_package(KF6 ${KF_MIN_VERSION} REQUIRED COMPONENTS Parts XmlGui WidgetsAddons IconThemes)
endif()

find_package(Ghostty 1.0.1 REQUIRED)

qt_standard_project_setup(REQUIRES ${QT_MIN_VERSION})

if(BUILD_APP OR BUILD_KPART)
    ecm_find_qmlmodule(QtQuick.Dialogs REQUIRED)
    ecm_find_qmlmodule(org.kde.kirigami.forms REQUIRED)
    ecm_find_qmlmodule(org.kde.desktop REQUIRED)
endif()

if(BUILD_APP)
    ecm_find_qmlmodule(Qt.labs.platform REQUIRED)
    ecm_find_qmlmodule(org.kde.kirigami.dialogs REQUIRED)
    ecm_find_qmlmodule(org.kde.kirigami.delegates REQUIRED)
    ecm_find_qmlmodule(org.kde.kirigami.actioncollection REQUIRED)
    ecm_find_qmlmodule(org.kde.kirigamiaddons.settings REQUIRED)
    ecm_find_qmlmodule(org.kde.kitemmodels REQUIRED)
    ecm_find_qmlmodule(org.kde.notification REQUIRED)
endif()

ecm_setup_version(PROJECT VARIABLE_PREFIX KWI
    VERSION_HEADER "${CMAKE_CURRENT_BINARY_DIR}/kwi-version.h")

add_subdirectory(libs/ghostty-qt)
add_subdirectory(libs/ghostty-qt-quick)
add_subdirectory(libs/kwi-terminal)

if(BUILD_APP OR BUILD_KPART)
    configure_file(src/kwi-config.h.in kwi-config.h @ONLY)
    add_subdirectory(src)
    add_subdirectory(data)

    if(BUILD_TESTING)
        add_subdirectory(autotests)
    endif()
endif()

if(BUILD_TESTING)
    add_subdirectory(tests)

    if(APPLE)
        # Qt's native macOS data paths do not honor XDG_*_HOME. Give imported
        # upstream suites a private home before any application initializes.
        set(test_directories libs/ghostty-qt/autotests libs/kwi-terminal/autotests)
        if(BUILD_APP OR BUILD_KPART)
            list(APPEND test_directories autotests)
        endif()
        foreach(test_directory IN LISTS test_directories)
            get_property(upstream_tests DIRECTORY "${test_directory}" PROPERTY TESTS)
            foreach(test IN LISTS upstream_tests)
                set(test_home "${KWI_TEST_DATA_DIR}/homes/${test}")
                file(MAKE_DIRECTORY "${test_home}")
                get_test_property(${test} ENVIRONMENT_MODIFICATION DIRECTORY "${test_directory}" test_environment)
                if(NOT test_environment)
                    set(test_environment "")
                endif()
                list(APPEND test_environment "HOME=set:${test_home}" "CFFIXED_USER_HOME=set:${test_home}")
                set_tests_properties(${test} DIRECTORY "${test_directory}" PROPERTIES
                    ENVIRONMENT_MODIFICATION "${test_environment}")
            endforeach()
        endforeach()
    endif()
endif()

ki18n_install(po)

include(KDEClangFormat)
file(GLOB_RECURSE ALL_CLANG_FORMAT_SOURCE_FILES
    autotests/*.cpp autotests/*.h
    src/*.cpp src/*.h
    libs/*.cpp libs/*.h)
kde_clang_format(${ALL_CLANG_FORMAT_SOURCE_FILES})
add_custom_target(format DEPENDS clang-format)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
