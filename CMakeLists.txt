CMAKE_MINIMUM_REQUIRED( VERSION 3.9.0 )
PROJECT( lmprof C )

INCLUDE(CheckCCompilerFlag)
IF( CMAKE_C_COMPILER_ID MATCHES "Clang" )
  SET(CMAKE_COMPILER_IS_CLANG 1) # using Clang or AppleClang
ENDIF()

# Lua
IF( NOT LUA_INCLUDE_DIR OR (WIN32 AND NOT LUA_LIBRARIES) )
  SET( CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/" )
  FIND_PACKAGE( Lua REQUIRED )
ENDIF()

################################################################################
# Path/Library Setup.
################################################################################

SET(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH};${CMAKE_CURRENT_SOURCE_DIR}/etc/")
IF( NOT CMAKE_BUILD_TYPE )
  SET(CMAKE_BUILD_TYPE "Release" CACHE STRING "Choose the type of build, \
  options are: Debug Release RelWithDebInfo MinSizeRel." FORCE)
ENDIF()

SET(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/" CACHE STRING "Library build output directory")
SET(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/")
SET(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/")

SET(CMAKE_INSTALL_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib" CACHE PATH "Installation directory for libraries")
SET(CMAKE_INSTALL_INC_DIR "${CMAKE_INSTALL_PREFIX}/include" CACHE PATH "Installation directory for headers")

################################################################################
# Compiler Setup
################################################################################

OPTION(LUA_BIT32 "32bit compile" OFF)
OPTION(LUA_NATIVE_ARCH "Enable compiler optimizations for the native processor architecture" ON)

SET(CMAKE_POSITION_INDEPENDENT_CODE ON)

# Windows systems
IF( MSVC )
  OPTION(LUA_USE_WINDOWS "Windows specific build" ON)
  OPTION(LUA_BUILD_AS_DLL "Build Lua library as DLL" ON)
  IF( NOT( ${CMAKE_COMPILER_IS_CLANG} ) )
    MESSAGE(WARNING "MSVC detected! For MSVC/msbuild environments, it is advised to use the LLVM/ClangCL toolset")
  ENDIF()

  IF(MSVC AND NOT "${CMAKE_BUILD_TYPE}" MATCHES "Debug")
    SET(MSVC_OPT_FLAG "/Ox /DNDEBUG")
  ELSE()
    SET(MSVC_OPT_FLAG "")
  ENDIF()

  IF( LUA_BIT32 )
    ADD_COMPILE_DEFINITIONS(LUA_32BITS=1)
  ENDIF()

  IF( LUA_NATIVE_ARCH )
    CHECK_C_COMPILER_FLAG("/arch:AVX2" COMPILER_OPT_ARCH_AVX2_SUPPORTED)
    IF( LUA_NATIVE_ARCH AND COMPILER_OPT_ARCH_AVX2_SUPPORTED )
      ADD_COMPILE_OPTIONS(/arch:AVX2)
    ENDIF()
  ENDIF()

  ADD_COMPILE_OPTIONS(/nologo /Zc:__cplusplus)
  ADD_COMPILE_DEFINITIONS(NOMINMAX)
  ADD_COMPILE_DEFINITIONS(_CRT_SECURE_NO_DEPRECATE)
  ADD_COMPILE_DEFINITIONS(_CRT_NONSTDC_NO_DEPRECATE)

  SET(LUA_C_FLAGS "${MSVC_OPT_FLAG} /Ob2 /Oi /Ot /GT /GF /GS- /MP /EHsc /GL")
  SET(LUA_REL_FLAGS "${LUA_REL_FLAGS} /GL")
  SET(LUA_LINKFLAGS "${LUA_LINKFLAGS} /LTCG")

  # Visual Studio 2019 feature
  CHECK_C_COMPILER_FLAG("/Ob3" COMPILER_OPT_OB3)
  IF( COMPILER_OPT_OB3 )
    STRING(REGEX REPLACE "[-/]Ob[1-4]" "" CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE}")
    STRING(REGEX REPLACE "[-/]Ob[1-4]" "" CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE}")
    STRING(REGEX REPLACE "[-/]Ob[1-4]" "" CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO}")
    STRING(REGEX REPLACE "[-/]Ob[1-4]" "" CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")
    STRING(REPLACE "/Ob2" "/Ob3" LUA_C_FLAGS "${LUA_C_FLAGS}")

    SET(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} /Ob3")
    SET(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /Ob3")
  ENDIF()

  SET(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} ${LUA_C_FLAGS} ${LUA_REL_FLAGS} /Oy")
  SET(CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO} ${LUA_C_FLAGS} ${LUA_REL_FLAGS} /Zi")

  SET(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} ${LUA_C_FLAGS} ${LUA_REL_FLAGS} /Oy")
  SET(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO} ${LUA_C_FLAGS} ${LUA_REL_FLAGS} /Zi")

  SET(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS_RELEASE} ${LUA_LINKFLAGS}")
  SET(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} ${LUA_LINKFLAGS}")
  SET(CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO "${CMAKE_EXE_LINKER_FLAGS_RELWITHDEBINFO} ${LUA_LINKFLAGS}")

  SET(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} ${LUA_LINKFLAGS}")
  SET(CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO "${CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO} ${LUA_LINKFLAGS}")

  SET(CMAKE_MODULE_LINKER_FLAGS_RELEASE "${CMAKE_MODULE_LINKER_FLAGS_RELEASE} ${LUA_LINKFLAGS}")
  SET(CMAKE_MODULE_LINKER_FLAGS_RELWITHDEBINFO "${CMAKE_MODULE_LINKER_FLAGS_RELWITHDEBINFO} ${LUA_LINKFLAGS}")

  # W4 to turn compiler warnings all the way up...
  STRING(REGEX REPLACE "[-/]W[1-4]" "" CMAKE_C_FLAGS "${CMAKE_C_FLAGS}")
  STRING(REGEX REPLACE "[-/]W[1-4]" "" CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}")
  SET(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /W3")
  SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /W3")

# Posix systems (including msys2/cygwin)
ELSE()
  OPTION(LUA_USE_POSIX "Use POSIX functionality" ON)

  IF( APPLE )
    SET(PLAT "macosx")
    SET(LINK_FLAGS "-bundle -undefined dynamic_lookup -all_load")
  ENDIF()

  IF( LUA_BIT32 )
    ADD_COMPILE_DEFINITIONS(LUA_32BITS=1)
    IF( "${CMAKE_C_COMPILER_ID}" STREQUAL "GNU" OR CMAKE_COMPILER_IS_CLANG )
      SET(CMAKE_C_FLAGS "-m32 ${CMAKE_C_FLAGS}")
      SET(CMAKE_CXX_FLAGS "-m32 ${CMAKE_CXX_FLAGS}")
    ENDIF()
  ENDIF()

  # Compile everything with -march=native
  IF( LUA_NATIVE_ARCH )
    CHECK_C_COMPILER_FLAG("-march=native" COMPILER_OPT_ARCH_NATIVE_SUPPORTED)
    IF( LUA_NATIVE_ARCH AND COMPILER_OPT_ARCH_NATIVE_SUPPORTED )
      ADD_COMPILE_OPTIONS(-march=native)
    ENDIF()
  ENDIF()

  # Temporary fix: CMake no longer defines WIN32 on MSYS.
  IF( CYGWIN OR MSYS )
    SET(LUA_BUILD_AS_DLL ON)
    ADD_COMPILE_DEFINITIONS(_WIN32)
  ENDIF()

  # Compiler options taken from Lua: lua/blob/master/makefile
  ADD_COMPILE_OPTIONS(
    -Wall -Wextra -Wsign-compare -Wundef -Wwrite-strings -Wdisabled-optimization
    -Wno-inline -Wunused-parameter -Wno-comment -Wno-unused-function
    -Wno-array-bounds -Wno-sign-conversion -Wformat=2
    # -Wshadow
    # -Werror
    # -Wconversion
    # -Wsign-conversion
    # -Wcast-qual
  )

  IF (NOT CMAKE_C_COMPILER_ID STREQUAL "Intel")
    ADD_COMPILE_OPTIONS(
        -Wredundant-decls -Wdouble-promotion -Wstrict-overflow=2
        -Wno-format-nonliteral
    )
  ENDIF()

  IF( CMAKE_COMPILER_IS_CLANG )
    ADD_COMPILE_OPTIONS(-ferror-limit=5 -fno-common -Wno-deprecated
      # Clang Everything support;
      #-Weverything
      #-Wno-gnu-zero-variadic-macro-arguments
      #-Wno-covered-switch-default
      #-Wno-reserved-id-macro
      #-Wno-unused-macros
      #-Wno-padded
      #-Wno-old-style-cast
      #-Wno-extra-semi-stmt
      #-Wno-c++98-compat-pedantic
      #-Wno-zero-as-null-pointer-constant
      #-Wno-gnu-anonymous-struct
      #-Wno-gnu-label-as-value
      #-Wno-nested-anon-types
      #-Wno-enum-enum-conversion
    )
  ELSEIF( CMAKE_COMPILER_IS_GNUCC )
    ADD_COMPILE_OPTIONS(-fmax-errors=5 -Wduplicated-cond -Wrestrict -Wlogical-op
      -Wno-aggressive-loop-optimizations
      -Wno-ignored-qualifiers
      #-Wnull-dereference
      #-Wduplicated-branches
    )
  ENDIF()

  # On POSIX Lua links to standard math library "m"
  IF( LUA_USE_POSIX )
    ADD_COMPILE_DEFINITIONS(LUA_USE_POSIX)
    LIST(APPEND LIBS m)
  ENDIF()
ENDIF()

SET(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG}")
SET(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE}")
SET(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO}")
SET(CMAKE_CXX_FLAGS_MINSIZEREL "${CMAKE_C_FLAGS_MINSIZEREL}")

################################################################################
# Build Options
################################################################################

OPTION(LUA_COMPILED_AS_HPP "Library compiled for Lua with C++ linkage" OFF)
OPTION(LUA_INCLUDE_TEST "Include ltests.h" OFF)
OPTION(LMPROF_BUILTIN "Link against internal Lua headers" OFF)
OPTION(LMPROF_FORCE_LOGGER "Force enable the debug logger" OFF)
OPTION(LMPROF_RDTSC "Use the rdtsc (processor time stamp) instruction for timing" OFF)
OPTION(LMPROF_FILE_API "Enable the usage of luaL_loadfile and other File IO. Otherwise, the Lua runtime is in charge of all serialization." ON)
OPTION(LMPROF_HASH_SPLITMIX "Use a splitmix inspired hashing algorithm storing parent/child relationship structures" ON)
OPTION(LMPROF_USE_STRHASH "If enabled, use the luaS_hash implementation. Otherwise, use jenkins-one-at-a-time for aggregating profile records." OFF)
OPTION(LMPROF_RAW_CALIBRATION "Do not modify the calibration overhead. By default the calibration data is halved to ensure most/if-not-all potential variability is accounted for." OFF)

SET(LMPROF_STACK_SIZE CACHE STRING "Maximum size of each coroutines profiler stack")
SET(LMPROF_HASH_SIZE CACHE STRING "Default number of buckets in a hash table")
SET(TRACE_EVENT_PAGE_SIZE CACHE STRING "The default TraceEventPage size")

IF( CMAKE_BUILD_TYPE STREQUAL Debug )
  SET(LUA_INCLUDE_TEST ON)
ENDIF()

IF( LUA_COMPILED_AS_HPP )
  ADD_COMPILE_DEFINITIONS(LUA_COMPILED_AS_HPP)
ENDIF()

IF( LUA_INCLUDE_TEST )
  ADD_COMPILE_DEFINITIONS(LUA_USER_H="ltests.h")
ENDIF()

IF( LMPROF_BUILTIN )
  ADD_COMPILE_DEFINITIONS(LMPROF_BUILTIN)
ENDIF()

IF( LMPROF_FILE_API )
  ADD_COMPILE_DEFINITIONS(LMPROF_FILE_API)
ENDIF()

IF( LMPROF_USE_STRHASH )
  ADD_COMPILE_DEFINITIONS(LMPROF_USE_STRHASH)
ENDIF()

IF( LMPROF_RAW_CALIBRATION )
  ADD_COMPILE_DEFINITIONS(LMPROF_RAW_CALIBRATION)
ENDIF()

IF( LMPROF_STACK_SIZE )
  ADD_COMPILE_DEFINITIONS(LMPROF_MAXSTACK=${LMPROF_STACK_SIZE})
ENDIF()

IF( LMPROF_HASH_SPLITMIX )
  ADD_COMPILE_DEFINITIONS(LMPROF_HASH_SPLITMIX)
ENDIF()

IF( LMPROF_HASH_SIZE )
  ADD_COMPILE_DEFINITIONS(LMPROF_HASH_SIZE=${LMPROF_HASH_SIZE})
ENDIF()

IF( TRACE_EVENT_PAGE_SIZE )
  ADD_COMPILE_DEFINITIONS(TRACE_EVENT_PAGE_SIZE=${TRACE_EVENT_PAGE_SIZE})
ENDIF()

################################################################################
# Compilation
################################################################################

INCLUDE_DIRECTORIES(${LUA_INCLUDE_DIR})
FILE(GLOB_RECURSE sourceFiles ./src/*.cpp ./src/*.c)
FILE(GLOB_RECURSE headerFiles ./src/*.hpp ./src/*.h)
SET (SOURCES ${sourceFiles})

SET(SRC_LMPROF ${SOURCES} )
SET(PUB_LMPROF src/lmprof_conf.h src/lmprof_lib.h)
SET(PUB_LMPROF_UTILS src/collections/lmprof_hash.h src/collections/lmprof_record.h src/collections/lmprof_stack.h src/collections/lmprof_traceevent.h)

IF( LUA_COMPILED_AS_HPP )
  SET_SOURCE_FILES_PROPERTIES(${SRC_LMPROF} PROPERTIES LANGUAGE CXX )
ELSE()
  SET_SOURCE_FILES_PROPERTIES(${SRC_LMPROF} PROPERTIES LANGUAGE C )
ENDIF()

ADD_LIBRARY (lmprof MODULE ${SOURCES})

SET_TARGET_PROPERTIES(lmprof PROPERTIES PREFIX "")
SET_TARGET_PROPERTIES(lmprof PROPERTIES OUTPUT_NAME "lmprof")
IF( LUA_BIT32 AND NOT MSVC )
  SET_TARGET_PROPERTIES(lmprof PROPERTIES COMPILE_FLAGS "-m32" LINK_FLAGS "-m32")
ENDIF()

IF( LINK_FLAGS )
  SET_TARGET_PROPERTIES(lmprof PROPERTIES LINK_FLAGS "${LINK_FLAGS}")
ENDIF()

IF( LUA_BUILD_AS_DLL )
  TARGET_COMPILE_DEFINITIONS(lmprof PUBLIC LUA_BUILD_AS_DLL)
ENDIF()

# Win32 modules need to be linked to the Lua library.
IF( WIN32 OR CYGWIN OR MSYS )
  TARGET_INCLUDE_DIRECTORIES(lmprof PRIVATE ${INCLUDE_DIRECTORIES})
  TARGET_LINK_LIBRARIES(lmprof ${LUA_LIBRARIES})
ENDIF()

IF( CMAKE_INSTALL_PREFIX )
  INSTALL(TARGETS lmprof DESTINATION "${CMAKE_INSTALL_PREFIX}/lib")
ENDIF(CMAKE_INSTALL_PREFIX)

################################################################################
# Install
################################################################################

# Do not allow installation if including test builds
SET(SKIP_INSTALL SKIP_INSTALL_ALL OR LUA_INCLUDE_TEST)

IF( NOT SKIP_INSTALL_HEADERS AND NOT ${SKIP_INSTALL} )
  INSTALL(FILES ${PUB_LMPROF} DESTINATION "${CMAKE_INSTALL_INC_DIR}")
  INSTALL(FILES ${PUB_LMPROF_UTILS} DESTINATION "${CMAKE_INSTALL_INC_DIR}/collections")
ENDIF()

IF( NOT SKIP_INSTALL_LIBRARIES AND NOT ${SKIP_INSTALL} )
  IF( UNIX AND NOT APPLE )
    SET_TARGET_PROPERTIES(lmprof PROPERTIES INSTALL_RPATH "${CMAKE_INSTALL_LIB_DIR}" )
  ENDIF()

  INSTALL(TARGETS lmprof
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIB_DIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIB_DIR}
  )
ENDIF()
