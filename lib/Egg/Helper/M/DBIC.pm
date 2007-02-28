package Egg::Helper::M::DBIC;
#
# Copyright (C) 2007 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: DBIC.pm 257 2007-02-28 13:09:44Z lushe $
#
use strict;
use warnings;
use base qw/Egg::Component/;
use DBIx::Class::Schema::Loader qw/make_schema_at/;

our $VERSION= '0.02';

sub get_options {
	my($class)= @_;
	$class->SUPER::get_options
	  (" d-dsn= u-user= p-password= s-host= i-inet_port= ");
}
sub new {
	my $self= shift->SUPER::new();
	my $g= $self->global;
	return $self->help_disp if $g->{help};

	my $schema_name= $g->{any_name}
	   || return $self->help_disp(q{ I want Schema Name. });
	return $self->help_disp(qq{ bad format to schema_name : $schema_name })
	  if (! $schema_name || $schema_name!~m{^[A-Za-z][A-Za-z0-9_]*$});

	$g->{dsn}  || return $self->help_disp(q{ I want 'dsn'.  });
	$g->{user} || return $self->help_disp(q{ I want 'user'. });
	$g->{password} ||= "";

	$g->{dsn}.= ";host=$g->{host}"      if $g->{host};
	$g->{dsn}.= ";port=$g->{inet_port}" if $g->{inet_port};

	my @source= @{$g}{qw{ dsn user password }};
	my $schema_path=
	  "$g->{project_root}/lib/$g->{project_name}/Model/DBIC/$schema_name";

	-e "$schema_path.pm" and die qq{ It already exists. : $schema_path.pm };

	my $added_schema_code= <<END_OF_CODE;
use base qw/Egg::Model::DBIC::Schema/;

__PACKAGE__->config(
  dsn      => '$g->{dsn}',
  user     => '$g->{user}',
  password => '$g->{password}',
  options  => { AutoCommit => 1 },
  );
END_OF_CODE

	my $added_moniker_code= <<END_OF_CODE;
use base qw/Egg::Model::DBIC::Moniker/;
END_OF_CODE

	chdir($g->{project_root});
	eval{

		make_schema_at(
		  $self->project_name. "::Model::DBIC::$schema_name", {
		    debug          => 1,
		    relationships  => 1,
		    dump_directory => './lib'
		    }, \@source,
		  );

		my $value= $self->read_file("$schema_path.pm");
		$value=~s{\n+(use\s+base\s+[^\;]+\;)\s*}
		         [\n## $1\n\n$added_schema_code\n]s;
		$self->save_file({}, { filename=> "$schema_path.pm", value=> $value });

		for my $moniker (<$schema_path/*>) {  ## no critic
			$moniker=~/\.pm$/ || next;
			my $v= $self->read_file($moniker);
			next if $v=~m{Egg\:\:Model\:\:DBIC\:\:Moniker}s;
			$v=~s{\n+(use\s+base\s+[^\;]+\;)\s*}
			     [\n## $1\n\n$added_moniker_code\n]s;
			$self->save_file({}, { filename=> $moniker, value=> $v });
		}

	  };
	chdir($g->{start_dir});

	if (my $err= $@) {
		$self->remove_file("$schema_path.pm");
		$self->remove_dir($schema_path);
		Egg::Error->throw($err);
	} else {
		print <<END_OF_INFO;
... done.

Please add 'schema_names' to the configuration.

 Example of configuration.
 
   MODEL=> [
     [ 'DBIC' => {
         schema_names => [qw/ $schema_name /],
         },
       ]
     ],

END_OF_INFO
	}
}
sub help_disp {
	my $self= shift;
	my $msg = shift || ""; $msg and $msg.= "\n\n";
	my $pname= lc($self->project_name);
	print <<END_OF_HELP;
$msg# usage: perl $pname\_helper.pl M:DBIC [SCHEMA_NAME] [OPTIONS]

OPTIONS:  -d ... DNS.
          -s ... HOST.
          -i ... PORT.
          -u ... DB_USER.
          -p ... DB_PASSWORD.

Example:
  % perl $pname\_helper.pl M:DBIC MySchema \\
  >  -d dbi:Pg:dbname=mydb  \\
  >  -u dbuser              \\
  >  -p dbpassword

* Do not include the ',' in password.

END_OF_HELP
}

1;

__END__

=head1 NAME

Egg::Helper::M::DBIC - Helper for Egg::Model::DBIC.

=head1 SYNOPSIS

  % cd /MYPROJECT_ROOT/bin
  
  % perl myproject_helper.pl M:DBIC MySchema \
  > -d dbi:Pg:dbname=dbname \
  > -s localhost \
  > -i 5432 \
  > -u db_user \
  > -p db_password
  
  ... done.
  
  output path : /MYPROJECT_ROOT/lib/MYPROJECT/Model/DBIC/MySchema*

=head1 OPTIONS

=head2 -d DSN.

=head2 -s Host of data base.

=head2 -i Data base port.

=head2 -u Data base user.

=head2 -p Data base password.

=head1 SEE ALSO

L<Egg::Model::DBIC>,
L<Egg::Helper>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
