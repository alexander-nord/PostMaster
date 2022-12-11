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

sub UpdateRecentPostsFile;



if (@ARGV != 3) { die "\n  USAGE:  ./AddBlog.pl [Site-Name] [Blog-Genre] [File.md]\n\n"; }



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


my $genre = $ARGV[1];

my $formatted_genre = lc($genre);
$formatted_genre =~ s/\s/\_/g;

my $genre_dir_name = $site_dir_name.$formatted_genre;
if (!(-d $genre_dir_name)) {
	die "\n  ERROR:  Need to create new genre ($genre) before adding blogs\n\n";
}


my $markdown_file_name = $ARGV[2];

my $output_html_str = ApplyHTMLTemplateToMarkdownFile($markdown_file_name,$genre_dir_name,'blog');
if (!$output_html_str) {
	die "\n  Blog creation failed (bad template application attempt)\n\n";
}


# We should be able to extract a title from the formatted html
my $title;
if ($output_html_str =~ /\<h\d\>([^\<]+)\</) {
	$title = $1;
} else {
	die "\n  Blog creation failed (no title found)\n\n";
}


# Make the title friendly for a file name
my $formatted_title = $title;
$formatted_title =~ s/\s/\%20/g;
$formatted_title =~ s/\"|\'|\;|\.|\/|\!|\?|\&|\#//g;

# We'll incorporate the posting date into the URL
my ($year,$month,$day) = GetYearMonthDayNum();
if ($month < 10) { $month = '0'.$month; }
if ($day   < 10) { $day   = '0'.$day;   }

my $formatted_date = $year.'-'.$month.'-'.$day;

# What's the file name (final bit of 'URL-ery')?
my $output_html_name = $genre_dir_name.$formatted_date.'_'.$formatted_title.'.html';
$output_html_name =~ s/\s/\%20/g;

# WRITE THE HTML FILE!
my $HTMLOutFile = OpenOutputFile($output_html_name);
print $HTMLOutFile "$output_html_str";
close($HTMLOutFile);


# That's it for 
my $post_img = '-';
if ($output_html_str =~ /\<img[^\>]+src\=\"([^\"]+)\"/) {
	$post_img = $1;
}


# Add the file to our list of ALL recent posts
UpdateRecentPostsFile($site_dir_name,"\"$title\" $output_html_name $formatted_date $post_img");

# Add the file to the genre-specific list of recent posts
UpdateRecentPostsFile($genre_dir_name,"\"$title\" $output_html_name $formatted_date $post_img");

1;





#######################################################################
#
#  Function:  UpdateRecentPostsFile
#
sub UpdateRecentPostsFile
{
	my $dir_name = shift;
	my $post_data_str = shift;

	my $recent_posts_fname = $dir_name.'recent-posts';

	my $tmp_recents_fname = $recent_posts_fname.'.tmp';
	my $TmpRecentsFile = OpenOutputFile($tmp_recents_fname);
	print $TmpRecentsFile "$post_data_str\n";

	if (FileExists($recent_posts_fname)) {
		my $RecentPostsFile = OpenInputFile($recent_posts_fname);
		while (my $line = <$RecentPostsFile>) {
			$line =~ s/\n|\r//g;
			if ($line =~ /^\s*(\".+\" \S+)\s*$/) {
				print $TmpRecentsFile "$1\n";
			}
		}
		close($RecentPostsFile);
	}

	close($TmpRecentsFile);

	RunSystemCommand("mv \"$tmp_recents_fname\" \"$recent_posts_fname\"");

}

