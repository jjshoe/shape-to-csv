#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

my @urls =
(
	'ftp://ftp2.census.gov/geo/tiger/TIGER2013/COUNTY/tl_2013_us_county.zip',
);

my @places_numbers = 
( 
	'01', 
	'02', 
	'04', 
	'05', 
	'06', 
	'08', 
	'09', 
	'10', 
	'11', 
	'12', 
	'13', 
	'15', 
	'16', 
	'17', 
	'18', 
	'19', 
	'20',	
	'21', 
	'22',
	'23', 
	'24', 
	'25', 
	'26', 
	'27', 
	'28', 
	'29', 
	'30', 
	'31', 
	'32', 
	'33', 
	'34', 
	'35', 
	'36', 
	'37',
	'38', 
	'39', 
	'40', 
	'41', 
	'42', 
	'44', 
	'45', 
	'46', 
	'47', 
	'48', 
	'49', 
	'50', 
	'51', 
	'53', 
	'54', 
	'55', 
	'56',
);

my @files = ();

# Numbers for each of the states, we assemble the urls and push them onto the list
foreach my $number (@places_numbers)
{
	push(@urls , "ftp://ftp2.census.gov/geo/tiger/TIGER2013/PLACE/tl_2013_" . $number . "_place.zip");
}

# Download the url if we haven't already downloaded the file (someday we should cache a hash)
foreach my $url (@urls)
{
	my @url_pieces = split('/', $url);

	my $file = $url_pieces[(scalar(@url_pieces) - 1)];
	
	push (@files, "downloads/$file");

	if (!-f 'downloads/' . $file)
	{
		print "Downloading $url\n"; 
		`wget $url -P downloads`;
	}
}

# Extract each file and convert dot file to csv
`unzip -n -d downloads downloads/\\*zip`;

# Convert .shp to .kml
if (opendir(my $dh, 'downloads'))
{
	while (my $file = readdir($dh))
	{
		if ($file =~ /\.shp$/)
		{
			my @path_pieces = split('/', $file);
		
			my $shape_file = $path_pieces[(scalar(@path_pieces) - 1)];
			my $kml_file = $shape_file;
			my $error_file = $shape_file;
			my $csv_file = $shape_file;

			$kml_file =~ s/\.shp/\.kml/;
			$error_file =~ s/\.shp/\.error/;
			$csv_file =~ s/\.shp/\.csv/;

			`ogr2ogr -f "KML" downloads/$kml_file downloads/$shape_file`;
			`perl ../kml-to-csv/kml_to_csv.pl --kml_file=downloads/$kml_file --error_file=$error_file --xpath_to_loop='/kml/Document/Folder/Placemark' --names_for_values name Location --xpath_to_values name Polygon,MultiGeometry --xpath_to_values_retain_xml 0 1 --default_column_names color --default_column_values B5BAB6 >> ./$csv_file`;

			if (!-s $error_file)
			{
				unlink($error_file);
			}
		}
	}

	close($dh);
}
else
{
	die "Unable to open 'downloads'";
}
