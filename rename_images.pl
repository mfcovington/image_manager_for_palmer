#!/usr/bin/env perl
# FILE_NAME.pl
# Mike Covington
# created: 2012-12-06
#
# Description:
#
use strict;
use warnings;
use autodie;
use feature 'say';
use File::Find;
use File::Copy;
use Image::ExifTool qw(:Public);
use Getopt::Long;

my $img_dir = "./";
my $log_dir = "./";
my $no_log;
my $options = GetOptions(
    "img_dir=s" => \$img_dir,
    "log_dir=s" => \$log_dir,
    "no_log"    => \$no_log,
);
my $autotransfer_dir = $img_dir . "/auto_transfer/";
my $organized_dir    = $img_dir . "/organized/";


my @images;
find( sub { push @images, $File::Find::name if /IMG_\d*\.CR2$/ },
    $autotransfer_dir );

rename_images(@images);

sub rename_images {
    for my $image_name (@_) {
        my $info_subset = ImageInfo(
            $image_name, 'OwnerName', 'CreateDate', 'MeasuredEV', 'FileType'
        );
        my $camera_name = $info_subset->{'OwnerName'};
        my ( $date, $time ) = split / /, $info_subset->{'CreateDate'};
        $date =~ s/://g;
        $time =~ s/://g;
        my $format = $info_subset->{'FileType'};
        my $image_name_new = join ".", $date, $time, $camera_name, $format;
        my $out_dir = $organized_dir;
        move( $image_name, $out_dir . $image_name_new );
    }
}

exit;

__END__

make dirs if needed
move darktime images to different dir
Make log of all transfers and renaming!