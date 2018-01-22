# Resources:
# General primer for makefiles:
# http://nuclear.mutantstargoat.com/articles/make/#practical-makefile
# Dependency files:
# http://make.mad-scientist.net/papers/advanced-auto-dependency-generation/
# Tutorial I was following but doesn't quite work for me
# https://mcuoneclipse.com/2017/07/22/tutorial-makefile-projects-with-eclipse/

#--------------------------------------------------
# Tools
AS := arm-none-eabi-as
CC := arm-none-eabi-gcc
LL := arm-none-eabi-gcc
RM := rm -rf

#--------------------------------------------------
# Binaries
BIN_DIR := bin
TARGET := test
EXE := $(BIN_DIR)/$(TARGET).axf
MAP := $(BIN_DIR)/$(TARGET).map

#--------------------------------------------------
# Seperate C and Assembly (.S) sources
CMSIS_SRC := $(wildcard CMSIS/*.c) 
CMSIS_ASRC := $(wildcard CMSIS/*.S)
SRC := $(wildcard src/*.c) $(CMSIS_SRC)
# Strip Paths from file names
# vpath
# sort removes duplicates
# notdir strips path from filename
vpath %.c $(sort $(dir $(SRC)))
OBJ := $(notdir $(SRC:.c=.o))
AOBJ := $(CMSIS_ASRC:.S=.o) #Assembly Objects

#--------------------------------------------------
# Dependencies
# Explained in full in the given link for Auto-Dependency Generation
DEP_DIR := .d
$(shell mkdir -p $(DEP_DIR) >/dev/null) # Ensures .dep exists
# Flags to make GCC generate dependency files in temp folder
DEP_FLAGS = -MT $@ -MMD -MP -MF $(DEP_DIR)/$*.Td


# Make a dep file for each object, then include each for this makefile
#DEP := $(OBJ:.o=d)
#-include $(DEP)

#--------------------------------------------------
# Includes 
INC := -I"CMSIS" -I"src"

#--------------------------------------------------
# Libraries
LIB :=

#--------------------------------------------------
# Linker Scripts
LL_SCRIPTS := $(wildcard linker/*.ld)
LL_SCRIPTS_PARAM := $(LL_SCRIPTS:%=-T%)

#--------------------------------------------------
# Flags

# Assembler flags
AS_FLAGS := -mthumb -mcpu=cortex-m0plus 

# C Compiler flags
# -0g -> 'efficient debug' availabe since ~ gcc 4.9
CC_FLAGS := -std=gnu99 -Og -ffunction-sections -fdata-sections -fno-builtin -mcpu=cortex-m0plus -mthumb -DCPU_MKL25Z128VLK4 -D__USE_CMSIS $(INC)

# Linker Flags
#  --specs=nano.specs uses a reduced sized libc, libc_nano
#  -nostdlib means do NOT link against libc
LL_FLAGS := --specs=nano.specs -Wl,-Map,$(MAP) -Wl,--gc-sections -Wl,-print-memory-usage -mcpu=cortex-m0plus -mthumb $(LL_SCRIPTS_PARAM) -o $(EXE)  

#--------------------------------------------------
# Compile Commands
COMPILE.c = $(CC) $(DEP_FLAGS) $(CC_FLAGS) -c
COMPILE.S = $(AS) $(AS_FLAGS) 
POSTCOMPILE = @mv -f $(DEP_DIR)/$*.Td $(DEP_DIR)/$*.d && touch $@

#--------------------------------------------------
# Rules

ifneq ($(MAKECMDGOALS),clean)
-include $(wildcard $(patsubst %,$(DEP_DIR)/%.d,$(basename $(SRC))))
endif

.PHONY: all
all: $(EXE)
	@echo "-- Build Completed --"

# Clean Rules
.PHONY: clean
clean:
	$(RM) $(OBJ) $(AOBJ) $(EXE)

#.PHONY: cleandep
#cleandep:
#	$(RM) $(DEP)

# Executable Rule
$(EXE): $(OBJ) $(AOBJ) $(LL_SCRIPTS)
	@echo '-- Building exe: $@ --'
	$(LL) $(LL_FLAGS) $(OBJS) $(AOBJ) $(LIB)

# Object Rule for C Sources
%.o : %.c $(DEP_DIR)/%.d
	$(COMPILE.c) $<
	$(POSTCOMPILE)

# Object Rule for Assembly Sources
%.o : %.S
	$(COMPILE.S) $< -o $@

# Prevent make from 'Remaking' the makefile ?
# Makefile: ;

# Prevent make from failing if dep file doesn't exist 
$(DEP_DIR)/%.d: ;

# Prevent make from deleting dep files
.PRECIOUS: $(DEP_DIR)/%.d

