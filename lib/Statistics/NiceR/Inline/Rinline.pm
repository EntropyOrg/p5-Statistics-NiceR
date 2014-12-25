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

our $Rconfig;

# Get all the build parameters for R. This is a bit complicated on Windows
# since it tries to guess some of the parameters.
sub _r_config {
	my $iswin32 = $^O eq 'MSWin32';
	my $is64 = $Config{archname} =~ /x86_64|x86-64|amd64|x64/;
	#my @r_arch = qw(i386 x64); # possible architectures
	my $arch = $is64 ? 'x64' : 'i386';

	# List fields that are part of the config.
	$Rconfig->{ARCH_ARGS} = [];    # arguments to choose the subarchitecture
	$Rconfig->{PATH} = [];         # any directories that must be added to the path to run R at runtime
	$Rconfig->{MYEXTLIB} = '';     # path to R library needed for linking
	$Rconfig->{R_BIN_PATH} = '';   # path to R binary
	$Rconfig->{R_TOOLS_PATH} = ''; # path to R tools (needed on for configuration on Windows)

	my $r_path = which('R');

	if( $iswin32 and not $r_path ) {
		# could not find R in %PATH% on Windows
		# TODO make this better
		my $guess_path = '';

		# TODO Maybe get version information from registry? The R installer has a checkbox for that

		eval {
			require 'Win32.pm';
			my $pf;
			{
				no strict 'subs';
				$pf = Win32::GetFolderPath( Win32::CSIDL_PROGRAM_FILES );
			}

			my $path_glob = File::Spec->catfile( $pf, 'R', '*', 'bin',);
			my @all_paths = File::Glob::bsd_glob( $path_glob );

			@all_paths = sort { $b cmp $a } @all_paths;
			$guess_path = $all_paths[0]; # get newest one
		};

		# Try finding R now!
		local $ENV{PATH} = "$ENV{PATH}$Config{path_sep}$guess_path";
		$r_path = which('R');

		# OK, so we found it. Add it to the PATH for running later.
		if( $r_path ) {
			push @{$Rconfig->{PATH}}, dirname( $r_path );
		}
	}

	unless( $r_path ) {
		Statistics::NiceR::Error::RInterpreter->throw("R executable not found");
	}

	my $subarch_dir = File::Spec->catfile( dirname( $r_path ) , $arch );
	if( -d $subarch_dir ) {
		# sub-architecture exists
		$Rconfig->{ARCH_ARGS} = [ '--arch', $arch ];
		if( $iswin32 ) {
			# need add the R.dll to the path and MYEXTLIB
			push @{$Rconfig->{PATH}}, $subarch_dir;
			eval {
				require 'Win32.pm';
				$Rconfig->{MYEXTLIB} = File::Spec->catfile( $subarch_dir, 'R.dll' );
				# Use short path so that the spaces are removed.
				# MYEXTLIB doesn't like spaces right now.
				# See <https://github.com/Perl-Toolchain-Gang/ExtUtils-MakeMaker/issues/184>.
				$Rconfig->{MYEXTLIB} = Win32::GetShortPathName($Rconfig->{MYEXTLIB});
			};
		}
	}

	$Rconfig->{R_BIN_PATH} = $r_path;
	if( $iswin32 ) {
		$Rconfig->{R_TOOLS_PATH} = File::Spec->catfile( qw(C: Rtools bin) );
	}
}

sub run_R {
	my (@args) = @_;

	my $r_path = $Rconfig->{R_BIN_PATH};

	my @command = ( $r_path, @{ $Rconfig->{ARCH_ARGS} }, @args );
	my( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) =
		run( command => \@command, );

	# sigh... because R CMD config outputs warnings to STDOUT, we need
	# clean up the output
	$stdout_buf = [ grep {
		$_  !~ /WARNING: ignoring environment value of R_HOME/
		} @$stdout_buf ];

	unless( $success ) {
		Statistics::NiceR::Error::RInterpreter
			->throw("Unable to run R with args: @command: @$full_buf");
	}

	return join "\n", @$stdout_buf;
}

sub import {
	unless( $Rconfig ) {
		_r_config();
		# Needed to get R binary and dynamic library at runtime
		if( @{$Rconfig->{PATH}} ) {
			$ENV{PATH} = "$ENV{PATH}$Config{path_sep}" . ( join $Config{path_sep}, @{$Rconfig->{PATH}} );
		}
	}
	unless( $ENV{R_HOME} ) {
		my $Rhome = run_R(qw(RHOME));
		chomp $Rhome;
		$ENV{R_HOME} = $Rhome;
	}
}

sub Inline {
	return unless $_[-1] eq 'C';
	import();
	my $local_PATH = $ENV{PATH};
	if( exists $Rconfig->{R_TOOLS_PATH} ) {
		# only on Windows
		$local_PATH = "$ENV{PATH}$Config{path_sep}$Rconfig->{R_TOOLS_PATH}";
	}
	local $ENV{PATH} = $local_PATH;
	my $R_inc = run_R( qw( CMD config --cppflags ) );
	chomp $R_inc;
	my $R_libs   = run_R( qw( CMD config --ldflags ) );
	chomp $R_libs;
	my $dir = File::Spec->rel2abs( dirname(__FILE__) );
	+{
		INC => $R_inc,
		LIBS => $R_libs,
		( MYEXTLIB => $Rconfig->{MYEXTLIB} )x!! $Rconfig->{MYEXTLIB},
		TYPEMAPS => File::Spec->catfile( $dir, 'typemap' ),
		AUTO_INCLUDE => q{
			#include <Rinternals.h>
			#include <Rembedded.h>
			#include <R_ext/Parse.h> },
	};
}

1;
