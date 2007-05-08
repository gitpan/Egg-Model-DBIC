package Egg::Helper::Model::DBIC;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: DBIC.pm 104 2007-05-08 00:26:24Z lushe $
#

=head1 NAME

Egg::Helper::Model::DBIC - Helper to generate DBIC schema.

=head1 SYNOPSIS

  % perl myapp_helper.pl Model:DBIC [SchemaName] -d dbi:Pg:dbname=mydata -u db_user

=head1 DESCRIPTION

It is a plug-in to construct Schema from an existing data base with the
automatic operation by L<DBIx::Class::Schema::Loader>.

The name of Schema made specifying 'Model:DBIC' for the helper of the project
for a mode, and continuously is specified.

And, the following options are given.

=over 4

=item * -d

DNS of connected data base.

=item * -s

Host address of connected data base.

=item * -i

Port number of connected data base.

=item * -u

Account for data base.

=item * -p

Password for data base.

=back

  % perl myapp_helper.pl Model:DBIC MySchema \
    -d dbi:Pg:dbname=mydata \
    -s 192.168.1.1          \
    -p 5432                 \
    -u db_user              \
    -p db_password

* When Schema of the same name already exists L<Egg::Plugin::File::Rotate>.
  And, Schema is newly generated.  Even if an original code is included in
  Schema before, it is not reflected in new Schema.

Please see the document of L<Egg::Model::DBIC>.

=cut
use strict;
use warnings;
use base qw/ Egg::Plugin::File::Rotate /;
use DBIx::Class::Schema::Loader qw/make_schema_at/;

our $VERSION= '2.00';

sub _setup_get_options {
	shift->SUPER::_setup_get_options
	   (" d-dsn= u-user= p-password= s-host= i-inet_port= ");
}
sub _execute {
	my($self) = @_;
	my $g     = $self->global;
	my $conf  = $self->load_project_config;
	my $libdir= $conf->{dir}{lib} || die q{ I want config ' dir -> lib '. };
	-e $libdir || die q{ ' dir -> lib ' is not found. };

	return $self->_output_help if ($g->{help} or ! $g->{any_name});

	my $schema= $g->{any_name}=~/\:/
	   ? return $self->_output_help(qq{ Bad schema name '$g->{any_name}'. })
	   : $g->{any_name};

	my $pname  = $self->project_name;
	my $modname= $self->mod_name_resolv("$pname/DBIC/$schema");

	$g->{dsn}  ||= $ENV{EGG_RDBMS_DSN}
	           || return $self->help_disp(q{ I want 'dsn'. });
	$g->{user} ||= $ENV{EGG_RDBMS_USER}
	           || return $self->help_disp(q{ I want 'user'. });
	$g->{password} ||= $ENV{EGG_RDBMS_PASSWORD} || "";

	$g->{dsn}.= ";host=$g->{host}"      if $g->{host};
	$g->{dsn}.= ";port=$g->{inet_port}" if $g->{inet_port};

	$g->{schema_path}= "$libdir/". join('/', @$modname);

	$self->rotate("$g->{schema_path}.pm") if -e "$g->{schema_path}.pm";
	$self->rotate($g->{schema_path})      if -e $g->{schema_path};

	my $schema_plus= <<END_CODE;
use base qw/Egg::Model::DBIC::Schema/;

__PACKAGE__->config(
  dsn      => '$g->{dsn}',
  user     => '$g->{user}',
  password => '$g->{password}',
  options  => { AutoCommit => 1 },
  );
END_CODE

	$self->chdir($self->project_root);
	eval {

		make_schema_at( join('::', @$modname), {
		    debug          => 1,
		    relationships  => 1,
		    dump_directory => './lib'
		    },
		  [ @{$g}{qw{ dsn user password }} ],
		  );

		my $value= $self->fread("$g->{schema_path}.pm");
		$value=~s{\n+(use\s+base\s+[^\;]+\;)\s*} [\n# $1\n\n${schema_plus}\n]s;
		$self->save_file({ filename=> "$g->{schema_path}.pm", value=> $value });
	  };
	$self->chdir($g->{start_dir});

	if (my $err= $@) {
		$self->remove_file("$g->{schema_path}.pm");
		$self->remove_dir($g->{schema_path});
		$self->rotate("$g->{schema_path}.pm", reverse => 1 );
		$self->rotate($g->{schema_path}, reverse => 1 );
		die $err;
	} else {
		print <<END_INFO;
... done.

output of Schema: $g->{schema_path}

END_INFO
	}
}
sub _output_help {
	my $self = shift;
	my $msg  = shift || ""; $msg and $msg.= "\n\n";
	my $pname= lc($self->project_name);
	print <<END_OF_HELP;
${msg}Usage: perl $pname\_helper.pl Model:DBIC [SCHEMA_NAME] [OPTIONS]

OPTIONS:  -d ... DNS.
          -s ... DB_HOST.
          -i ... DB_PORT.
          -u ... DB_USER.
          -p ... DB_PASSWORD.

Example:
  % perl $pname\_helper.pl Model:DBIC MySchema \\
  >  -d dbi:Pg:dbname=mydb  \\
  >  -u dbuser              \\
  >  -p dbpassword

END_OF_HELP
}

=head1 SEE ALSO

L<DBIx::Class::Schema::Loader>,
L<Egg::Model::DBIC>,
L<Egg::Plugin::File::Rotate>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
