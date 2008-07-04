package Sub::Auto;

our $VERSION = 0.01;

=head1 NAME

Sub::Auto - declare individual handlers for AUTLOADed subs, respecting can and inheritance

=head1 SYNOPSIS

 use Sub::Auto;

 autosub (^get_(\w+)$) {
    my ($what, @pars) = @_;
    print "Getting $what...\n";
 };

 autosub (^set_(\w+)_(\w+)$) {
    my ($adjective, $noun, @pars) = @_;
    print "Setting the $adjective $noun\n";
 };

 autosub handle_foo_events (foo$) {
    my ($subname, @pars) = @_;
    print "Called $subname to do something to a foo\n";
 }

 get_foo();
 if (__PACKAGE__->can('set_blue_cat')) { ... }

=head1 DESCRIPTION

C<AUTOLOAD>, like other languages' C<method-missing> features is a useful feature
for those situations when you want to handle sub or method calls dynamically, and
can't pre-generate the subroutines with accessor generators.

To be sure, this is almost never the case, but occasionally, C<AUTOLOAD> is convenient.

Well, "convenient" is a strong word, writing C<sub AUTOLOAD> handlers is mildly
unpleasant, and doesn't handle inheritance and C<can> by default.

Using C<Sub::Auto> you can:

=over 4

=item *

Declare multiple handlers, each responding to calls matching a given regular expression.

=item *

Optionally name your handler, for clarity, or because you want to call it directly.

=item *

Ensure that unhandled methods get dealt with by the next class in the inheritance chain.

=back

=head1 USAGE

=head2 C<autosub>

 autosub [name] (regex) { ... };

The declaration must end with a semicolon: this is a current limitation of L<Devel::Declare>.

If the regex contains capturing parentheses, then each of those items will be prepended
to the sub's argument list.  For example:

 autosub ((\w+)_(\w+)) {
    my ($verb, $noun, @params) = @_;
    print "$verb'ing $noun - " . join ','=>@params;
 };

 jump_up('one', 'two'); # prints "jump'ing up - one,two"

If the matching regex didn't have any capturing parens, the entire method name
is passed as the first argument.

The name of the sub is optional.  It registers a normal subroutine or method with
that name in the current package.  Nothing will be automatically prepended to a call
to this method!

 autosub add ((\w+)_(\w+)) {
    my ($verb, $noun, $one,$two) = @_;
    print $one + $two;
 };

 foo (undef,undef, 1, 2);

=head1 SEE ALSO

L<Class::AutoloadCAN> by Ben Tilly, does all the heavy lifting.

L<Devel::Declare> by Matt Trout provides the tasty syntactic sugar.

L<http://greenokapi.net/blog/2008/07/03/more-perl-hate-and-what-to-do-about-it-autoload/>

L<Class::Accessor> or various other method generators that are a saner solution in general
than using AUTOLOAD at all.

=head1 AUTHOR AND LICENSE

 (c) 2008 osfameron@cpan.org

This module is released under the same terms as Perl itself.

=cut

use strict; use warnings;

use Class::AutoloadCAN;
use Devel::Declare;

sub import {
    my ($package)  = caller();

    no strict 'refs';

    my @CANS;
    Devel::Declare->install_declarator(
        $package, 'autosub', DECLARE_PACKAGE | DECLARE_PROTO,
        sub { '' }, # we're not using this hook to install additional source
        sub {
            my ($name, $re, $sub) = @_;
              # add sub to the list of 
            push @CANS, [qr/$re/, $sub];
              # optionally install the sub to caller
            *{ "${package}::$name" } = $sub if $name;
              # in case someone is actually using the retval of autosub
            return $sub;
        }
    );
    *{ "${package}::CAN" } = mk_can(\@CANS);

    # trick via mst.   See also export_to_level and Sub::Exporter
    goto &Class::AutoloadCAN::import;
}

sub mk_can {
    my $CANS = shift;

    return sub {
        my ($class, $method, $self, @arguments) = @_;
        for my $can (@$CANS) {
            my ($re, $sub) = @$can;
            if (my @result = $method =~ /$re/) {
                @result = $method unless defined $1; # or $& ?
                return sub {
                    $sub->(@result, @_)
                    };
            }
        }
        return;
        };
}
    
1;
