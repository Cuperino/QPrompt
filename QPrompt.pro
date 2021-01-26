EMPLATE = subdirs

SUBDIRS = \
        kirigami \
        ki18n \
        src

kirigami.subdir  = 3rdparty/kirigami
ki18n.subdir  = 3rdparty/ki18n
src.subdir = src

src.depends = kirigami ki18n

android: {
    include(3rdparty/kirigami/kirigami.pri)
}
wasm: {
    include(3rdparty/kirigami/kirigami.pri)
}
