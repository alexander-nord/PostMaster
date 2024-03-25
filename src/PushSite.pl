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



sub GetCpanelUsername;
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


my $cpanel_username = GetCpanelUsername($site_dir_name.'.metadata');


my $cpanel_root = '/home/'.$cpanel_username;
$cpanel_root =~ s/\/$//;


my $commit_message;
if (scalar(@ARGV) == 2) { $commit_message = $ARGV[1];           }
else                    { $commit_message = GenCommitMessage(); }

GenJavaScriptFiles($site_dir_name);
# GitAddAndBuildYML($site_dir_name,$cpanel_root,$commit_message);


1;







###################################################################
#
#  Function:  GetCpanelUsername
#
sub GetCpanelUsername
{

	my $metadata_file_name = shift;

	if (!(-e $metadata_file_name)) {
		die "\n  ERROR:  Failed to locate metadata file '$metadata_file_name' (PushSite.pl)\n\n";
	}
	open(my $MetadataFile,'<',$metadata_file_name)
		|| die "\n  ERROR:  Failed to open metadata file '$metadata_file_name' (PushSite.pl)\n\n";

	my $cpanel_username;
	while (my $line = <$MetadataFile>) {
		next if ($line !~ /^\s*CPANELUSER\s*:\s*(\S+)\s*$/);
		$cpanel_username = $1;
		last;
	}
	close($MetadataFile);

	if (!$cpanel_username) {
		die "\n  ERROR:  Metadata file '$metadata_file_name' does not have required field 'CPANELUSER' (PushSite.pl)\n\n";
	}

	return $cpanel_username;

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


	my %BlockedDirs;
	$BlockedDirs{'.'}    = 1;
	$BlockedDirs{'..'}   = 1;
	$BlockedDirs{'.git'} = 1;

	my %DoNotPublish;
	$DoNotPublish{'.cpanel.yml'}  = 1;
	$DoNotPublish{'.blog.md'}     = 1;
	$DoNotPublish{'.blog.html'}   = 1;
	$DoNotPublish{'.metadata'}    = 1;
	$DoNotPublish{'.post-list'}   = 1;
	$DoNotPublish{'.genre-list'}  = 1;
	$DoNotPublish{'.static-list'} = 1;

	
	chdir $site_dir_name;
	my $local_site_name = getcwd();
	$local_site_name =~ s/^.+\/([^\/]+)\/?$/$1/;
	$local_site_name = $local_site_name.'/';


	my $yml_file_name = '.cpanel.yml';
	open (my $YML,'>',$yml_file_name)
		|| die "\n  ERROR:  Failed to open YAML file '$yml_file_name' (PushSite.pl)\n\n";


	print $YML "---\n";
	print $YML "deployment:\n";
	print $YML "  tasks:\n";
	print $YML "    - /bin/rm -rf $cpanel_root/public_html/\n";
	print $YML "    - /bin/rm -rf $cpanel_root/www/\n";
	print $YML "    - /bin/mkdir  $cpanel_root/public_html/\n";
	print $YML "    - /bin/mkdir  $cpanel_root/www/\n";


	my @SubdirList = ('');
	foreach my $subdir_name (@SubdirList) {

		opendir(my $Subdir,"./$subdir_name")
			|| die "\n  ERROR:  Failed to open subdirectory '$site_dir_name$subdir_name' (PushSite.pl)\n\n";
		
		while (my $fname = readdir($Subdir)) {

			$fname =~ s/\/$//;
			next if ($BlockedDirs{$fname});

			if (-d "$subdir_name$fname") {
				push(@SubdirList,$subdir_name.$fname.'/');
				print $YML "    - /bin/mkdir $cpanel_root/public_html/$subdir_name$fname\n";
				print $YML "    - /bin/mkdir $cpanel_root/www/$subdir_name$fname\n";
			} else {
				if (system("git add $subdir_name$fname")) {
					die "\n  ERROR:  Failed to git add file '$subdir_name$fname' (PushSite.pl)\n\n";
				}
				if (!$DoNotPublish{$fname}) {
					print $YML "    - /bin/cp $cpanel_root/$local_site_name$subdir_name$fname $cpanel_root/public_html/$subdir_name\n";
					print $YML "    - /bin/cp $cpanel_root/$local_site_name$subdir_name$fname $cpanel_root/www/$subdir_name\n";
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

	my $post_titles_str = 'const PostTitles = [';
	my $post_urls_str   = 'const PostURLs = [';
	for (my $i=0; $i<scalar(@PostTitles); $i++) {

		$post_titles_str = $post_titles_str."\"$PostTitles[$i]\",";

		$PostData[$i] =~ /^\s*(\S+)/;
		$post_urls_str = $post_urls_str."\"$1\",";

		last if ($i+1 == $MAX_NAVBAR_POSTS);

	}
	
	$post_titles_str =~ s/\,$//;
	$post_titles_str = $post_titles_str.'];';
	
	$post_urls_str =~ s/\,$//;
	$post_urls_str = $post_urls_str.'];';	


	# GENRES

	my ($genre_titles_ref,$genre_urls_ref) = RipListFile($site_dir_name.'.genre-list');
	my @GenreTitles = @{$genre_titles_ref};
	my @GenreURLs   = @{$genre_urls_ref};

	my $genre_titles_str = 'const GenreTitles = [';
	my $genre_urls_str = 'const GenreURLs = [';
	for (my $i=0; $i<scalar(@GenreTitles); $i++) {
		$genre_titles_str = $genre_titles_str."\"$GenreTitles[$i]\",";
		$genre_urls_str = $genre_urls_str."\"$GenreURLs[$i]\",";
	}
	
	$genre_titles_str =~ s/\,$//;
	$genre_titles_str = $genre_titles_str.'];';
	
	$genre_urls_str =~ s/\,$//;
	$genre_urls_str = $genre_urls_str.'];';	


	# STATICS

	my ($static_titles_ref,$static_data_ref) = RipListFile($site_dir_name.'.static-list');
	my @StaticTitles = @{$static_titles_ref};
	my @StaticData   = @{$static_data_ref};

	my $static_titles_str = 'const StaticTitles = [';
	my $static_urls_str = 'const StaticURLs = [';
	for (my $i=0; $i<scalar(@StaticTitles); $i++) {
		$StaticData[$i] =~ /^\s*(\S+)\s*(\d)\s*$/;
		my $static_url = $1;
		my $post_to_navbar = $2;
		if ($post_to_navbar == 1) {
			$static_titles_str = $static_titles_str."\"$StaticTitles[$i]\",";
			$static_urls_str = $static_urls_str."\"$static_url\",";
		}
	}
	
	$static_titles_str =~ s/\,$//;
	$static_titles_str = $static_titles_str.'];';
	
	$static_urls_str =~ s/\,$//;
	$static_urls_str = $static_urls_str.'];';	



	open(my $NBJS,'>',$site_dir_name.'navbar.js')
		|| die "\n  ERROR:  Failed to open output 'navbar.js' file\n\n";

	print $NBJS "function GenNavBar () {\n\n";
	print $NBJS "\t$post_titles_str\n";
	print $NBJS "\t$post_urls_str\n";
	print $NBJS "\t$genre_titles_str\n";
	print $NBJS "\t$genre_urls_str\n";
	print $NBJS "\t$static_titles_str\n";
	print $NBJS "\t$static_urls_str\n";
	print $NBJS "\n\n";

	open (my $Template,'<',$template_file_name)
		|| die "\n  ERROR:  Failed to open input '$template_file_name'\n\n";
	while (my $line = <$Template>) {
		print $NBJS "\t$line";
	}
	close($Template);

	print $NBJS "\n\n}\n\n";
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


	my $titles_str = 'const PostTitles = [';
	foreach my $title (@Titles) {
		$titles_str = $titles_str."\"$title\",";
	}
	$titles_str =~ s/\,$//;
	$titles_str = $titles_str.'];';


	my $urls_str = 'const PostURLs = [';
	my $dates_str = 'const PostDates = [';
	my $genres_str = 'const PostGenres = [';
	foreach my $datum (@PostData) {
		
		$datum =~ /^\s*(\S+)\s+\"([^\"]+)\"/;
		my $url = $1;
		my $date = $2;

		$urls_str = $urls_str."\"$url\",";
		$dates_str = $dates_str."\"$date\",";
		
		$url =~ /\/([^\/]+)\/[^\/]+\/[^\/]+$/;
		$genres_str = $genres_str."\"$1\",";

	}

	$urls_str =~ s/\,$//;
	$urls_str = $urls_str.'];';

	$dates_str =~ s/\,$//;
	$dates_str = $dates_str.'];';

	$genres_str =~ s/\,$//;
	$genres_str = $genres_str.'];';


	open(my $PLJS,'>',$site_dir_name.'postlist.js')
		|| die "\n  ERROR:  Failed to open output 'postlist.js' file\n\n";

	print $PLJS "function GenPostList () {\n\n";
	print $PLJS "\t$titles_str\n";
	print $PLJS "\t$urls_str\n";
	print $PLJS "\t$dates_str\n";
	print $PLJS "\t$genres_str\n";
	print $PLJS "\n\n";

	open (my $Template,'<',$template_file_name)
		|| die "\n  ERROR:  Failed to open input '$template_file_name'\n\n";
	while (my $line = <$Template>) {
		print $PLJS "\t$line";
	}
	close($Template);

	print $PLJS "\n\n}\n\n";
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







