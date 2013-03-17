#!/usr/bin/env perl
# fix_orientation.pl
# Mike Covington
# created: 2013-03-16
#
# Description:
#
use strict;
use warnings;
use File::Find;
use Image::ExifTool qw(:Public);

my $image_dir = $ARGV[0];
my $format = "CR2";
my @images;
find( sub { push @images, $File::Find::name if /\.$format$/ }, $image_dir );
fix_orientation(@images);

sub fix_orientation {
    for my $image_name (@_) {
        my $exifTool = new Image::ExifTool;
        $exifTool->SetNewValue('Rotation', 0);
        $exifTool->SetNewValue('Orientation', 'Horizontal (normal)');
        $exifTool->WriteInfo($image_name);
    }
}

exit;
