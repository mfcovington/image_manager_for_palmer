#!/usr/bin/env perl
# check_autoimport.pl
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
use Image::ExifTool qw(:Public);
use Getopt::Long;
use List::Util 'min';
use Data::Printer;

# TODO:
# - Add help/usage statement
# - Display results in a better way

my $autotransfer_dir =
  "/Users/palmer/Desktop/image_manager_for_palmer/auto_transfer/";
my $format  = "CR2";
my $options = GetOptions(
    "autotransfer_dir=s" => \$autotransfer_dir,
    "format=s"           => \$format,
);

my @images;
find( sub { push @images, $File::Find::name if /\.$format$/ },
    $autotransfer_dir );

my %cam_counter;
my @timestamps;
for my $image_name (@images) {
    my $info_subset = ImageInfo( $image_name, 'OwnerName', 'CreateDate' );
    my ( $date, $time ) = split / /, $info_subset->{'CreateDate'};

    $date =~ s/://g;
    $time =~ s/://g;
    my $datetime = join ".", $date, $time;
    $cam_counter{ $info_subset->{'OwnerName'} }++;
    push @timestamps, $datetime;
}
my $oldest_image = min @timestamps;

p %cam_counter;
say "oldest image: $oldest_image";

exit;