// Project name: Reverse Geocode in Odin
//
// Description:  This program reads a list of cities and countries and finds the
//               nearest city to a given latitude and longitude.
//               The list of countries is stored in a hashmap to speed up the search.
//               The list of cities is stored in a dynamic array to test the correction,
//               but the cities data is also stored in a KD-Tree to speed up the search.
//               The KD-Tree is a binary tree that stores the cities in a 2D space.
//               The distance between the geographic coordinates area calculated using
//               the Haversine formula. This uses a model of the earth surface as a 
//               surface of a sphere, this is not the best approximation, but it is a
//               good approximation for short distances.
//
//               This project was inspaired by the project Reverse Geocode, that is
//               implemented in Python, and I use the same data files origin, then
//               that project. None of it's original code was used, but the idea of
//               using a KD-Tree to speed up the search was also from it.
//               
//               Github - richardpenman - reverse_geocode
//               https://github.com/richardpenman/reverse_geocode             
//
//               Source of the geocode data files, that are used in this project:
//               http://download.geonames.org/export/dump/cities1000.zip
//               
//               Unzip it to generate the file:
//               cities1000.txt
//               
//               Run the Python script to filter the columns of the  cities to the
//               ones that are used in this project.
//
//               $ python filter_cities.py
// 
// References:
//               Wikipedia k-d tree
//               https://en.wikipedia.org/wiki/K-d_tree
//
// Author:       João Nuno Carvalho
// Date:         2023.12.17
// License:      MIT Open Source License
//


package reverse_geocode

import "core:fmt"
import "core:os"
import "core:strings"
import "core:math"
import "core:strconv"

// Medium earth radius, in kilometers.
RADIUS_OF_EARTH_KM :: 6_368 // km
TRIM_CUTSET :: " \t\n\r"

City :: struct {
    name:         string,
    latitude:     f64,
    longitude:    f64,
    country_code: string,
}

city_create :: proc( name: string, latitude: f64, longitude: f64, country_code: string ) -> ^City {
    city_ptr := new( City )
    city_ptr.name         = strings.clone( name )
    city_ptr.latitude     = latitude
    city_ptr.longitude    = longitude
    city_ptr.country_code = strings.clone( country_code )
    return city_ptr
}

main :: proc( ) {
    fmt.printf( "Reverse Geocode in Odin ...\n\n" )

    // latitude Lisbon
    target_lat :f64 = 38.7167
    target_lon :f64 = -9.1333

    // latitude Lisbon near
    // target_lat :f64 = 38.600
    // target_lon :f64 = -5.1333

    countries_data      : map[string]string
    cities_data_lst     : [dynamic]^City
    cities_data_kd_tree : KDTree

    {
        // Read countries.csv
        file_name := ".//countries.csv"
        countries_file_contents, err_1 := os.read_entire_file(file_name)
        if err_1 != true {
            fmt.println( "Error reading countries.csv file:", err_1 )
            os.exit(1)
        }
        defer delete( countries_file_contents ) 

        // Read cities_1000_filtered.csv
        file_name = ".//cities1000_filtered.csv"
        cities_file_contents, err_2 := os.read_entire_file(file_name)
        if err_2 != true {
            fmt.println("Error reading cities1000_filtered.csv file:", err_2)
            os.exit(1)
        }
        defer delete( cities_file_contents )

        countries_data = parse_csv_countries( string( countries_file_contents ) )
        
        cities_data_lst, cities_data_kd_tree = parse_csv_cities( string( cities_file_contents ) )
    }
    
    defer delete( countries_data )
    defer delete( cities_data_lst )

    // fmt.printf("countries_data:\n\n%v \n\n [%v] [%v]\n\n", countries_data, "PT", countries_data["PT"])

    // fmt.printf("cities_data_list: \n\n %v \n\n", cities_data_lst,)


    fmt.printf("Target location:  lat %v, long %v\n", target_lat, target_lon )    
    nearest_location_1, distance_1, country_code_1 := 
        find_nearest_location_slow(  cities_data_lst, target_lat, target_lon )
    
    // country_code = strings.trim( country_code, TRIM_CUTSET )

    country_name_1 := countries_data[ country_code_1 ] or_else "Unknown"

    fmt.printf("Nearest location: %v, distance: %v km, country_code: %v, country_name: %v\n",
    nearest_location_1, distance_1, country_code_1, country_name_1 )


    lat_long_loction_2, best_distance_2, nearest_location_city_fast := kdtree_find_nearest_neighbor_location_fast( 
                    &cities_data_kd_tree, target_lat, target_lon)

    // We are going to ignore the return value lat_long_loction_2 because
    // we already know it inside city.
    _ = lat_long_loction_2                

    city := nearest_location_city_fast

    country_name_2 := countries_data[ city.country_code ] or_else "Unknown"

    fmt.printf("Nearest location: %v, distance: %v km, country_code: %v, country_name: %v\n",
    city.name, best_distance_2, city.country_code, country_name_2 )
 
    fmt.printf( "\n... end\n" )
}

parse_csv_countries :: proc( contents: string ) -> map[string]string {
    // Reads the countries.csv file and returns a hashmap of the countries.
    lines := strings.split( contents, "\n" )
    // lines = lines[ 1 : ]  // Remove the header line
    // Make the hashmap.
    countries_data := make( map[string]string, len( lines ) )
    for line in lines {
        values := strings.split( line, "," )
        // We don't need to clone because split already allocates new strings.
        // country_code := strings.clone( values[ 0 ] )
        // country_name := strings.clone( values[ 1 ] )
        if len( values ) < 2 {
            // Last line is empty. 
            // fmt.printf( "Error parsing line: %v\n", line )
            continue
        }
        
        country_code := strings.trim( values[ 0 ], TRIM_CUTSET )
        country_name := strings.trim( values[ 1 ], TRIM_CUTSET )
        countries_data[ country_code ] = country_name
    }
    return countries_data
}

string_to_float64 :: proc(str: string) -> (f64, bool) {
    value, ok := strconv.parse_f64(str, nil)
    return value, ok
}

// Columns in the cities_1000_filtered.csv file:
//    0 - City name
//    1 - Latitude
//    2 - Longitude
//    3 - Country code
parse_csv_cities :: proc(contents: string) -> ( [dynamic]^City, KDTree)  {
    lines := strings.split( contents, "\n" )
    // lines = lines[ 1 : ]  // Remove the header line
    
    cities_list := make( [dynamic]^City, 0, len(lines ) )
    cities_kdtree := kdtree_creation()

    for line in lines {
        values := strings.split(line, ",")

        if len( values ) < 4 {
            // Last line is empty.
            // fmt.printf( "Error parsing line: %v\n", line )
            continue
        }
        // We don't need to clone because split already allocates new strings.
        city_name    := strings.trim( values[ 0 ], TRIM_CUTSET )
        latitude, _  := string_to_float64( values[ 1 ] )
        longitude, _ := string_to_float64( values[ 2 ] )
        country_code := strings.trim( values[ 3 ], TRIM_CUTSET )
        city : ^City = city_create( city_name, latitude, longitude, country_code )

        // Append to the list just to check that is correct.
        append( &cities_list, city )
        
        // Add the KD-Tree insertion / construction.
        kdtree_insert( &cities_kdtree, city)

    }
    return cities_list, cities_kdtree
}

degrees_to_radians :: proc( degrees: f64 ) -> f64 {
    return degrees * ( math.PI / 180.0 )
}

// Distance between two points on the earth, in kilometers, modeled has a sphere.
haversine_distance :: proc( lat1: f64, lon1: f64, lat2: f64, lon2: f64 ) -> f64 {

    dLat := degrees_to_radians( lat2 - lat1 )
    dLon := degrees_to_radians( lon2 - lon1 )

    a := math.sin( dLat / 2 ) * math.sin( dLat / 2 ) +
         math.cos( degrees_to_radians(lat1 ) ) * math.cos( degrees_to_radians( lat2 ) ) *
         math.sin( dLon / 2 ) * math.sin( dLon / 2 )

    c := 2 * math.atan2( math.sqrt( a ), math.sqrt( 1 - a ) )

    return RADIUS_OF_EARTH_KM * c
}

find_nearest_location_slow :: proc( cities_data_lst : [dynamic]^City, target_lat: f64, target_lon: f64 ) -> 
                            ( string, f64, string ) {
    // Find the nearest city location to the target latitude and longitude.
    nearest_location : string
    country_code     : string
    min_distance := math.F64_MAX


    for city in cities_data_lst {
        distance := haversine_distance( target_lat, target_lon, city.latitude, city.longitude )
        if distance < min_distance {
            min_distance     = distance
            nearest_location = city.name
            country_code     = city.country_code
        }
    }
    
    return nearest_location, min_distance, country_code
}


//***********************
// KD-Tree implementation

Node :: struct {
    point:       [2]f64,
    city:        ^City,
    left, right: ^Node,
}

KDTree :: struct {
    root: ^Node,
}

kdtree_creation :: proc( ) -> KDTree {
    return KDTree{ }
}

kdtree_insert :: proc( tree: ^KDTree, city: ^City ) {
    insert_recursive :: proc( node: ^^Node, point: [2]f64, city: ^City, depth: int ) {
        if node^ == nil {
            node^ = new( Node )
            node^.point = point
            node^.city  = city
            return
        }

        cd := depth % 2
        if point[ cd ] < node^.point[ cd ] {
            insert_recursive( &( node^ ).left, point, city, depth + 1 )
        } else {
            insert_recursive( &( node^ ).right, point, city, depth + 1 )
        }
    }

    point : [2]f64
    point[0] = city.latitude
    point[1] = city.longitude 

    insert_recursive( &tree.root, point, city, 0 )
}

distance_wrapper :: proc( coord_1, coord_2 : [2]f64 ) -> f64 {
    lat_1 := coord_1[0]
    lon_1 := coord_1[1]
    lat_2 := coord_2[0]
    lon_2 := coord_2[1]
    return haversine_distance( lat_1, lon_1, lat_2, lon_2 )
}

kdtree_find_nearest_neighbor_location_fast :: proc( tree: ^KDTree, target_lat, target_long: f64 ) ->
    ( [2]f64, f64, ^City ) {
    
    nearest_recursive :: proc(node: ^Node, target: [2]f64, depth: int, best_dist: ^f64,
                              best_point: ^[2]f64, best_city: ^^City ) {
        best_city := best_city

        if node == nil {
            return
        }

        cd := depth % 2
        d := distance_wrapper(target, node.point)
        if d < best_dist^ {
            best_dist^  = d
            best_point^ = node.point
            best_city^   = node.city
        }

        if target[ cd ] < node.point[ cd ] {
            nearest_recursive( node.left, target, depth + 1, best_dist, best_point, best_city )

            if node.right != nil && best_dist^ > distance_wrapper(target, node.right.point ) {
                nearest_recursive( node.right, target, depth + 1, best_dist, best_point, best_city )
            }

        } else {
            nearest_recursive(node.right, target, depth+1, best_dist, best_point, best_city)
            
            if node.left != nil && best_dist^ > distance_wrapper( target, node.left.point ) {
                nearest_recursive( node.left, target, depth + 1, best_dist, best_point, best_city )
            }

        }
    }

    best_point := [2]f64{ 0, 0 }
    best_dist  := math.F64_MAX
    best_city  : ^City
    
    target_coord := [2]f64{ target_lat, target_long }
    
    nearest_recursive( tree.root, target_coord, 0, 
        &best_dist, &best_point, &best_city )
    
    best_coord := [2]f64{ best_city.latitude, best_city.longitude }

    best_distance := distance_wrapper( target_coord, best_coord )
    
    return best_point, best_distance, best_city
}




