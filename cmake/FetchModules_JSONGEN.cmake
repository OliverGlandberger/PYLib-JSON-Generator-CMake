function(jsongen_fetch_and_configure_module repo_name namespace git_repo git_tag output_dir_var)
    include(FetchContent)
    set(FETCHCONTENT_QUIET OFF)

    FetchContent_Declare(
        ${repo_name}
        GIT_REPOSITORY ${git_repo}
        GIT_TAG        ${git_tag}
    )
    set(${output_dir_var} "${CMAKE_BINARY_DIR}/modules/${repo_name}")

    FetchContent_MakeAvailable(${repo_name})
    FetchContent_GetProperties(${repo_name})
    if(${repo_name}_POPULATED)
        message(STATUS "Successfully populated ${repo_name}")
        message(STATUS "Source Dir: ${${repo_name}_SOURCE_DIR}")
        message(STATUS "Binary Dir: ${${repo_name}_BINARY_DIR}")

        # If you want to copy subprojects for JSONGen as well, define a
        # "copy_fetched_python_project" function similarly, but name it differently
        # (e.g. jsongen_copy_fetched_python_project) and call it here
        # if(JSONGEN_IS_ROOT_PROJECT)
        #   jsongen_copy_fetched_python_project(
        #       ${repo_name}
        #       "${${repo_name}_SOURCE_DIR}"
        #   )
        # endif()
    else()
        message(FATAL_ERROR "Failed to populate ${repo_name}")
    endif()
endfunction()

function(jsongen_fetch_requirements_file file_path)
    if(NOT EXISTS "${file_path}")
        message(STATUS "No fetch_requirements.txt found at: ${file_path}")
        return()
    endif()

    message(STATUS "Reading JSONGen fetch requirements from: ${file_path}")
    file(STRINGS "${file_path}" LINES)

    foreach(LINE ${LINES})
        string(STRIP "${LINE}" LINE)
        if(LINE MATCHES "^(#|$)")
            continue()
        endif()

        string(REPLACE "|" ";" TOKENS "${LINE}")
        list(LENGTH TOKENS NUM_TOKENS)
        if(NOT NUM_TOKENS EQUAL 4)
            message(FATAL_ERROR "Invalid line:\n  ${LINE}")
        endif()

        list(GET TOKENS 0 REPO_NAME)
        list(GET TOKENS 1 REPO_NAMESPACE)
        list(GET TOKENS 2 GIT_REPO)
        list(GET TOKENS 3 GIT_TAG)

        # Skip self-fetch if referencing "PYLib-JSONGenerator" or "pylib-jsongenerator"
        if("${REPO_NAME}" STREQUAL "PYLib-JSONGenerator"
           OR "${REPO_NAME}" STREQUAL "pylib-jsongenerator")
            message(STATUS "Skipping self-fetch for ${REPO_NAME}")
            continue()
        endif()

        set(OUTPUT_DIR_VAR "${REPO_NAME}_OUTPUT_DIR")
        jsongen_fetch_and_configure_module(
            "${REPO_NAME}" "${REPO_NAMESPACE}"
            "${GIT_REPO}"  "${GIT_TAG}"
            "${OUTPUT_DIR_VAR}"
        )
    endforeach()
endfunction()

# If JSONGen is built standalone as root, parse its own fetch_requirements.txt
if(JSONGEN_IS_ROOT_PROJECT)
    jsongen_fetch_requirements_file("${${JSONGEN_NAMESPACE}_FETCH_REQUIREMENTS_FILE}")
endif()
