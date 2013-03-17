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
use Getopt::Long;

my $format = "CR2";
my ( $image_dir, $help );
my $options = GetOptions(
    "image_dir=s" => \$image_dir,
    "format=s"    => \$format,
    "help"        => \$help,
);

my $usage = <<EOF;

    USAGE:
    $0
        --image_dir    Directory containing images
                         [$image_dir]
        --format       Image file format [$format]
        --help

EOF

die $usage if $help;
die $usage unless $image_dir;

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
