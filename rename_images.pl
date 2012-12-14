#!/usr/bin/env perl
# rename_images.pl
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
use File::Path 'make_path';
use Image::ExifTool qw(:Public);
use Getopt::Long;
use POSIX 'strftime';

# Add help/usage statement

my $dawn             = 6;
my $daylength        = 16;
my $mEV_threshold    = 7;
my $autotransfer_dir = "/Users/palmer/Desktop/image_manager_for_palmer/auto_transfer/";
my $log_dir          = "/Users/palmer/Desktop/image_manager_for_palmer/";
my $irods_dir        = "/iplant/home/shared/ucd.brassica/raw.data/NAM_images/";
my $format           = "CR2";
my $no_log;
my $options = GetOptions(
    "dawn=i"             => \$dawn,
    "daylength=i"        => \$daylength,
    "mEV_threshold=i"    => \$mEV_threshold,
    "autotransfer_dir=s" => \$autotransfer_dir,
    "log_dir=s"          => \$log_dir,
    "irods_dir=s"        => \$irods_dir,
    "format=s"           => \$format,
    "no_log"             => \$no_log,
);
my ($base_dir) = $autotransfer_dir =~ / (.*\/) [^\/]+ /x;
my $now = timestamp_for_dir();
my $organized_dir = $base_dir . "organized/$now/";
my $night_dir     = $base_dir . "night/$now/";
my $conflict_dir  = $base_dir . "conflict/$now/";
$irods_dir .= "/$now/";

make_path($log_dir);
open my $log_fh, ">>", "$log_dir/image_transfer.log" unless $no_log;
say $log_fh "STARTING - " . localtime() unless $no_log;

my @images;
find( sub { push @images, $File::Find::name if /\.$format$/ },
    $autotransfer_dir );

my @renamed_images = rename_images(@images);
upload_to_iplant(@renamed_images);

say $log_fh "FINISHED - " . localtime() unless $no_log;

sub timestamp_for_dir {
    return strftime "%Y%m%d.%H%M%S", localtime;
}

sub rename_images {
    my @new_names;
    make_path( $organized_dir, $night_dir, $conflict_dir ) if scalar @_ > 0;
    for my $image_name (@_) {
        my $info_subset = ImageInfo(
            $image_name, 'OwnerName', 'CreateDate', 'MeasuredEV',
            'FileType'
        );

        my ( $date, $time ) = split / /, $info_subset->{'CreateDate'};
        my $day   = is_day($time);
        my $light = is_light( $info_subset->{'MeasuredEV'} );
        my $out_dir;
        if    ( $day  && $light )  { $out_dir = $organized_dir }
        elsif ( !$day && !$light ) { $out_dir = $night_dir }
        else                       { $out_dir = $conflict_dir }

        $date =~ s/://g;
        $time =~ s/://g;
        my $camera_name    = $info_subset->{'OwnerName'};
        my $format         = $info_subset->{'FileType'};
        my $image_name_new = join ".", $date, $time, $camera_name, $format;

        my $new_path = $out_dir . $image_name_new;
        move( $image_name, $new_path );
        push @new_names, $new_path;
        say $log_fh "  mv $image_name $new_path" unless $no_log;
    }
    return @new_names;
}

sub is_day {
    my ( $hh, $mm ) = split /:/, shift;
    my $hour = $hh + $mm / 60;
    return 1
      if ( $dawn + $daylength <= 24 && $hour > $dawn && $hour < $dawn + $daylength )
      || ( $dawn + $daylength > 24 && $hour > $dawn )
      || ( $dawn + $daylength > 24 && $hour < $dawn + $daylength - 24 );
}

sub is_light {
    return 1 if shift > $mEV_threshold;
}

sub upload_to_iplant {
    if ( scalar @_ > 0 ) {
        system("imkdir $irods_dir");
        for my $image_name (@_) {
            next unless $image_name =~ m/organized/;
            system("icd $irods_dir");
            system("iput -T $image_name");
            say $log_fh "  iput -T $image_name" unless $no_log;
        }
    }
}

exit;