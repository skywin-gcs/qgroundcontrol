target_sources(${CMAKE_PROJECT_NAME}
    PRIVATE
        MissionAssistant.cc
        MissionAssistant.h
        MapProvider.h
        TileCache.cc
        TileCache.h
        FlightAnalytics.cc
        FlightAnalytics.h
)

target_include_directories(${CMAKE_PROJECT_NAME}
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
)
