require 'rake'

SPEC_DIR = File.join(File.dirname(__FILE__), 'spec')
FIXTURE_DIR = File.join(SPEC_DIR, 'fixtures')
SPECS = "#{SPEC_DIR}/*_spec.rb"

begin
  require 'spec/rake/spectask'
  
  begin
    require 'rcov/rcovtask'

    Spec::Rake::SpecTask.new do |t|
      t.libs << SPEC_DIR
      t.pattern = SPECS
      t.rcov = true
      t.rcov_dir = "#{SPEC_DIR}/coverage"
      t.verbose = true
    end
  
    desc "Generate and open coverage reports"
    task :rcov do
      system "open #{SPEC_DIR}/coverage/index.html"
    end
    task :rcov => :spec
  rescue LoadError
    ### Enabling these warnings makes every run of rake whiny unless you have these gems.
    # warn ">>> You don't seem to have the rcov gem installed; not adding coverage tasks"
    Spec::Rake::SpecTask.new do |t|
      t.libs << SPEC_DIR
      t.pattern = SPECS
      t.verbose = true
    end
  end
rescue LoadError
  # warn ">>> You don't seem to have the rspec gem installed; not adding rspec tasks"
end