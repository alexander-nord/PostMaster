#
#  integrate_new_content.pm - Alex Nord, 2022
#
use warnings;
use strict;
use POSIX;

sub locate_int_new_con { return './' if ($0 !~ /\//); $0 =~ /^(.*\/)[^\/]+$/; return $1; }
use lib locate_int_new_con();
use bureaucracy; # This is ONLY used for getting dates -- all I/O errors should be highly specific!
use manage_content;
use markdown_to_html;


sub ApplyHTMLTemplateToMarkdownFile;
sub BuildPostHTMLFromTemplate;
sub CopyLocalFilesToSite;



####################################################################
#
#  Function:  ApplyHTMLTemplateToMarkdownFile
#
sub ApplyHTMLTemplateToMarkdownFile
{

	my $markdown_file_name = shift;
	my $genre_dir_name = shift;
	my $intended_type = shift;


	if (!(-e $markdown_file_name)) {
		print "\n  ERROR:  Failed to locate markdown file '$markdown_file_name'\n\n";
		return 0;
	}


	$intended_type = lc($intended_type);
	my $is_blog = 1;
	if ($intended_type eq 'genre') {
		$is_blog = 0;
	} elsif ($intended_type ne 'blog') {
		print "\n  ERROR:  Only supported template types are 'blog' and 'genre' ('$intended_type' requested)\n\n";
		return 0;
	}


	$genre_dir_name = $genre_dir_name.'/' if ($genre_dir_name !~ /\/$/);

	$genre_dir_name =~ /^(.+\/)([^\/]+)\/$/;
	my $site_dir_name = $1;
	my $genre = $2;

	if (!(-d $genre_dir_name)) {
		print "\n  ERROR:  Failed to locate genre '$genre' in site directory '$site_dir_name'\n\n";
		return 0;
	}


	my $site_data_dir_name = $site_dir_name;
	$site_data_dir_name =~ s/\/([^\/]+)\/$/\/\.$1\-PostMaster\-Data\//;

	if (!(-d $site_data_dir_name)) {
		print "\n  ERROR:  Site located at '$site_dir_name' does not appear to be a PostMaster site (failed to locate '$site_data_dir_name')\n\n";
		return 0;
	}


	my %SiteData;
	if (open(my $SiteDataFile,'<',$site_data_dir_name.'metadata')) {
		while (my $line = <$SiteDataFile>) {
			$line =~ s/\n|\r//g;
			if ($line =~ /^([^\:]+)\:(.+)$/) {
				my $label = $1;
				my $datum = $2;
				$datum =~ s/^\s+//;
				$datum =~ s/\s+$//;
				$SiteData{$1} = $2;
			}
		}
		close($SiteDataFile);
	} else {
		print "\n  ERROR:  Failed to locate a 'metadata' file in the directory '$site_data_dir_name'\n\n";
		return 0;
	}


	my $title;
	if (open(my $TitleAwk, 'awk /^\s*#\s+/ "'.$markdown_file_name.'" |')) {
		$title = <$TitleAwk>;
		$title =~ s/\n|\r//g;
		$title =~ s/^\s*\#\s*//;
		$title =~ s/\s*$//;
		close($TitleAwk);
	} else {
		print "\n  ERROR:  Failed to 'awk' a title from the markdown file '$markdown_file_name'\n\n";
		return 0;
	}

	if (!$title && $is_blog) {
		print "\n  ERROR:  No title (level-1 header) detected in markdown file '$markdown_file_name'\n\n";
		return 0;
	}


	$SiteData{'GENRE'} = $genre;
	$SiteData{'TITLE'} = $title if ($is_blog);


	my $postmaster_dir_name = LocateScript();
	if ($postmaster_dir_name eq './') {
		$postmaster_dir_name = '../';
	} else {
		$postmaster_dir_name =~ s/src\/?$//;
	}

	my $template = $postmaster_dir_name.'inc/templates/';
	if ($is_blog) {
		$template = $template.'blog/blog.html';
	} else {
		$template = $template.'genre/genre.html';
	}

	if (!(-e $template)) {
		print "\n  ERROR:  Failed to locate template file \"$template\"\n\n";
		return 0;
	}

	$SiteData{'site_dir_name'} = $site_dir_name;
	$SiteData{'postmaster_dir_name'} = $postmaster_dir_name;
	$SiteData{'markdown_file_name'} = $markdown_file_name;

	my $html = BuildPostHTMLFromTemplate($postmaster_dir_name.'inc/templates/blog/blog.html',\%SiteData);
	
	if ($html) {
		$html = CopyLocalFilesToSite($html);
		$html = Tabify($html);
	}

	return $html;

}





####################################################################
#
#  Function:  BuildPostHTMLFromTemplate
#
sub BuildPostHTMLFromTemplate
{
	my $template_file_name = shift;
	my $site_data_ref = shift;

	my %SiteData = %{$site_data_ref};

	my $TemplateFile;
	if (open($TemplateFile,'<',$template_file_name) == 0) {
		print "\n  ERROR:  Failed to open template file '$template_file_name'\n\n";
		return 0;
	}

	my $html = '';
	while (my $line = <$TemplateFile>) {

		$line =~ s/\n|\r//g;
		next if (!$line);

		# Skip top-level header (this is the article's title!)
		next if ($line =~ /^\s*\#\s+/);

		my @FillElements = split(/\[\[/,$line);
		my $num_fill_elements = scalar(@FillElements);

		my $fill_element_id = 0;
		if ($FillElements[0] !~ /\]\]/) {
			$html = $html.$FillElements[0];
			$fill_element_id++;
		}

		while ($fill_element_id < $num_fill_elements) {

			my $fill_element = $FillElements[$fill_element_id];
			if (!$fill_element) {
				$fill_element_id++;
				next;
			}

			$fill_element =~ /^(\S+)\]\](.*)$/;
			my $what_to_fill = $1;
			my $remainder = $2;

			if ($what_to_fill !~ /\:/) {

				# If there isn't a colon, we're being asked to fill in
				# a piece of data that's general to the site...

				if ($what_to_fill eq 'FONTS') {
					
					my $fill_html = BuildPostHTMLFromTemplate($SiteData{'site_dir_name'}.$SiteData{$what_to_fill},\%SiteData);
					$html = $html.$fill_html;

				} elsif ($SiteData{$what_to_fill}) {

					if ($what_to_fill eq 'OWNER') {
						$html = $html.$SiteData{$what_to_fill};
					} else {
						$html = $html.'../'.$SiteData{$what_to_fill};
					}

				} else {
				
					print "\n  ERROR: Fill request for unrecognized site datum: '$what_to_fill'\n\n";
					return 0;
				
				}

			} elsif ($what_to_fill =~ /^(\S+)\:copy$/) {

				my $fill_file_name = $1;
				my $fill_html = BuildPostHTMLFromTemplate($SiteData{'postmaster_dir_name'}.$fill_file_name,\%SiteData);
				$html = $html.$fill_html;

			} elsif ($what_to_fill =~ /^(\S+)\:name/) {

				my $what_to_name = $1;
				$html = $html.$SiteData{$what_to_name};

			} elsif ($what_to_fill =~ /^(\S+)\:generate/) {

				my $what_to_gen = $1;

				if ($what_to_gen eq 'CONTENT') {
					
					my $post_html = MarkdownToHTMLString($SiteData{'markdown_file_name'});
					$html = $html.$post_html;

				} elsif ($what_to_gen eq 'YEAR') {

					my ($year,$month,$day) = GetYearMonthDayNum();
					$html = $html.$year;

				} elsif ($what_to_gen eq 'DATE') {

					my $ymd_str = GetYearMonthDayStr();
					$ymd_str =~ s/(\d)(\w\w)$/$1\<sup\>$2\<\/sup\>/;
					$html = $html.$ymd_str;


				} else {
					print "\n  ERROR:  Unrecognized generation request: '$what_to_fill'\n\n";
					return 0;
				}

			}

			$html = $html.$remainder;

			$fill_element_id++;

		}

		$html = $html."\n";

	}
	close($TemplateFile);

	return $html;

}








####################################################################
#
#  Function:  CopyLocalFilesToSite
#
sub CopyLocalFilesToSite
{
	my $html_in = shift;

	my $html_out = "";
	foreach my $line (split(/\n/,$html_in)) {

		if ($line =~ /\<img src=\"([^\"]+)\"/) {

			my $original_filename = $1;

			$original_filename =~ /\/?([^\/]+)$/;
			my $reduced_filename = $1;
			my $target_filename = NameOutputFile('../files/imgs/'.$reduced_filename);

			if (system("cp \"$original_filename\" \"$target_filename\"")) {
				print "\n  ERROR:  Failed to copy '$original_filename' to site data (target:'$target_filename')\n\n";
				return 0;
			}

			$line =~ s/\"$original_filename\"/\"$target_filename\"/;	

			PlanGitOperation($target_filename,'add');

		} elsif ($line =~ /\<a href\=\"([^\"]+)\"/) {

			my $original_link = $1;
			if (-e $original_link) {

				$original_link =~ /\/?([^\/]+)$/;
				my $reduced_filename = $1;
				my $target_filename = NameOutputFile('../files/docs/'.$reduced_filename);

				if (system("cp \"$original_link\" \"$target_filename\"")) {
					print "\n  ERROR:  Failed to copy '$original_link' to site data (target:'$target_filename')\n\n";
					return 0;
				}

				$line =~ s/\"$original_link\"/\"$target_filename\"/;

				PlanGitOperation($target_filename,'add');

			}

		}
		
		$html_out = $html_out.$line."\n";

	}

	return $html_out;

}







1; # EOF

