#!/usr/bin/env perl
#
#  AddGenre.pl - Alex Nord, 2022
#
use warnings;
use strict;
use POSIX;

sub LocateScript { return './' if ($0 !~ /\//); $0 =~ /^(.*\/)[^\/]+$/; return $1; }
use lib LocateScript();
use bureaucracy;
use markdown_to_html;


sub ConfirmLegalGenre;


if (@ARGV != 3) {
	die "\n  USAGE:  ./AddGenre.pl [Site-Name] [New-Genre] [Genre-Description.md]\n\n";
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


my $markdown_file_name = $ARGV[2];
if (!(-e $markdown_file_name)) {
	die "\n  ERROR:  Failed to locate text file '$ARGV[2]' (text describing blog genre)\n\n";
}


my $new_genre = ConfirmLegalGenre($ARGV[1]);
my $formatted_genre = lc($new_genre);
$formatted_genre =~ s/\s/\_/g;

my $genre_dir_name = $site_dir_name.$formatted_genre;
if (-d $genre_dir_name) {
	die "\n  ERROR:  Genre '$new_genre' already exists\n\n";
}
$genre_dir_name = CreateDirectory($genre_dir_name);


# Get the HTML-ified version of the genre description
my $genre_index_html = ApplyHTMLTemplateToMarkdownFile($markdown_file_name,$genre_dir_name,'genre');

if (!$genre_index_html) {
	RunSystemCommand("rm -rf \"$genre_dir_name\"");
	die "\n  ERROR:  Failed to parse genre description file '$markdown_file_name' into html template\n\n";
}

my $genre_index_filename = $genre_dir_name.'index.html';
my $GenreIndex = OpenOutputFile($genre_index_filename);
print $GenreIndex "$genre_index_html";
close($GenreIndex);

my $genre_list_filename = $site_dir_name.'blog-genres';
my $GenreListFile = AppendToOutputFile($genre_list_filename);
print $GenreListFile "$new_genre\n";
close($GenreListFile);

PlanGitOperation($genre_index_filename,'add');
PlanGitOperation($genre_list_filename,'add');

1;






#######################################################################
#
#  Function:  GenreIsLegal
#
sub ConfirmLegalGenre
{
	my $desired_genre_name = shift;

	if ($desired_genre_name =~ /\/|\%|\\/) {
		die "\n  ERROR:  Illegal genre name (no funny characters, please!)\n\n";
	}

	if ($desired_genre_name eq '.' || $desired_genre_name eq '..') {
		die "\n  ERROR:  Illegal genre name (nice try, though!)\n\n";
	}

	return $desired_genre_name;
}









