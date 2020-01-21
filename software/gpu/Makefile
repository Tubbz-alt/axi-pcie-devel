# Variables
HOME     := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
CC       := nvcc
DEF      :=
BIN      := $(HOME)/bin
CFLAGS   := -I$(HOME)/driver
LFLAGS   := -lcuda

# Application Sources
APP_DIR := $(HOME)/src
APP_SRC := $(wildcard $(APP_DIR)/*.cu)
APP_BIN := $(patsubst $(APP_DIR)/%.cu,$(BIN)/%,$(APP_SRC))

# Targets
all: $(APP_BIN) 

# Clean
clean:
	@rm -f $(BIN)/*

# Application sources
$(BIN)/%: $(APP_DIR)/%.cu $(LIB_OBJ)
	@test -d $(BIN) || mkdir $(BIN)
	@echo "Compiling $@ from $<"; $(CC) $(CFLAGS) $(DEF) -o $@ $< $(LFLAGS)

