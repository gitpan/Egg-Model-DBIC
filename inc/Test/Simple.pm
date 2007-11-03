#line 1
package Test::Simple;

use 5.004;

use strict 'vars';
use vars qw($VERSION @ISA @EXPORT);
$VERSION = '0.64';
$VERSION = eval $VERSION;    # make the alpha version come out as a number

use Test::Builder::Module;
@ISA    = qw(Test::Builder::Module);
@EXPORT = qw(ok);

my $CLASS = __PACKAGE__;


#line 78

sub ok ($;$) {
    $CLASS->builder->ok(@_);
}


#line 228

1;
