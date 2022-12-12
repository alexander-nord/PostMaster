#
#  manage-content.pm - Alex Nord, 2022
#
use warnings;
use strict;
use POSIX;


sub locate_manage_con { return './' if ($0 !~ /\//); $0 =~ /^(.*\/)[^\/]+$/; return $1; }
use lib locate_manage_con();
use bureaucracy; # This is ONLY used for getting dates -- all I/O errors should be highly specific!


sub PlanGitOperation;
sub PushSite;



####################################################################
#
#  Function:  PlanGitOperation
#
sub PlanGitOperation
{
	my $file_name = shift;
	my $operation = shift;

	$file_name =~ s/^(.*\/sites\/[^\/]+\/)//;

	my $meta_dir_name = $1;
	$meta_dir_name =~ s/\/([^\/]+)$/\/\.$1\-PostMaster\-Data\//;

	ConfirmDirectory($meta_dir_name);

	my $git_cmd_queue_name = $meta_dir_name.'git-queue';
	my $GitCmdQueue;
	if (-e $git_cmd_queue_name) {
		$GitCmdQueue = AppendToOutputFile($git_cmd_queue_name);
	} else {
		$GitCmdQueue = OpenOutputFile($git_cmd_queue_name);
	}

	print $GitCmdQueue "git $operation $file_name";

	close($GitCmdQueue);

}



####################################################################
#
#  Function:  PushSite
#
sub PushSite
{
	my $site_name = shift;

	my $src_dir_name = locate_manage_con();
	
	my $site_dir_name = ConfirmDirectory($src_dir_name.'../sites/'.$site_name);
	chdir($site_dir_name);

	my $git_cmd_queue_name = '../.'.$site_name.'-PostMaster-Data/git-queue';
	if (-e $git_cmd_queue_name) {

		# In particular, it seems possible that we could have multiple
		# requests to update 'recent-posts' files, so we can just skip
		# that redundancy.
		my %AlreadyRun;

		my $GitCmdQueue = OpenInputFile($git_cmd_queue_name);
		while (my $cmd_line = <$GitCmdQueue>) {
			$cmd_line =~ s/\n|\r//g;
			next if (!$cmd_line || $AlreadyRun{$cmd_line});
			RunSystemCommand($cmd_line);
			$AlreadyRun{$cmd_line} = 1;
		}
		close($GitCmdQueue);

		RunSystemCommand("git commit");
		RunSystemCommand("git push origin");

		RunSystemCommand("rm $git_cmd_queue_name");

	} else {
		print "\n  No updates in git command queue\n\n";
	}

	# I'm pretty sure you don't need to do this, but what's the harm?
	chdir($src_dir_name);

}


1; # EOF

