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

# Add help/usage statement

my $dawn             = 6;
my $daylength        = 16;
my $mEV_threshold    = 7;
my $autotransfer_dir = "/Volumes/Humperdink/auto_transfer/";
my $log_dir          = "/Volumes/Humperdink/";
my $irods_dir        = "/iplant/home/shared/ucd.brassica/raw.data/NAM_images/";
my $format           = "CR2";
my $options = GetOptions(
    "dawn=i"             => \$dawn,
    "daylength=i"        => \$daylength,
    "mEV_threshold=i"    => \$mEV_threshold,
    "autotransfer_dir=s" => \$autotransfer_dir,
    "log_dir=s"          => \$log_dir,
    "irods_dir=s"        => \$irods_dir,
    "format=s"           => \$format,
);
$autotransfer_dir =~ / (.*\/) [^\/]+ /x;
my $base_dir = $1 || "";
my $organized_dir = $base_dir . "organized/";
my $night_dir     = $base_dir . "night/";
my $conflict_dir  = $base_dir . "conflict/";

make_path($log_dir);
open my $log_fh, ">>", "$log_dir/image_transfer.log";
say $log_fh "▼ STARTING - " . localtime();

my @images;
find( sub { push @images, $File::Find::name if /\.$format$/ },
    $autotransfer_dir );

if ( scalar @images > 0 ) {
    rename_images(@images);
    upload_to_iplant();
}

say $log_fh "- FINISHED - " . localtime();
close $log_fh;

sub rename_images {
    for my $image_name (@_) {
        my $info_subset = ImageInfo(
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
    return 1
      if ( $dawn + $daylength <= 24 && $hour > $dawn && $hour < $dawn + $daylength )
      || ( $dawn + $daylength > 24 && $hour > $dawn )
      || ( $dawn + $daylength > 24 && $hour < $dawn + $daylength - 24 );
}

sub is_light {
    return 1 if shift > $mEV_threshold;
}

sub upload_to_iplant {
    system("imkdir -p $irods_dir");
    my $irsync_cmd = "  irsync -r $organized_dir i:$irods_dir";
    system($irsync_cmd);
    say $log_fh $irsync_cmd;
}

exit;
