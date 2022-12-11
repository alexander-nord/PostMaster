#!/usr/bin/env perl
#
#  BuildSiteShell.pl - Alex Nord, 2022
#
#  Input file consists of 4 unlabeled lines with the following:
#     - Site name
#     - Owner's name
#     - Github username (or '0')
#     - Domain name     (or '0')
#
use warnings;
use strict;
use POSIX;

sub LocateScript { return './' if ($0 !~ /\//); $0 =~ /^(.*\/)[^\/]+$/; return $1; }
use lib LocateScript();
use bureaucracy;
use markdown_to_html;



if (@ARGV != 2) {
	die "\n  USAGE: ./BuildSiteShell.pl [Site-Info-File]\n\n";
}



my $all_sites_dir_name = LocateScript();
if ($all_sites_dir_name eq 'BuildSiteShell.pl') {
	$all_sites_dir_name = '../sites/';
} else {
	$all_sites_dir_name =~ s/src\/BuildSiteShell.pl$/sites\//;
}

if (!(-d $all_sites_dir_name)) {
	CreateDirectory($all_sites_dir_name);
}
$all_sites_dir_name = ConfirmDirectory($all_sites_dir_name);


my $info_file_name = ConfirmFile($ARGV[0]);
my $InfoFile = OpenInputFile($info_file_name);

# Site name
my $site_name = <$InfoFile>;
$site_name =~ s/\n|\r//g;
$site_name =~ s/^\s*//;
$site_name =~ s/\s*$//;

# Owner's name
my $owner_name = <$InfoFile>;
$owner_name =~ s/\n|\r//g;
$owner_name =~ s/^\s*//;
$owner_name =~ s/\s*$//;

# Github username
my $github_username = <$InfoFile>;
$github_username =~ s/\n|\r//g;
$github_username =~ s/^\s*//;
$github_username =~ s/\s*$//;

# Domain name
my $domain = <$InfoFile>;
$domain =~ s/\n|\r//g;
$domain =~ s/^\s*//;
$domain =~ s/\s*$//;

close($InfoFile);


my $new_site_dir_name;
if ($github_username) {
	$new_site_dir_name = NameDirectory($all_sites_dir_name.$site_name);
	if (system("git clone https://github.com/$github_username/$github_username.github.io \"$new_site_dir_name\"")) {
		die "\n  ERROR:  Failed to link GitHub user page '$github_username.github.io'\n\n";
	}
} else {
	$new_site_dir_name = CreateDirectory($all_sites_dir_name.$site_name);
}


my $PM_data_dir_name = $new_site_dir_name;
$PM_data_dir_name =~ s/\/$/\-PostMaster\-Data/;
$PM_data_dir_name = CreateDirectory($PM_data_dir_name);


my $style_dir_name = CreateDirectory($new_site_dir_name.'style');

my $default_style_dir_name = $all_sites_dir_name;
$default_style_dir_name =~ s/sites\//style\//;
$default_style_dir_name = ConfirmDirectory($default_style_dir_name);

my $default_files_dir_name = $all_sites_dir_name;
$default_files_dir_name =~ s/sites\//files\//;

RunSystemCommand("cp \"$default_style_dir_name".'default.css'."\" \"$style_dir_name\"");
RunSystemCommand("cp \"$default_style_dir_name".'default.fontlinks.html'."\" \"$style_dir_name\"");


my $file_dir_name = CreateDirectory($new_site_dir_name.'files');
my $imgs_dir_name = CreateDirectory($file_dir_name.'imgs');
my $docs_dir_name = CreateDirectory($file_dir_name.'docs');

RunSystemCommand("cp \"$default_files_dir_name".'default.jpg'."\" \"$imgs_dir_name\"");


my $statics_dir_name = CreateDirectory($new_site_dir_name.'statics');


my $metadata_file_name = $PM_data_dir_name.'metadata';
my $MetaDataFile = OpenOutputFile($metadata_file_name);
print $MetaDataFile "SITE:$site_name\n";
print $MetaDataFile "OWNER:$owner_name\n";
print $MetaDataFile "GITHUB:$github_username";
print $MetaDataFile "DOMAIN:$domain\n";
print $MetaDataFile "CSS:style/default.css\n";
print $MetaDataFile "FONTS:style/default.fontlinks.html\n";
print $MetaDataFile "AUTOGRAPH:files/imgs/default.jpg\n";





1;