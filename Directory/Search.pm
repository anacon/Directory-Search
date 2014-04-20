package Directory::Search;

#	04/18/2012 MF
#	scan & search directories
#	alternative api to File::Find

# uncomment to debug:
#use strict;
#use warnings;
our $VERSION = '0.211'; # 12/24/2012

 
## define queue of dirs to scan and files to fetch
sub new{

	my $class = shift;
	my %args = @_;

	my $o = {};
	bless $o, $class;

	my $dirs       = delete $args{directory}    || '.';
	$o->{recur}    = delete $args{recursive}    || 0  ;
	$o->{debug}    = delete $args{debug}        || 0  ;

	$o->{hiddir}   = delete $args{hidden_dirs}  || 0  ;
	$o->{dirrx}    = delete $args{dir_regex}          ;
	$o->{!_dirrx}  = delete $args{not_dir_regex}      ;

	$o->{ext}      = delete $args{extension}          ;
	$o->{backup}   = delete $args{backup_files} || 0  ;
	$o->{hidden}   = delete $args{hidden_files} || 0  ;
	$o->{filerx}   = delete $args{file_regex}         ;
	$o->{!_filerx} = delete $args{not_file_regex}     ;

	# setup initial directory queue 
	if     ( ref $dirs eq 'ARRAY' ) { $o->{queue} = $dirs;
	}elsif ( ! ref $dirs )	        { $o->{queue} = [ $dirs ];
	}else                           { die "invalid path argument"; 
	}

	# resolve home directory & trailing slash
	my $home = glob("~");
	for ( @{ $o->{queue} } ){

		$_ =~ s/^[~]/$home/;
		chop $_ if /\/$/;
	}
	
	# deep copy initial queue, to enable reset method
	$o->{base} = [ @{ $o->{queue} } ];

	$o->_scan();
	return $o;
}


## fetch next file, iterator
sub next{

	my $o = shift;

	until ( scalar @{ $o->{files} } ){

		return unless scalar @{ $o->{queue} };
		$o->_scan ();
	}

	if ($o->{debug}){print "  - $_\n" for  @{ $o->{queue} } }
	if ($o->{debug}){print "    -- $_\n" for  @{ $o->{files} } }

	my $file = shift @{ $o->{files} };
	return unless $file;

	my $dir = $o->{dir};
	my $path = "$dir/$file";
	$path =~ s{^\./}{};

	return unless defined wantarray;
	return [$file, $dir, $path] unless wantarray;
	return $file, $dir, $path;
}


## fetch all remaining files
sub all{

	my $o = shift;
	my $mode = shift;
	my @files;

	while (my @out = $o->next){

		if ($mode) { push @files, $out[0] }
		else       { push @files, $out[2] }
	}
	return @files if wantarray;
	return \@files;
}


## execute callback sequentially on all files
sub exec{

	my $o = shift;
	my $code = shift;

	while (my @out = $o->next){

		$code->(@out);
	}
}


## reset queue to beginning
sub reset{

	my $o = shift;
	$o->{queue} = [ @{ $o->{base} } ];
	$o->{files} = [];
	$o->_scan();
}


##_ scan next in directory queue 
sub _scan{

	my $o   = shift;
	my $dir = shift @{ $o->{queue} };

	opendir my $DH, $dir;
	for ( readdir $DH ){

		next if $_ =~ /^\.+$/;

		if (-d "$dir/$_"){

			next unless $o->{recur};
			next unless $o->_dirfilter($_);
			push ( @{ $o->{queue} }, "$dir/$_" );
			  
		}elsif (-f "$dir/$_"){

			next unless $o->_filefilter($_);
			push @{ $o->{files} }, $_;
		}
	}
	closedir $DH;
	$o->{dir} = $dir;
}


##_ filter directories to queue
sub _dirfilter{

	my $o   = shift;
	my $dir = shift;

	return if !$o->{hiddir} && $dir =~ /^\./;

	if (defined $o->{dirrx}){

		return unless $file =~ $o->{dirrx};
	}
	if (defined $o->{!_dirrx}){

		return if $file =~ $o->{!_dirrx};
	}
	return 1;
}


##_ filter files to queue
##_ return true puts file in queue 
sub _filefilter{

	my $o    = shift;
	my $file = shift;

	return if !$o->{backup} && $file =~ /~$/;
	return if !$o->{hidden} && $file =~ /^\./;

	if ( $o->{ext} ){return unless $file =~ /\.$o->{ext}$/i}

	if (defined $o->{filerx}){

		return unless $file =~ $o->{filerx};
	}
	if (defined $o->{!_filerx}){

		return if $file =~ $o->{!_filerx};
	}
	return 1;
}


##_ detect operating system
# for possible future use
#sub _os{
#
#	my $o = shift;
#	my %os = (
#		MacOS   => 'mac',
#		MSWin32 => 'msw',
#		linux   => 'nix',
#		Unix    => 'nix',
#		);
#
#	$o->{os} = $os{$^O} || '--';
#}


1;
__END__

















