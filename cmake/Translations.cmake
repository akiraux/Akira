# Translations.cmake, CMake macros written for Marlin, feel free to re-use them
include(CMakeParseArguments)

macro (add_translations_directory NLS_PACKAGE)
    add_custom_target (i18n ALL COMMENT “Building i18n messages.”)
    find_program (MSGFMT_EXECUTABLE msgfmt)
    # be sure that all languages are present
    # Using all usual languages code from https://www.gnu.org/software/gettext/manual/html_node/Language-Codes.html#Language-Codes
    # Rare language codes should be added on-demand.
    set (LANGUAGES_NEEDED aa ab ae af ak am an ar as ast av ay az ba be bg bh bi bm bn bo br bs ca ce ch ckb co cr cs cu cv cy da de dv dz ee el en_AU en_CA en_GB eo es et eu fa ff fi fj fo fr fr_CA fy ga gd gl gn gu gv ha he hi ho hr ht hu hy hz ia id ie ig ii ik io is it iu ja jv ka kg ki kj kk kl km kn ko kr ks ku kv kw ky la lb lg li ln lo lt lu lv mg mh mi mk ml mn mo mr ms mt my na nb nd ne ng nl nn no nr nv ny oc oj om or os pa pi pl ps pt pt_BR qu rm rn ro ru rue rw sa sc sd se sg si sk sl sm sma sn so sq sr ss st su sv sw ta te tg th ti tk tl tn to tr ts tt tw ty ug uk ur uz ve vi vo wa wo xh yi yo za zh zh_CN zh_HK zh_TW zu)
    foreach (LANGUAGE_NEEDED ${LANGUAGES_NEEDED})
        create_po_file (${LANGUAGE_NEEDED})
    endforeach (LANGUAGE_NEEDED ${LANGUAGES_NEEDED})
    # generate .mo from .po
    file (GLOB PO_FILES ${CMAKE_CURRENT_SOURCE_DIR}/*.po)
    foreach (PO_INPUT ${PO_FILES})
        get_filename_component (PO_INPUT_BASE ${PO_INPUT} NAME_WE)
        set (MO_OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${PO_INPUT_BASE}.mo)
        add_custom_command (TARGET i18n COMMAND ${MSGFMT_EXECUTABLE} -o ${MO_OUTPUT} ${PO_INPUT})

        install (FILES ${MO_OUTPUT} DESTINATION
            share/locale/${PO_INPUT_BASE}/LC_MESSAGES
            RENAME ${NLS_PACKAGE}.mo)
    endforeach (PO_INPUT ${PO_FILES})
endmacro (add_translations_directory)

# Apply the right default template.
macro (create_po_file LANGUAGE_NEEDED)
    set (FILE ${CMAKE_CURRENT_SOURCE_DIR}/${LANGUAGE_NEEDED}.po)
    if (NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${LANGUAGE_NEEDED}.po)
        file (APPEND ${FILE} "msgid \"\"\n")
        file (APPEND ${FILE} "msgstr \"\"\n")
        file (APPEND ${FILE} "\"MIME-Version: 1.0\\n\"\n")
        file (APPEND ${FILE} "\"Content-Type: text/plain; charset=UTF-8\\n\"\n")

        if ("${LANGUAGE_NEEDED}" STREQUAL "ja"
            OR "${LANGUAGE_NEEDED}" STREQUAL "vi"
            OR "${LANGUAGE_NEEDED}" STREQUAL "ko")
                file (APPEND ${FILE} "\"Plural-Forms: nplurals=2; plural=n == 1 ? 0 : 1;\\n\"\n")
        elseif ("${LANGUAGE_NEEDED}" STREQUAL "en"
            OR "${LANGUAGE_NEEDED}" STREQUAL "de"
            OR "${LANGUAGE_NEEDED}" STREQUAL "nl"
            OR "${LANGUAGE_NEEDED}" STREQUAL "sv"
            OR "${LANGUAGE_NEEDED}" STREQUAL "nb"
            OR "${LANGUAGE_NEEDED}" STREQUAL "nn"
            OR "${LANGUAGE_NEEDED}" STREQUAL "nb"
            OR "${LANGUAGE_NEEDED}" STREQUAL "no"
            OR "${LANGUAGE_NEEDED}" STREQUAL "fo"
            OR "${LANGUAGE_NEEDED}" STREQUAL "es"
            OR "${LANGUAGE_NEEDED}" STREQUAL "pt"
            OR "${LANGUAGE_NEEDED}" STREQUAL "it"
            OR "${LANGUAGE_NEEDED}" STREQUAL "bg"
            OR "${LANGUAGE_NEEDED}" STREQUAL "he"
            OR "${LANGUAGE_NEEDED}" STREQUAL "fi"
            OR "${LANGUAGE_NEEDED}" STREQUAL "et"
            OR "${LANGUAGE_NEEDED}" STREQUAL "eo"
            OR "${LANGUAGE_NEEDED}" STREQUAL "hu"
            OR "${LANGUAGE_NEEDED}" STREQUAL "tr"
            OR "${LANGUAGE_NEEDED}" STREQUAL "es")
                file (APPEND ${FILE} "\"Plural-Forms: nplurals=2; plural=n != 1;\\n\"\n")
        elseif ("${LANGUAGE_NEEDED}" STREQUAL "fr"
            OR "${LANGUAGE_NEEDED}" STREQUAL "fr_CA"
            OR "${LANGUAGE_NEEDED}" STREQUAL "pt_BR")
                file (APPEND ${FILE} "\"Plural-Forms: nplurals=2; plural=n>1;\\n\"\n")
        elseif ("${LANGUAGE_NEEDED}" STREQUAL "lv")
                file (APPEND ${FILE} "\"Plural-Forms: nplurals=3; plural=n%10==1 && n%100!=11 ? 0 : n != 0 ? 1 : 2;\\n\"\n")
        elseif ("${LANGUAGE_NEEDED}" STREQUAL "ro")
                file (APPEND ${FILE} "\"Plural-Forms: nplurals=3; plural=n==1 ? 0 : (n==0 || (n%100 > 0 && n%100 < 20)) ? 1 : 2;\\n\"\n")
        elseif ("${LANGUAGE_NEEDED}" STREQUAL "lt")
                file (APPEND ${FILE} "\"Plural-Forms: nplurals=3; plural=n%10==1 && n%100!=11 ? 0 : n%10>=2 && (n%100<10 || n%100>=20) ? 1 : 2;\\n\"\n")
        elseif ("${LANGUAGE_NEEDED}" STREQUAL "ru"
            OR "${LANGUAGE_NEEDED}" STREQUAL "uk"
            OR "${LANGUAGE_NEEDED}" STREQUAL "be"
            OR "${LANGUAGE_NEEDED}" STREQUAL "sr"
            OR "${LANGUAGE_NEEDED}" STREQUAL "hr")
                file (APPEND ${FILE} "\"Plural-Forms: nplurals=3; plural=n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2;\\n\"\n")
        elseif ("${LANGUAGE_NEEDED}" STREQUAL "cs"
            OR "${LANGUAGE_NEEDED}" STREQUAL "sk")
                file (APPEND ${FILE} "\"Plural-Forms: nplurals=3; plural=(n==1) ? 0 : (n>=2 && n<=4) ? 1 : 2;\\n\"\n")
        elseif ("${LANGUAGE_NEEDED}" STREQUAL "pl")
                file (APPEND ${FILE} "\"Plural-Forms: nplurals=3; plural=n==1 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2;\\n\"\n")
        elseif ("${LANGUAGE_NEEDED}" STREQUAL "sl")
                file (APPEND ${FILE} "\"Plural-Forms: nplurals=4; plural=n%100==1 ? 0 : n%100==2 ? 1 : n%100==3 || n%100==4 ? 2 : 3;\\n\"\n")
        endif ()

    endif ()
endmacro (create_po_file)

macro (configure_file_translation SOURCE RESULT PO_DIR)
    find_program (INTLTOOL_MERGE_EXECUTABLE intltool-merge)
    set(EXTRA_PO_DIR ${PO_DIR}/extra/)
    get_filename_component(EXTRA_PO_DIR ${EXTRA_PO_DIR} ABSOLUTE)

    # Intltool can't create a new directory.
    get_filename_component(SOURCE_DIRECTORY ${SOURCE} DIRECTORY)
    file(MAKE_DIRECTORY ${SOURCE_DIRECTORY})

    set (INTLTOOL_FLAG "")
    if (${SOURCE} MATCHES ".desktop")
        set (INTLTOOL_FLAG "--desktop-style")
    elseif (${SOURCE} MATCHES ".gschema")
        set (INTLTOOL_FLAG "--schemas-style")
    elseif (${SOURCE} MATCHES ".xml")
        set (INTLTOOL_FLAG "--xml-style")
    endif ()
    execute_process (WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} COMMAND ${INTLTOOL_MERGE_EXECUTABLE} --quiet ${INTLTOOL_FLAG} ${EXTRA_PO_DIR} ${SOURCE} ${RESULT})
endmacro ()

macro (add_translations_catalog NLS_PACKAGE)
    cmake_parse_arguments (ARGS "" "" "DESKTOP_FILES;APPDATA_FILES;SCHEMA_FILES" ${ARGN})
    add_custom_target (pot COMMENT “Building translation catalog.”)
    find_program (XGETTEXT_EXECUTABLE xgettext)
    find_program (INTLTOOL_EXTRACT_EXECUTABLE intltool-extract)

    set(EXTRA_PO_DIR ${CMAKE_CURRENT_SOURCE_DIR}/extra)

    set(C_SOURCE "")
    set(VALA_SOURCE "")
    set(GLADE_SOURCE "")

    foreach(FILES_INPUT ${ARGN})
        if((${FILES_INPUT} MATCHES ${CMAKE_SOURCE_DIR}) OR (${FILES_INPUT} MATCHES ${CMAKE_BINARY_DIR}))
            set(BASE_DIRECTORY ${FILES_INPUT})
        else ()
            set(BASE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${FILES_INPUT})
        endif ()

        file (GLOB_RECURSE SOURCE_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/ ${BASE_DIRECTORY}/*.c)
        foreach(C_FILE ${SOURCE_FILES})
            set(C_SOURCE ${C_SOURCE} ${C_FILE})
        endforeach()

        file (GLOB_RECURSE SOURCE_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/ ${BASE_DIRECTORY}/*.vala)
        foreach(VALA_FILE ${SOURCE_FILES})
            set(VALA_SOURCE ${VALA_SOURCE} ${VALA_FILE})
        endforeach()

        file (GLOB_RECURSE SOURCE_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR}/ ${BASE_DIRECTORY}/*.ui)
        foreach(GLADE_FILE ${SOURCE_FILES})
            set(GLADE_SOURCE ${GLADE_SOURCE} ${GLADE_FILE})
        endforeach()
    endforeach()

    set (XGETTEXT_C_ARGS --add-comments="/" --keyword="_" --keyword="N_" --keyword="C_:1c,2" --keyword="NC_:1c,2" --keyword="ngettext:1,2" --keyword="Q_:1g")
    set(BASE_XGETTEXT_COMMAND
        ${XGETTEXT_EXECUTABLE} -d ${NLS_PACKAGE}
        -o ${CMAKE_CURRENT_SOURCE_DIR}/${NLS_PACKAGE}.pot
        ${XGETTEXT_C_ARGS} --from-code=UTF-8)

    set(EXTRA_XGETTEXT_COMMAND
        ${XGETTEXT_EXECUTABLE} -d extra
        -o ${EXTRA_PO_DIR}/extra.pot --no-location --from-code=UTF-8)

    set (INTLTOOL_EXTRACT_COMMAND
        ${INTLTOOL_EXTRACT_EXECUTABLE} --local --srcdir=/)

    set(CONTINUE_FLAG "")

    IF(NOT "${C_SOURCE}" STREQUAL "")
        add_custom_command(TARGET pot WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} COMMAND ${BASE_XGETTEXT_COMMAND} ${C_SOURCE})
        set(CONTINUE_FLAG "-j")
    ENDIF()

    IF(NOT "${VALA_SOURCE}" STREQUAL "")
        add_custom_command(TARGET pot WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} COMMAND ${BASE_XGETTEXT_COMMAND} ${CONTINUE_FLAG} -LC\# ${VALA_SOURCE})
        set(CONTINUE_FLAG "-j")
    ENDIF()

    IF(NOT "${GLADE_SOURCE}" STREQUAL "")
        add_custom_command (TARGET pot WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} COMMAND ${BASE_XGETTEXT_COMMAND} ${CONTINUE_FLAG} -LGlade ${GLADE_SOURCE})
    ENDIF()

    # We need to create the directory if one extra content exists.
    IF((NOT "${ARGS_DESKTOP_FILES}" STREQUAL "") OR (NOT "${ARGS_APPDATA_SOURCE}" STREQUAL "") OR (NOT "${ARGS_SCHEMA_SOURCE}" STREQUAL ""))
        file(MAKE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/extra/)
    ENDIF()

    set(CONTINUE_FLAG "")

    foreach(DESKTOP_SOURCE ${ARGS_DESKTOP_FILES})
        get_filename_component(DESKTOP_SOURCE ${DESKTOP_SOURCE} ABSOLUTE)
        add_custom_command(TARGET pot WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} COMMAND ${INTLTOOL_EXTRACT_COMMAND} --type=gettext/keys ${DESKTOP_SOURCE})
        get_filename_component(DESKTOP_SOURCE_NAME ${DESKTOP_SOURCE} NAME)
        add_custom_command(TARGET pot WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} COMMAND ${EXTRA_XGETTEXT_COMMAND} ${CONTINUE_FLAG} ${XGETTEXT_C_ARGS} ${CMAKE_CURRENT_BINARY_DIR}/tmp/${DESKTOP_SOURCE_NAME}.h)
        set(CONTINUE_FLAG "-j")
    endforeach()

    foreach(APPDATA_SOURCE ${ARGS_APPDATA_FILES})
        get_filename_component(APPDATA_SOURCE ${APPDATA_SOURCE} ABSOLUTE)
        add_custom_command(TARGET pot WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} COMMAND ${INTLTOOL_EXTRACT_COMMAND} --type=gettext/xml ${APPDATA_SOURCE})
        get_filename_component(APPDATA_SOURCE_NAME ${APPDATA_SOURCE} NAME)
        add_custom_command(TARGET pot WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} COMMAND ${EXTRA_XGETTEXT_COMMAND} ${CONTINUE_FLAG} ${XGETTEXT_C_ARGS} ${CMAKE_CURRENT_BINARY_DIR}/tmp/${APPDATA_SOURCE_NAME}.h)
        set(CONTINUE_FLAG "-j")
    endforeach()

    foreach(SCHEMA_SOURCE ${ARGS_SCHEMA_FILES})
        get_filename_component(SCHEMA_SOURCE ${SCHEMA_SOURCE} ABSOLUTE)
        add_custom_command(TARGET pot WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR} COMMAND ${INTLTOOL_EXTRACT_COMMAND} --type=gettext/schemas ${SCHEMA_SOURCE})
        get_filename_component(SCHEMA_SOURCE_NAME ${SCHEMA_SOURCE} NAME)
        add_custom_command(TARGET pot WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR} COMMAND ${EXTRA_XGETTEXT_COMMAND} ${CONTINUE_FLAG} ${XGETTEXT_C_ARGS} ${CMAKE_CURRENT_BINARY_DIR}/tmp/${SCHEMA_SOURCE_NAME}.h)
        set(CONTINUE_FLAG "-j")
    endforeach()
endmacro ()
