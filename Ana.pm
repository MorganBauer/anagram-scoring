package Ana;

sub score {
  my ($a, $b) = @_;

  my $G = Ana::Graph->new_from_words($a, $b);
  # Identify common pairs
  # Construct constraint graph
  # Find maximal independent set
  # Shortest mapping
}

sub normalize {
  my ($w) = @_;
  join "", sort split //, $w;
}

sub are_anagrams {
  my ($a, $b) = @_;
  normalize($a) eq normalize($b);
}

package Ana::Graph;
use Carp 'confess';
use strict;

# A graph has:
#  A list of vertex names
#  A hash mapping names to vertex indices
#  A two-dimensional adjacency array of edges ($adj->[$i][$j])
#
# [ Vnames, Vmap, Adj ]

# new_graph([ vertex-names... ])
sub new_graph {
  my ($self, $vnames) = @_;
  my @vnames = @$vnames;
  my %vmap = map { $vnames[$_] => $_ } 0 .. $#vnames;
  my $adj = [];
  bless [ \@vnames, \%vmap, $adj ] => $self;
}

sub Vnames { $_[0][0] }
sub V { $_[0][0] }
sub E { # list of edges?  what format is useful?  [$vi, $wi] maybe?
}
sub adj { $_[0][2] }

sub add_vertices {
  my ($self, @vnames) = @_;
  push $self->V->@*, @vnames;
}

sub add_edges {
  my ($self, @edges) = @_;
  $self->add_edge($_) for @edges;
}

sub add_edge {
  my ($self, $e) = @_;
  my ($v1, $v2) = $self->vi(@$e);
  $self->adj->[$v1][$v2] = 1;
  $self->adj->[$v2][$v1] = 1;
}

sub vi {
  my ($self, @vnames) = @_;
  my @vi;
  push @vi, $self->[1]{$_} // confess "Unknown vertex '$_'" for @vnames;
  @vi;
}

sub vnames {
  my ($self, @indices) = @_;
  return ($self->Vnames->@*)[@indices];
}

sub are_adjacent {
  my ($self, $v, $w) = @_;
  my ($vi, $wi) = $self->vi($v, $w);
  $self->adj->[$vi][$wi];
}

sub neighbors {
  my ($self, $v) = @_;
  my @ni = $self->adj->[$self->vi($v)]->@*;
  return $self->vnames(@ni);
}


# Given words A and B:
# the vertices are pairs (i, j) such that A[i] = B[j] and A[i+1] = B[j+1]
# two vertices are connected if the corresponding pair mappings are compatible
sub new_from_words {
  my ($class, $a, $b) = @_;
  my (@a) = split //, $a;
  my (@b) = split //, $b;

  my @V;
  for my $i (0 .. $#a-1) {
    for my $j (0 .. $#b-1) {
      if ($a[$i] eq $b[$j] && $a[$i+1] eq $b[$j+1]) {
        push @V, "$i,$j";
      }
    }
  }

  my $G = $class->new_graph(\@V);

  for my $q1 (0 .. $#V-1) {
    for my $q2 ($q1+1 .. $#V) {
      my ($i, $j) = split /,/, $V[$q1];
      my ($k, $l) = split /,/, $V[$q2];
      my $BAD = 0;
      if ($i == $k && $j != $l) { $BAD = 1 }
      elsif ($i+1 == $k && $j+1 != $l) { $BAD = 1 }
      elsif ($i+1 < $k && !disjoint([$j, $j+1], [$l, $l+1])) { $BAD = 1 }

      if ($BAD) {
        $G->add_edges( [ @V[$q1, $q2] ] );
      }
    }
  }

  return $G;
}

sub disjoint {
  my ($S, $T) = @_;
  for my $s (@$S) {
    for my $t (@$T) {
      return if $s eq $t;
    }
  }
  return 1;
}

sub to_dot {
  my ($self) = @_;
  my @vertex_line;
  my @edge_line;
  for my $v ($self->V) { push @vertex_line, "v$v"; }
  for my $e ($self->Enames) { my ($v1, $v2) = split /;/, $e; push @edge_line, "v$v1 -- v$v2;" }
  my $dot = join "\n", @vertex_line, @edge_line;
  return "graph G {\n$dot\n}\n";
}

sub components {
  my ($self) = @_;
  my @components;
  my @V = $self->V;
  my %used;
  while (@V) {
    my $V = shift @V;
    next if $used{$V};
    my @queue = ($V);
    my @component;

    # DFS starting from V
    while (@queue) {
      my $v = shift @queue;
      push @component, $v;
      $used{$v} = 1;
      push @queue, $self->neighbors($v);
    }
    push @components, \@component;
  }
  return @components;
}

1;