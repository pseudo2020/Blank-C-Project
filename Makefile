# USAGE:
# make             -> Build executable with CFLAGS_DEBUG.
# make run         -> Build executable with CFLAGS_DEBUG, then run it.
# make release     -> Build executable with CFLAGS_RELEASE.
# make release run -> Build executable with CFLAGS_RELEASE, then run it.
# make clean       -> Remove everything in OUTPUT_DIR
# Use the environment variable ARGS to pass arguments to 'run'.
#
# GENERIC BEHAVIOUR:
# Use CC to compile every file with the SRC_SUFFIX in SRC_DIR,
# passing flags:
#     * CFLAGS
#     * CFLAGS_DEBUG or CFLAGS_RELEASE
#     * CFLAG_INCLUDE followed by INCLUDE_DIRS
#     * CFLAG_OUTPUT
# and putting the resulting .OBJ_SUFFIX files into OBJ_DIR.
# Then link the files in OBJ_DIR using LD with flags:
#     * LDFLAGS
#     * LDFLAGS_DEBUG or LDFLAGS_RELEASE
#     * LDFLAG_LIBDIR followed by LIB_DIRS
#     * LDFLAG_LIB followed by LIBS
#     * LDFLAG_OUTPUT
# into a file called EXEC_NAME in OUTPUT_DIR.

# ========= config =========
# compiler
CC := gcc -c
CFLAGS         := -march=native -Wall -Wextra -Werror -pedantic -std=c90 -Wshadow -Wundef
CFLAGS_DEBUG   := -g3
CFLAGS_RELEASE := -O3
CFLAG_INCLUDE := -I
CFLAG_OUTPUT  := -o

# linker
LD := gcc
LDFLAGS         := $(CFLAGS)
LDFLAGS_DEBUG   := $(CFLAGS_DEBUG)
LDFLAGS_RELEASE := $(CFLAGS_RELEASE)
LDFLAG_LIBDIR := -L
LDFLAG_LIB    := -l
LDFLAG_OUTPUT := -o

# SRC and OBJ file formats
SRC_SUFFIX := .c
OBJ_SUFFIX := .o

# directories (use normal slashes)
SRC_DIR      := src
OUTPUT_DIR   := bin
OBJ_DIR      := $(OUTPUT_DIR)/obj
INCLUDE_DIRS := inc
LIB_DIRS     :=
LIBS         :=

EXEC_NAME := main
# ========= endconfig =========

ifeq ($(OS),Windows_NT)
EXEC_NAME := $(EXEC_NAME).exe
RM    := del /q /s
MKDIR := mkdir
# No normal compiler/linker should care about
# the slash direction but use this if you plan
# to do system specific stuff.
FIXPATH  = $(subst /,\,$1)
SUBDIRS  = $1 $(subst ./,,$(subst \,/, \
	$(shell PowerShell.exe -NoProfile -NonInteractive \
		"Get-ChildItem -Path $1 -Recurse -Attributes Directory | Resolve-Path -Relative")))
else
RM    := rm -rf
MKDIR := mkdir -p
FIXPATH  = $1
SUBDIRS  = $(shell find $1 -type d)
endif

EXEC     := $(OUTPUT_DIR)/$(EXEC_NAME)
SRC_SUBDIRS := $(call SUBDIRS,$(SRC_DIR))
OBJ_SUBDIRS := $(subst $(SRC_DIR),$(OBJ_DIR),$(SRC_SUBDIRS))
SRCS        := $(wildcard $(patsubst %,%/*$(SRC_SUFFIX),$(SRC_SUBDIRS)))
OBJS        := $(patsubst $(SRC_DIR)/%$(SRC_SUFFIX),$(OBJ_DIR)/%$(OBJ_SUFFIX),$(SRCS))
INCLUDES := $(addprefix $(CFLAG_INCLUDE),$(INCLUDE_DIRS))
LIB_DIRS := $(addprefix $(LDFLAG_LIBDIR),$(LIB_DIRS))
LIBS     := $(addprefix $(LDFLAG_LIB),$(LIBS))

.PHONY: all release run clean

# Set DEBUG or RELEASE flags
ifneq (,$(findstring release,$(MAKECMDGOALS)))
CFLAGS   := $(CFLAGS_RELEASE) $(CFLAGS)
LDFLAGS  := $(LDFLAGS_RELEASE) $(LDFLAGS)
else
CFLAGS  := $(CFLAGS_DEBUG) $(CFLAGS)
LDFLAGS := $(LDFLAGS_DEBUG) $(LDFLAGS)
endif

all: $(EXEC)
	@echo Building complete.

release: all

run: all
	$(call FIXPATH,$(EXEC) $(ARGS))
	@echo Executing complete.

clean:
	$(RM) $(call FIXPATH,$(OUTPUT_DIR))
	@echo Cleaning complete.

# Link OBJS.
$(EXEC): $(OBJS)
	$(LD) $(LDFLAGS) \
	$(LIB_DIRS) $(LIBS) \
		$(OBJS) \
		$(LDFLAG_OUTPUT) $(EXEC)

# Compile SRCS.
$(OBJ_DIR)/%$(OBJ_SUFFIX): $(SRC_DIR)/%$(SRC_SUFFIX) | $(OBJ_SUBDIRS)
	$(CC) $(CFLAGS) \
		$(INCLUDES) \
		$^ \
		$(CFLAG_OUTPUT) $@

$(OBJ_SUBDIRS): | $(OUTPUT_DIR)
	$(MKDIR) $(call FIXPATH,$@)

$(OUTPUT_DIR):
	$(MKDIR) $(call FIXPATH,$(OUTPUT_DIR))
