use Test::More 'no_plan';
use strict;

BEGIN { chdir 't' if -d 't' };
BEGIN { use lib '../lib' };

my $Class = 'Object::Accessor::Inheritable';
use_ok( $Class );
