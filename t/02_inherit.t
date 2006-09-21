use Test::More 'no_plan';
use strict;
use Data::Dumper;

BEGIN { chdir 't' if -d 't' };
BEGIN { use lib '../lib' };

my $Class   = 'Object::Accessor::Inheritable';
my $BuClass = $Class . '::BottomUp';
my $TdClass = $Class . '::TopDown';

use_ok( $Class );

my $Verbose     = @ARGV ? 1 : 0;
my $SharedMeth  = 'shared';
my $ParentMeth  = 'parent';


my $x = $Class->new;
my $y = $Class->new;

### 'a' is the top level object, 'c' is the lowest level child object
my %Map = map {
                $_ => [ $Class->new(    $_, $SharedMeth, $ParentMeth ),
                        $TdClass->new(  $_, $SharedMeth, $ParentMeth ),
                        $BuClass->new(  $_, $SharedMeth, $ParentMeth ),
                    ]
            } qw[a b c];

my $TopObjMeth  = [sort keys %Map]->[0];
my $TopObjRef   = $Map{ $TopObjMeth };
my $ObjCount    = scalar( @$TopObjRef );

### set the relationships, get the amount of object dynamically
### from the definition hash
{   for my $i ( 0 .. $ObjCount - 1 ) {
        for my $key ( reverse sort keys %Map ) {
            
            ### $key-- doesn't work, magic increment only works on ++ :(
            my $pkey = chr(ord($key) - 1);   # parent is the previous in line

            last unless $Map{ $pkey };      # there's no parent anymore?

            diag "Setting parent for id: $i from $key to $pkey\n" if $Verbose;
            
            ### set the parent for this object
            $Map{$key}->[$i]->parent( $Map{$pkey}->[$i] );
        }            
    }
}        

### basic tests
{   while( my($meth,$objs_ref) = each %Map ) {
        for my $obj ( @$objs_ref ) {
            can_ok( $obj, $meth, $SharedMeth, $ParentMeth );
        }            
    }
}    
         
### parent tests
{   diag("Testing parents") if $Verbose;;
    my @list = reverse sort keys %Map;
    while( my $key = shift @list ) {
        my $pkey = $list[0] or next;  # need a parent

        my $i = 0;
        for my $obj ( @{ $Map{$key} } ) {
            is( $obj->parent,   $Map{ $list[0] }->[$i],
                                "Parent of $key = $pkey for $obj" );
            $i++;
            
        }
    }
}

### Storage & Retrieval Tests;   
{   ### first, test if everyone can read from the top most accessor
    {   diag("Testing inherited accessors") if $Verbose;;
        $_->$TopObjMeth( $$ ) for @$TopObjRef;
    
        while( my($meth,$objs_ref) = each %Map ) {
            for my $obj ( @$objs_ref ) {
                is( $obj->$TopObjMeth, $$,
                                    "$obj->$TopObjMeth ($meth) returns $$" );
            }
        }
        
        $_->$TopObjMeth( undef ) for @$TopObjRef;
    }

    
    ### next, test if everyone can read from the shared accessor 
    {   diag("Testing shared accessors") if $Verbose;;
        $_->$SharedMeth( $$ ) for @$TopObjRef;
    
        while( my($meth,$objs_ref) = each %Map ) {
            for my $obj ( @$objs_ref ) {
                
                ### if we're a a topdown class or the top parent,
                ### we should be getting $$, otherwise we should get undef
                my $expect = ( $obj->isa( $TdClass ) or !($obj->parent) )
                                ? $$
                                : undef;

                my $pp = $expect || '<undef>';
            
                is( $obj->$SharedMeth, $expect,
                                    "$obj->$SharedMeth ($meth) returns $pp" );
            }
        }
        
        $_->$SharedMeth( undef ) for @$TopObjRef;
    }
}

