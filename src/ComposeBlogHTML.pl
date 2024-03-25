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


sub RipTextFromFile;
sub ComposeBlog;
sub GatherKeywords;
sub GrabTitleFromHTML;
sub TitleToHTMLFilename;
sub GetFormattedDate;



if (@ARGV != 1) {
	die "\n  USAGE:  ./ComposeBlogHTML.pl [path/to/blog/dir]\n\n";
}


my $blog_dir_name = $ARGV[0];
$blog_dir_name = $blog_dir_name.'/' if ($blog_dir_name !~ /\//);
if (!(-d $blog_dir_name)) {
	die "\n  ERROR:  Failed to locate blog directory '$ARGV[0]' (ComposeBlogHTML.pl)\n\n";
}


my $blog_file_name = ComposeBlog($blog_dir_name);


print "PAGE: $blog_file_name\n";


1;







###################################################################
#
#  Function:  RipTextFromFile
#
sub RipTextFromFile
{

	my $filename = shift;

	if (!(-e $filename)) {
		die "\n  ERROR:  Failed to locate file '$filename' (ComposeBlogHTML.pl)\n\n";
	}
	open(my $File,'<',$filename)
		|| die "\n  ERROR:  Failed to open file '$filename' (ComposeBlogHTML.pl)\n\n";

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
#  Function:  ComposeBlog
#
sub ComposeBlog
{
	
	my $blog_dir_name = shift;

	my $keywords_ref  = GatherKeywords($blog_dir_name);
	my %Keywords = %{$keywords_ref};

	my $blog_template_file_name = $SCRIPT_DIR.'templates/blog.html';

	my $blog_html_file_name = TitleToHTMLFilename($Keywords{'TITLE'});
	if ($blog_html_file_name eq '.html') {
		die "\n  ERROR:  Failed to put convert blog title '$Keywords{'TITLE'}' to an html title (ComposeBlogHTML.pl)\n\n";
	}
	$blog_html_file_name = $blog_dir_name.$blog_html_file_name;


	open(my $HTMLFile,'>',$blog_html_file_name)
		|| die "\n  ERROR:  Failed to open output HTML file '$blog_html_file_name' (ComposeBlogHTML.pl)\n\n";

	open(my $TemplateFile,'<',$blog_template_file_name)
		|| die "\n  ERROR:  Failed to open template blog HTML file '$blog_template_file_name' (ComposeBlogHTML.pl)\n\n";


	while (my $line = <$TemplateFile>) {

		$line =~ s/\n|\r//g;

		while ($line =~ /__PM_([A-Z]+)/) {

			my $keyword = $1;
			my $text_to_replace = "__PM_$keyword";

			my $replacement_text;
			if ($keyword eq 'BLOGTEXT' || $keyword eq 'NAVBARJS' || $keyword eq 'FONTS') {
				
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


	return $blog_html_file_name;

}






###################################################################
#
#  Function:  GatherKeywords
#
sub GatherKeywords
{

	my $blog_dir_name = shift;


	my $genre_dir_name = $blog_dir_name;
	$genre_dir_name =~ s/\/[^\/]+\/$/\//;

	my $site_dir_name = $genre_dir_name;
	$site_dir_name =~ s/\/[^\/]+\/$/\//;

	my @MetadataFileNames;
	push(@MetadataFileNames,$genre_dir_name.'metadata.txt');
	push(@MetadataFileNames, $site_dir_name.'metadata.txt');


	my %Keywords;
	foreach my $metadata_file_name (@MetadataFileNames) {

		if (!(-e $metadata_file_name)) {
			die "\n  ERROR:  Failed to locate metadata file '$metadata_file_name' (ComposeBlogHTML.pl)\n\n";
		}

		open(my $MetadataFile,'<',$metadata_file_name)
			|| die "\n  ERROR:  Failed to open metadata file '$metadata_file_name' (ComposeBlogHTML.pl)\n\n";
		while (my $line = <$MetadataFile>) {
			if ($line =~ /^\s*(\S+)\s*\:\s*(.+)\s*$/) {
				$Keywords{$1} = $2;
			}
		}
		close($MetadataFile);

	}

	# What's the actual blog content (hmtl)?!
	$Keywords{'BLOGTEXT'} = $blog_dir_name.'.blog.html';

	# Grab the title from the html, all clever-like
	$Keywords{'TITLE'} = GrabTitleFromHTML($Keywords{'BLOGTEXT'});

	# The blog is considered 'published' when this script is run
	$Keywords{'PUBLISHDATE'} = GetFormattedDate();

	# The font and navbar files are likely relative to the site 
	# directory location, so we'll need to make sure we're looking
	# in the right place
	if (!(-e $Keywords{'FONTS'   })) { $Keywords{'FONTS'   } = $site_dir_name.$Keywords{'FONTS'   }; }
	if (!(-e $Keywords{'NAVBARJS'})) { $Keywords{'NAVBARJS'} = $site_dir_name.$Keywords{'NAVBARJS'}; }

	return \%Keywords;

}





###################################################################
#
#  Function:  GrabTitleFromHTML
#
sub GrabTitleFromHTML
{
	my $filename = shift;

	if (!(-e $filename)) {
		die "\n  ERROR:  Failed to locate blog HTML file '$filename' (ComposeBlogHTML.pl)\n\n";
	}
	open(my $File,'<',$filename)
		|| die "\n  ERROR:  Failed to open blog HTML file '$filename' (ComposeBlogHTML.pl)\n\n";


	my $title;
	while (my $line = <$File>) {
		if ($line =~ /<h1>(.*)<\/h1>/) {
			$title = $1;
			last;
		}
	}
	close($File);


	if (!$title) {
		die "\n  ERROR:  Failed to read blog title (level-1 header) from blog HTML file '$filename' (ComposeBlogHTML.pl)\n\n";
	}


	return $title;

}






###################################################################
#
#  Function:  TitleToHTMLFilename
#
sub TitleToHTMLFilename
{
	my $title = shift;

	$title =~ s/\<[^\>]+\>//g;
	$title =~ s/^\s*//g;
	$title =~ s/\s*$//g;
	$title =~ s/\s/\_/g;
	$title =~ s/\W//g;

	return $title.'.html';

}





###################################################################
#
#  Function:  GetFormattedDate
#
sub GetFormattedDate 
{
	my @Months = ("January","February","March","April","May","June","July","August","September","October","November","December");
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();

	$year += 1900;
	
	my $formatted_day = $mday.'<sup>';
	if    ($mday eq '1' || $mday eq '21' || $mday eq '31') { $formatted_day = $formatted_day.'st'; }
	elsif ($mday eq '2' || $mday eq '22'                 ) { $formatted_day = $formatted_day.'nd'; }
	elsif ($mday eq '3' || $mday eq '23'                 ) { $formatted_day = $formatted_day.'rd'; }
	else                                                   { $formatted_day = $formatted_day.'th'; }
	$formatted_day = $formatted_day.'</sup>';

	return "$year, $Months[$mon] $formatted_day";

}


