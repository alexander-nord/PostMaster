#!/usr/bin/env perl
use warnings;
use strict;
use POSIX;
use Cwd;


my $WORKING_DIR = getcwd();
$WORKING_DIR = $WORKING_DIR.'/' if ($WORKING_DIR !~ /\/$/);

sub GetScriptDir { my $sd = $0; $sd =~ s/\/?[^\/]+$//; $sd = '.' if (!$sd); return $sd.'/'; }
my $SCRIPT_DIR = GetScriptDir();
use lib GetScriptDir();
use __FixLinks;


sub PostDirBuildFail;
sub CopyFilesToPageDir;
sub CreatePageDir;
sub ComposePageHTML;



if (@ARGV != 2) {
	die "\n  USAGE:  ./BuildPostFromMarkdown.pl [path/to/intended/post/dir] [file.md]\n\n";
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

	my $out_html_file_name = $out_dir_name.'.post.html';
	open(my $OutHTML,'>',$out_html_file_name)
		|| PageDirBuildFail("Failed to open output html file '$out_html_file_name'");


	while (my $line = <$HTMLScanner>) {
	
		if ($line =~ /\S/) {
			$line = FixLinks($line,$md_dir_name,$out_dir_name);
			PageDirBuildFail("Failed while attempting to manage links") if (!$line);
		}
		
		print $OutHTML "$line";
	
	}
	close($HTMLScanner);


	my $out_md_file_name = $out_dir_name.'.post.md';
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

	my $post_file_name = shift;

	
	$post_file_name =~ /^(.+\/)([^\/]+\/[^\/]+)$/;
	my $genre_dir_name = $1;
	my $post_dir_file_names = $2;


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
	

	my $post_url = $site_url.'/'.$genre_dir_base_name.'/'.$post_dir_file_names;


	open(my $Post,'<',$post_file_name)
		|| die "\n  ERROR:  Failed to open post file '$post_file_name'\n\n";

	my $post_title;
	my $publish_date;
	while (my $line = <$Post>) {
		if (!$post_title && $line =~ /^<h2>\s*(.+)\s*<\/h2>/) {
			$post_title = $1;
		} elsif (!$publish_date && $line =~ /<p class="blogDate">\s*(.+)\s*<\/p>/) {
			$publish_date = $1;
		}
	}
	close($Post);

	AddToPostList($post_title,$post_url,$publish_date,$site_dir_name.'.post-list');

}






###################################################################
#
#  Function:  AddToPostList
#
sub AddToPostList
{

	my $new_post_title      = shift;
	my $new_post_url        = shift;
	my $new_post_pub_date   = shift;
	my $post_list_file_name = shift;

	if ($new_post_url !~ /^http/) {
		$new_post_url = 'http://'.$new_post_url;
	}

	my @OldPostList;

	if (-e $post_list_file_name) {
	
		open(my $PostListFile,'<',$post_list_file_name)
			|| die "\n  ERROR:  Failed to open '$post_list_file_name' (reading)\n\n";
	
		while (my $line = <$PostListFile>) {

			$line =~ s/\n|\r//g;
			next if (!$line);

			push(@OldPostList,$line);
	
		}
	
		close($PostListFile);
	
	}

	
	open(my $PostListFile,'>',$post_list_file_name)
		|| die "\n  ERROR:  Failed to open '$post_list_file_name' (writing)\n\n";
	
	print $PostListFile "\"$new_post_title\" $new_post_url \"$new_post_pub_date\"\n";
	
	foreach my $old_post_line (@OldPostList) {
		
		$old_post_line =~ /^\s*\"([^\"]+)\"\s+(\S+)\s+\"([^\"]+)\"\s*$/;
		my $old_title = $1;
		my $old_url   = $2;
		my $old_date  = $3;

		if ($old_url ne $new_post_url) {
			print $PostListFile "\"$old_title\" $old_url \"$old_date\"\n";
		}

	}

	close($PostListFile);


}






###################################################################
#
#  Function:  ComposePageHTML
#
sub ComposePageHTML
{

	my $dir_name = shift;


	my $compose_script = $SCRIPT_DIR.'ComposePostHTML.pl';
	my $compose_cmd = "perl $compose_script $dir_name |";


	open(my $PageTitleReader,$compose_cmd)
		|| PageDirBuildFail("Page composition command '$compose_cmd' failed");
	my $post_fname_line = <$PageTitleReader>;
	close($PageTitleReader);


	if ($post_fname_line =~ /POST:\s*(\S+)/) {
		my $post_file_name = $1;
		RecordPageCreation($post_file_name);
	} else {
		PageDirBuildFail("Failed to determine new post filename");
	}


}



