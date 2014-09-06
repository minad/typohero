use strict;
use LaTeX::Decode::Data;

my %WORDMAC = ( %WORDMACROS, %WORDMACROSEXTRA, %PUNCTUATION, %SYMBOLS,
            %GREEK );

print "module TypoHero\n  LATEX = {\n";
foreach (keys(%WORDMAC)) {
    my $v = sprintf('\\u%04x', ord($WORDMAC{$_}));
    print "   '\\\\$_' => \"$v\",\n";
}
foreach (keys(%NEGATEDSYMBOLS)) {
    my $v = sprintf('\\u%04x', ord($NEGATEDSYMBOLS{$_}));
    print "   '\\\\not\\\\$_' => \"$v\",\n";
}
print "  }\nend\n";
