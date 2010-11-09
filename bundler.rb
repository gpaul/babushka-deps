dep 'app bundled' do
  requires 'deployed app', 'bundler.gem', 'db gem'
  met? { in_dir(var(:rails_root)) { shell 'bundle check', :log => true } }
  meet { in_dir(var(:rails_root)) {
    install_args = var(:rails_env) != 'production' ? '' : '--without development --without test --path ./vendor'
    unless shell("bundle install #{install_args}", :log => true)
      confirm("Try a `bundle update`") {
        shell 'bundle update', :log => true
      }
    end
  } }
end

dep 'deployed app' do
  met? { File.directory? var(:rails_root) / 'app' }
end
