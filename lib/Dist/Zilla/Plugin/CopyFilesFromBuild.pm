use strict;
use warnings;
use utf8;

package Dist::Zilla::Plugin::CopyFilesFromBuild;
# ABSTRACT: Copy (or move) specific files after building (for SCM inclusion, etc.)

use Moose;
use MooseX::Has::Sugar;
with qw/ Dist::Zilla::Role::AfterBuild /;

use File::Copy ();
# use File::Slurp qw( read_file write_file );
use List::Util 1.33 qw( any );
use Set::Scalar;
# accept some arguments multiple times.
sub mvp_multivalue_args { qw{ copy move } }

has copy => (
    ro, lazy,
    isa        => 'ArrayRef[Str]',
    default    => sub { [] },
);

has move => (
    ro, lazy,
    isa        => 'ArrayRef[Str]',
    default    => sub { [] },
);

sub after_build {
    my $self = shift;
    my $data = shift;

    my $build_root = $data->{build_root};
    for my $path (@{$self->copy}) {
        if ($path eq '') {
            next;
        }
        my $src = $build_root->file( $path );
        if (-e $src) {
            my $dest = $self->zilla->root->file( $src->basename );
            File::Copy::copy "$src", "$dest"
                or $self->log_fatal("Unable to copy $src to $dest: $!");
            $self->log("Copied $src to $dest");
        }
    }

    my $moved_something = 0;

    for my $path (@{$self->move}) {
        if ($path eq '') {
            next;
        }
        my $src = $build_root->file( $path );
        if (-e $src) {
            my $dest = $self->zilla->root->file( $src->basename );
            File::Copy::move "$src", "$dest"
                or $self->log_fatal("Unable to move $src to $dest: $!");
            $moved_something++;
            $self->log("Moved $src to $dest");
        }
    }

    if ($moved_something) {
        # These are probably horrible hacks. If so, please tell me a
        # better way.
        $self->_prune_moved_files();
        $self->_filter_manifest($build_root);
    }
}

sub _prune_moved_files {
    my ($self, ) = @_;
    for my $file (@{ $self->zilla->files }) {
        next unless any { $file->name eq $_ } @{$self->move};

        $self->log_debug([ 'pruning moved file %s', $file->name ]);

        $self->zilla->prune_file($file);
    }
}

sub _read_manifest {
    my ($self, $manifest_filename) = @_;
    my $input = IO::File->new($manifest_filename);
    my @lines = $input->getlines;
    chomp @lines;
    return @lines;
}

sub _write_manifest {
    my ($self, $manifest_filename, @contents) = @_;
    my $output = IO::File->new($manifest_filename, 'w');
    $output->print(join("\n", (sort @contents)), "\n");
}

sub _filter_manifest {
    my ($self, $build_root) = @_;
    if (@{$self->move}) {
        my $manifest_file = $build_root->file( 'MANIFEST' );
        return unless -e $manifest_file;
        my $files = Set::Scalar->new($self->_read_manifest($manifest_file));
        my $moved_files = Set::Scalar->new(@{$self->move});
        my $filtered_files = $files->difference($moved_files);
        $self->log_debug("Removing moved files from MANIFEST");
        $self->_write_manifest($manifest_file, $filtered_files->members);
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1; # Magic true value required at end of module
__END__

=head1 SYNOPSIS

In your dist.ini:

    [CopyFilesFromBuild]
    copy = README
    move = README.pod
    copy = Makefile.PL

=head1 DESCRIPTION

This plugin will automatically copy the files that you specify in
dist.ini from the build directory into the distribution directoory.
This is so you can commit them to version control.

If you want to put a build-generated file in version control but you
I<don't> want it to I<remain> in the build dir, use C<move> instead of
C<copy>. When you use C<move>, the F<MANIFEST> file will be updated if
it exists, and the moved files will be pruned from their former
location.

=head1 RATIONALE

This plugin is based on CopyReadmeFromBuild. I wrote it because that
plugin was copying the wrong README file (F<README> instead of
F<README.mkdn> or F<README.pod>), and it could not be configured to do
otherwise. So I wrote my own module that copies exactly the files that
I specify.

I added the C<move> functionality because I wanted to generate a
F<README.pod> file for Github, but MakeMaker wanted to also install
the README.pod file as part of the distribution. So I made it possible
to take a file generated during the build and move it I<out> of the
build directory, so that it would not be included in the distribution.

=for Pod::Coverage after_build mvp_multivalue_args

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<rct+perlbug@thompsonclan.org>.

=head1 SEE ALSO

=for :list
* L<Dist::Zilla::Plugin::CopyReadmeFromBuild> - The basis for this module
