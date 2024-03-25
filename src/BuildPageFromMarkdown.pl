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


sub PageDirBuildFail;
sub FixImageLinks;
sub CopyFilesToPageDir;
sub CreatePageDir;
sub ComposePageHTML;



if (@ARGV != 2) {
	die "\n  USAGE:  ./BuildPageFromMarkdown.pl [path/to/intended/page/dir] [file.md]\n\n";
}



if (-d $ARGV[0]) {
	die "\n  ERROR:  Directory '$ARGV[0]' already exists -- update, don't build! (BuildPageFromMarkdown)\n\n";
}


my $md_file_name = $ARGV[1];
if (!(-e $md_file_name)) {
	die "\n  ERROR:  Failed to locate markdown file '$md_file_name' (BuildPageFromMarkdown.pl)\n\n";
}


my ($dir_name,$created_dirs_ref) = CreatePageDir();


CopyFilesToPageDir($dir_name,$md_file_name);
ComposePageHTML($dir_name);


print "PAGEDIR: $dir_name\n";



1;









###################################################################
#
#  Function:  PageDirBuildFail
#
sub PageDirBuildFail
{
	my $err_msg = shift;
	foreach my $dir_name (@{$created_dirs_ref}) { 
		system("rm -rf $dir_name"); 
	}
	die "\n  ERROR: $err_msg (BuildPageFromMarkdown.pl)\n\n";
}






###################################################################
#
#  Function:  FixImageLinks
#
sub FixImageLinks
{
	my $html_str     = shift;
	my $md_dir_name  = shift;
	my $out_dir_name = shift;

	my @Images;
	while ($html_str =~ /<img src="(\S+)"/) {
		push(@Images,$1);
		$html_str =~ s/<img src="\S+"/<img src="" class="blogPic"/;
	}


	foreach my $img (@Images) {

		$img =~ /\/?([^\/]+)$/;
		my $img_id = $1;

		my $src_img = $md_dir_name.$img;
		if (!(-e $src_img)) {
			PageDirBuildFail("Failed to locate image file '$src_img'");
		}

		my $out_img = $dir_name.$img_id;
		my $img_copy_cmd = "cp \"$src_img\" \"$out_img\"";
		if (system($img_copy_cmd)) {
			PageDirBuildFail("Failed to copy image file (command:'$img_copy_cmd')");
		}

		$html_str =~ s/<img src=""/<img src="$img_id"/;

	}

	return $html_str;

}





###################################################################
#
#  Function:  CopyFilesToPageDir
#
sub CopyFilesToPageDir
{
	my $out_dir_name = shift;
	my $md_file_name = shift;

	my $md_dir_name = $WORKING_DIR;
	if ($md_file_name =~ /^(\S*\/)[^\/]+$/) {
		my $md_listed_path = $1;
		if ($md_listed_path =~ /^\~/) {
			$md_listed_path =~ s/^\~/$ENV{'HOME'}/;
		} elsif ($md_listed_path =~ /^\//) {
			$md_dir_name = $md_listed_path;
		} else {
			$md_dir_name = $WORKING_DIR.$md_listed_path;
		}
	}

	my $md_to_html_cmd = 'perl '.$SCRIPT_DIR.'MarkdownToHTML.pl '.$md_file_name.' |';
	open(my $HTMLScanner,$md_to_html_cmd) 
		|| PageDirBuildFail("Failed to run markdown parsing command '$md_to_html_cmd'");

	my $out_html_file_name = $out_dir_name.'.blog.html';
	open(my $OutHTML,'>',$out_html_file_name)
		|| PageDirBuildFail("Failed to open output html file '$out_html_file_name'");

	while (my $line = <$HTMLScanner>) {

		$line = FixImageLinks($line,$md_dir_name,$out_dir_name);

		print $OutHTML "$line";

	}
	close($HTMLScanner);


	my $out_md_file_name = $out_dir_name.'.blog.md';
	my $md_copy_cmd = "cp \"$md_file_name\" \"$out_md_file_name\"";
	if (system($md_copy_cmd)) {
		PageDirBuildFail("Failed to copy markdown file to output directory (command:'$md_copy_cmd')");
	}

}






###################################################################
#
#  Function:  CreatePageDir
#
sub CreatePageDir
{
	my @CreatedDirs; # In case something fails, we'll want to undo any useless dir creation
	my $dir_name = '';
	for my $dir_element (split(/\//,$ARGV[0])) {

		# We need to be careful with the first element!
		if (!$dir_name) {
			if ($dir_element eq '~') {
				$dir_name = $ENV{'HOME'};
				$dir_name = $dir_name.'/' if ($dir_name !~ /\/$/);
				next;
			} elsif ($ARGV[0] !~ /^\//) {
				$dir_name = $WORKING_DIR;
			} else {
				$dir_name = '/';
			}
		}
		next if (!$dir_element); # This shouldn't happen, but I guess it's okay...


		$dir_name = $dir_name.$dir_element.'/';

		if (!(-d $dir_name)) {
			if (system("mkdir $dir_name")) {
				PageDirBuildFail("Creation of directory '$dir_name'");
			} else {
				push(@CreatedDirs,$dir_name);
			}
		}

	}

	return ($dir_name,\@CreatedDirs);

}






###################################################################
#
#  Function:  RecordPageCreation
#
sub RecordPageCreation
{

	my $page_file_name = shift;

	
	$page_file_name =~ /^(.+\/)([^\/]+\/[^\/]+)$/;
	my $genre_dir_name = $1;
	my $page_dir_file_names = $2;


	$genre_dir_name =~ /^(.+\/)([^\/]+)\/$/;
	my $site_dir_name = $1;
	my $genre_dir_base_name = $2;


	open(my $SiteMetadata,'<',$site_dir_name.'.metadata')
		|| die "\n  ERROR:  Failed to open metadata file '$site_dir_name.metadata'\n\n";
	my $site_url;
	while (my $line = <$SiteMetadata>) {
		if ($line =~ /^\s*SITEURL\s*:\s*(\S+)/) {
			$site_url = $1;
			$site_url =~ s/\/$//;
			last;
		}
	}
	close($SiteMetadata);
	

	my $page_url = $site_url.'/'.$genre_dir_base_name.'/'.$page_dir_file_names;


	open(my $Page,'<',$page_file_name)
		|| die "\n  ERROR:  Failed to open page file '$page_file_name'\n\n";

	my $page_title;
	my $publish_date;
	while (my $line = <$Page>) {
		if (!$page_title && $line =~ /^<h2>\s*(.+)\s*<\/h2>/) {
			$page_title = $1;
		} elsif (!$publish_date && $line =~ /<p class="blogDate">\s*(.+)\s*<\/p>/) {
			$publish_date = $1;
		}
	}
	close($Page);

	AddToPostList($page_title,$page_url,$publish_date,$site_dir_name.'.post-list');

}






###################################################################
#
#  Function:  AddToPostList
#
sub AddToPostList
{

	my $new_page_title      = shift;
	my $new_page_url        = shift;
	my $new_page_pub_date   = shift;
	my $post_list_file_name = shift;

	if ($new_page_url !~ /^http/) {
		$new_page_url = 'http://'.$new_page_url;
	}

	my @OldPostList;

	if (-e $post_list_file_name) {
	
		open(my $PostFile,'<',$post_list_file_name)
			|| die "\n  ERROR:  Failed to open '$post_list_file_name' (reading)\n\n";
	
		while (my $line = <$PostFile>) {

			$line =~ s/\n|\r//g;
			next if (!$line);

			push(@OldPostList,$line);
	
		}
	
		close($PostFile);
	
	}

	
	open(my $PostFile,'>',$post_list_file_name)
		|| die "\n  ERROR:  Failed to open '$post_list_file_name' (writing)\n\n";
	
	print $PostFile "\"$new_page_title\" $new_page_url \"$new_page_pub_date\"\n";
	
	foreach my $old_post_line (@OldPostList) {
		
		$old_post_line =~ /^\s*\"([^\"]+)\"\s+(\S+)\s+\"([^\"]+)\"\s*$/;
		my $old_title = $1;
		my $old_url   = $2;
		my $old_date  = $3;

		if ($old_url ne $new_page_url) {
			print $PostFile "\"$old_title\" $old_url \"$old_date\"\n";
		}

	}

	close($PostFile);


}






###################################################################
#
#  Function:  ComposePageHTML
#
sub ComposePageHTML
{

	my $dir_name = shift;


	my $compose_script = $SCRIPT_DIR.'ComposeBlogHTML.pl';
	my $compose_cmd = "perl $compose_script $dir_name |";


	open(my $PageTitleReader,$compose_cmd)
		|| PageDirBuildFail("Page composition command '$compose_cmd' failed");
	my $page_fname_line = <$PageTitleReader>;
	close($PageTitleReader);


	if ($page_fname_line =~ /PAGE:\s*(\S+)/) {
		my $page_file_name = $1;
		RecordPageCreation($page_file_name);
	} else {
		PageDirBuildFail("Failed to determine new page filename");
	}


}



