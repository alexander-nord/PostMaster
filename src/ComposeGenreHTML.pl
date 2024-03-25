#!/usr/bin/env perl
use warnings;
use strict;
use POSIX;
use Cwd;


my $WORKING_DIR = getcwd();
$WORKING_DIR = $WORKING_DIR.'/' if ($WORKING_DIR !~ /\/$/);

my $SCRIPT_DIR = $0;
$SCRIPT_DIR =~ s/\/?[^\/]+$//;
$SCRIPT_DIR = '.' if (!$SCRIPT_DIR);
$SCRIPT_DIR = $SCRIPT_DIR.'/';


sub GatherKeywords;
sub ComposeGenre;


if (@ARGV != 1) {
	die "\n  USAGE:  ./ComposeGenreHTML.pl [path/to/genre/dir]\n\n";
}


my $genre_dir_name = $ARGV[0];
if (!(-d $genre_dir_name)) {
	die "\n  ERROR:  Failed to locate genre directory '$genre_dir_name'\n\n";
}
$genre_dir_name = $genre_dir_name.'/' if ($genre_dir_name !~ /\/$/);


ComposeGenre($genre_dir_name);



1;







###################################################################
#
#  Function:  RipTextFromFile
#
sub RipTextFromFile
{

	my $filename = shift;

	if (!(-e $filename)) {
		die "\n  ERROR:  Failed to locate file '$filename' (ComposeGenreHTML.pl)\n\n";
	}
	open(my $File,'<',$filename)
		|| die "\n  ERROR:  Failed to open file '$filename' (ComposeGenreHTML.pl)\n\n";

	my $text = '';
	while (my $line = <$File>) {
		$line =~ s/\n|\r//g;
		$text = $text.$line."\n";
	}
	close($File);

	return $text;

}






###################################################################
#
#  Function:  GatherKeywords
#
sub GatherKeywords
{
	my $genre_dir_name = shift;

	my $site_dir_name = $genre_dir_name;
	$site_dir_name =~ s/\/[^\/]+\/$/\//;

	my @MetadataFileNames;
	push(@MetadataFileNames,$genre_dir_name.'.metadata');
	push(@MetadataFileNames, $site_dir_name.'.metadata');


	my %Keywords;
	foreach my $metadata_file_name (@MetadataFileNames) {

		if (!(-e $metadata_file_name)) {
			die "\n  ERROR:  Failed to locate metadata file '$metadata_file_name' (ComposeGenreHTML.pl)\n\n";
		}

		open(my $MetadataFile,'<',$metadata_file_name)
			|| die "\n  ERROR:  Failed to open metadata file '$metadata_file_name' (ComposeGenreHTML.pl)\n\n";
		while (my $line = <$MetadataFile>) {
			if ($line =~ /^\s*(\S+)\s*\:\s*(.+)\s*$/) {
				$Keywords{$1} = $2;
			}
		}
		close($MetadataFile);

	}


	# The font, navbar, and postlist files are likely relative to the site 
	# directory location, so we'll need to make sure we're looking
	# in the right place
	if (!(-e $Keywords{'FONTS'     })) { $Keywords{'FONTS'     } = $site_dir_name.$Keywords{'FONTS'     }; }
	if (!(-e $Keywords{'NAVBARJS'  })) { $Keywords{'NAVBARJS'  } = $site_dir_name.$Keywords{'NAVBARJS'  }; }
	if (!(-e $Keywords{'POSTLISTJS'})) { $Keywords{'POSTLISTJS'} = $site_dir_name.$Keywords{'POSTLISTJS'}; }


	return \%Keywords;


}






###################################################################
#
#  Function:  ComposeGenre
#
sub ComposeGenre
{
	
	my $genre_dir_name = shift;

	my $keywords_ref = GatherKeywords($genre_dir_name);
	my %Keywords = %{$keywords_ref};

	my $genre_template_file_name = $SCRIPT_DIR.'templates/genre.html';

	my $html_file_name = $genre_dir_name.'index.html';
	open(my $HTMLFile,'>',$html_file_name)
		|| die "\n  ERROR:  Failed to open output HTML file '$html_file_name' (ComposeGenreHTML.pl)\n\n";

	open(my $TemplateFile,'<',$genre_template_file_name)
		|| die "\n  ERROR:  Failed to open template genre HTML file '$genre_template_file_name' (ComposeGenreHTML.pl)\n\n";


	while (my $line = <$TemplateFile>) {

		$line =~ s/\n|\r//g;

		while ($line =~ /__PM_([A-Z]+)/) {

			my $keyword = $1;
			my $text_to_replace = "__PM_$keyword";

			my $replacement_text;
			if ($keyword eq 'POSTLISTJS' || $keyword eq 'NAVBARJS' || $keyword eq 'FONTS') {
				
				$replacement_text = RipTextFromFile($Keywords{$keyword});

				# If this is the blog text, we've already found and printed the title				
				if ($keyword eq 'BLOGTEXT') {
					$replacement_text =~ s/<h1>.*<\/h1>//;
				}

			} else {

				$replacement_text = $Keywords{$keyword};

			}

			if (!$replacement_text) {
				die "\n  ERROR:  Unable to find a replacement for '$text_to_replace' in blog template (ComposeBlogHTML.pl)\n\n";
			}

			$line =~ s/$text_to_replace/$replacement_text/;

		}

		print $HTMLFile "$line\n";

	}

	close($TemplateFile);
	close($HTMLFile);


}





