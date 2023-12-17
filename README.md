# Reverse Geocode in Odin
It calculates the nearest city to a latitude and longitude, from a data file, as a point and not as a polygon.

## Description
This program reads a list of cities and countries and finds the nearest city to a given latitude and longitude. The list of countries is stored in a hashmap to speed up the search. The list of cities is stored in a dynamic array to test the correction, but the cities data is also stored in a KD-Tree to speed up the search. The KD-Tree is a binary tree that stores the cities in a 2D space. <br>

The distance between the geographic coordinates area calculated using the Haversine formula. This uses a model of the earth surface as a surface of a sphere, this is not the best approximation, but it is a good approximation for short distances. <br>

This project was inspired by the project Reverse Geocode, that is implemented in Python, and I use the same data files origin, then that project. None of it's original code was used, but the idea of using a KD-Tree to speed up the search was also from it. <br>

Github - richardpenman - reverse_geocode <br>
[https://github.com/richardpenman/reverse_geocode](https://github.com/richardpenman/reverse_geocode)             

Source of the geocode cities data files, that are used in this project: <br>
[http://download.geonames.org/export/dump/cities1000.zip](http://download.geonames.org/export/dump/cities1000.zip)

Unzip it to generate the file ```cities1000.txt``` <br>

Run the Python script to filter the columns of the  cities to the ones that are used in this project. <br>

``` bash
$ python filter_cities.py
```

Run the Odin program: <br>

``` bash
$ make
$ make run
```

## References
- Wikipedia k-d tree <br>
  [https://en.wikipedia.org/wiki/K-d_tree](https://en.wikipedia.org/wiki/K-d_tree)

## License
MIT Open Source License

## Have fun
Best regards, <br>
João Nuno Carvalho

