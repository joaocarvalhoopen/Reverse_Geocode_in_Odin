all:
#	odin build . -out:reverse_geocode.exe -debug -vet
	odin build . -out:reverse_geocode.exe -o:speed

clean:
	rm reverse_geocode.exe

run:
	./reverse_geocode.exe