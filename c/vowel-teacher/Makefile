CC=gcc
CFLAGS=-c -Wall -ggdb $(shell pkg-config --cflags gtk+-2.0 gmodule-2.0 sndfile)
LDFLAGS=$(shell pkg-config --libs gtk+-2.0 gmodule-2.0 sndfile)
SOURCES=main.c recording.c
OBJECTS=main.o recording.o
EXECUTABLE=drawing

all: $(SOURCES) $(EXECUTABLE)

$(EXECUTABLE): $(OBJECTS)
	$(CC) $(LDFLAGS) $(OBJECTS) -o $@

main.o: main.c recording.h error.h
	$(CC) $(CFLAGS) main.c

recording.o: recording.c recording.h error.h
	$(CC) $(CFLAGS) recording.c

