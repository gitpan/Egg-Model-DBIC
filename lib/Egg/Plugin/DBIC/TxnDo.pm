package Egg::Plugin::DBIC::TxnDo;
#
# Copyright (C) 2007 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: TxnDo.pm 63 2007-03-25 10:26:45Z lushe $
#
use strict;
use warnings;

our $VERSION = '0.01';

sub setup {
	my($e)= @_;
	my $dbic = $e->model('DBIC') || die q{ Please build in MODEL DBIC. };
	my $names= $dbic->config->{schema_names};
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	for my $name (ref($names) eq 'ARRAY' ? @$names: $names) {
		$name= lc($name) || next;
		my $schema= $e->model($name)
		   || Egg::Error->throw(qq{ $name Model cannot be acquired. });
		my $auto_commit= $schema->storage->dbh->{AutoCommit} || 0;

	## schema Method.
		my $smethod= "$name\_schema";
		*{__PACKAGE__."::$smethod"}=
		   sub { $_[0]->{$smethod} ||= $_[0]->model($name) };

	## dbh Method.
		my $dmethod= "$name\_dbh";
		*{__PACKAGE__."::$dmethod"}=
		   sub { $_[0]->{$dmethod} ||= $_[0]->$smethod->storage->dbh };

	## table Method.
		*{__PACKAGE__."::$name\_table"}= sub {
			my $egg= shift;
			my $table= lc(shift)
			   || Egg::Error->throw(q{ I want source name. });
			$egg->model("$name\:$table");
		  };

		next if $auto_commit;

	## txn_do Method.
		my $tmethod= "$name\_txn_do";
		*{__PACKAGE__."::$tmethod"}=
		   sub { my $egg= shift; $egg->$smethod->txn_do(@_) };

	}
	$e->next::method;
}

1;

__END__

=head1 NAME

Egg::Plugin::DBIC::TxnDo - The accessor such as 'txn_do' of DBIC for Egg is offered.

=head1 SYNOPSIS

  my $dbh= $e->myapp_dbh;                    # <= $e->model('myApp')->storage->txn_dbh;
  
  my $schema= $e->myapp_schema;              # <= $e->model('myApp');
  
  my $table = $e->myapp_table('myMoniker');  # <= $e->model('myApp:myMoniker');
  
  my $coderef = sub {
    $genus->extinct(1);
    $genus->update;
    };
  
  $e->myapp_txn_do($coderef);

=head1 DESCRIPTION

This plugin offers the accessor and others to make 'txn_do' L<DBIx::Class>
for the transaction convenient.

This plugin does neither beginning the transaction nor processing concerning
the end. The method of dependence on 'txn_do' is only offered.

Please refer to L<Egg::Plugin::DBIC::Transaction> for the function concerning
the automation of the transaction.

L<DBIx::Class> : L<http://search.cpan.org/dist/DBIx-Class/lib/DBIx/Class/Manual/DocMap.pod>.

=head1 METHODS

* The method of '*_txn_do' of Schema to which AutoCommit is invalid is not
  generated. The error occurs if it calls it.
  Even if AutoCommit is invalid, other methods can be used.

=over 4

=item setup

It is a method for the start preparation that is called from the controller of 
the project. * Do not call it from the application.

=back

=head2 [schema_name]_txn_do ([CODE_REF])

It is an accessor to 'txn_do' method of L<DBIx::Class>.

* Please see the document of L<DBIx::Class> in detail.

=head2 [schema_name]_dbh

The data base handler of Schema is returned.

* It is the same as $e->model([schema_name])->storage->txn_dbh.

=head2 [schema_name]_schema

The object of Schema is returned.

* It is the same as $e->model([schema_name]).

=head2 [schema_name]_table ([source_name])

The table object in Schema is returned.

* It is the same as $e->model([schema_name])->resultset([source_name])
  and $e->model([schema_name]:[source_name]).


=head1 SEE ALSO

L<Egg::Model::DBIC>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
