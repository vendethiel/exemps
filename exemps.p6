#!/usr/bin/env perl6
grammar PsDecl {
  class PsAct {
    method TOP($/) { make $<decl>.made }
    method decl($/) {
      make %(:name($<name>.Str), :fields($<fields>.made))
    }
    method fields($/) {
      make %($<field>>>.made)
    }
    method field($/) {
      make (~$<name> => ~$<value>)
    }
  }

  rule TOP { <decl> }
  rule decl { 'type' <.ws> $<name>=\w+ '=' <fields> }
  rule fields {
    '{' ~ '}'
    <field>+ %% ','
  }

  rule field {
    $<name>=\w+ '::' $<value>=<-[, \}]>+
  }
}

my %gen;
sub gen($name) {
  given $name {
    when %gen { %gen{$name} }
    when "Int" { 1 }
    when /^Maybe/ { 'Nothing' }
  }
}

sub unparse($tree) {
  my $type = $tree<name>;
  my $var = $type.lc;
  my $fields = $tree<fields>.kv.map({$^a ~ ": " ~ gen($^b)});
  my $gen = "\{\n" ~ $fields.map(*.indent(2)).join(",\n") ~ "\n}";
  %gen{$type} = $gen;
  qq:to/END/;
$var :: $type
$var = $gen
END
}

sub parse(Str $code) {
  unparse(PsDecl.parse($code, :actions(PsDecl::PsAct.new)).made)
}

multi sub MAIN(*@code) {
  for @code {
    say parse($_);
  }
}
multi sub MAIN() {
  say parse(slurp);
}
