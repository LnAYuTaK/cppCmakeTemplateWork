include(cmake/SystemLink.cmake)
include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


macro(cppCmakeTemplateWork_supports_sanitizers)
  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)
    set(SUPPORTS_UBSAN ON)
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    set(SUPPORTS_ASAN ON)
  endif()
endmacro()

macro(cppCmakeTemplateWork_setup_options)
  option(cppCmakeTemplateWork_ENABLE_HARDENING "Enable hardening" ON)
  option(cppCmakeTemplateWork_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    cppCmakeTemplateWork_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    cppCmakeTemplateWork_ENABLE_HARDENING
    OFF)

  cppCmakeTemplateWork_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR cppCmakeTemplateWork_PACKAGING_MAINTAINER_MODE)
    option(cppCmakeTemplateWork_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(cppCmakeTemplateWork_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(cppCmakeTemplateWork_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(cppCmakeTemplateWork_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(cppCmakeTemplateWork_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(cppCmakeTemplateWork_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(cppCmakeTemplateWork_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(cppCmakeTemplateWork_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(cppCmakeTemplateWork_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(cppCmakeTemplateWork_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(cppCmakeTemplateWork_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(cppCmakeTemplateWork_ENABLE_PCH "Enable precompiled headers" OFF)
    option(cppCmakeTemplateWork_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(cppCmakeTemplateWork_ENABLE_IPO "Enable IPO/LTO" ON)
    option(cppCmakeTemplateWork_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(cppCmakeTemplateWork_ENABLE_USER_LINKER "Enable user-selected linker" OFF)
    option(cppCmakeTemplateWork_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(cppCmakeTemplateWork_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(cppCmakeTemplateWork_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(cppCmakeTemplateWork_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(cppCmakeTemplateWork_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(cppCmakeTemplateWork_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(cppCmakeTemplateWork_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(cppCmakeTemplateWork_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(cppCmakeTemplateWork_ENABLE_PCH "Enable precompiled headers" OFF)
    option(cppCmakeTemplateWork_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      cppCmakeTemplateWork_ENABLE_IPO
      cppCmakeTemplateWork_WARNINGS_AS_ERRORS
      cppCmakeTemplateWork_ENABLE_USER_LINKER
      cppCmakeTemplateWork_ENABLE_SANITIZER_ADDRESS
      cppCmakeTemplateWork_ENABLE_SANITIZER_LEAK
      cppCmakeTemplateWork_ENABLE_SANITIZER_UNDEFINED
      cppCmakeTemplateWork_ENABLE_SANITIZER_THREAD
      cppCmakeTemplateWork_ENABLE_SANITIZER_MEMORY
      cppCmakeTemplateWork_ENABLE_UNITY_BUILD
      cppCmakeTemplateWork_ENABLE_CLANG_TIDY
      cppCmakeTemplateWork_ENABLE_CPPCHECK
      cppCmakeTemplateWork_ENABLE_COVERAGE
      cppCmakeTemplateWork_ENABLE_PCH
      cppCmakeTemplateWork_ENABLE_CACHE)
  endif()

  cppCmakeTemplateWork_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (cppCmakeTemplateWork_ENABLE_SANITIZER_ADDRESS OR cppCmakeTemplateWork_ENABLE_SANITIZER_THREAD OR cppCmakeTemplateWork_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(cppCmakeTemplateWork_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(cppCmakeTemplateWork_global_options)
  if(cppCmakeTemplateWork_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    cppCmakeTemplateWork_enable_ipo()
  endif()

  cppCmakeTemplateWork_supports_sanitizers()

  if(cppCmakeTemplateWork_ENABLE_HARDENING AND cppCmakeTemplateWork_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR cppCmakeTemplateWork_ENABLE_SANITIZER_UNDEFINED
       OR cppCmakeTemplateWork_ENABLE_SANITIZER_ADDRESS
       OR cppCmakeTemplateWork_ENABLE_SANITIZER_THREAD
       OR cppCmakeTemplateWork_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${cppCmakeTemplateWork_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${cppCmakeTemplateWork_ENABLE_SANITIZER_UNDEFINED}")
    cppCmakeTemplateWork_enable_hardening(cppCmakeTemplateWork_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(cppCmakeTemplateWork_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(cppCmakeTemplateWork_warnings INTERFACE)
  add_library(cppCmakeTemplateWork_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  cppCmakeTemplateWork_set_project_warnings(
    cppCmakeTemplateWork_warnings
    ${cppCmakeTemplateWork_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  if(cppCmakeTemplateWork_ENABLE_USER_LINKER)
    include(cmake/Linker.cmake)
    configure_linker(cppCmakeTemplateWork_options)
  endif()

  include(cmake/Sanitizers.cmake)
  cppCmakeTemplateWork_enable_sanitizers(
    cppCmakeTemplateWork_options
    ${cppCmakeTemplateWork_ENABLE_SANITIZER_ADDRESS}
    ${cppCmakeTemplateWork_ENABLE_SANITIZER_LEAK}
    ${cppCmakeTemplateWork_ENABLE_SANITIZER_UNDEFINED}
    ${cppCmakeTemplateWork_ENABLE_SANITIZER_THREAD}
    ${cppCmakeTemplateWork_ENABLE_SANITIZER_MEMORY})

  set_target_properties(cppCmakeTemplateWork_options PROPERTIES UNITY_BUILD ${cppCmakeTemplateWork_ENABLE_UNITY_BUILD})

  if(cppCmakeTemplateWork_ENABLE_PCH)
    target_precompile_headers(
      cppCmakeTemplateWork_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(cppCmakeTemplateWork_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    cppCmakeTemplateWork_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(cppCmakeTemplateWork_ENABLE_CLANG_TIDY)
    cppCmakeTemplateWork_enable_clang_tidy(cppCmakeTemplateWork_options ${cppCmakeTemplateWork_WARNINGS_AS_ERRORS})
  endif()

  if(cppCmakeTemplateWork_ENABLE_CPPCHECK)
    cppCmakeTemplateWork_enable_cppcheck(${cppCmakeTemplateWork_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(cppCmakeTemplateWork_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    cppCmakeTemplateWork_enable_coverage(cppCmakeTemplateWork_options)
  endif()

  if(cppCmakeTemplateWork_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(cppCmakeTemplateWork_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(cppCmakeTemplateWork_ENABLE_HARDENING AND NOT cppCmakeTemplateWork_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR cppCmakeTemplateWork_ENABLE_SANITIZER_UNDEFINED
       OR cppCmakeTemplateWork_ENABLE_SANITIZER_ADDRESS
       OR cppCmakeTemplateWork_ENABLE_SANITIZER_THREAD
       OR cppCmakeTemplateWork_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    cppCmakeTemplateWork_enable_hardening(cppCmakeTemplateWork_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
