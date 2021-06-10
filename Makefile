# Developer's makefile for building Lua
LUA_DIR = # Insert local Lua build here.
LUA_LIB = ${LUA_DIR}
LUA_CFLAGS = -I$(LUA_DIR) -DLMPROF_FILE_API -DLMPROF_HASH_SPLITMIX # -DLMPROF_BUILTIN -DLMPROF_FORCE_LOGGER
LUA_LIBS =

# == CHANGE THE SETTINGS BELOW TO SUIT YOUR ENVIRONMENT =======================

# Warnings valid for both C and C++
CWARNSCPP= \
	-Wfatal-errors \
	-Wextra \
	-Wshadow \
	-Wsign-compare \
	-Wundef \
	-Wwrite-strings \
	-Wredundant-decls \
	-Wdisabled-optimization \
	-Wdouble-promotion \
	# the next warnings might be useful sometimes,
	# -Werror \
	# -pedantic   # warns if we use jump tables \
	# -Wconversion  \
	# -Wsign-conversion \
	# -Wstrict-overflow=2 \
	# -Wformat=2 \
	# -Wcast-qual \


# Warnings for gcc, not valid for clang
CWARNGCC= \
	-Wlogical-op \
	-Wno-aggressive-loop-optimizations \
	-Wno-inline \
	-Wno-ignored-qualifiers \


# The next warnings are neither valid nor needed for C++
CWARNSC= -Wdeclaration-after-statement \
	-Wmissing-prototypes \
	-Wnested-externs \
	-Wstrict-prototypes \
	-Wc++-compat \
	-Wold-style-definition \

# TESTS= -DLUA_USER_H='"ltests.h"' -O0 -g

# Your platform. See PLATS for possible values.
PLAT= guess

CC= gcc -std=gnu99 $(CWARNSCPP) $(CWARNSC) $(CWARNGCC)
CFLAGS= -O3 -fPIC -shared -Wall -Wextra $(SYSCFLAGS) $(MYCFLAGS) $(LUA_CFLAGS)
LDFLAGS= $(SYSLDFLAGS) $(MYLDFLAGS)
LIBS= -lm $(SYSLIBS) $(MYLIBS) $(LUA_LIBS) -ldl -L${LUA_LIB}

AR= ar rcu
RANLIB= ranlib
RM= rm -f
UNAME= uname

SYSCFLAGS=
SYSLDFLAGS=
SYSLIBS=

MYCFLAGS= $(TESTS)
MYLDFLAGS= $(TESTS)
MYLIBS=
MYOBJS=

# == END OF USER SETTINGS. NO NEED TO CHANGE ANYTHING BELOW THIS LINE =========

PLATS= guess aix bsd c89 freebsd generic linux linux-readline macosx mingw posix solaris

CORE_T=	lmprof.so
CORE_O=	src/collections/lmprof_collections.o src/collections/lmprof_record.o src/lmprof_report.o src/lmprof.o src/lmprof_lib.o

ALL_T= $(CORE_T)
ALL_O= $(CORE_O)

# Targets start here.
default: $(PLAT)

all:	$(ALL_T)

o:	$(ALL_O)

$(CORE_T): $(CORE_O)
	$(CC) $(CORE_O) -o $(CORE_T) $(CFLAGS) $(LIBS) $(MYLIBS)

install: $(CORE_T)
	mkdir -p $(LUA_LIB)/lmprof $(LUA_LIB)/lmprof && cp $(CORE_T) $(LUA_LIB)

clean:
	$(RM) $(ALL_T) $(ALL_O)

depend:
	@$(CC) $(CFLAGS) -MM -DLUA_USE_POSIX src/*.c src/collections/*.c

echo:
	@echo "PLAT= $(PLAT)"
	@echo "CC= $(CC)"
	@echo "CPP= $(CPP)"
	@echo "CFLAGS= $(CFLAGS)"
	@echo "LDFLAGS= $(SYSLDFLAGS)"
	@echo "LIBS= $(LIBS)"
	@echo "AR= $(AR)"
	@echo "RANLIB= $(RANLIB)"
	@echo "RM= $(RM)"
	@echo "UNAME= $(UNAME)"

# Convenience targets for popular platforms
ALL= all

help:
	@echo "Do 'make PLATFORM' where PLATFORM is one of these:"
	@echo "   $(PLATS)"
	@echo "See doc/readme.html for complete instructions."

guess:
	@echo Guessing `$(UNAME)`
	@$(MAKE) `$(UNAME)`

AIX aix:
	$(MAKE) $(ALL) CC="xlc" CFLAGS="-O2 -DLUA_USE_POSIX -DLUA_USE_DLOPEN" SYSLIBS="-ldl" SYSLDFLAGS="-brtl -bexpall"

bsd:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_POSIX -DLUA_USE_DLOPEN" SYSLIBS="-Wl,-E"

c89:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_C89" CC="gcc -std=gnu89"
	@echo ''
	@echo '*** C89 does not guarantee 64-bit integers for Lua.'
	@echo ''

FreeBSD NetBSD OpenBSD freebsd:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_LINUX -DLUA_USE_READLINE -I/usr/include/edit" SYSLIBS="-Wl,-E -ledit" CC="cc"

generic: $(ALL)

Linux linux:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_LINUX" SYSLIBS="-Wl,-E -ldl"

Darwin macos macosx:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_MACOSX -DLUA_USE_READLINE" SYSLIBS="-lreadline" LUA_LIBS="-llua" MYLDFLAGS="-bundle -undefined dynamic_lookup -all_load"

mingw:
	$(MAKE) "LUA_A=lua54.dll" "LUA_T=lua.exe" \
	"AR=$(CC) -shared -o" "RANLIB=strip --strip-unneeded" \
	"SYSCFLAGS=-DLUA_BUILD_AS_DLL" "SYSLIBS=" "SYSLDFLAGS=-s" lua.exe
	$(MAKE) "LUAC_T=luac.exe" luac.exe

posix:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_POSIX"

SunOS solaris:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_POSIX -DLUA_USE_DLOPEN -D_REENTRANT" SYSLIBS="-ldl"

$(ALL_O): Makefile

# DO NOT EDIT
# automatically made with 'gcc -MM l*.c'

lmprof.o: src/lmprof.c src/lmprof_conf.h ../lua/lua.h ../lua/luaconf.h \
 ../lua/luaconf.h ../lua/lauxlib.h ../lua/lua.h src/lmprof.h \
 src/lmprof_state.h src/collections/lmprof_stack.h \
 src/collections/../lmprof_conf.h src/collections/lmprof_record.h \
 src/collections/lmprof_traceevent.h src/collections/lmprof_hash.h \
 src/collections/lmprof_traceevent.h src/collections/lmprof_record.h
lmprof_lib.o: src/lmprof_lib.c src/lmprof_conf.h ../lua/lua.h \
 ../lua/luaconf.h ../lua/luaconf.h ../lua/lauxlib.h ../lua/lua.h \
 src/lmprof.h src/lmprof_state.h src/collections/lmprof_stack.h \
 src/collections/../lmprof_conf.h src/collections/lmprof_record.h \
 src/collections/lmprof_traceevent.h src/collections/lmprof_hash.h \
 src/collections/lmprof_traceevent.h src/collections/lmprof_record.h \
 src/lmprof_lib.h src/lmprof_report.h
lmprof_report.o: src/lmprof_report.c src/lmprof_conf.h ../lua/lua.h \
 ../lua/luaconf.h ../lua/luaconf.h ../lua/lauxlib.h ../lua/lua.h \
 src/lmprof_report.h src/lmprof_state.h src/collections/lmprof_stack.h \
 src/collections/../lmprof_conf.h src/collections/lmprof_record.h \
 src/collections/lmprof_traceevent.h src/collections/lmprof_hash.h \
 src/collections/lmprof_traceevent.h src/collections/lmprof_record.h \
 src/lmprof.h
lmprof_collections.o: src/collections/lmprof_collections.c \
 src/collections/../lmprof_conf.h ../lua/lua.h ../lua/luaconf.h \
 ../lua/luaconf.h ../lua/lauxlib.h ../lua/lua.h \
 src/collections/lmprof_record.h src/collections/lmprof_stack.h \
 src/collections/lmprof_traceevent.h src/collections/lmprof_hash.h
lmprof_record.o: src/collections/lmprof_record.c \
 src/collections/../lmprof_conf.h ../lua/lua.h ../lua/luaconf.h \
 ../lua/luaconf.h ../lua/lauxlib.h ../lua/lua.h \
 src/collections/lmprof_record.h

# (end of Makefile)
