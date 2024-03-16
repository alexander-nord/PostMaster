#!/usr/bin/env perl
use warnings;
use strict;
use POSIX;

sub LocateScript { return './' if ($0 !~ /\//); $0 =~ /^(.*\/)[^\/]+$/; return $1; }
use lib LocateScript();
use bureaucracy;
use markdown_to_html;
use integrate_new_content;


if (scalar(@ARGV) != 2) {
	die "\n  USAGE:  ./AddStatic.pl [Site-Name] [File.md] [add-to-navbar?(0|1)]\n\n";
}


my $postmaster_dir_name = LocateScript();
if ($postmaster_dir_name eq './') {
	$postmaster_dir_name = ConfirmDirectory('../');
} else {
	$postmaster_dir_name =~ s/src\/?$//;
	$postmaster_dir_name = ConfirmDirectory($postmaster_dir_name);
}

my $site_dir_name = ConfirmDirectory($postmaster_dir_name.'sites/'.$ARGV[0]);
my $site_data_dir_name = $site_dir_name;
$site_data_dir_name =~ s/\/([^\/]+)\/$/\/\.$1\-PostMaster\-Data\//;
ConfirmDirectory($site_data_dir_name);


my $filename = ConfirmFile($ARGV[1]);

my $add_to_navbar = $ARGV[2];
if ($add_to_navbar ne '0' && $add_to_navbar ne '1') {
	if ($add_to_navbar =~ /f|false|n|no/) {
		$add_to_navbar = 0;
	} elsif ($add_to_navbar =~ /t|true|y|yes/) {
		$add_to_navbar = 1;
	} else {
		die "\n  ERROR:  Unrecognized value for 'add-to-navbar?' argument (0 or 1)\n\n";
	}
}


# Guess whether the static file is html or markdown
my $InFile = OpenInputFile($filename);
my $looks_like_html = 0;
while (my $line = <$InFile>) {
	if ($line =~ '\<html\>|\<body\>|\<p\>|\<div\>') {
		$looks_like_html = 1;
		last;
	}
}
close($InFile);


# If it looks like we've been provided with 
my $html;
if ($looks_like_html) {

	# Simply read the file into our HTML string
	$InFile = OpenInputFile($filename);
	while (my $line = <$InFile>) {
		$line =~ s/^\s+//;
		$html = $html.$line;
	}
	close($InFile);

} else {

	# We're going to assume this is markdown, so
	# let's try parsing it into HTML
	$html = MarkdownToHTMLString($filename);

	if (!$html) {
		die "\n  Static page creation failed (couldn't generate html)\n\n";
	}

}


# We'll need to make sure we know what to call this thing...
my $title;
if ($html =~ /\<h\d\>([^\<]+)\</) {
	$title = $1;
} else {
	die "\n  Static page creation failed (no title found)\n\n";
}

my $formatted_title = $title;
$formatted_title =~ s/\s/\%20/g;
$formatted_title =~ s/\"|\'|\;|\.|\/|\!|\?|\&|\#//g;

if (!(-d $site_dir_name.'statics')) {
	CreateDirectory($site_dir_name.'statics');
}

my $html_file_name = $site_dir_name.'statics/'.$formatted_title.'.html';
if (-e $html_file_name) {
	die "\n  ERROR:  Naming conflict - static page '$html_file_name' already exists\n\n";
}


# If we've made it this far, then we're ready to make this page!
$html = CopyLocalFilesToSite($html);

my $HTMLOutFile = OpenOutputFile($html_file_name);
print $HTMLOutFile "$html";
close($HTMLOutFile);


# Finally, add this to our list of static pages!
my $tmp_fname = $site_dir_name.'statics/tmp';
my $TmpFile = OpenOutputFile($tmp_fname);
print $TmpFile "\"$title\" statics/$formatted_title.html $add_to_navbar\n";

my $static_posts_fname = $site_dir_name.'statics/static-posts';
if (FileExists($static_posts_fname)) {
	my $StaticsFile = OpenInputFile($static_posts_fname);
	while (my $line = <$StaticsFile>) {
		$line =~ s/\n|\r//g;
		next if (!$line);
		print "$line\n";
	}
	close($StaticsFile);
}

close($TmpFile);
RunSystemCommand("mv \"$tmp_fname\" \"$static_posts_fname\"");

PlanGitOperation($static_posts_fname,'add');


1;

