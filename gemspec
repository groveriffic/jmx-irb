spec = Gem::Specification.new do |s|
    s.name = 'jmx-irb'
    s.version = '0.1'
    s.summary = 'IRB Like console over JMX'
    s.author = 'Sam Ehlers'
    s.require_paths = ['lib']
    s.files = Dir['lib/**/*.rb'] + Dir['bin/**/*.rb']
end
