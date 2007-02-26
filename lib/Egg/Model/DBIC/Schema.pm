package Egg::Model::DBIC::Schema;
#
# Copyright (C) 2007 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Schema.pm 254 2007-02-26 15:08:15Z lushe $
#
use strict;
use warnings;
use base qw/DBIx::Class::Schema Egg::Base/;

our $VERSION = '0.01';

1;

__END__

=head1 NAME

Egg::Model::DBIC::Schema - Base class for Schema module for Egg.

=head1 SYNOPSIS

  package MYPROJECT::Model::DBIC::MyApp;
  use strict;
  use base qw/Egg::Model::DBIC::Schema/;
  
  .....
  ..
  
  1;

=head1 DESCRIPTION

This module has succeeded to DBIx::Class::Schema and Egg::Base.

=head1 SEE ALSO

L<DBIx::Class>,
L<Egg::Model::DBIC>,
L<Egg::Helper::M::DBIC>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
