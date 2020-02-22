Pod::Spec.new do |s|
  s.name          = 'CombineDataSources'
  s.version       = '0.2.4'
  s.summary       = 'CombineDataSources provides custom Combine subscribers for collection/table view'
  s.description   = <<-DESC
CombineDataSources provides custom Combine subscribers that act as table and collection view controllers and bind a stream of element collections to table or collection sections with cells.
                   DESC
  s.homepage      = 'https://github.com/CombineCommunity/CombineDataSources'
  s.license       = 'MIT'
  s.author        = { 'Marin Todorov' => 'your emal here :)' }
  s.ios.deployment_target = '13.0'
  s.source        = { :git => 'https://github.com/CombineCommunity/CombineDataSources.git', :tag => s.version.to_s }
  s.source_files  = 'Sources/**/*.swift'
  s.framework     = ['Combine']
  s.swift_version = '5.0'
end
