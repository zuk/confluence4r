$LOAD_PATH << File.join(File.dirname(__FILE__), '..', 'lib')
FIXTURE_DIR = File.join(File.dirname(__FILE__), 'fixtures')

# Stolen from Facets http://facets.rubyforge.org/
def silence_warnings
  old_verbose, $VERBOSE = $VERBOSE, nil
  yield
ensure
  $VERBOSE = old_verbose
end
