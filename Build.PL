use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(code => <<'EOF');
sub git_tag {
  # adding --tags to allow use of non-annotated tags (as produced by github release tagging)
  my $gitver = q[git describe --tags --dirty --always];
  my $version = `$gitver` || 'unknown';
  $version =~ s/\s$//smxg;
  $version=~s/\A(?![\d])/0.0-/smx; #prepend 0.0- if does not start with a number
  return $version;
}

sub ACTION_code {
  my $self = shift;
  $self->SUPER::ACTION_build;

  my $dest_prefix = $self->install_base;
  my @commands = ( 'autoreconf -fiv', "./configure --prefix=$dest_prefix", 'make', );

  for my $command (@commands) {
    if(system $command) {
      die "build: Failed to execute $command";
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
