#-------------------------------------------------
#
# Project created by QtCreator 2014-12-16T13:16:40
#
#-------------------------------------------------

QT       -= core gui

TARGET = cppop
TEMPLATE = lib

DEFINES += CPPOP_LIBRARY

SOURCES += \
    buffers.cpp \
    server.cpp \
    interface.cpp \
    driver.cpp \
    callback.cpp

HEADERS +=\
    buffers.h \
    server.h \
    interface.h \
    driver.h \
    callback.h \
    common.h

LIBS += -lboost_thread

unix:!symbian {
    maemo5 {
        target.path = /opt/usr/lib
    } else {
        target.path = /usr/lib
    }
    INSTALLS += target
}
