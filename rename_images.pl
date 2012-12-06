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
use Data::Printer;
use Getopt::Long;


# my $image_name = $ARGV[0] || '/Users/mfc/sandbox/exif/IMG_0365.CR2';
# my $info_subset = ImageInfo($image_name, 'OwnerName', 'CreateDate', 'WB_RGGBLevels', 'ColorTempAsShot', 'FileType', 'Directory');
# my $camera_name = $info_subset->{'OwnerName'};
# my ( $date, $time ) = split / /, $info_subset->{'CreateDate'};
# $date =~ s/://g;
# $time =~ s/://g;
# my $format = $info_subset->{'FileType'};
# my $image_name_new = join ".", $date, $time, $camera_name, $format;
# say $image_name_new;
# my $out_dir = $info_subset->{'Directory'};
# say $out_dir;


my $img_dir = "./";
my $options = GetOptions( "img_dir=s" => \$img_dir, );

my $autotransfer_dir = $img_dir . "/auto_transfer/";
my $organized_dir    = $img_dir . "/organized/";

my @images;
find( sub { push @images, $File::Find::name if /IMG_\d*\.CR2$/ },
    $autotransfer_dir );

# find(sub {say $File::Find::name if /IMG_\d*\.CR2$/ }, "/Users/mfc/sandbox/exif/");
# p @images;

for my $image_name (@images) {
    my $info_subset =
      ImageInfo( $image_name, 'OwnerName', 'CreateDate', 'WB_RGGBLevels',
        'ColorTempAsShot', 'FileType', 'Directory' );
    my $camera_name = $info_subset->{'OwnerName'};
    my ( $date, $time ) = split / /, $info_subset->{'CreateDate'};
    $date =~ s/://g;
    $time =~ s/://g;
    my $format = $info_subset->{'FileType'};
    my $image_name_new = join ".", $date, $time, $camera_name, $format;

    # say $image_name_new;
    my $out_dir = $info_subset->{'Directory'};

    # say $out_dir;
    move( $image_name, $organized_dir . $image_name_new );
}

exit;

__END__
19800101.013047.Mildred.CR2

my $out_dir = $info_subset->{'Directory'};
my $image_name_new = "$out_dir/$camera_name.$date.$time.$format";
say $image_name_new;

# copy( $image_name, $image_name_new ); # or move()
# move( "$old_dir/$image_name", "$new_dir/$image_name_new" );
copy( "$old_dir/$image_name", "$new_dir/$image_name_new" );



my $img_dir = "./";
my $options = GetOptions( "img_dir=s" => \$img_dir, );

my $autotransfer_dir = $img_dir . "/auto_transfer/";
my $organized_dir    = $img_dir . "/organized/";

find(\&do_something_with_file, $autotransfer_dir);

sub do_something_with_file
{
    #.....
    # construct new name
    move( "$autotransfer_dir/fileA", "$organized_dir/fileB" );
}

__END__


Cameras are named cam001 - cam104

auto-transfer directory is set by us

Each cam creates a new folder each its connected.

Auto-naming scheme: `./11_29_12 1/IMG_####.CR2`


    ./image_dir/
               /auto_transfer/
                             /11_29_12\ 1/IMG_####.CR2
               /organized/
                         /20121129_160930_cam001.CR2

Make log of all transfers and renaming!