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

my $dawn             = 6;
my $daylength        = 16;
my $mEV_threshold    = 7;
my $autotransfer_dir = "/Volumes/Humperdink/auto_transfer/";
my $log_dir          = "/Volumes/Humperdink/";
my $irods_dir        = "/iplant/home/shared/ucd.brassica/raw.data/NAM_images/";
my $format           = "CR2";
my $keep_rot;
my $help;
my $options = GetOptions(
    "dawn=i"             => \$dawn,
    "daylength=i"        => \$daylength,
    "mEV_threshold=i"    => \$mEV_threshold,
    "autotransfer_dir=s" => \$autotransfer_dir,
    "log_dir=s"          => \$log_dir,
    "irods_dir=s"        => \$irods_dir,
    "format=s"           => \$format,
    "keep_rotation"      => \$keep_rot,
    "help"               => \$help,
);

my $usage = <<EOF;

    USAGE:
    $0
        --dawn              Time of lights-on [$dawn]
        --daylength         Daylength in hours [$daylength]
        --mEV_threshold     Threshold for blank/black images [$mEV_threshold]
        --autotransfer_dir  Directory containing inages transfered from camera
                              [$autotransfer_dir]
        --log_dir           Directory to write the log file
                              [$log_dir]
        --irods_dir         Remote iRODS directory for syncing images
                              [$irods_dir]
        --format            Image file format [$format]
        --keep_rotation     Don't reset 'Rotation' to 0 in exif data
        --help

EOF

die $usage if $help;

$autotransfer_dir =~ / (.*\/) [^\/]+ /x;
my $base_dir      = $1 || "";
my $organized_dir = $base_dir . "organized/";
my $night_dir     = $base_dir . "night/";
my $conflict_dir  = $base_dir . "conflict/";

make_path($log_dir);
open my $log_fh, ">>", "$log_dir/image_transfer.log";
say $log_fh "▼ STARTING - " . localtime();

$format =~ s|^\.+||;
my @images;
find( sub { push @images, $File::Find::name if /\.$format$/ },
    $autotransfer_dir );

rename_images(@images) if scalar @images > 0;
upload_to_irods();

say $log_fh "- FINISHED - " . localtime();
close $log_fh;

sub rename_images {
    for my $image_name (@_) {
        my $exifTool = new Image::ExifTool;
        $exifTool->SetNewValue('Resolution', 0) unless $keep_rot;
        my $info_subset = $exifTool->ExtractInfo(
            $image_name, 'OwnerName', 'CreateDate', 'MeasuredEV',
            'FileType'
        );

        my ( $date, $time ) = split / /, $info_subset->{'CreateDate'};
        my $day   = is_day($time);
        my $light = is_light( $info_subset->{'MeasuredEV'} );

        $date =~ s/://g;
        $time =~ s/://g;
        my $camera_name    = $info_subset->{'OwnerName'};
        my $format         = $info_subset->{'FileType'};
        my $image_name_new = join ".", $date, $time, $camera_name, $format;

        my $out_dir;
        if    ( $day  && $light )  { $out_dir = $organized_dir }
        elsif ( !$day && !$light ) { $out_dir = $night_dir }
        else                       { $out_dir = $conflict_dir }
        $out_dir .= "$date/";
        make_path($out_dir);

        my $new_path = $out_dir . $image_name_new;
        move( $image_name, $new_path )
          and ( say $log_fh "  mv $image_name $new_path" );
    }
}

sub is_day {
    my ( $hh, $mm ) = split /:/, shift;
    my $hour = $hh + $mm / 60;
    my $dusk = $dawn + $daylength;
    return 1
      if ( $dusk <= 24 && $hour > $dawn && $hour < $dusk )
      || ( $dusk  > 24 && $hour > $dawn )
      || ( $dusk  > 24 && $hour < $dusk - 24 );
}

sub is_light {
    return 1 if shift > $mEV_threshold;
}

sub upload_to_irods {
    system("imkdir -p $irods_dir");
    my $irsync_cmd = "  irsync -r $organized_dir i:$irods_dir";
    system($irsync_cmd);
    say $log_fh $irsync_cmd;
}

exit;
