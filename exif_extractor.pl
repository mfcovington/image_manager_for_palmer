#!/usr/bin/env perl
# exif_extractor.pl
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
use Getopt::Long;

my ( $image, $all, $help );
my $options = GetOptions(
    "image=s" => \$image,
    "all"     => \$all,
    "help"    => \$help,
);

my $usage = <<USAGE_END;

USAGE:
$0
  --image    Image name
  --all      Extract all Metadata
               by default, extracts:
                 * CreateDate
                 * Directory
                 * FileName
                 * FileNumber
                 * MeasuredEV
                 * OwnerName
  --help

USAGE_END

die "**NO IMAGE SPECIFIED**\n" . $usage unless $image;
die $usage if $help;

if ($all) {
    p ImageInfo($image);
}
else {
    p ImageInfo(
        $image,       'CreateDate', 'Directory', 'FileName',
        'FileNumber', 'MeasuredEV', 'OwnerName'
    );
}

exit;
