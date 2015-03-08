begin
  require 'yard'

  YARD::Rake::YardocTask.new do |t|
    t.options = ['--markup=markdown']
    t.stats_options = ['--list-undoc']
  end

  desc 'Find TODO items'
  task :todo do
    YARD::Registry.load!.all.each do |o|
      puts '@todo: ' + o.tag(:todo).text if o.tag(:todo)
    end
  end
rescue LoadError
  puts 'YARD is not loaded' unless ENV['CI']
end
