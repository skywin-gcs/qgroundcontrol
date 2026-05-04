# Test for Features module
add_qgc_test(FeaturesUnitTest LABELS Unit Features TIMEOUT ${QGC_TEST_TIMEOUT_UNIT})

target_sources(${CMAKE_PROJECT_NAME}
    PRIVATE
        FeaturesTest.cc
)

target_include_directories(${CMAKE_PROJECT_NAME}
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
)
