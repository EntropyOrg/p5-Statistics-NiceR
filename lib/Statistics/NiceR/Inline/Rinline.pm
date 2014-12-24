package Statistics::NiceR::Inline::Rinline;

use strict;
use warnings;
use File::Basename;
use File::Spec;
use File::Which;
use Statistics::NiceR::Error;
use IPC::Cmd qw(run);
use Config;
use File::Glob;

sub find_R {
	my $iswin32 = $^O eq 'MSWin32';

	my $r_path = which('R');
	if( $iswin32 and not $r_path ) {
		# TODO make this better
		my $guess_path = '';
		my $rtools_path;
		# TODO get version information from registry. The R installer has a checkbox for that
		eval {
			require 'Win32.pm';
			my $pf;
			$rtools_path = File::Spec->catfile( qw(C: Rtools bin) );
			{
			no strict 'subs';
			$pf = Win32::GetFolderPath( Win32::CSIDL_PROGRAM_FILES );
			}

			my $path_glob = File::Spec->catfile( $pf, 'R', '*', 'bin',);
			my @all_paths = File::Glob::bsd_glob( $path_glob );

			@all_paths = sort { $b <=> $a } @all_paths;
			$guess_path = $all_paths[0];
		};
		local $ENV{PATH} = "$ENV{PATH};$rtools_path;$guess_path";
		$r_path = which('R');
	}

	unless( $r_path ) {
		Statistics::NiceR::Error::RInterpreter->throw("R executable not found");
	}

	$r_path;
}

sub run_R {
	my (@args) = @_;
	my $is64 = $Config{archname} =~ /x86_64|x86-64|amd64|x64/;
	my @r_arch = qw(i386 x64); # possible architectures
	my $arch = $is64 ? 'x64' : 'i386';

	my $r_path = find_R();
	my @arch_args = ();
	if( -d  File::Spec->catfile( dirname( $r_path ) , $arch ) ) {
		# sub-architecture exists
		@arch_args = ('--arch', $arch);
	}

	my( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) =
		run( command => [ $r_path, @arch_args, @args ], );

	# sigh... because R CMD config outputs warnings to STDOUT, we need
	# clean up the output
	$stdout_buf = [ grep {
			$_  !~ /WARNING: ignoring environment value of R_HOME/
		} @$stdout_buf ];

	unless( $success ) {
		Statistics::NiceR::Error::RInterpreter
			->throw("Unable to run R with args: @arch_args @args");
	}

	return join "\n", @$stdout_buf;
}

sub import {
	find_R();
	unless( $ENV{R_HOME} ) {
		my $Rhome = run_R(qw(RHOME));
		chomp $Rhome;
		$ENV{R_HOME} = $Rhome;
	}
}

sub Inline {
	return unless $_[-1] eq 'C';
	import();
	my $R_inc = run_R( qw( CMD config --cppflags ) );
	my $R_libs   = run_R( qw( CMD config --ldflags ) );
	my $dir = File::Spec->rel2abs( dirname(__FILE__) );
	+{
		INC => $R_inc,
		LIBS => $R_libs,
		TYPEMAPS => File::Spec->catfile( $dir, 'typemap' ),
		AUTO_INCLUDE => q{
			#include <Rinternals.h>
			#include <Rembedded.h>
			#include <R_ext/Parse.h> },
	};
}

1;
