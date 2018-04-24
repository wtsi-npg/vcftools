use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(code => <<'EOF');

use File::Copy;

sub git_tag {
  # adding --tags to allow use of non-annotated tags (as produced by github release tagging)
  my $gitver = q[git describe --tags --dirty --always];
  my $version = `$gitver` || 'unknown';
  $version =~ s/\s$//smxg;
  $version=~s/\A(?![\d])/0.0-/smx; #prepend 0.0- if does not start with a number
  return $version;
}

sub ACTION_build {
  my $self = shift;
  $self->SUPER::ACTION_build;

  my $dest_prefix = $self->install_base;
  my @commands = ( 'autoreconf -fiv', "./configure --prefix=$dest_prefix --with-pmdir=lib/perl5", 'make', );

  for my $command (@commands) {
    if(system $command) { die "build: Failed to execute $command"; }
  }

  # copy src/perl files to blib
  if ( -d 'src/perl' ) {
    if ( ! -d 'blib' ) { mkdir 'blib' or die q[Failed to create blib directory]; }
    if ( ! -d 'blib/lib' ) { mkdir 'blib/lib' or die q[Failed to create blib/lib directory]; }

    opendir my $dir, 'src/perl' or die "Cannot open src/perl directory: $!";
    my @files = readdir $dir;
    closedir $dir;

    for my $f (map { "src/perl/$_" } @files) {
      if ( -f $f ) {
        copy("$f", 'blib/lib') or die "Copy $f failed: $!";
      }
    }
  }
}

sub ACTION_install {
  my $self = shift;
  $self->SUPER::ACTION_build;

  my @commands = ( 'make install', );

  for my $command (@commands) {
    if(system $command) {
      die "test: Failed to execute $command";
    }
  }
}
EOF

my $builder = $class->new(
                'module_name'         => 'vcftools',
                'dist_author'         => q(npg <npg@sanger.ac.uk>),
                'dist_version'        => $class->git_tag(),
                'dist_abstract'       => 'A set of tools written in Perl and C++ for working with VCF files',
                'license'             => 'lgpl',
         );

$builder->create_build_script();

1;
