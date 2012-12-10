#!/usr/bin/env perl
# exif_extractor.pl.pl
# Mike Covington
# created: 2012-11-05
#
# Description:
#
use strict;
use warnings;
use autodie;
use feature 'say';
use Data::Printer;
use Image::ExifTool qw(:Public);

my $image_name = $ARGV[0] || die "no image specified\nUSAGE: $0 image_name.format\n";

# in case Palmer wants to extract a subset:
# my $info_subset = ImageInfo($image_name, 'OwnerName', 'CreateDate', 'WB_RGGBLevels', 'ColorTempAsShot', 'FileType', 'Directory');
# p $info_subset;

my $info_all = ImageInfo($image_name);
p $info_all;

exit;