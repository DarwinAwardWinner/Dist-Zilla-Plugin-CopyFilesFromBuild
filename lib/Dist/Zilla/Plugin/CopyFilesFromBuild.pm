use strict;
use warnings;
use v5.10;
use utf8;

package Dist::Zilla::Plugin::CopyFilesFromBuild;
# ABSTRACT: Copy specific files after building (for SCM inclusion, etc.)

use Moose;
use MooseX::Has::Sugar;
with qw/ Dist::Zilla::Role::AfterBuild /;

use File::Copy qw/ copy /;

# accept some arguments multiple times.
sub mvp_multivalue_args { qw{ file } }

has copyright => ( ro, default => 1 );
has files => (
    ro, lazy, auto_deref,
    isa        => 'ArrayRef[Str]',
    init_arg   => 'file',
    default    => sub { [] },
);

sub after_build {
    my $self = shift;
    my $data = shift;

    my $build_root = $data->{build_root};
    for(@{$self->files}) {
        my $src = $build_root->file( $_ );
        if (-e $src) {
            my $dest = $self->zilla->root->file( $src->basename );
            copy "$src", "$dest" or die "Unable to copy $src to $dest: $!";
        }
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1; # Magic true value required at end of module
__END__

=head1 SYNOPSIS

In your dist.ini:

    [CopyFilesFromBuild]
    file = README
    file = README.md
    file = Makefile.PL

=head1 DESCRIPTION


This plugin will automatically copy the files that you specify in
dist.ini from the build directory into the distribution directoory.
This is so you can commit them to version control.

=for Pod::Coverage after_build mvp_multivalue_args

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<rct+perlbug@thompsonclan.org>.

=head1 SEE ALSO

=for :list
* L<Dist::Zilla::Plugin::CopyReadmeFromBuild> - The basis for this module

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
