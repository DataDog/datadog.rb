require 'rake/clean'

CLEAN.include %w(.yardoc/ doc/ tmp/)

CLOBBER.include %w(pkg/ spec/cassettes/)
