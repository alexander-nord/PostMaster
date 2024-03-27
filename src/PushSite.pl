#!/usr/bin/env perl
use warnings;
use strict;
use POSIX;
use Cwd;


my $SCRIPT_DIR = $0;
$SCRIPT_DIR =~ s/\/?[^\/]+$//;
$SCRIPT_DIR = '.' if (!$SCRIPT_DIR);
$SCRIPT_DIR = $SCRIPT_DIR.'/';


my $MAX_NAVBAR_POSTS = 3;



sub GetCpanelData;
sub GitAddAndBuildYML;
sub GenJavaScriptFiles;
sub GenCommitMessage;



if (@ARGV != 1 && @ARGV != 2) {
	die "\n  USAGE:  ./PushSite.pl [path/to/site] {OPTIONAL: Commit Message}\n\n";
}


my $site_dir_name = $ARGV[0];
if (!(-d $site_dir_name)) {
	die "\n  ERROR:  Failed to locate site directory '$site_dir_name' (PushSite.pl)\n\n";
}
$site_dir_name = $site_dir_name.'/' if ($site_dir_name !~ /\/$/);


my ($cpanel_username,$cpanel_url) = GetCpanelData($site_dir_name.'.metadata');


$cpanel_url =~ /^ssh:\/\/[^\/]+(\/.+)\/?$/;
my $cpanel_root = $1;


my $commit_message;
if (scalar(@ARGV) == 2) { $commit_message = $ARGV[1];           }
else                    { $commit_message = GenCommitMessage(); }

GenJavaScriptFiles($site_dir_name);
GitAddAndBuildYML($site_dir_name,$cpanel_root,$commit_message);


1;







###################################################################
#
#  Function:  GetCpanelData
#
sub GetCpanelData
{

	my $metadata_file_name = shift;

	if (!(-e $metadata_file_name)) {
		die "\n  ERROR:  Failed to locate metadata file '$metadata_file_name' (PushSite.pl)\n\n";
	}
	open(my $MetadataFile,'<',$metadata_file_name)
		|| die "\n  ERROR:  Failed to open metadata file '$metadata_file_name' (PushSite.pl)\n\n";

	my $cpanel_username;
	my $cpanel_url;
	while (my $line = <$MetadataFile>) {
		if ($line =~ /^\s*CPANELUSER\s*:\s*(\S+)\s*$/) {
			$cpanel_username = $1;
		} elsif ($line =~ /^\s*CPANELURL\s*:\s*(\S+)\s*$/) {
			$cpanel_url = $1;
		}
	}
	close($MetadataFile);

	if (!$cpanel_username) {
		die "\n  ERROR:  Metadata file '$metadata_file_name' does not have required field 'CPANELUSER' (PushSite.pl)\n\n";
	}
	if (!$cpanel_url) {
		die "\n  ERROR:  Metadata file '$metadata_file_name' does not have required field 'CPANELURL' (PushSite.pl)\n\n";
	}

	return ($cpanel_username,$cpanel_url);

}







###################################################################
#
#  Function:  GitAddAndBuildYML
#
sub GitAddAndBuildYML
{

	my $site_dir_name  = shift;
	my $cpanel_root    = shift;
	my $commit_message = shift;

	
	chdir $site_dir_name;


	my $yml_file_name = '.cpanel.yml';
	open (my $YML,'>',$yml_file_name)
		|| die "\n  ERROR:  Failed to open YAML file '$yml_file_name' (PushSite.pl)\n\n";


	my $cpanel_html_dir_name = $cpanel_root;
	$cpanel_html_dir_name =~ s/\/[^\/]+$/\/public_html/;

	my $cpanel_www_dir_name = $cpanel_root;
	$cpanel_www_dir_name =~ s/\/[^\/]+$/\/www/;


	print $YML "---\n";
	print $YML "deployment:\n";
	print $YML "  tasks:\n";
	print $YML "    - /bin/rm -rf $cpanel_html_dir_name/\n";
	print $YML "    - /bin/rm -rf $cpanel_www_dir_name/\n";
	print $YML "    - /bin/mkdir  $cpanel_html_dir_name/\n";
	print $YML "    - /bin/mkdir  $cpanel_www_dir_name/\n";


	my @SubdirList = ('');
	foreach my $subdir_name (@SubdirList) {

		opendir(my $Subdir,"./$subdir_name")
			|| die "\n  ERROR:  Failed to open subdirectory '$site_dir_name$subdir_name' (PushSite.pl)\n\n";
		
		while (my $fname = readdir($Subdir)) {

			$fname =~ s/\/$//;
			if ($fname eq '.' || $fname eq '..') {
				next;
			}

			if (-d "$subdir_name$fname" && $fname ne '.git') {
				push(@SubdirList,$subdir_name.$fname.'/');
				print $YML "    - /bin/mkdir $cpanel_html_dir_name/$subdir_name$fname\n";
				print $YML "    - /bin/mkdir $cpanel_www_dir_name/$subdir_name$fname\n";
			} else {
				if (system("git add $subdir_name$fname")) {
					die "\n  ERROR:  Failed to git add file '$subdir_name$fname' (PushSite.pl)\n\n";
				}
				if ($fname !~ /^\./) {
					print $YML "    - /bin/cp $cpanel_root/$subdir_name$fname $cpanel_html_dir_name/$subdir_name\n";
					print $YML "    - /bin/cp $cpanel_root/$subdir_name$fname $cpanel_www_dir_name/$subdir_name\n";
				}
			}

		}
		closedir($Subdir);

	}
	close($YML);
	
	
	# Now that we're done walking the directories, we can add the cpanel YML!
	if (system("git add .cpanel.yml")) {
		die "\n  ERROR:  Failed to git add cpanel YML file (PushSite.pl)\n\n";
	}

	if (system("git commit -m \"$commit_message\" && git push -u origin HEAD")) {
		die "\n  ERROR:  Failed to commit or push to main (PushSite.pl)\n\n";
	}

}






###################################################################
#
#  Function:  GenJavaScriptFiles
#
sub GenJavaScriptFiles
{
	my $site_dir_name = shift;

	my $templates_dir_name = $SCRIPT_DIR.'templates/';
	my $navbar_file_name   = $templates_dir_name.'navbar.js';
	my $postlist_file_name = $templates_dir_name.'postlist.js';

	GenNavBarJS($site_dir_name,$navbar_file_name);
	GenPostListJS($site_dir_name,$postlist_file_name);

}






###################################################################
#
#  Function:  GenNavBarJS
#
sub GenNavBarJS
{

	my $site_dir_name = shift;
	my $template_file_name = shift;


	# POSTS

	my ($post_titles_ref,$post_data_ref) = RipListFile($site_dir_name.'.post-list');
	my @PostTitles = @{$post_titles_ref};
	my @PostData   = @{$post_data_ref};

	my $post_titles_str = "\tvar PostTitles = new Array();\n";
	my $post_urls_str   = "\tvar PostURLs = new Array();\n";
	for (my $i=0; $i<scalar(@PostTitles); $i++) {

		$PostData[$i] =~ /^\s*(\S+)/;
		my $post_url = $1;

		$post_url = 'http://'.$post_url if ($post_url !~ /^http/);
		
		$post_titles_str = $post_titles_str."\tPostTitles.push(\"$PostTitles[$i]\");\n";
		$post_urls_str = $post_urls_str."\tPostURLs.push(\"$post_url\");\n";

		last if ($i+1 == $MAX_NAVBAR_POSTS);

	}
	


	# GENRES

	my ($genre_titles_ref,$genre_urls_ref) = RipListFile($site_dir_name.'.genre-list');
	my @GenreTitles = @{$genre_titles_ref};
	my @GenreURLs   = @{$genre_urls_ref};

	my $genre_titles_str = "\tvar GenreTitles = new Array();\n";
	my $genre_urls_str   = "\tvar GenreURLs = new Array();\n";
	for (my $i=0; $i<scalar(@GenreTitles); $i++) {

		$GenreURLs[$i] =~ /^\s*(\S+)/;
		my $genre_url = $1;
		
		$genre_url = 'http://'.$genre_url if ($genre_url !~ /^http/);

		$genre_titles_str = $genre_titles_str."\tGenreTitles.push(\"$GenreTitles[$i]\");\n";
		$genre_urls_str = $genre_urls_str."\tGenreURLs.push(\"$genre_url\");\n";
	
	}
	


	# STATICS

	my ($static_titles_ref,$static_data_ref) = RipListFile($site_dir_name.'.static-list');
	my @StaticTitles = @{$static_titles_ref};
	my @StaticData   = @{$static_data_ref};

	my $static_titles_str = "\tvar StaticTitles = new Array();\n";
	my $static_urls_str = "\tvar StaticURLs = new Array();\n";
	for (my $i=0; $i<scalar(@StaticTitles); $i++) {

		$StaticData[$i] =~ /^\s*(\S+)\s+(\d)/;
		my $static_url = $1;
		my $post_to_navbar = $2;
		
		if ($post_to_navbar == 1) {
		
			$static_url = 'http://'.$static_url if ($static_url !~ /^http/);

			$static_titles_str = $static_titles_str."\tStaticTitles.push(\"$StaticTitles[$i]\");\n";
			$static_urls_str = $static_urls_str."\tStaticURLs.push(\"$static_url\");\n";
		
		}

	}
	


	open(my $NBJS,'>',$site_dir_name.'navbar.js')
		|| die "\n  ERROR:  Failed to open output 'navbar.js' file\n\n";

	print $NBJS "function GenNavBar () {\n\n";
	print $NBJS "$post_titles_str\n";
	print $NBJS "$post_urls_str\n";
	print $NBJS "$genre_titles_str\n";
	print $NBJS "$genre_urls_str\n";
	print $NBJS "$static_titles_str\n";
	print $NBJS "$static_urls_str\n";
	print $NBJS "\n";

	print $NBJS "\n";
	open (my $Template,'<',$template_file_name)
		|| die "\n  ERROR:  Failed to open input '$template_file_name'\n\n";
	while (my $line = <$Template>) {
		print $NBJS "\t$line";
	}
	close($Template);
	print $NBJS "\n";

	print $NBJS "}\n\n";
	print $NBJS "GenNavBar();\n\n";

	close($NBJS);


}







###################################################################
#
#  Function:  GenPostListJS
#
sub GenPostListJS
{

	my $site_dir_name = shift;
	my $template_file_name = shift;


	my ($titles_ref,$post_data_ref) = RipListFile($site_dir_name.'.post-list');

	my @Titles   = @{$titles_ref};
	my @PostData = @{$post_data_ref};


	my $titles_str = "\tvar PostTitles = new Array();\n";
	foreach my $title (@Titles) {
		$titles_str = $titles_str."\tPostTitles.push(\"$title\");\n";
	}


	my $urls_str = "\tvar PostURLs = new Array();\n";
	my $dates_str = "\tvar PostDates = new Array();\n";
	my $genres_str = "\tvar PostGenres = new Array();\n";
	foreach my $datum (@PostData) {
		
		$datum =~ /^\s*(\S+)\s+\"([^\"]+)\"/;
		my $url = $1;
		my $date = $2;

		$url = 'http://'.$url if ($url !~ /^http/);

		$url =~ /\/([^\/]+)\/[^\/]+\/[^\/]+$/;
		my $genre = $1;

		$urls_str = $urls_str."\tPostURLs.push(\"$url\");\n";
		$dates_str = $dates_str."\tPostDates.push(\"$date\");\n";
		$genres_str = $genres_str."\tPostGenres.push(\"$genre\");\n";

	}


	open(my $PLJS,'>',$site_dir_name.'postlist.js')
		|| die "\n  ERROR:  Failed to open output 'postlist.js' file\n\n";

	print $PLJS "function GenPostList () {\n\n";
	print $PLJS "$titles_str\n";
	print $PLJS "$urls_str\n";
	print $PLJS "$dates_str\n";
	print $PLJS "$genres_str\n";
	print $PLJS "\n";

	print $PLJS "\n";
	open (my $Template,'<',$template_file_name)
		|| die "\n  ERROR:  Failed to open input '$template_file_name'\n\n";
	while (my $line = <$Template>) {
		print $PLJS "\t$line";
	}
	close($Template);
	print $PLJS "\n";

	print $PLJS "}\n\n";
	print $PLJS "GenPostList();\n\n";

	close($PLJS);

}








###################################################################
#
#  Function:  RipListFile
#
sub RipListFile
{

	my $list_file_name = shift;

	if (!(-e $list_file_name)) {
		die "\n  ERROR:  Failed to locate list file '$list_file_name' (PushSite.pl)\n\n";
	}

		
	open(my $ListFile,'<',$list_file_name)
		|| die "\n  ERROR:  Failed to open input list file '$list_file_name'\n\n";
		
	my @Titles;
	my @OtherData;
	while (my $line = <$ListFile>) {
		
		if ($line =~ /^\s*\"(.+)\"\s+(.+)\s*$/) {
				
			my $title = $1;
			my $other_data = $2;

			push(@Titles,$title);
			push(@OtherData,$other_data);
				
		}
	
	}
		
	close($ListFile);

	return (\@Titles,\@OtherData);

}





###################################################################
#
#  Function:  GenCommitMessage
#
sub GenCommitMessage
{
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
        $year += 1900;
        $mon++;
        $mon = '0'.$mon if ($mon < 10);
        $mday = '0'.$mday if ($mday < 10);
        my $commit_date = $year.'-'.$mon.'-'.$mday;

        return "PostMaster: Automated commit ($commit_date)";
}







