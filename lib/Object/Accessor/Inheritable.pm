package Object::Accessor::Inheritable;
use strict;

use vars qw[$AUTOLOAD $VERSION];
use base 'Object::Accessor';

$VERSION            = '0.01';
my $ParentMethod    = 'parent';

=head1 NAME

Object::Accessor::Inheritable -- Enable data inheritance between objects

=head1 SYNOPSIS

    $Class = 'Object::Accessor::Inheritable';
    my $parent = $Class->new( qw[parent_method shared_method] );
    my $child  = $Class->new( qw[child_method  shared_method] );
    
    $child->parent( $parent );      # define the relationship


    $parent->parent_method( $$ );   # set the value in the parent
    $child->child_method(   $$ );   # set the value in the child;

    print $child->parent_method;    # print it from the child
    print $parent->child_method;    # error; no such method for parent


    $parent->shared_method( 'p' );  # set the value in the parent
    $child->shared_method(  'c' );  # set another value in the child

    print $parent->shared_method;   # prints 'p'
    print $child->shared_method;    # prints 'c'

=head1 DESCRIPTION

C<Object::Accessor::Inheritable> lets you inherit data between
C<Object::Accessor::Inheritable> objects by defining a relationship
between these objects. This works analogous to C<perl>s own C<@ISA>
resolving, but rather than on classes, it works on objects.

=head1 METHODS

=head2 $obj = Object::Accessor::Inheritable->new( ... )

This creates a new C<Object::Accessor::Inheritable> object. 
This is just a wrapper around C<Object::Accessor>, so all arguments
are  passed straight on to it's C<new> method. Please consult the 
C<Object::Accessor> manpage for details on the arguments.

In addition, it adds the C<parent> method to your object, so you
can define relationships between this object, and other objects
of the C<Object::Accessor::Inheritable> class.

By default, data retrievel is down C<bottom up>, meaning we prefer
child data over parent data. The alternative is to retrieve data
C<top down>, where parent data is prefered over child data.

To allow C<top down> retrieval, create your object as follows 
instead:

    $topdown = Object::Accessor::Inheritable::TopDown->new( ... )
    
You can also be explicit in your C<bottom up> preference by 
declaring your object as follows:

    $bottomup = Object::Accessor::Inheritable::BottomUp->new( ... )

=head2 $parent = $obj->parent | $obj->parent( $parent )

Get or set the parent of this object. It should be another 
C<Object::Accessor::Inheritable>, or an object that supports the
same interface, providing it's own C<parent> method.

=cut

sub new {
    my $self = shift;
    my $obj  = $self->SUPER::new( @_ ) or return;
    
    $obj->mk_accessors( $ParentMethod );
    
    return $obj;
}

sub AUTOLOAD {
    my $self    = shift;
    my $method  = $AUTOLOAD;
    $method     =~ s/.+:://;
    my $smethod = 'SUPER::'.$method;

    ### dont try to find the parentmethod in the parents, this one MUST
    ### be resolved on the local object
    return $self->$smethod( @_ ) if $method eq $ParentMethod;

    ### get a list of all the parents in this chain,
    ### reverse the list if the caller wants us to *first* look in our
    ### object, THEN the parents.
    my @list    = ($self->___get_parents, $self);
    @list       = reverse @list unless $self->isa( __PACKAGE__ . '::TopDown' );
    
    ### return the first hit we find
    for my $obj ( @list ) {
        return $obj->$smethod( @_ ) if $obj->can( $method );                       
    }

    ### no one can do this?? just return then
    ### XXX should we explicitly call the method again on $self,
    ### so we can provoke an error message?
    return;
}        

sub ___get_parents {
    my $self = shift;
    my $meth = [caller(0)]->[3];    # full name of this sub
    $meth    =~ s/.+:://;           # just the sub name
    
    my @parents;
    if( $self->can( $ParentMethod ) ) {

        ### get the parent object
        ### make sure to *prepend* the parent object, so we get
        ### them in parent-most order
        my $parent = $self->$ParentMethod;
        unshift @parents, $parent if $parent;
        
        ### recursively get the parents of this parent, and so on
        if( $parent && $parent->can( $meth ) ) {
            unshift @parents, $parent->$meth;
        }
    }
    return @parents;
}

{   package Object::Accessor::Inheritable::BottomUp;
    use base 'Object::Accessor::Inheritable';
}

{   package Object::Accessor::Inheritable::TopDown;
    use base 'Object::Accessor::Inheritable';
}

=head1 SEE ALSO

C<Object::Accessor>

=head1 AUTHOR

Jos Boumans C<kane@cpan.org>

=head1 BUGS

Please report bugs to C<bug-object-accessor-inheritable@rt.cpan.org>

=head1 COPYRIGHT

This library is free software;
you may redistribute and/or modify it under the same terms as Perl itself.

=cut

1;
