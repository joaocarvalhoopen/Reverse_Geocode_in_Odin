## location of geocode data to download
# GEOCODE_URL = 'http://download.geonames.org/export/dump/cities1000.zip'
# GEOCODE_FILENAME = 'cities1000.txt'

import csv

# Make a file with only the desired columns.
def filter_csv( input_file, output_file ):
    with open( input_file, 'r', encoding='utf-8') as infile, \
         open( output_file, 'w', newline='', encoding='utf-8' ) as outfile:

        reader = csv.reader( infile, delimiter='\t' )
        writer = csv.writer( outfile, delimiter=',' )

        for row in reader:
            # Extract the columns
            #  1 - City name
            #  4 - Latitude
            #  5 - Longitude
            #  8 - Country code
            ### 11 - Continent and country capital
            # filtered_row = [row[1], row[4], row[5], row[8], row[11]]
            filtered_row = [ row[1], row[4], row[5], row[8] ]
            writer.writerow( filtered_row )

if __name__ == '__main__':
    filter_csv( 'cities1000.txt', 'cities1000_filtered.csv' )