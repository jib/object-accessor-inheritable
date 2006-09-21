use ExtUtils::MakeMaker;
use strict;

WriteMakefile (
    NAME            => 'Object::Accessor::Inheritable',
    VERSION_FROM    => 'lib/Object/Accessor/Inheritable.pm', # finds $VERSION
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    PREREQ_PM       => {    'Object::Accessor'  => 0,
                            'Test::More'        => 0,
                    },
    AUTHOR          => 'Jos Boumans <kane[at]cpan.org>',
	ABSTRACT        => 'Data inheritance between objects'
);             
