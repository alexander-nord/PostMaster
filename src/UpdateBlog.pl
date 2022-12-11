#!/usr/bin/env perl
#
#  AddBlog.pl - Alex Nord, 2022
#
use warnings;
use strict;
use POSIX;

sub LocateScript { return './' if ($0 !~ /\//); $0 =~ /^(.*\/)[^\/]+$/; return $1; }
use lib LocateScript();
use bureaucracy;
use markdown_to_html;
use integrate_new_content;


if (@ARGV != 2) { die "\n  USAGE:  ./AddBlog.pl [File-Path] [Update.md]\n\n"; }


my $html_filename = $ARGV[0];
my $markdown_filename = $ARGV[1];


if (!FileExists($html_filename)) { 
	die "\n  ERROR:  Failed to locate HTML file '$html_filename'\n\n";
}

if (!FileExists($markdown_filename)) { 
	die "\n  ERROR:  Failed to locate update markdown file '$markdown_filename'\n\n"; 
}


my $update_html = MarkdownToHTMLString($markdown_filename);
$update_html = CopyLocalFilesToSite($update_html);

my $update_date = GetYearMonthDayStr();
$update_date =~ s/(\d)(\w\w)$/$1\<sup\>$2\<\/sup\>/;
$update_html = "<em>".$update_date." Update</em>\n<br>\n".$update_html."\n<br>\n<hline>\n<br>\n";


my $tmp_html_filename = $html_filename;
$tmp_html_filename =~ s/\.html$/\.tmp/;

my $HTMLIn = OpenInputFile($html_filename);
my $HTMLOut = OpenOutputFile($tmp_html_filename);

while (my $line = <$HTMLIn>) {
	print $HTMLOut "$line";
	if ($line =~ /\<div class\=\"blogContent\"/) {
		print $HTMLOut "$update_html";
	}
}

close($HTMLIn);
close($HTMLOut);


RunSystemCommand("mv \"$tmp_html_filename\" \"$html_filename\"");



1;











