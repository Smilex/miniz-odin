OS=$(shell uname)

ifeq ($(OS), Darwin)
all: darwin
else
all: unix
endif

wasm:
	mkdir -p ../lib
	$(CC) -c -Os --target=wasm32 --sysroot=$(shell odin root)/vendor/libc miniz.c        -o ../lib/miniz.o        -DMINIZ_NO_STDIO

unix:
	mkdir -p ../lib
	$(CC) -c -O2 -Os -fPIC miniz.c
	$(AR) rcs ../lib/miniz.a        miniz.o
	#$(CC) -fPIC -shared -Wl,-soname=miniz.so         -o ../lib/miniz.so        miniz.o
	rm *.o

darwin:
	mkdir -p ../lib/darwin
	$(CC) -arch x86_64 -c -O2 -Os -fPIC miniz.c -o miniz-x86_64.o -mmacosx-version-min=10.12
	$(CC) -arch arm64  -c -O2 -Os -fPIC miniz.c -o miniz-arm64.o -mmacosx-version-min=10.12
	lipo -create miniz-x86_64.o miniz-arm64.o -output ../lib/darwin/miniz.a
	rm *.o
