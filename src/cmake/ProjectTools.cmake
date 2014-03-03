# ============================================================================
# Copyright (c) 2011-2012 University of Pennsylvania
# Copyright (c) 2013-2014 Carnegie Mellon University
# Copyright (c) 2013-2014 Andreas Schuh
# All rights reserved.
#
# See COPYING file for license information or visit
# http://opensource.andreasschuh.com/cmake-basis/download.html#license
# ============================================================================

##############################################################################
# @file  ProjectTools.cmake
# @brief Definition of main project tools.
##############################################################################


# ----------------------------------------------------------------------------
# include guard
if (__BASIS_PROJECTTOOLS_INCLUDED)
  return ()
else ()
  set (__BASIS_PROJECTTOOLS_INCLUDED TRUE)
endif ()


# ============================================================================
# basis_name_check
# ============================================================================

# ----------------------------------------------------------------------------
## @brief Check if a project name fits the BASIS standards.
#
macro (basis_name_check INPUT_PROJECT_NAME)
  if (NOT ${INPUT_PROJECT_NAME} MATCHES "^([a-z][-_a-z0-9]*|[a-zA-Z0-9][-_a-zA-Z0-9]*)$")
    message (FATAL_ERROR "Invalid name: ${${INPUT_PROJECT_NAME}}\n"
                         "We suggest that you use upper CamelCase notation."
                         "(see http://en.wikipedia.org/wiki/CamelCase#Variations_and_synonyms)."
                         "Please choose a name with either only captial letters"
                         "in the case of an acronym or a name with mixed case, "
                         "but starting with a captial letter.\n"
                         "Note that numbers, `-` and `_` are allowed, but not as first character.")
  endif()
endmacro()

# ============================================================================
# meta-data
# ============================================================================

## @brief Auxiliary macro used by basis_project_check_metadata.
#
# Used by basis_project_check_metadata to check the existence of each project
# source directory specified in the given list variable and to report an error
# otherwise. As a side effect, this macro makes all relative paths absolute
# with respect to PROJECT_SOURCE_DIR or sets the directory variable to the
# default value (ARGN).
macro (basis_check_or_set_source_paths _VAR)
  if (${_VAR})
    set (_PATHS)
    foreach (_PATH IN LISTS ${_VAR})
      if (NOT IS_ABSOLUTE "${_PATH}")
        set (${_PATH} "${PROJECT_SOURCE_DIR}/${_PATH}")
      endif ()
      if (NOT IS_DIRECTORY "${_PATH}")
        message (FATAL_ERROR "The ${_VAR} is set to the non-existing path\n\t${_PATH}\n"
                             "Check the basis_project() arguments and keep in mind that"
                             " relative paths have to be relative to the top-level directory"
                             " of the project or module, respectively, i.e.\n\t${PROJECT_SOURCE_DIR}")
      endif ()
    endforeach ()
    set (${_VAR} "${_PATHS}")
    unset (_PATHS)
    unset (_PATH)
  else ()
    set (${_VAR} ${ARGN})
  endif ()
endmacro ()

# ----------------------------------------------------------------------------
## @brief Check meta-data and set defaults.
#
# @sa basis_project()
# @sa basis_slicer_module()
macro (basis_project_check_metadata)
  # PROJECT_AUTHOR
  if (PROJECT_AUTHORS AND PROJECT_AUTHOR)
    message (FATAL_ERROR "Options AUTHOR and AUTHORS are mutually exclusive!")
  endif ()
  if (PROJECT_AUTHOR)
    set (PROJECT_AUTHORS "${PROJECT_AUTHOR}")
  endif ()
  if (NOT PROJECT_AUTHORS AND PROJECT_IS_MODULE)
    set (PROJECT_AUTHORS "${TOPLEVEL_PROJECT_AUTHORS}")
  endif ()
  if (NOT PROJECT_IS_MODULE)
    set (TOPLEVEL_PROJECT_AUTHORS "${PROJECT_AUTHORS}")
  endif ()
  # PROJECT_NAME or PROJECT_SUBPROJECT
  if (PROJECT_SUBPROJECT AND PROJECT_NAME)
    message (FATAL_ERROR "Options SUBPROJECT and NAME are mutually exclusive!")
  elseif (PROJECT_SUBPROJECT)
    set (PROJECT_NAME "${PROJECT_SUBPROJECT}")
    set (PROJECT_IS_SUBPROJECT TRUE)
  else ()
    set (PROJECT_IS_SUBPROJECT FALSE)
  endif ()
  unset (PROJECT_SUBPROJECT)
  if (NOT PROJECT_NAME)
    message (FATAL_ERROR "CMake BASIS variable PROJECT_NAME not specified!")
  endif ()
  basis_name_check(PROJECT_NAME)
  string (TOLOWER "${PROJECT_NAME}" PROJECT_NAME_L)
  string (TOUPPER "${PROJECT_NAME}" PROJECT_NAME_U)
  if (NOT PROJECT_IS_MODULE)
    set (TOPLEVEL_PROJECT_NAME   "${PROJECT_NAME}")
    set (TOPLEVEL_PROJECT_NAME_L "${PROJECT_NAME_L}")
    set (TOPLEVEL_PROJECT_NAME_U "${PROJECT_NAME_U}")
  endif ()
  # PROJECT_PACKAGE_NAME
  if (PROJECT_PACKAGE AND PROJECT_PACKAGE_NAME)
    message (FATAL_ERROR "Options PACKAGE_NAME and PACKAGE are mutually exclusive!")
  endif ()
  if (PROJECT_PACKAGE)
    set (PROJECT_PACKAGE_NAME "${PROJECT_PACKAGE}")
  endif ()
  if (NOT PROJECT_PACKAGE_NAME)
    if (PROJECT_IS_MODULE)
      set (PROJECT_PACKAGE_NAME "${TOPLEVEL_PROJECT_PACKAGE_NAME}")
    else ()
      if (PROJECT_IS_SUBPROJECT)
        message (FATAL_ERROR "Missing PACKAGE_NAME option for SUBPROJECT ${PROJECT_NAME}!"
                             " Note that the PACKAGE_NAME option is required for subprojects"
                             " in order to enable the independent build. It should be"
                             " set to the name of the top-level project this subproject"
                             " belongs to. Otherwise, the subproject can only be build"
                             " as part of the package it belongs to.")
      endif ()
      set (PROJECT_PACKAGE_NAME "${PROJECT_NAME}")
    endif ()
  endif ()
  basis_name_check(PROJECT_PACKAGE_NAME)
  string (TOLOWER "${PROJECT_PACKAGE_NAME}" PROJECT_PACKAGE_NAME_L)
  string (TOUPPER "${PROJECT_PACKAGE_NAME}" PROJECT_PACKAGE_NAME_U)
  if (NOT PROJECT_IS_MODULE)
    set (TOPLEVEL_PROJECT_PACKAGE_NAME   "${PROJECT_PACKAGE_NAME}")
    set (TOPLEVEL_PROJECT_PACKAGE_NAME_L "${PROJECT_PACKAGE_NAME_L}")
    set (TOPLEVEL_PROJECT_PACKAGE_NAME_U "${PROJECT_PACKAGE_NAME_U}")
  endif ()
  # PROJECT_PACKAGE_VENDOR
  if (PROJECT_PROVIDER AND PROJECT_VENDOR AND PROJECT_PACKAGE_VENDOR)
    message (FATAL_ERROR "Options PACKAGE_VENDOR, VENDOR, and PROVIDER (deprecated) are mutually exclusive!")
  endif ()
  if (PROJECT_PROVIDER)
    message (WARNING "Option PROVIDER is deprecated and should be replaced by VENDOR!"
                     " Consider additionally the new options PROVIDER_NAME and DIVISION_NAME")
    set (PROJECT_PACKAGE_VENDOR "${PROJECT_PROVIDER}")
  endif ()
  if (PROJECT_VENDOR)
    set (PROJECT_PACKAGE_VENDOR "${PROJECT_VENDOR}")
  endif ()
  if (NOT PROJECT_PACKAGE_VENDOR AND PROJECT_IS_MODULE)
    set (PROJECT_PACKAGE_VENDOR "${TOPLEVEL_PROJECT_PACKAGE_VENDOR}")
  endif ()
  string (TOLOWER "${PROJECT_PACKAGE_VENDOR}" PROJECT_PACKAGE_VENDOR_L)
  string (TOUPPER "${PROJECT_PACKAGE_VENDOR}" PROJECT_PACKAGE_VENDOR_U)
  if (NOT PROJECT_IS_MODULE)
    set (TOPLEVEL_PROJECT_PACKAGE_VENDOR   "${PROJECT_PACKAGE_VENDOR}")
    set (TOPLEVEL_PROJECT_PACKAGE_VENDOR_L "${PROJECT_PACKAGE_VENDOR_L}")
    set (TOPLEVEL_PROJECT_PACKAGE_VENDOR_U "${PROJECT_PACKAGE_VENDOR_U}")
  endif ()
  # PROJECT_PACKAGE_WEBSITE
  if (PROJECT_WEBSITE AND PROJECT_PACKAGE_WEBSITE)
    message (FATAL_ERROR "Options PACKAGE_WEBSITE and WEBSITE are mutually exclusive!")
  endif ()
  if (PROJECT_WEBSITE)
    set (PROJECT_PACKAGE_WEBSITE "${PROJECT_WEBSITE}")
  endif ()
  if (PROJECT_IS_MODULE)
    if (NOT PROJECT_PACKAGE_WEBSITE)
      set (PROJECT_PACKAGE_WEBSITE "${TOPLEVEL_PROJECT_PACKAGE_WEBSITE}")
    endif ()
  else ()
    set (TOPLEVEL_PROJECT_PACKAGE_WEBSITE "${PROJECT_PACKAGE_WEBSITE}")
  endif ()
  # PROJECT_PACKAGE_LOGO - see also basis_initialize_settings
  if (PROJECT_IS_MODULE)
    if (NOT PROJECT_PACKAGE_LOGO)
      set (PROJECT_PACKAGE_LOGO "${TOPLEVEL_PROJECT_PACKAGE_LOGO}")
    endif ()
  else ()
    set (TOPLEVEL_PROJECT_PACKAGE_LOGO "${PROJECT_PACKAGE_LOGO}")
  endif ()
  # PROJECT_PROVIDER_NAME
  if (NOT PROJECT_PROVIDER_NAME AND PROJECT_IS_MODULE)
    set (PROJECT_PROVIDER_NAME "${TOPLEVEL_PROJECT_PROVIDER_NAME}")
  endif ()
  string (TOLOWER "${PROJECT_PROVIDER_NAME}" PROJECT_PROVIDER_NAME_L)
  string (TOUPPER "${PROJECT_PROVIDER_NAME}" PROJECT_PROVIDER_NAME_U)
  if (NOT PROJECT_IS_MODULE)
    set (TOPLEVEL_PROJECT_PROVIDER_NAME   "${PROJECT_PROVIDER_NAME}")
    set (TOPLEVEL_PROJECT_PROVIDER_NAME_L "${PROJECT_PROVIDER_NAME_L}")
    set (TOPLEVEL_PROJECT_PROVIDER_NAME_U "${PROJECT_PROVIDER_NAME_U}")
  endif ()
  # PROJECT_PROVIDER_WEBSITE
  if (PROJECT_IS_MODULE)
    if (NOT PROJECT_PROVIDER_WEBSITE)
      set (PROJECT_PROVIDER_WEBSITE "${TOPLEVEL_PROJECT_PROVIDER_WEBSITE}")
    endif ()
  else ()
    set (TOPLEVEL_PROJECT_PROVIDER_WEBSITE "${PROJECT_PROVIDER_WEBSITE}")
  endif ()
  # PROJECT_PROVIDER_LOGO - see also basis_initialize_settings
  if (PROJECT_IS_MODULE)
    if (NOT PROJECT_PROVIDER_LOGO)
      set (PROJECT_PROVIDER_LOGO "${TOPLEVEL_PROJECT_PROVIDER_LOGO}")
    endif ()
  else ()
    set (TOPLEVEL_PROJECT_PROVIDER_LOGO "${PROJECT_PROVIDER_LOGO}")
  endif ()
  # PROJECT_DIVISION_NAME
  if (NOT PROJECT_DIVISION_NAME AND PROJECT_IS_MODULE)
    set (PROJECT_DIVISION_NAME "${TOPLEVEL_PROJECT_DIVISION_NAME}")
  endif ()
  string (TOLOWER "${PROJECT_DIVISION_NAME}" PROJECT_DIVISION_NAME_L)
  string (TOUPPER "${PROJECT_DIVISION_NAME}" PROJECT_DIVISION_NAME_U)
  if (NOT PROJECT_IS_MODULE)
    set (TOPLEVEL_PROJECT_DIVISION_NAME   "${PROJECT_DIVISION_NAME}")
    set (TOPLEVEL_PROJECT_DIVISION_NAME_L "${PROJECT_DIVISION_NAME_L}")
    set (TOPLEVEL_PROJECT_DIVISION_NAME_U "${PROJECT_DIVISION_NAME_U}")
  endif ()
  # PROJECT_DIVISION_WEBSITE
  if (PROJECT_IS_MODULE)
    if (NOT PROJECT_DIVISION_WEBSITE)
      set (PROJECT_DIVISION_WEBSITE "${TOPLEVEL_PROJECT_DIVISION_WEBSITE}")
    endif ()
  else ()
    set (TOPLEVEL_PROJECT_DIVISION_WEBSITE "${PROJECT_DIVISION_WEBSITE}")
  endif ()
  # PROJECT_DIVISION_LOGO - see also basis_initialize_settings
  if (PROJECT_IS_MODULE)
    if (NOT PROJECT_DIVISION_LOGO)
      set (PROJECT_DIVISION_LOGO "${TOPLEVEL_PROJECT_DIVISION_LOGO}")
    endif ()
  else ()
    set (TOPLEVEL_PROJECT_DIVISION_LOGO "${PROJECT_DIVISION_LOGO}")
  endif ()
  # PROJECT_VERSION
  if (PROJECT_VERSION)
    if (NOT PROJECT_VERSION MATCHES "^[0-9]+(\\.[0-9]+)?(\\.[0-9]+)?(rc[0-9]+|[a-z])?$")
      message (FATAL_ERROR "Project ${PROJECT_NAME} has invalid version: ${PROJECT_VERSION}!")
    endif ()
    if (PROJECT_IS_MODULE)
      if (PROJECT_VERSION MATCHES "^0+(\\.0+)?(\\.0+)?$")
        set (PROJECT_VERSION "${TOPLEVEL_PROJECT_VERSION}")
      endif ()
    else ()
      set (TOPLEVEL_PROJECT_VERSION "${PROJECT_VERSION}")
    endif ()
  else ()
    if (PROJECT_IS_MODULE)
      set (PROJECT_VERSION "${TOPLEVEL_PROJECT_VERSION}")
    else ()
      message (FATAL_ERROR "Project version not specified!")
    endif ()
  endif ()
  # PROJECT_DESCRIPTION
  if (PROJECT_DESCRIPTION)
    basis_list_to_string (PROJECT_DESCRIPTION ${PROJECT_DESCRIPTION})
  else ()
    set (PROJECT_DESCRIPTION "")
  endif ()
  # PROJECT_COPYRIGHT
  if (PROJECT_IS_MODULE)
    if (NOT PROJECT_COPYRIGHT)
      set (PROJECT_COPYRIGHT "${TOPLEVEL_PROJECT_COPYRIGHT}")
    endif ()
  else ()
    set (TOPLEVEL_PROJECT_COPYRIGHT "${PROJECT_COPYRIGHT}")
  endif ()
  # PROJECT_LICENSE
  if (PROJECT_IS_MODULE)
    if (NOT PROJECT_LICENSE)
      set (PROJECT_LICENSE "${TOPLEVEL_PROJECT_LICENSE}")
    endif ()
  else ()
    set (TOPLEVEL_PROJECT_LICENSE "${PROJECT_LICENSE}")
  endif ()
  # PROJECT_CONTACT
  if (PROJECT_IS_MODULE)
    if (NOT PROJECT_CONTACT)
      set (PROJECT_CONTACT "${TOPLEVEL_PROJECT_CONTACT}")
    endif ()
  else ()
    set (TOPLEVEL_PROJECT_CONTACT "${PROJECT_CONTACT}")
  endif ()
  # source tree directories
  basis_check_or_set_source_paths (PROJECT_INCLUDE_DIRS "${PROJECT_SOURCE_DIR}/include")
  basis_check_or_set_source_paths (PROJECT_CODE_DIRS    "${PROJECT_SOURCE_DIR}/src")
  basis_check_or_set_source_paths (PROJECT_MODULES_DIR  "${PROJECT_SOURCE_DIR}/modules")
  basis_check_or_set_source_paths (PROJECT_CONFIG_DIR   "${PROJECT_SOURCE_DIR}/config")
  basis_check_or_set_source_paths (PROJECT_DATA_DIR     "${PROJECT_SOURCE_DIR}/data")
  basis_check_or_set_source_paths (PROJECT_DOC_DIR      "${PROJECT_SOURCE_DIR}/doc")
  basis_check_or_set_source_paths (PROJECT_DOCRES_DIR   "${PROJECT_DOC_DIR}/static")
  basis_check_or_set_source_paths (PROJECT_EXAMPLE_DIR  "${PROJECT_SOURCE_DIR}/example")
  basis_check_or_set_source_paths (PROJECT_LIBRARY_DIR  "${PROJECT_SOURCE_DIR}/lib")
  basis_check_or_set_source_paths (PROJECT_TESTING_DIR  "${PROJECT_SOURCE_DIR}/test")
  # let basis_project_impl() know that basis_project() was called
  set (BASIS_basis_project_CALLED TRUE)
endmacro ()

# ----------------------------------------------------------------------------
## @brief Sets basic project information including the name, version, and dependencies.
#
# Any BASIS project has to call this macro in the file BasisProject.cmake
# located in the top level directory of the source tree in order to define
# the project attributes required by BASIS to setup the build system.
# Moreover, if the BASIS project is a module of another BASIS project, this
# file and the variables set by this macro are used by the top-level project to
# identify its modules and the dependencies among them.
#
# @par Project version:
# The version number consists of three components: the major version number,
# the minor version number, and the patch number. The format of the version
# string is "<major>.<minor>.<patch>", where the minor version number and patch
# number default to "0" if not given. Only digits are allowed except of the two
# separating dots.
# @n
# - A change of the major version number indicates changes of the softwares
#   @api (and @abi) and/or its behavior and/or the change or addition of major
#   features.
# - A change of the minor version number indicates changes that are not only
#   bug fixes and no major changes. Hence, changes of the @api but not the @abi.
# - A change of the patch number indicates changes only related to bug fixes
#   which did not change the softwares @api. It is the least important component
#   of the version number.
#
# @par Dependencies:
# Dependencies on other BASIS projects, which can be subprojects of the same
# BASIS top-level project, as well as dependencies on external packages such as ITK
# have to be defined here using the @p DEPENDS argument option. This will be used
# by a top-level project to ensure that the dependencies among its subprojects are
# resolved properly. For each external dependency, the BASIS functions
# basis_find_package() and basis_use_package() are invoked by
# basis_project_initialize(). If an external package is not CMake aware and
# additional CMake code shall be executed to include the settings of the external
# package (which is usually done in a so-called <tt>Use&lt;Pkg&gt;.cmake</tt> file
# if the package would be CMake aware), such code should be added to the
# <tt>Settings.cmake</tt> file of the project.
#
# @param [in] ARGN This list is parsed for the following arguments:
# @par
# <table border="0">
#   <tr>
#     @tp @b NAME name @endtp
#     <td>The name of the project.</td>
#   </tr>
#   <tr>
#     @tp @b SUPER_BUILD @endtp
#     <td>EXPERIMENTAL - Compile modules as part of a super build using ExternalProject_Add().
#         This can dramatically speed up configure time by compiling all modules
#         as if they were independent projects.</td>
#   </tr>
#   <tr>
#     @tp @b SUBPROJECT name @endtp
#     <td>Use this option instead of @c NAME to indicate that this project is a
#         subproject of the package @c PACKAGE. This results, for example, in target
#         UIDs such as "<package>.<name>.<target>" instead of "<package>.<target>".
#         Moreover, the libraries and shared files of a subproject are installed
#         in subdirectores whose name equals the name of the subproject. This option
#         should only be used for projects which are modules of another BASIS project,
#         where these modules should reside in their own sub-namespace rather than
#         on the same level as the top-level project.</td>
#   </tr>
#   <tr>
#     @tp @b PACKAGE_NAME pkg @endtp
#     <td>Name of the package this project (module) belongs to. Defaults to the
#         name of the (top-level) project. This option can further be used in case
#         of a top-level project to specify a different package name for the installation.
#         In case of a subproject which is a module of another BASIS project, setting
#         the package name explicitly using this option enables the build of the
#         subproject as separate project while preserving the directory structure
#         and other namespace settings. Therefore, this option is required if the
#         @c SUBPROJECT option is given and the project shall be build independently
#         as stand-alone package. (default: name of top-level package)</td>
#   </tr>
#   <tr>
#     @tp @b PACKAGE_VENDOR name @endtp
#     <td>Short ID of package vendor (i.e, provider and/or division acronym) this variable is used
#         for package identification and is the name given to the folder that will be used as the default 
#         installation path location subdirectory.</td>
#   </tr>
#   <tr>
#     @tp @b VENDOR name @endtp
#     <td>Short alias for @c PACKAGE_VENDOR.</td>
#   </tr>
#   <tr>
#     @tp @b PACKAGE_WEBSITE url @endtp
#     <td>URL of project website used for documentation and packaging.
#         (default: project website of top-level project or empty string)</td>
#   </tr>
#   <tr>
#     @tp @b PACKAGE_LOGO path @endtp
#     <td>Path to package logo file for this installable package. Used in documentation and packaging.
#         Relative paths must be relative to @c PROJECT_SOURCE_DIR.
#         (default: empty string)</td>
#   </tr>
#   <tr>
#     @tp @b WEBSITE url @endtp
#     <td>Short alias for @c PACKAGE_WEBSITE.</td>
#   </tr>
#   <tr>
#     @tp @b PROVIDER_NAME name @endtp
#     <td>The provider/vendor/creator of this package, used for packaging and installation.
#         (default: provider of top-level project or empty string)</td>
#   </tr>
#   <tr>
#     @tp @b PROVIDER_WEBSITE url @endtp
#     <td>URL of provider website used for documentation and packaging.
#         (default: provider website of top-level project or empty string)</td>
#   </tr>
#   <tr>
#     @tp @b PROVIDER_LOGO path @endtp
#     <td>Path to provider logo file used for documentation and packaging.
#         Relative paths must be relative to @c PROJECT_SOURCE_DIR.
#         (default: empty string)</td>
#   </tr>
#   <tr>
#     @tp @b DIVISION_NAME name @endtp
#     <td>The provider division of this package, used for packaging and installation.
#         (default: provider division of top-level project or empty string)</td>
#   </tr>
#   <tr>
#     @tp @b DIVISION_WEBSITE url @endtp
#     <td>URL of provider division website used for documentation and packaging.
#         (default: provider website of top-level project or empty string)</td>
#   </tr>
#   <tr>
#     @tp @b DIVISION_LOGO path @endtp
#     <td>Path to provider division logo file used for documentation and packaging.
#         Relative paths must be relative to @c PROJECT_SOURCE_DIR.
#         (default: empty string)</td>
#   </tr>
#   <tr>
#     @tp @b VERSION major[.minor[.patch]] @endtp
#     <td>Project version string. (default: 1.0.0)</td>
#   </tr>
#   <tr>
#     @tp @b DESCRIPTION description @endtp
#     <td>Package description, used for packing. If multiple arguments are given,
#         they are concatenated using one space character as delimiter.</td>
#   </tr>
#   <tr>
#     @tp @b TEMPLATE path @endtp
#    <td> The TEMPLATE variable stores the directory of the chosen project template along 
#         with the template version so that the correct template is used by basisproject when a project is updated.
#         Note that this variable is used in BASIS itself to specify the default template to use for the BASIS 
#         installation, i.e., the default used by basisproject if no --template argument is provided.
#         If the template is part of the BASIS installation, only the template name and version part of the 
#         full path are needed. Otherwise, the full absolute path is used. For example,
#               @code
#                 basis_project (
#                    # ...
#                    TEMPLATE "sbia/1.8"
#                    # ...
#                 )
#               @endcode
#               @code
#                 basis_project (
#                    # ...
#                    TEMPLATE "/opt/local/share/custom-basis-template/1.0"
#                    # ...
#                 )
#              @endcode 
#       The installed templates can be found in the share/templates folder of installed BASIS software,
#       as well as the data/templates foler of the BASIS source tree.</td>
#   </tr>
#   <tr>
#     @tp @b MODULES_DIR path @endtp
#     <td>A single path to directory containing multiple module folders each containing their own 
#         BasisProject.cmake that will each be picked up automatically. 
#         Also see the related variable @c MODULE_DIRS.
#         A relative path must be relative to @c PROJECT_SOURCE_DIR.
#         (default: ${PROJECT_SOURCE_DIR}/modules)</td>
#   </tr>
#   <tr>
#     @tp @b MODULE_DIRS path1 [path2...] @endtp
#     <td>Multiple paths, each to a single directory containing a 
#         BasisProject.cmake file. Each will be picked up as a module.
#         Also see the related variable @c MODULES_DIR.
#         A relative path must be relative to @c PROJECT_SOURCE_DIR.
#         (default: empty string)</td>
#   </tr>
#   <tr>
#     @tp @b INCLUDE_DIR path @endtp
#     <td>A single path to the directory to be included that contains 
#         header files that are part of the public interface. 
#         Also see the related variable @c INCLUDE_DIRS.
#         A relative path must be relative to @c PROJECT_SOURCE_DIR.
#         (default: ${PROJECT_SOURCE_DIR}/modules)</td>
#   </tr>
#   <tr>
#     @tp @b INCLUDE_DIRS path1 [path2...] @endtp
#     <td>Multiple paths, each to a single directory containing header
#         files that are part of the public interface.
#         Also see the related variable @c INCLUDE_DIR.
#         A relative path must be relative to @c PROJECT_SOURCE_DIR.
#         (default: empty string)</td>
#   </tr>
#   <tr>
#     @tp @b DEPENDS name[, name] @endtp
#     <td>List of dependencies, i.e., either names of other BASIS (sub)projects
#         or names of external packages.</td>
#   </tr>
#   <tr>
#     @tp @b OPTIONAL_DEPENDS name[, name] @endtp
#     <td>List of dependencies, i.e., either names of other BASIS (sub)projects
#         or names of external packages which are used only if available.</td>
#   </tr>
#   <tr>
#     @tp @b TEST_DEPENDS name[, name] @endtp
#     <td>List of dependencies, i.e., either names of other BASIS (sub)projects
#         or names of external packages which are only required by the tests.</td>
#   </tr>
#   <tr>
#     @tp @b OPTIONAL_TEST_DEPENDS name[, name] @endtp
#     <td>List of dependencies, i.e., either names of other BASIS (sub)projects
#         or names of external packages which are used only by the tests if available.</td>
#   </tr>
# </table>
#
# @returns Sets the following non-cached CMake variables:
# @retval PROJECT_NAME                    @c NAME argument.
# @retval PROJECT_PACKAGE_NAME            @c PACKAGE_NAME argument.
# @retval PROJECT_PACKAGE_VENDOR          @c PACKAGE_VENDOR argument.
# @retval PROJECT_PACKAGE_WEBSITE         @c PACKAGE_WEBSITE argument.
# @retval PROJECT_PACKAGE_LOGO            @c PACKAGE_LOGO argument as abolute path.
# @retval PROJECT_PROVIDER_NAME           @c PROVIDER_NAME argument.
# @retval PROJECT_PROVIDER_WEBSITE        @c PROVIDER_WEBSITE argument
# @retval PROJECT_PROVIDER_LOGO           @c PROVIDER_LOGO argument as abolute path.
# @retval PROJECT_DIVISION_NAME           @c DIVISION_NAME argument.
# @retval PROJECT_DIVISION_WEBSITE        @c DIVISION_WEBSITE argument.
# @retval PROJECT_DIVISION_LOGO           @c DIVISION_LOGO argument as absolute path.
# @retval PROJECT_VERSION                 @c VERSION argument.
# @retval PROJECT_DESCRIPTION             @c DESCRIPTION argument.
# @retval PROJECT_DEPENDS                 @c DEPENDS arguments.
# @retval PROJECT_OPTIONAL_DEPENDS        @c OPTIONAL_DEPENDS arguments.
# @retval PROJECT_TEST_DEPENDS            @c TEST_DEPENDS arguments.
# @retval PROJECT_OPTIONAL_TEST_DEPENDS   @c OPTIONAL_TEST_DEPENDS arguments.
# @retval PROJECT_IS_SUBPROJECT           @c TRUE if @c IS_SUBPROJECT option given or @c FALSE otherwise.
# @retval PROJECT_CODE_DIRS               @c LIST of directories on which basis_add_subdirectory() will be called.
# @retval PROJECT_MODULE_DIRS             @c LIST of directories that are project modules containg a BasisProject.cmake file.
#
# @ingroup CMakeAPI
#
# @see BasisSettings.cmake
macro (basis_project)
  # @see BasisSettings.cmake for parameter lists.
  # @see basis_project_check_metadata() above for implementation details
  CMAKE_PARSE_ARGUMENTS (
    PROJECT
      "${BASIS_METADATA_LIST_SWITCH}"
      "${BASIS_METADATA_LIST_SINGLE}"
      "${BASIS_METADATA_LIST_MULTI}"
    ${ARGN}
  )
  basis_project_check_metadata ()
endmacro ()


## @addtogroup CMakeUtilities
# @{


# ============================================================================
# initialization
# ============================================================================

# ----------------------------------------------------------------------------
## @brief Ensure certain requirements on build tree.
#
# Requirements:
# - Root of build tree must not be root of source tree.
#
# @param [in] ARGN Not used.
#
# @returns Nothing.
function (basis_buildtree_asserts)
  string (TOLOWER "${CMAKE_SOURCE_DIR}" SOURCE_ROOT)
  string (TOLOWER "${CMAKE_BINARY_DIR}" BUILD_ROOT)
  basis_sanitize_for_regex (SOURCE_ROOT_RE "${SOURCE_ROOT}")
  if (BUILD_ROOT MATCHES "^${SOURCE_ROOT_RE}$")
    message(FATAL_ERROR "This project should not be configured & build in the "
                        "source directory:\n"
                        "  ${CMAKE_SOURCE_DIR}\n"
                        "You must run CMake in a separate build directory.")
  endif()
endfunction ()

# ----------------------------------------------------------------------------
## @brief Ensure certain requirements on install tree.
#
# Requirements:
# - Prefix must be an absolute path.
# - Install tree must be different from source and build tree.
#
# @param [in] ARGN Not used.
#
# @returns Nothing.
function (basis_installtree_asserts)
  if (NOT IS_ABSOLUTE "${CMAKE_INSTALL_PREFIX}")
    message (FATAL_ERROR "CMAKE_INSTALL_PREFIX must be an absolute path!")
  endif ()
  string (TOLOWER "${CMAKE_SOURCE_DIR}"     SOURCE_ROOT)
  string (TOLOWER "${CMAKE_BINARY_DIR}"     BUILD_ROOT)
  string (TOLOWER "${CMAKE_INSTALL_PREFIX}" INSTALL_ROOT)
  basis_sanitize_for_regex (INSTALL_ROOT_RE "${INSTALL_ROOT}")
  if (BUILD_ROOT MATCHES "^${INSTALL_ROOT_RE}$" OR SOURCE_ROOT MATCHES "^${INSTALL_ROOT_RE}$")
    message (FATAL_ERROR "The current CMAKE_INSTALL_PREFIX points at the source or build tree:\n"
                         "  ${CMAKE_INSTALL_PREFIX}\n"
                         "This is not permitted by this project. "
                         "Please choose another installation prefix."
    )
  endif()
endfunction ()

# ----------------------------------------------------------------------------
## @brief Initialize project modules.
#
# Most parts of this macro were copied from the ITK4 project
# (http://www.vtk.org/Wiki/ITK_Release_4), in particular, the top-level
# CMakeLists.txt file. This file does not state any specific license, but
# the ITK package itself is released under the Apache License Version 2.0,
# January 2004 (http://www.apache.org/licenses/).
#
# @attention At this point, the project-specific variables have not been
#            set yet. For example, use @c CMAKE_CURRENT_SOURCE_DIR instead of
#            @c PROJECT_SOURCE_DIR.
macro (basis_project_modules)
  # --------------------------------------------------------------------------
  # reset variables
  set (PROJECT_MODULES)
  set (PROJECT_MODULES_ENABLED)
  set (PROJECT_MODULES_DISABLED)
  # --------------------------------------------------------------------------
  # load module DAG

  # glob BasisProject.cmake files in modules subdirectory
  if (PROJECT_MODULES_DIR)
    file (
      GLOB
        MODULE_INFO_FILES
      RELATIVE
        "${CMAKE_CURRENT_SOURCE_DIR}"
        "${PROJECT_MODULES_DIR}/*/BasisProject.cmake"
    )
  endif ()
  
  # add each manually specified module
  foreach (_PATH IN LISTS PROJECT_MODULE_DIRS)
    if (NOT IS_ABSOLUTE ${_PATH})
      set (_PATH "${CMAKE_CURRENT_SOURCE_DIR}/${_PATH}")
    endif ()
    if (EXISTS "${_PATH}/BasisProject.cmake")
      list (APPEND MODULE_INFO_FILES "${_PATH}/BasisProject.cmake")
    else ()
      message (FATAL_ERROR "Check your top-level ${CMAKE_CURRENT_SOURCE_DIR}/BasisProject.cmake"
                           " file because the module ${_PATH}/BasisProject.cmake"
                           " file does not appear to exist.")
    endif ()
  endforeach ()
  unset (_PATH)

  # use function scope to avoid overwriting of this project's variables
  function (basis_module_info F)
    set (PROJECT_IS_MODULE TRUE)
    set (BASIS_basis_project_CALLED FALSE)
    include ("${F}")
    # make sure that basis_project() was called
    if (NOT BASIS_basis_project_CALLED)
      message (FATAL_ERROR "basis_module_info(): Missing basis_project() command in ${F}!")
    endif ()
    # remember dependencies
    foreach (V IN ITEMS DEPENDS OPTIONAL_DEPENDS TEST_DEPENDS OPTIONAL_TEST_DEPENDS)
      set (${V})
      foreach (D ${PROJECT_${V}})
        basis_tokenize_dependency ("${D}" PKG VER CMP)
        list (APPEND ${V} "${PKG}")
      endforeach ()
    endforeach ()
    set (${PROJECT_NAME}_DEPENDS               "${DEPENDS}"               PARENT_SCOPE)
    set (${PROJECT_NAME}_OPTIONAL_DEPENDS      "${OPTIONAL_DEPENDS}"      PARENT_SCOPE)
    set (${PROJECT_NAME}_TEST_DEPENDS          "${TEST_DEPENDS}"          PARENT_SCOPE)
    set (${PROJECT_NAME}_OPTIONAL_TEST_DEPENDS "${OPTIONAL_TEST_DEPENDS}" PARENT_SCOPE)
    set (${PROJECT_NAME}_DECLARED              TRUE                       PARENT_SCOPE)
    # remember source directories - used by basis_add_doxygen_doc()
    set (${PROJECT_NAME}_INCLUDE_DIRS "${PROJECT_INCLUDE_DIRS}")
    set (${PROJECT_NAME}_CODE_DIRS    "${PROJECT_CODE_DIRS}")
    # remember if module depends on Slicer - used by basis_find_packages()
    if (PROJECT_IS_SLICER_MODULE)
      foreach (_D IN LISTS BASIS_SLICER_METADATA_LIST)
          if (DEFINED PROJECT_${_D})
            set (${PROJECT_NAME}_${_D} "${PROJECT_${_D}}" PARENT_SCOPE)
          endif ()
      endforeach ()
      set (${PROJECT_NAME}_IS_SLICER_MODULE TRUE PARENT_SCOPE)
    else ()
      set (${PROJECT_NAME}_IS_SLICER_MODULE FALSE PARENT_SCOPE)
    endif ()
    # do not use MODULE instead of PROJECT_NAME in this function as it is not
    # set in the scope of this function but its parent scope only
    set (MODULE "${PROJECT_NAME}" PARENT_SCOPE)
  endfunction ()

  set (PROJECT_MODULES)
  foreach (F IN LISTS MODULE_INFO_FILES)
    basis_module_info (${F})
    list (APPEND PROJECT_MODULES ${MODULE})
    get_filename_component (${MODULE}_BASE ${F} PATH)
    set (MODULE_${MODULE}_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/${${MODULE}_BASE}")
    # use module name as subdirectory name such that the default package
    # configuration file knows where to find the module configurations
    set (MODULE_${MODULE}_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/modules/${MODULE}")
    # help modules to find each other using basis_find_package()
    set (${MODULE}_DIR "${MODULE_${MODULE}_BINARY_DIR}")
  endforeach()
  unset (MODULE)

  # validate the module DAG to identify cyclic dependencies
  macro (basis_module_check MODULE NEEDED_BY STACK)
    if (${MODULE}_DECLARED)
      if (${MODULE}_CHECK_STARTED AND NOT ${MODULE}_CHECK_FINISHED)
        # we reached a module while traversing its own dependencies recursively
        set (MSG "")
        foreach (M ${STACK})
          set (MSG " ${M} =>${MSG}")
          if ("${M}" STREQUAL "${MODULE}")
            break ()
          endif ()
        endforeach ()
        message (FATAL_ERROR "Module dependency cycle detected:\n ${MSG} ${MODULE}")
      elseif (NOT ${MODULE}_CHECK_STARTED)
        # traverse dependencies of this module
        set (${MODULE}_CHECK_STARTED TRUE)
        foreach (D IN LISTS ${MODULE}_DEPENDS)
          basis_module_check (${D} ${MODULE} "${MODULE};${STACK}")
        endforeach ()
        set (${MODULE}_CHECK_FINISHED TRUE)
      endif ()
    endif ()
  endmacro ()

  foreach (MODULE ${PROJECT_MODULES})
    basis_module_check ("${MODULE}" "" "")
  endforeach ()

  # --------------------------------------------------------------------------
  # determine list of enabled modules

  # provide an option for all modules
  if (PROJECT_MODULES)
    option (BUILD_ALL_MODULES "Request to build all modules." OFF)
    option (BUILD_MODULES_BY_DEFAULT "ON - Automatically request modules be built, OFF - manually request each." ON)
    mark_as_advanced(BUILD_MODULES_BY_DEFAULT)
  endif ()

  # provide an option for each module
  foreach (MODULE ${PROJECT_MODULES})
    option (MODULE_${MODULE} "Request to build the module ${MODULE}." ${BUILD_MODULES_BY_DEFAULT})
    if (${MODULE}_EXCLUDE_FROM_ALL)
      set (${MODULE}_IN_ALL FALSE)
    else ()
      set (${MODULE}_IN_ALL ${BUILD_ALL_MODULES})
    endif ()
  endforeach ()

  # follow dependencies
  macro (basis_module_enable MODULE NEEDED_BY)
    if (${MODULE}_DECLARED)
      if (NOT "${NEEDED_BY}" STREQUAL "")
        list (APPEND ${MODULE}_NEEDED_BY "${NEEDED_BY}")
      endif ()
      if (NOT ${MODULE}_ENABLED)
        if ("${NEEDED_BY}" STREQUAL "")
          set (${MODULE}_NEEDED_BY)
        endif ()
        set (${MODULE}_ENABLED TRUE)
        foreach (D IN LISTS ${MODULE}_DEPENDS)
          basis_module_enable (${D} ${MODULE})
        endforeach ()
      endif ()
    endif ()
  endmacro ()

  foreach (MODULE ${PROJECT_MODULES})
    if (MODULE_${MODULE} OR ${MODULE}_IN_ALL)
      basis_module_enable ("${MODULE}" "")
    endif ()
  endforeach ()

  # build final list of enabled modules
  set (PROJECT_MODULES_ENABLED "")
  set (PROJECT_MODULES_DISABLED "")
  foreach (MODULE ${PROJECT_MODULES})
    if (${MODULE}_DECLARED)
      if (${MODULE}_ENABLED)
        list (APPEND PROJECT_MODULES_ENABLED ${MODULE})
      else ()
        list (APPEND PROJECT_MODULES_DISABLED ${MODULE})
      endif ()
    endif ()
  endforeach ()
  list (SORT PROJECT_MODULES_ENABLED) # Deterministic order.
  list (SORT PROJECT_MODULES_DISABLED) # Deterministic order.

  # order list to satisfy dependencies
  include (${BASIS_MODULE_PATH}/TopologicalSort.cmake)
  topological_sort (PROJECT_MODULES_ENABLED "" "_DEPENDS")

  # remove external dependencies
  set (L)
  foreach (MODULE ${PROJECT_MODULES_ENABLED})
    if (${MODULE}_DECLARED)
      list (APPEND L "${MODULE}")
    endif ()
  endforeach ()
  set (PROJECT_MODULES_ENABLED "${L}")
  unset (L)

  # report what will be built
  if (PROJECT_MODULES_ENABLED)
    message (STATUS "Enabled modules [${PROJECT_MODULES_ENABLED}].")
  endif ()

  # turn options ON for modules that are required by other modules
  foreach (MODULE ${PROJECT_MODULES})
    if (DEFINED MODULE_${MODULE} # there was an option for the user
        AND NOT MODULE_${MODULE} # user did not set it to ON themself
        AND NOT ${MODULE}_IN_ALL # BUILD_ALL_MODULES was not set ON
        AND ${MODULE}_NEEDED_BY) # module is needed by other module(s)
      set (MODULE_${MODULE} ON CACHE BOOL "Request building module ${MODULE}." FORCE)
      message ("Enabled module ${MODULE}, needed by [${${MODULE}_NEEDED_BY}].")
    endif ()
  endforeach ()
  
endmacro ()

# ----------------------------------------------------------------------------
## @brief Configure public header files.
function (basis_configure_public_headers)
  # --------------------------------------------------------------------------
  # settings

  # log file which lists the configured header files
  set (CMAKE_FILE "${BINARY_INCLUDE_DIR}/${PROJECT_NAME}PublicHeaders.cmake")
  
  # ----------------------------------------------------------------------------
  #  header files to configure excluding the .in suffix
  set (
    EXTENSIONS
      ".h"
      ".hh"
      ".hpp"
      ".hxx"
      ".inl"
      ".txx"
      ".inc"
  )

  # --------------------------------------------------------------------------
  # clean up last run before the error because a file was added/removed
  file (REMOVE "${CMAKE_FILE}.tmp")
  file (REMOVE "${CMAKE_FILE}.updated")
  if (EXISTS "${CMAKE_FILE}")
    # required to be able to remove now obsolete files from the build tree
    file (RENAME "${CMAKE_FILE}" "${CMAKE_FILE}.tmp")
  endif ()

  # --------------------------------------------------------------------------
  # configure public header files
  message (STATUS "Configuring public header files...")

  if (NOT PROJECT_INCLUDE_DIRS)
    message (FATAL_ERROR "Missing argument PROJECT_INCLUDE_DIRS!")
  endif ()

  # configure all .in files with substitution
  set (CONFIGURED_HEADERS)
  foreach (INCLUDE_DIR IN LISTS PROJECT_INCLUDE_DIRS)
    set (PATTERN)
    foreach (E IN LISTS EXTENSIONS)
      list (APPEND PATTERN "${INCLUDE_DIR}/*${E}.in")
    endforeach ()
    file (GLOB_RECURSE FILES RELATIVE "${INCLUDE_DIR}" ${PATTERN})
    foreach (HEADER IN LISTS FILES)
      get_filename_component (SOURCE "${INCLUDE_DIR}/${HEADER}" ABSOLUTE)
      string (REGEX REPLACE "\\.in$" "" HEADER "${HEADER}")
      configure_file ("${SOURCE}" "${BINARY_INCLUDE_DIR}/${HEADER}" @ONLY)
      list (APPEND CONFIGURED_HEADERS "${SOURCE}")
    endforeach ()
  endforeach ()

  # regular headers are copied separately via 
  # execute_process to avoid a full configure step
  # However, all headers should be checked for changes. 

  execute_process (
    COMMAND "${CMAKE_COMMAND}" ${COMMON_ARGS}
            -D "PROJECT_INCLUDE_DIRS=${PROJECT_INCLUDE_DIRS}"
            -D "BINARY_INCLUDE_DIR=${BINARY_INCLUDE_DIR}"
            -D "EXTENSIONS=${EXTENSIONS}"
            -D "CMAKE_FILE=${CMAKE_FILE}"
            -D "CONFIGURED_HEADERS=${CONFIGURED_HEADERS}"
            -P "${BASIS_MODULE_PATH}/ConfigureIncludeFiles.cmake"
    RESULT_VARIABLE RT
  )

  if (RT EQUAL 0)
    execute_process (
      COMMAND "${CMAKE_COMMAND}" -E touch "${CMAKE_FILE}.updated"
    )
  else ()
    message (FATAL_ERROR "Failed to configure public header files!")
  endif ()

  if (NOT EXISTS "${CMAKE_FILE}")
    message (FATAL_ERROR "File ${CMAKE_FILE} not generated as it should have been!")
  endif ()

  # remove header files from build tree which were copied there before but
  # are part of a now disabled module or were simply removed from the source tree
  if (EXISTS "${CMAKE_FILE}.tmp")
    execute_process (
      # Compare current list of headers to list of previously configured files.
      # If the lists differ, this command removes files which have been removed
      # from the directory tree with root PROJECT_INCLUDE_DIR also from the
      # tree with root directory BINARY_INCLUDE_DIR.
      COMMAND "${CMAKE_COMMAND}" ${COMMON_ARGS}
              -D "PROJECT_INCLUDE_DIRS=${PROJECT_INCLUDE_DIRS}"
              -D "BINARY_INCLUDE_DIR=${BINARY_INCLUDE_DIR}"
              -D "CMAKE_FILE=${CMAKE_FILE}.tmp"
              -D "REFERENCE_FILE=${CMAKE_FILE}"
              -P "${BASIS_MODULE_PATH}/CheckPublicHeaders.cmake"
      VERBATIM
    )
    file (REMOVE "${CMAKE_FILE}.tmp")
    if (NOT RT EQUAL 0)
      message (FATAL_ERROR "Failed to remove obsolete header files from build tree."
                           " Remove the ${BINARY_INCLUDE_DIR} directory and re-run CMake.")
    endif ()
  endif ()

  message (STATUS "Configuring public header files... - done")

  # We need a list of the configured files to add them as dependency of the
  # custom build targets such that these get re-build whenever a file changed.
  # Additionally, including this file here which is modified whenever a
  # header file is added or removed triggeres a re-configuration of the
  # build system which is required to re-execute this function and adjust
  # these custom build targets.
  include ("${CMAKE_FILE}")

  # --------------------------------------------------------------------------
  # check if any header was added or removed (always out-of-date)

  # error message displayed when a file was added or removed which requires
  # a reconfiguration of the build system
  set (ERRORMSG "You have either added, removed, or renamed a public header file"
                " with a .in suffix in the file name. Therefore, the build system"
                " needs to be re-configured. Either try to build again which will"
                " trigger CMake and re-configure the build system or run CMake manually.")
  basis_list_to_string (ERRORMSG ${ERRORMSG})

  # custom command which globs the files in the project's include directory
  set (COMMENT "Checking if public header files were added or removed")
  if (PROJECT_IS_MODULE)
    set (COMMENT "${COMMENT} to ${PROJECT_NAME} module")
  endif ()
  add_custom_command (
    OUTPUT  "${CMAKE_FILE}.tmp"
    COMMAND "${CMAKE_COMMAND}"
            -D "PROJECT_INCLUDE_DIRS=${PROJECT_INCLUDE_DIRS}"
            -D "BINARY_INCLUDE_DIR=${BINARY_INCLUDE_DIR}"
            -D "EXTENSIONS=${EXTENSIONS}"
            -D "CMAKE_FILE=${CMAKE_FILE}.tmp"
            -D "PREVIEW=TRUE" # do not actually configure the files
            -D "CONFIGURED_HEADERS=${CONFIGURED_HEADERS}"
            -P "${BASIS_MODULE_PATH}/ConfigureIncludeFiles.cmake"
    COMMENT "${COMMENT}"
    VERBATIM
  )

  # custom target to detect whether a file was added or removed
  basis_make_target_uid (CHECK_HEADERS_TARGET headers_check)
  add_custom_target (
    ${CHECK_HEADERS_TARGET} ALL
    # trigger execution of custom command that generates the list
    # of current files in the project's include directory
    DEPENDS "${CMAKE_FILE}.tmp"
    # Compare current list of headers to list of previously configured files.
    # If the lists differ, the build of this target fails with the given error message.
    COMMAND "${CMAKE_COMMAND}"
            -D "PROJECT_INCLUDE_DIRS=${PROJECT_INCLUDE_DIRS}"
            -D "BINARY_INCLUDE_DIR=${BINARY_INCLUDE_DIR}"
            -D "CMAKE_FILE=${CMAKE_FILE}"
            -D "REFERENCE_FILE=${CMAKE_FILE}.tmp"
            -D "ERRORMSG=${ERRORMSG}"
            -D "REMOVE_FILES_IF_DIFFERENT=TRUE" # triggers reconfigure on next build
            -P "${BASIS_MODULE_PATH}/CheckPublicHeaders.cmake"
    # remove temporary file again to force its regeneration
    COMMAND "${CMAKE_COMMAND}" -E remove "${CMAKE_FILE}.tmp"
    VERBATIM
  )
  if (PROJECT_IS_MODULE)
    if (NOT TARGET headers_check)
      add_custom_target (headers_check ALL)
    endif ()
    add_dependencies (headers_check ${CHECK_HEADERS_TARGET})
  endif ()

  # --------------------------------------------------------------------------
  # add build command to re-configure public header files
  if (PUBLIC_HEADERS)
    set (COMMENT "Configuring public header files")
    if (PROJECT_IS_MODULE)
      set (COMMENT "${COMMENT} of ${PROJECT_NAME} module")
    endif ()
    add_custom_command (
      OUTPUT  "${CMAKE_FILE}.updated" # do not use same file as included
                                      # before otherwise CMake will re-configure
                                      # the build system next time
      COMMAND "${CMAKE_COMMAND}"
              -D "PROJECT_INCLUDE_DIRS=${PROJECT_INCLUDE_DIRS}"
              -D "BINARY_INCLUDE_DIR=${BINARY_INCLUDE_DIR}"
              -D "EXTENSIONS=${EXTENSIONS}"
              -P "${BASIS_MODULE_PATH}/ConfigureIncludeFiles.cmake"
      COMMAND "${CMAKE_COMMAND}" -E touch "${CMAKE_FILE}.updated"
      DEPENDS ${PUBLIC_HEADERS}
      COMMENT "${COMMENT}"
      VERBATIM
    )
    basis_make_target_uid (CONFIGURE_HEADERS_TARGET headers)
    add_custom_target (
      ${CONFIGURE_HEADERS_TARGET} ALL
      DEPENDS ${CHECK_HEADERS_TARGET} "${CMAKE_FILE}.updated"
      SOURCES ${PUBLIC_HEADERS}
    )
    if (PROJECT_IS_MODULE)
      if (NOT TARGET headers)
        add_custom_target (headers ALL)
      endif ()
      add_dependencies (headers ${CONFIGURE_HEADERS_TARGET})
    endif ()
  endif ()
endfunction ()

# ----------------------------------------------------------------------------
## @brief Add library targets for the public modules in @c PROJECT_LIBRARY_DIR.
#
# This function configures ("builds") the library modules in the
# @c PROJECT_LIBRARY_DIR that are written in a scripting language such as
# Python or Perl. The names of the added library targets can be modified using
# the <tt>&lt;LANG&gt;_LIBRARY_TARGET</tt> variables, which are set to their
# default values in the @c BasisSettings.cmake file.
function (basis_configure_script_libraries)
  if (NOT IS_DIRECTORY "${PROJECT_LIBRARY_DIR}")
    return ()
  endif ()
  # Python
  if (PythonInterp_FOUND)
    set (PYTHON_EXT .py .py.in)
    set (PYTHON_LIB_DIRS)
    if (PYTHON_VERSION_MAJOR)
      list (APPEND PYTHON_LIB_DIRS "${PROJECT_LIBRARY_DIR}/python${PYTHON_VERSION_MAJOR}")
    endif ()
    list (APPEND PYTHON_LIB_DIRS "${PROJECT_LIBRARY_DIR}/python")
    list (APPEND PYTHON_LIB_DIRS "${PROJECT_LIBRARY_DIR}")
  else ()
    set (PYTHON_LIB_DIRS)
  endif ()
  # Jython
  if (JythonInterp_FOUND)
    set (JYTHON_EXT .py .py.in)
    set (JYTHON_LIB_DIRS)
    if (JYTHON_VERSION_MAJOR)
      list (APPEND JYTHON_LIB_DIRS "${PROJECT_LIBRARY_DIR}/jython${JYTHON_VERSION_MAJOR}")
    endif ()
    list (APPEND JYTHON_LIB_DIRS "${PROJECT_LIBRARY_DIR}/jython")
    list (APPEND JYTHON_LIB_DIRS "${PROJECT_LIBRARY_DIR}")
  else ()
    set (JYTHON_LIB_DIRS)
  endif ()
  # Perl
  if (Perl_FOUND)
    set (PERL_EXT .pm .pm.in)
    set (PERL_LIB_DIRS)
    if (PERL_VERSION_MAJOR)
      list (APPEND PERL_LIB_DIRS "${PROJECT_LIBRARY_DIR}/perl${PERL_VERSION_MAJOR}")
    endif ()
    list (APPEND PERL_LIB_DIRS "${PROJECT_LIBRARY_DIR}/perl")
    list (APPEND PERL_LIB_DIRS "${PROJECT_LIBRARY_DIR}")
  else ()
    set (PERL_LIB_DIRS)
  endif ()
  # MATLAB
  if (MATLAB_FOUND)
    set (MATLAB_EXT .m .m.in)
    set (MATLAB_LIB_DIRS)
    if (MATLAB_RELEASE)
      list (APPEND MATLAB_LIB_DIRS "${PROJECT_LIBRARY_DIR}/matlab/${MATLAB_RELEASE}")
    endif ()
    if (MATLAB_VERSION_MAJOR)
      list (APPEND MATLAB_LIB_DIRS "${PROJECT_LIBRARY_DIR}/matlab${MATLAB_VERSION_MAJOR}")
    endif ()
    list (APPEND MATLAB_LIB_DIRS "${PROJECT_LIBRARY_DIR}/matlab")
    list (APPEND MATLAB_LIB_DIRS "${PROJECT_LIBRARY_DIR}")
  else ()
    set (MATLAB_LIB_DIRS)
  endif ()
  # Bash
  if (BASH_FOUND)
    set (BASH_EXT .sh .sh.in)
    set (BASH_LIB_DIRS)
    if (BASH_VERSION_MAJOR)
      list (APPEND BASH_LIB_DIRS "${PROJECT_LIBRARY_DIR}/bash${BASH_VERSION_MAJOR}")
    endif ()
    list (APPEND BASH_LIB_DIRS "${PROJECT_LIBRARY_DIR}/bash")
    list (APPEND BASH_LIB_DIRS "${PROJECT_LIBRARY_DIR}")
  else ()
    set (BASH_LIB_DIRS)
  endif ()
  # add library targets
  set (TARGETS)
  foreach (LANGUAGE IN ITEMS PYTHON JYTHON PERL MATLAB BASH)
    foreach (LIB_DIR IN LISTS ${LANGUAGE}_LIB_DIRS)
      set (EXPRESSIONS)
      foreach (MODULE_EXT IN LISTS ${LANGUAGE}_EXT)
        list (APPEND EXPRESSIONS "${LIB_DIR}/**${MODULE_EXT}")
      endforeach ()
      file (GLOB_RECURSE SOURCES ${EXPRESSIONS})
      basis_get_source_language (SOURCE_LANGUAGE ${SOURCES}) # in particular required to
                                                             # not falsely build Jython modules
                                                             # as Python library
      if (SOURCE_LANGUAGE MATCHES "UNKNOWN|AMBIGUOUS")
        message (WARNING "Failed to auto-detect scripting language of modules in ${LIB_DIR}!"
                         " Skipping source files matching one of the extensions [${${LANGUAGE}_EXT}].")
      elseif (SOURCE_LANGUAGE MATCHES "${LANGUAGE}")
        set (TARGET_NAME "${${LANGUAGE}_LIBRARY_TARGET}")
        basis_add_library (${TARGET_NAME} ${EXPRESSIONS} LANGUAGE ${LANGUAGE})
        basis_set_target_properties (
          ${TARGET_NAME}
          PROPERTIES
            SOURCE_DIRECTORY          "${LIB_DIR}"
            LIBRARY_OUTPUT_DIRECTORY  "${BINARY_${LANGUAGE}_LIBRARY_DIR}"
            LIBRARY_INSTALL_DIRECTORY "${INSTALL_${LANGUAGE}_SITE_DIR}"
            PREFIX                    ""
        )
        list (APPEND TARGETS ${TARGET_NAME})
        break ()
      endif ()
    endforeach ()
  endforeach ()
  if (TARGETS)
    basis_make_target_uid (LIBRARY_TARGET lib)
    add_custom_target (${LIBRARY_TARGET} ALL)
    basis_add_dependencies (${LIBRARY_TARGET} ${TARGETS})
  endif ()
endfunction ()

# ----------------------------------------------------------------------------
## @brief Configure root documentation files.
#
# The root documentation files are located in the top-level directory of the
# project's source tree. These are, in particular, the
# * @c AUTHORS.txt or AUTHORS.md file with information on the authors of the software,
# * @c COPYING.txt or COPYING.md file with copyright and licensing information,
# * @c README.txt or README.md file,
# * @c INSTALL.txt or INSTALL.md file with build and installation instructions,
# * @c WELCOME.txt or WELCOME.md file with text used as welcome text of the installer.
# where the top-level project requires all of these files except of the
# @c WELCOME.txt or WELCOME.md file which defaults to the readme file. Modules of a project
# usually do not include any of these files. Otherwise, the content of the
# module's documentation file is appended to the corresponding file of the
# top-level project.
macro (basis_configure_root_documentation_files)
  foreach (F AUTHORS COPYING README INSTALL WELCOME)

    if (EXISTS "${PROJECT_SOURCE_DIR}/${F}.txt")
      set (PROJECT_${F}_FILE "${PROJECT_SOURCE_DIR}/${F}.txt")
      set (DOC_EXT ".txt")
    elseif (EXISTS "${PROJECT_SOURCE_DIR}/${F}.md")
      set (PROJECT_${F}_FILE "${PROJECT_SOURCE_DIR}/${F}.md")
      set (DOC_EXT ".md")
    endif()
    
    if (EXISTS "${PROJECT_SOURCE_DIR}/${F}${DOC_EXT}")
      set (PROJECT_${F}_FILE "${PROJECT_SOURCE_DIR}/${F}${DOC_EXT}")
      if (PROJECT_IS_MODULE)
        file (READ "${PROJECT_${F}_FILE}" T)
        file (
          APPEND "${TOPLEVEL_PROJECT_${F}_FILE}"
          "\n\n\n"
          "------------------------------------------------------------------------------\n"
          "${PROJECT_NAME} Module\n"
          "------------------------------------------------------------------------------\n"
          "${T}"
        )
      else ()
        set (TOPLEVEL_PROJECT_${F}_FILE "${PROJECT_BINARY_DIR}/${F}${DOC_EXT}")
        # do not use configure_file() to copy the file, otherwise CMake will
        # update the build system only because we modified this file in the if-clause
        execute_process (COMMAND "${CMAKE_COMMAND}" -E copy "${PROJECT_${F}_FILE}" "${TOPLEVEL_PROJECT_${F}_FILE}")
        # use extension on Windows, but leave it out on Unix
        get_filename_component (N "${F}" NAME_WE)
        get_filename_component (E "${F}" EXT)
        if (WIN32)
          if (NOT E)
            set (E "${DOC_EXT}")
          endif ()
        else ()
          if ("${E}" STREQUAL "${DOC_EXT}")
            set (E "")
          endif ()
        endif ()
        set (N "${N}${E}")
        # install file
        if (F MATCHES "COPYING")
          install (
            FILES       "${PROJECT_BINARY_DIR}/${F}${DOC_EXT}"
            DESTINATION "${INSTALL_DOC_DIR}"
            RENAME      "${N}"
            OPTIONAL
          )
        endif ()
      endif ()
    elseif (NOT F MATCHES "WELCOME" AND NOT PROJECT_IS_MODULE)
      message (FATAL_ERROR "Project requires a ${F}.txt or ${F}.md file in ${PROJECT_SOURCE_DIR}!")
    endif ()
  endforeach ()
  set (PROJECT_LICENSE_FILE "${PROJECT_COPYING_FILE}") # compatibility with Slicer
endmacro ()

# ----------------------------------------------------------------------------
## @brief Get build time stamp.
#
# The build time stamp is used as an alternative to the version and revision
# information in @c PROJECT_RELEASE if version is invalid, i.e., set to 0.0.0
# as is the case for development branches, and now revision from a revision
# control system is available.
function (basis_get_build_timestamp TIMESTAMP)
  if (WIN32)
    execute_process (
      COMMAND "${BASIS_MODULE_PATH}/buildtimestamp.cmd"
      RESULT_VARIABLE RT
      OUTPUT_VARIABLE BUILD_TIMESTAMP
      ERROR_QUIET
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
  else ()
    execute_process (
      COMMAND "date" -u "+%Y.%m.%d (%H:%M UTC)"
      RESULT_VARIABLE RT
      OUTPUT_VARIABLE BUILD_TIMESTAMP
      ERROR_QUIET
      OUTPUT_STRIP_TRAILING_WHITESPACE
    )
  endif ()
  if (RT EQUAL 0)
    set (${TIMESTAMP} "${BUILD_TIMESTAMP}" PARENT_SCOPE)
  else ()
    set (${TIMESTAMP} PARENT_SCOPE)
  endif ()
endfunction ()

# ----------------------------------------------------------------------------
## @brief Find standard project logo files with standardized @c PROJECT_${LOGO_TYPE}_LOGO variable names
#  This is an internal function not designed for general use.
#
#  @param OUTPUT_VARIABLE the name of the variable that will contain the final 
#  @param SPECIFIED_LOGO the value that is already set for the logo
#  @param DEFAULT_NAME the default filename of the logo
#  
function (basis_find_logo OUTPUT_VARIABLE SPECIFIED_LOGO DEFUALT_NAME)
  # check for the default logo file locations
  if (NOT SPECIFIED_LOGO)
    if (EXISTS "${PROJECT_DOCRES_DIR}/${DEFAULT_NAME}")
      set (${OUTPUT_VARIABLE} "${PROJECT_DOCRES_DIR}/${DEFAULT_NAME}")
    elseif (EXISTS "${PROJECT_DOC_DIR}/${DEFAULT_NAME}")
      set (${OUTPUT_VARIABLE} "${PROJECT_DOC_DIR}/${DEFAULT_NAME}")
    endif ()
  endif()
  
  # if no logo is specified at all, skip this
  if (${OUTPUT_VARIABLE})
    if (NOT IS_ABSOLUTE "${SPECIFIED_LOGO}")
      if (EXISTS "${PROJECT_DOCRES_DIR}/${SPECIFIED_LOGO}")
        set (${OUTPUT_VARIABLE} "${PROJECT_DOCRES_DIR}/${SPECIFIED_LOGO}")
      elseif (EXISTS "${PROJECT_DOC_DIR}/${SPECIFIED_LOGO}")
        set (${OUTPUT_VARIABLE} "${PROJECT_DOC_DIR}/${SPECIFIED_LOGO}")
      else ()
        set (${OUTPUT_VARIABLE} "${PROJECT_SOURCE_DIR}/${SPECIFIED_LOGO}")
      endif ()
    endif ()
    
    if (EXISTS "${${OUTPUT_VARIABLE}}")
      set(${OUTPUT_VARIABLE} "${${OUTPUT_VARIABLE}}" PARENT_SCOPE)
    else()
      message (AUTHOR_WARNING "Problem:\n${OUTPUT_VARIABLE} file specified in the BasisProject.cmake basis_project() call of the project ${PROJECT_NAME} was not found. \nSolutions: \n  1. Add a logo file to one of the appropriate locations detailed below.\n  2. Correct the path if the logo exists. \n  3. Remove the line specifying the logo to look for if it does not exist.\n\nExpected to find file:\n  ${SPECIFIED_LOGO}\n\nDirectories checked for that file or path:\n    ${PROJECT_DOCRES_DIR}\n    ${PROJECT_DOC_DIR}\n    ${PROJECT_SOURCE_DIR}\n\n")
    endif ()
  endif ()
endfunction()

# ----------------------------------------------------------------------------
## @brief Initialize project, calls CMake's project() command.
#
# @sa basis_project()
# @sa basis_project_impl()
#
# @returns Sets the following non-cached CMake variables:
# @retval PROJECT_REVISION         Revision number of Subversion controlled
#                                  source tree or 0 if the source tree is
#                                  not under revision control.
# @retval PROJECT_RELEASE          A string of project version and revision
#                                  that can be used for the output of
#                                  version information. The format of this
#                                  string is either one of the following:
#                                  - "v1.0 (r42)"
#                                  - "v1.0.5 (r50)"
#                                  - "v1.0"   (if revision unknown)
#                                  - "r42"    (if version is 0.0.0)
#                                  - ""       (otherwise)
macro (basis_project_initialize)
  # --------------------------------------------------------------------------
  # CMake version and policies
  cmake_minimum_required (VERSION 2.8.4)

  # Add policies introduced with CMake versions newer than the one specified
  # above. These policies would otherwise trigger a policy not set warning by
  # newer CMake versions.

  if (POLICY CMP0016)
    cmake_policy (SET CMP0016 NEW)
  endif ()

  if (POLICY CMP0017)
    cmake_policy (SET CMP0017 NEW)
  endif ()

  # --------------------------------------------------------------------------
  # reset

  # only set if not set by top-level project before configuring a module
  basis_set_if_empty (PROJECT_IS_MODULE FALSE)
  # set only by basis_use_package() to TRUE such that functions such as
  # the overwritten (basis_)link_directories() command or add_library()
  # know that these directories/targets belong to an external project which
  # is part of the same superbuild. otherwise, it shall be FALSE.
  set (BUNDLE_PROJECT FALSE)

  # hide it here to avoid that it shows up in the GUI on error
  set (CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}" CACHE INTERNAL "" FORCE)

  # --------------------------------------------------------------------------
  # project meta-data
  if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/BasisProject.cmake")
    set (BASIS_basis_project_CALLED FALSE)
    include ("${CMAKE_CURRENT_SOURCE_DIR}/BasisProject.cmake")
    if (NOT BASIS_basis_project_CALLED)
      message (FATAL_ERROR "Missing basis_project() command in BasisProject.cmake!")
    endif ()
  else ()
    message (FATAL_ERROR "Missing BasisProject.cmake file!")
  endif ()

  # --------------------------------------------------------------------------
  # project()
  project ("${PROJECT_NAME}")

  # work-around for issue with CMAKE_PROJECT_NAME always being set to 'Project'
  if ("${PROJECT_SOURCE_DIR}" STREQUAL "${CMAKE_SOURCE_DIR}")
    set_property (CACHE CMAKE_PROJECT_NAME PROPERTY VALUE "${PROJECT_NAME}")
  endif ()

  # get revision of project
  #
  # Note: Use revision when branch, i.e., either trunk, a branch, or a tag
  #       has been modified last. For tags, this should in particular
  #       correspond to the revision when the tag was created.
  if (BASIS_REVISION_INFO)
    basis_svn_get_last_changed_revision ("${PROJECT_SOURCE_DIR}" PROJECT_REVISION)
  else ()
    set (PROJECT_REVISION 0)
  endif ()

  # extract version numbers from version string
  basis_version_numbers (
    "${PROJECT_VERSION}"
      PROJECT_VERSION_MAJOR
      PROJECT_VERSION_MINOR
      PROJECT_VERSION_PATCH
  )

  set (PROJECT_SOVERSION "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}")

  # version information string
  if (PROJECT_VERSION MATCHES "^0+(\\.0+)?(\\.0+)?")
    if (PROJECT_REVISION)
      set (PROJECT_RELEASE "r${PROJECT_REVISION}")
    else ()
      basis_get_build_timestamp (BUILD_TIMESTAMP)
      if (BUILD_TIMESTAMP)
        set (PROJECT_RELEASE "b${BUILD_TIMESTAMP}")
      else ()
        set (PROJECT_RELEASE "")
      endif ()
    endif ()
  else ()
    set (PROJECT_RELEASE "v${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}")
    if (PROJECT_VERSION_PATCH)
      set (PROJECT_RELEASE "${PROJECT_RELEASE}.${PROJECT_VERSION_PATCH}")
    endif ()
    if (PROJECT_REVISION)
      set (PROJECT_RELEASE "${PROJECT_RELEASE} (r${PROJECT_REVISION})")
    endif ()
  endif ()

  set (PROJECT_VERSION_AND_REVISION "${PROJECT_RELEASE}") # backwards compatibility to BASIS < 1.3

  # version number for use in Perl modules
  set (PROJECT_VERSION_PERL "${PROJECT_VERSION_MAJOR}")
  if (PROJECT_VERSION_MAJOR LESS 10)
    set (PROJECT_VERSION_PERL "${PROJECT_VERSION_PERL}.0${PROJECT_VERSION_MINOR}")
  else ()
    set (PROJECT_VERSION_PERL "${PROJECT_VERSION_PERL}.${PROJECT_VERSION_MINOR}")
  endif ()
  if (PROJECT_VERSION_PATCH LESS 10)
    set (PROJECT_VERSION_PERL "${PROJECT_VERSION_PERL}_0${PROJECT_VERSION_PATCH}")
  else ()
    set (PROJECT_VERSION_PERL "${PROJECT_VERSION_PERL}_${PROJECT_VERSION_PATCH}")
  endif ()

  # print project information
  if (NOT PROJECT_IS_MODULE)
    message (STATUS "${PROJECT_NAME} ${PROJECT_RELEASE}")
  endif ()

  # --------------------------------------------------------------------------
  # reset project properties - *after* PROJECT_NAME was set

  # The following variables are used across BASIS macros and functions. They
  # in particular remember information added by one function or macro which
  # is required by another function or macro.
  #
  # These variables need to be properties such that they can be set in
  # subdirectories. Moreover, they have to be assigned with the project's
  # root source directory such that a top-level project's properties are restored
  # after this subproject is finalized such that the top-level project itself can
  # be finalized properly.
  #
  # Attention: In particular the IMPORTED_* properties are already used
  #            during the import of targets when including the use files of
  #            external packages. Hence, this property has to be reset before.

  # see basis_add_imported_target()
  basis_set_project_property (PROPERTY IMPORTED_TARGETS   "")
  basis_set_project_property (PROPERTY IMPORTED_TYPES     "")
  basis_set_project_property (PROPERTY IMPORTED_LOCATIONS "")
  basis_set_project_property (PROPERTY IMPORTED_RANKS     "")
  # see basis_include_directories()
  basis_set_project_property (PROPERTY PROJECT_INCLUDE_DIRS "")
  # see basis_link_directories()
  basis_set_project_property (PROPERTY PROJECT_LINK_DIRS "")
  basis_set_project_property (PROPERTY BUNDLE_LINK_DIRS  "")
  # see add_executable(), add_library()
  basis_set_project_property (PROPERTY TARGETS "")
  # see basis_add_*() functions
  basis_set_project_property (PROPERTY EXPORT_TARGETS                "")
  basis_set_project_property (PROPERTY INSTALL_EXPORT_TARGETS        "")
  basis_set_project_property (PROPERTY CUSTOM_EXPORT_TARGETS         "")
  basis_set_project_property (PROPERTY TEST_EXPORT_TARGETS           "")
  basis_set_project_property (PROPERTY PROJECT_USES_CXX_UTILITIES    FALSE)
  basis_set_project_property (PROPERTY PROJECT_USES_PYTHON_UTILITIES FALSE)
  basis_set_project_property (PROPERTY PROJECT_USES_PERL_UTILITIES   FALSE)
  basis_set_project_property (PROPERTY PROJECT_USES_BASH_UTILITIES   FALSE)
  # yet unused
  basis_set_project_property (PROPERTY PROJECT_USES_JAVA_UTILITIES   FALSE)
  basis_set_project_property (PROPERTY PROJECT_USES_MATLAB_UTILITIES FALSE)

  # --------------------------------------------------------------------------
  # configure BASIS directory structure
  include ("${BASIS_MODULE_PATH}/DirectoriesSettings.cmake")
  # configure file used for the generation of the corresponding documentation
  configure_file (
    "${BASIS_MODULE_PATH}/Directories.cmake.in"
    "${BINARY_CONFIG_DIR}/Directories.cmake"
    @ONLY
  )
endmacro ()

# ----------------------------------------------------------------------------
## @brief Initialize project settings.
macro (basis_initialize_settings)
  # --------------------------------------------------------------------------
  # include project specific settings
  #
  # This file enables the project to modify the default behavior of BASIS,
  # but only if BASIS allows so as the BASIS project settings are included
  # afterwards.
  if (EXISTS "${PROJECT_CONFIG_DIR}/Settings.cmake.in")
    configure_file (
      "${PROJECT_CONFIG_DIR}/Settings.cmake.in"
      "${BINARY_CONFIG_DIR}/Settings.cmake"
      @ONLY
    )
    include ("${BINARY_CONFIG_DIR}/Settings.cmake" NO_POLICY_SCOPE)
  else ()
    include ("${PROJECT_CONFIG_DIR}/Settings.cmake" NO_POLICY_SCOPE OPTIONAL)
  endif ()
  
  # --------------------------------------------------------------------------
  # project logos
  basis_find_logo(PROJECT_PACKAGE_LOGO "${PROJECT_PACKAGE_LOGO}" "logo.png")
  basis_find_logo(PROJECT_PROVIDER_LOGO "${PROJECT_PROVIDER_LOGO}" "provider_logo.png")
  basis_find_logo(PROJECT_DIVISION_LOGO "${PROJECT_DIVISION_LOGO}" "division_logo.png")
  
  # --------------------------------------------------------------------------
  # configure project specific BASIS settings
  set (_BASIS_NAMESPACE_CMAKE "${PROJECT_PACKAGE_NAME_L}")
  if (PROJECT_IS_SUBPROJECT OR PROJECT_IS_MODULE)
    set (_NAMESPACE_CMAKE "${_BASIS_NAMESPACE_CMAKE}.${PROJECT_NAME_L}")
  else ()
    set (_NAMESPACE_CMAKE "${_BASIS_NAMESPACE_CMAKE}")
  endif ()
  # default namespaces used for supported programming languages
  foreach (_L IN LISTS BASIS_LANGUAGES_U)
    if (_L MATCHES "PERL")
      set (_NAMESPACE_${_L} "${PROJECT_PACKAGE_NAME}")
    else ()
      set (_NAMESPACE_${_L} "${PROJECT_PACKAGE_NAME_L}")
    endif ()
  endforeach ()
  if (PROJECT_IS_SUBPROJECT)
    foreach (_L IN LISTS BASIS_LANGUAGES_U)
      if (_L MATCHES "PERL")
        set (_NAMESPACE_${_L} "${_NAMESPACE_${_L}}${BASIS_NAMESPACE_DELIMITER_${_L}}${PROJECT_NAME}")
      elseif (NOT _L MATCHES "CMAKE")
        set (_NAMESPACE_${_L} "${_NAMESPACE_${_L}}${BASIS_NAMESPACE_DELIMITER_${_L}}${PROJECT_NAME_L}")
      endif ()
    endforeach ()
  endif ()
  # package configuration
  set (_TOPLEVEL_PROJECT_PACKAGE_CONFIG_PREFIX "${TOPLEVEL_PROJECT_PACKAGE_NAME}")
  if (PROJECT_IS_SUBPROJECT OR PROJECT_IS_MODULE)
    set (_PROJECT_PACKAGE_CONFIG_PREFIX "${_TOPLEVEL_PROJECT_PACKAGE_CONFIG_PREFIX}${PROJECT_NAME}")
  else ()
    set (_PROJECT_PACKAGE_CONFIG_PREFIX "${_TOPLEVEL_PROJECT_PACKAGE_CONFIG_PREFIX}")
  endif ()
  if (PROJECT_PACKAGE_VENDOR)
    set (_TOPLEVEL_PROJECT_PACKAGE_UID "${PROJECT_PACKAGE_VENDOR}-${PROJECT_PACKAGE_NAME}-${PROJECT_VERSION}")
  else ()
    set (_TOPLEVEL_PROJECT_PACKAGE_UID "${PROJECT_PACKAGE_NAME}-${PROJECT_VERSION}")
  endif ()
  # configure settings file which contains the documentation of these variables
  configure_file (
    "${BASIS_MODULE_PATH}/ProjectSettings.cmake.in"
    "${BINARY_CONFIG_DIR}/ProjectSettings.cmake"
    @ONLY
  )
  # unset local variables
  foreach (_L IN LISTS BASIS_LANGUAGES_U)
    unset (_BASIS_NAMESPACE_${_L})
    unset (_NAMESPACE_${_L})
  endforeach ()
  unset (_TOPLEVEL_PROJECT_PACKAGE_UID)
  unset (_TOPLEVEL_PROJECT_PACKAGE_CONFIG_PREFIX)
  unset (_PROJECT_PACKAGE_CONFIG_PREFIX)
  unset (_L)
  # include configured project specific BASIS settings
  include ("${BINARY_CONFIG_DIR}/ProjectSettings.cmake" NO_POLICY_SCOPE)
endmacro ()

# ----------------------------------------------------------------------------
## @brief Find packages this project depends on.
macro (basis_find_packages)
  set (BASIS_SET_TARGET_PROPERTIES_IMPORT TRUE) # see set_target_properties()

  # Attention: This function is used before the Directories.cmake.in and
  #            Settings.cmake.in files were configured and included.
  set (PROJECT_CONFIG_DIR "${CMAKE_CURRENT_SOURCE_DIR}/config")

  # --------------------------------------------------------------------------
  # add project config directory to CMAKE_MODULE_PATH
  set (CMAKE_MODULE_PATH "${PROJECT_CONFIG_DIR}" ${CMAKE_MODULE_PATH})

  # --------------------------------------------------------------------------
  # Depends.cmake

  # This file is in particular of interest if a dependency is required if
  # certain modules are enabled, but not others.

  # Attention: This function is used before the Directories.cmake.in and
  #            Settings.cmake.in files were configured and included.
  include ("${PROJECT_CONFIG_DIR}/Depends.cmake" OPTIONAL)

  # --------------------------------------------------------------------------
  # required dependencies
  foreach (P IN LISTS PROJECT_DEPENDS)
    basis_find_package ("${P}" REQUIRED)
    basis_use_package  ("${P}" REQUIRED)
  endforeach ()

  # --------------------------------------------------------------------------
  # optional dependencies
  foreach (P IN LISTS PROJECT_OPTIONAL_DEPENDS)
    basis_find_package ("${P}" QUIET)
    basis_use_package  ("${P}")
  endforeach ()

  # --------------------------------------------------------------------------
  # test dependencies
  if (BUILD_TESTING)
    # required test dependencies
    foreach (P IN LISTS PROJECT_TEST_DEPENDS)
      basis_find_package ("${P}") # do not use REQUIRED here to be able to show
      basis_use_package ("${P}")  # error message below
      basis_tokenize_dependency ("${P}" P VER CMPS)
      string (TOUPPER "${P}" U)
      if (NOT ${P}_FOUND AND NOT ${U}_FOUND)
        message (FATAL_ERROR "Could not find package ${P}! It is required by "
                             "the tests of ${PROJECT_NAME}. Either specify "
                             "package location manually and try again or "
                             "disable testing by setting BUILD_TESTING to OFF.")
        
      endif ()
      unset (U)
      unset (VER)
      unset (CMPS)
    endforeach ()
    # optional test dependencies
    foreach (P IN LISTS PROJECT_OPTIONAL_TEST_DEPENDS)
      basis_find_package ("${P}" QUIET)
      basis_use_package ("${P}")
    endforeach ()
  endif ()

  unset (P)

  set (BASIS_SET_TARGET_PROPERTIES_IMPORT FALSE) # see set_target_properties()
endmacro ()

# ============================================================================
# finalization
# ============================================================================

# ----------------------------------------------------------------------------
## @brief Add installation rules for public header files.
macro (basis_install_public_headers)
  # subdirectory of basis.h header file
  basis_library_prefix (_BASIS_H_PREFIX CXX)
  # install public header files from source tree
  foreach (INCLUDE_DIR IN LISTS PROJECT_INCLUDE_DIRS)
    basis_install_directory ("${INCLUDE_DIR}" "${INSTALL_INCLUDE_DIR}" PATTERN "*.in" EXCLUDE)
  endforeach ()
  
  # install configured public header files, excluding BASIS utilities
  file (GLOB_RECURSE _CONFIGURED_PUBLIC_HEADERS "${BINARY_INCLUDE_DIR}/*")
  list (REMOVE_ITEM _CONFIGURED_PUBLIC_HEADERS "${BINARY_INCLUDE_DIR}/${_BASIS_H_PREFIX}basis.h")
  if (_CONFIGURED_PUBLIC_HEADERS)
    basis_install_directory (
      "${BINARY_INCLUDE_DIR}" "${INSTALL_INCLUDE_DIR}"
      REGEX   "/${_BASIS_H_PREFIX}basis\\.h$" EXCLUDE # BASIS utilities header only installed
                                                      # below if included by any other public header
      PATTERN "*.cmake"                       EXCLUDE # e.g., <Name>PublicHeaders.cmake file,
      PATTERN "*.cmake.*"                     EXCLUDE # see basis_configure_public_headers()
    )
  endif ()
  # "parse" public header files to check if C++ BASIS utilities are included
  if (NOT BASIS_INSTALL_PUBLIC_HEADERS_OF_CXX_UTILITIES)
    # get list of all public header files of project
    set (_PUBLIC_HEADERS)
    if (NOT BASIS_CONFIGURE_INCLUDES)
      foreach (INCLUDE_DIR IN LISTS PROJECT_INCLUDE_DIRS)
        file (GLOB_RECURSE __PUBLIC_HEADERS "${INCLUDE_DIR}/*.h")
        list (APPEND _PUBLIC_HEADERS "${__PUBLIC_HEADERS}")
      endforeach ()
      unset (__PUBLIC_HEADERS)
    endif ()
    list (APPEND _PUBLIC_HEADERS ${_CONFIGURED_PUBLIC_HEADERS})
    # check include statements of each public header file
    foreach (_A IN LISTS _PUBLIC_HEADERS)
      basis_utilities_check (_B "${_A}" CXX)
      if (_B)
        set (BASIS_INSTALL_PUBLIC_HEADERS_OF_CXX_UTILITIES TRUE)
        break ()
      endif ()
    endforeach ()
    unset (_PUBLIC_HEADERS)
    unset (_A)
    unset (_B)
  endif ()
  unset (_CONFIGURED_PUBLIC_HEADERS)
  # install public header of BASIS utilities (optional)
  if (BASIS_INSTALL_PUBLIC_HEADERS_OF_CXX_UTILITIES)
    install (
      FILES       "${BINARY_INCLUDE_DIR}/${_BASIS_H_DIR}/basis.h"
      DESTINATION "${INSTALL_INCLUDE_DIR}/${_BASIS_H_PREFIX}"
      COMPONENT   "${BASIS_LIBRARY_COMPONENT}"
    )
  endif ()
endmacro ()


## @}
# end of Doxygen group

# ============================================================================
# root CMakeLists.txt implementation
# ============================================================================

# ----------------------------------------------------------------------------
## @brief Implementation of root <tt>CMakeLists.txt</tt> file of BASIS project.
#
# This macro implements the entire logic of the top-level
# <tt>CMakeLists.txt</tt> file. At first, the project is initialized and the
# BASIS settings configured using the project information given in the
# <tt>BasisProject.cmake</tt> file which must be located in the same directory.
# The, the code in the <tt>CMakeLists.txt</tt> files in the subdirectories is
# executed in order. At the end, the configuration of the build system is
# finalized, including in particular also the addition of custom build targets
# which perform the actual build of custom build targets such as the ones build
# using the MATLAB Compiler.
#
# @sa BasisProject.cmake
# @sa basis_project()
#
# @attention: add_uninstall must be done last and using a add_subdirectory() call
#             such that the code is executed last by the root cmake_install.cmake!
# @ingroup CMakeAPI
macro (basis_project_impl)
  # --------------------------------------------------------------------------
  # set CMAKE_INSTALL_PREFIX to cached invalid value to have
  # basis_initialize_settings() set it to BASIS's default rather than CMake's
  # default even if this is not the first configure run because a previous
  # one was interrupted by an error such as a requird package that was not found
  if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set (CMAKE_INSTALL_PREFIX "" CACHE INTERNAL "Installation prefix." FORCE)
  endif ()

  # --------------------------------------------------------------------------
  # initialize project
  basis_project_initialize ()

  # --------------------------------------------------------------------------
  # load information of modules
  if (NOT PROJECT_IS_MODULE)
    basis_project_modules ()
  endif ()

  if (BASIS_DEBUG)
    basis_dump_variables ("${PROJECT_BINARY_DIR}/VariablesAfterDetectionOfModules.cmake")
  endif ()

  # --------------------------------------------------------------------------
  # Python

  # In case of a Slicer Extension, the UseSlicer.cmake file of Slicer (>= 4.0)
  # will set PYTHON_EXECUTABLE and requires us not to set this variable before
  # the UseSlicer.cmake file has been included. Hence, we set this variable
  # here only if it has not been set by Slicer, but before any PythonInterp
  # dependency declared by this package such that the Python interpreter
  # configured while building BASIS is used to avoid conflicts of different
  # versions used to compile the Python utilities (if BASIS_COMPILE_SCRIPTS
  # was set to ON) and the one used to configure/build this package.
  #
  # Note: The PYTHON_EXECUTABLE variable has to be cached such that
  #       PythonInterp.cmake does not look for the interpreter itself.
  if (BASIS_PYTHON_EXECUTABLE)
    set (
      PYTHON_EXECUTABLE
        "${BASIS_PYTHON_EXECUTABLE}"
      CACHE PATH
        "The Python interpreter."
    )
    mark_as_advanced (PYTHON_EXECUTABLE)
  endif ()
  # Note that PERL_EXECUTABLE and BASH_EXECUTABLE are set in BASISUse.cmake.

  # --------------------------------------------------------------------------
  # find packages

  # any package use file must be included after PROJECT_NAME was set as the
  # imported targets are added to the <Project>_TARGETS property using
  # basis_set_project_property() in add_executable() and add_library()
  basis_use_package (BASIS)
  basis_find_packages ()

  if (BASIS_DEBUG)
    basis_dump_variables ("${PROJECT_BINARY_DIR}/VariablesAfterFindDependencies.cmake")
  endif ()

  # --------------------------------------------------------------------------
  # get interpreter versions - set to invalid version if not available
  if (USE_PythonInterp AND NOT PYTHON_VERSION_STRING)
    basis_get_python_version ()
  endif ()
  if (USE_JythonInterp AND NOT JYTHON_VERSION_STRING)
    basis_get_jython_version ()
  endif ()
  if (USE_Perl AND NOT PERL_VERSION_STRING)
    basis_get_perl_version ()
  endif ()
  if (USE_BASH AND NOT BASH_VERSION_STRING)
    basis_get_bash_version ()
  endif ()
  if (USE_MATLAB AND NOT MATLAB_VERSION_STRING)
    basis_get_matlab_version ()
  endif ()

  if (USE_PythonInterp AND PYTHON_EXECUTABLE AND PYTHON_VERSION_MAJOR EQUAL 0 OR (PYTHON_VERSION_MAJOR EQUAL 1 AND PYTHON_VERSION_MINOR EQUAL 4))
    message (WARNING "Failed to determine Python version! Check if you can run \"${PYTHON_EXECUTABLE} -E\" in a Terminal.")
  endif ()
  if (USE_JythonInterp AND JYTHON_EXECUTABLE AND JYTHON_VERSION_MAJOR EQUAL 0)
    message (WARNING "Failed to determine Jython version! Check if you can run \"${JYTHON_EXECUTABLE}\".")
  endif ()
  if (USE_Perl AND PERL_EXECUTABLE AND PERL_VERSION_MAJOR EQUAL 0)
    message (WARNING "Failed to determine Perl version! Check if you can run \"${PERL_EXECUTABLE}\".")
  endif ()
  if (USE_BASH AND NBASH_EXECUTABLE AND BASH_VERSION_MAJOR EQUAL 0)
    message (WARNING "Failed to determine Bash version! Check if you can run \"${BASH_EXECUTABLE}\".")
  endif ()
  if (USE_MATLAB AND MATLAB_EXECUTABLE AND MATLAB_VERSION_MAJOR EQUAL 0)
    message (WARNING "Failed to determine MATLAB version! Check if you can run \"${MATLAB_EXECUTABLE} -nodesktop -nosplash -r 'version,quit force'\" and try again.")
  endif ()

  # initial set of USE_Python
  # TODO: Consider making this a boolean option
  if (USE_PythonInterp OR USE_JythonInterp)
    set(USE_Python TRUE)
  elseif()
    set(USE_Python FALSE)
  endif()
  
  # --------------------------------------------------------------------------
  # initialize settings
  basis_initialize_settings ()

  # --------------------------------------------------------------------------
  # assertions
  basis_buildtree_asserts ()
  basis_installtree_asserts ()

  # --------------------------------------------------------------------------
  # default script configuration - see basis_configure_script()
  set (BASIS_SCRIPT_CONFIG_FILE "${BINARY_CONFIG_DIR}/BasisScriptConfig.cmake")
  configure_file ("${BASIS_MODULE_PATH}/ScriptConfig.cmake.in" "${BASIS_SCRIPT_CONFIG_FILE}" @ONLY)
  if (EXISTS "${PROJECT_CONFIG_DIR}/ScriptConfig.cmake.in")
    configure_file ("${PROJECT_CONFIG_DIR}/ScriptConfig.cmake.in" "${BINARY_CONFIG_DIR}/ScriptConfig.cmake" @ONLY)
  endif ()

  # --------------------------------------------------------------------------
  # root documentation files
  basis_configure_root_documentation_files ()

  # --------------------------------------------------------------------------
  # enable testing
  if (NOT PROJECT_IS_MODULE)
    include ("${BASIS_MODULE_PATH}/BasisTest.cmake")
    basis_disable_testing_if_no_tests ()
    if (BUILD_TESTING AND NOT EXISTS "${PROJECT_SOURCE_DIR}/CTestConfig.cmake")
      message (WARNING "Missing CTestConfig.cmake file in top directory of source tree!"
                       " You will not be able to submit test results to the CDash dashboard.")
    endif ()
  endif ()

  # --------------------------------------------------------------------------
  # public header files and script libraries

  # dump currently defined CMake variables such that these can be used to
  # configure the .in public header and module files during the build step
  basis_include_directories (BEFORE "${BINARY_INCLUDE_DIR}"
                                    "${PROJECT_INCLUDE_DIRS}"
                                    "${PROJECT_CODE_DIRS}")
  
  option(BASIS_CONFIGURE_PUBLIC_HEADERS "Perform CMake Variable configuration on .h, .hh, .hpp, .hxx, .inl, .txx, .inc headers that end with a .in suffix" OFF)
  mark_as_advanced(BASIS_CONFIGURE_PUBLIC_HEADERS)
  
  if(BASIS_CONFIGURE_PUBLIC_HEADERS)
    basis_configure_public_headers ()
  endif()
  basis_configure_script_libraries ()

  # --------------------------------------------------------------------------
  # subdirectories
  if (BASIS_DEBUG)
    basis_dump_variables ("${PROJECT_BINARY_DIR}/VariablesAfterInitialization.cmake")
  endif ()

  if (PROJECT_SUPER_BUILD OR BASIS_SUPER_BUILD)
    include (${BASIS_MODULE_PATH}/BasisSuperBuild.cmake)
  endif ()

  # build modules
  if (NOT PROJECT_IS_MODULE)
    foreach (MODULE IN LISTS PROJECT_MODULES_ENABLED)
      message (STATUS "Configuring module ${MODULE}...")
      set (PROJECT_IS_MODULE TRUE)
      # Set up modules, checking the super build special case first. 
      # By default the else case with add_subdirectory() will be called.
      # note: ${MODULE_${MODULE}_SOURCE_DIR} is the location of the module source code
      #       "${MODULE_${MODULE}_BINARY_DIR}" is the build directory for the module
      if (PROJECT_SUPER_BUILD OR BASIS_SUPER_BUILD)
        basis_super_build (${MODULE}) # automatically uses: "${MODULE_${MODULE}_SOURCE_DIR}" "${MODULE_${MODULE}_BINARY_DIR}"
      else ()
        add_subdirectory ("${MODULE_${MODULE}_SOURCE_DIR}" "${MODULE_${MODULE}_BINARY_DIR}")
      endif ()
      set (PROJECT_IS_MODULE FALSE)
      message (STATUS "Configuring module ${MODULE}... - done")
    endforeach ()
  endif ()

  # add default project directories to list of subdirectories
  # (in reverse order always at beginning of list)
  if (BUILD_EXAMPLE)
    list (INSERT PROJECT_SUBDIRS 0 "${PROJECT_EXAMPLE_DIR}")
  endif ()
  if (BUILD_TESTING)
    list (INSERT PROJECT_SUBDIRS 0 "${PROJECT_TESTING_DIR}")
  endif ()
  list (INSERT PROJECT_SUBDIRS 0 "${PROJECT_DATA_DIR}")
  list (INSERT PROJECT_SUBDIRS 0 "${PROJECT_CODE_DIRS}")

  # process subdirectories
  foreach (SUBDIR IN LISTS PROJECT_SUBDIRS)
    if (NOT IS_ABSOLUTE "${SUBDIR}")
      set (SUBDIR "${CMAKE_CURRENT_SOURCE_DIR}/${SUBDIR}")
    endif ()
    if (IS_DIRECTORY "${SUBDIR}")
      add_subdirectory ("${SUBDIR}")
    endif ()
  endforeach ()

  if (BASIS_DEBUG)
    basis_dump_variables ("${PROJECT_BINARY_DIR}/VariablesAfterSubdirectories.cmake")
  endif ()

  # --------------------------------------------------------------------------
  # write convenience file to setup MATLAB environment
  if (MATLAB_FOUND)
    basis_create_addpaths_mfile ()
  endif ()

  # --------------------------------------------------------------------------
  # copy project properties of modules
  if (NOT PROJECT_IS_MODULE)
    # copy properties of modules
    foreach (M IN LISTS PROJECT_MODULES_ENABLED)
      foreach (P IN ITEMS IMPORTED_TARGETS
                          IMPORTED_TYPES
                          IMPORTED_LOCATIONS
                          IMPORTED_RANKS
                          PROJECT_INCLUDE_DIRS
                          PROJECT_LINK_DIRS
                          BUNDLE_LINK_DIRS
                          TARGETS
                          CUSTOM_EXPORT_TARGETS
                          TEST_EXPORT_TARGETS)
        basis_get_project_property (V ${M} ${P})
        basis_set_project_property (APPEND PROPERTY ${P} ${V})
      endforeach ()
    endforeach ()
    foreach (L IN ITEMS CXX PYTHON PERL BASH)
      foreach (M IN LISTS PROJECT_MODULES_ENABLED)
        basis_get_project_property (P ${M} PROJECT_USES_${L}_UTILITIES)
        if (P)
          basis_set_project_property (PROPERTY PROJECT_USES_${L}_UTILITIES TRUE)
          break ()
        endif ()
      endforeach ()
    endforeach ()
  endif () 

  if (NOT BASIS_BUILD_ONLY)

    # --------------------------------------------------------------------------
    # finalize custom targets
    if (NOT PROJECT_IS_MODULE OR PROJECT_IS_SUBPROJECT)
      # configure the BASIS utilities
      basis_configure_utilities ()
      # add missing build commands for custom targets
      basis_finalize_targets ()
      # add build target for missing __init__.py files of Python package
      if (USE_Python)
        basis_add_init_py_target ()
      endif()
    endif ()
    
    # --------------------------------------------------------------------------
    # add installation rules for public headers
    basis_install_public_headers ()
    
    # --------------------------------------------------------------------------
    # generate configuration files
    include ("${BASIS_MODULE_PATH}/GenerateConfig.cmake")
    
    # ----------------------------------------------------------------------------
    # change log
    basis_add_changelog ()
    
    # --------------------------------------------------------------------------
    # build/install package documentation
    #
    # This is done after all files which may be interesting for inclusion
    # in the documentation are generated. In particular, this has to be done
    # after the configuration of the BASIS utilities.
    if (IS_DIRECTORY "${PROJECT_DOC_DIR}" AND BUILD_DOCUMENTATION)
      add_subdirectory ("${PROJECT_DOC_DIR}")
    endif ()

    # --------------------------------------------------------------------------
    # package software
    if ((NOT PROJECT_IS_MODULE OR PROJECT_IS_SUBPROJECT))
      include ("${BASIS_MODULE_PATH}/BasisPack.cmake")
    endif()
 
    # --------------------------------------------------------------------------
    # add installation rule to register package with CMake
    if (BASIS_REGISTER AND NOT PROJECT_IS_MODULE AND PROJECT_VERSION VERSION_GREATER 0.0.0)
      basis_register_package ()
    endif ()
 
    # --------------------------------------------------------------------------
    # uninstaller
    if (NOT PROJECT_IS_MODULE)
      # add uninstall target
      basis_add_uninstall ()
      ## add code to generate uninstaller at the end of the installation
      #
      # @attention: add_uninstall must be done last and using a add_subdirectory() call
      #             such that the code is executed last by the root cmake_install.cmake!
      add_subdirectory ("${BASIS_MODULE_PATH}/uninstall" "${PROJECT_BINARY_DIR}/uninstall")
    endif ()

  endif ()

  if (BASIS_DEBUG)
    basis_dump_variables ("${PROJECT_BINARY_DIR}/VariablesAfterFinalization.cmake")
  endif ()
  
endmacro ()
