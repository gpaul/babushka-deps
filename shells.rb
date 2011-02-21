meta :shell_setup do
  template {
    met? { grep which(basename), '/etc/shells' }
    meet { append_to_file which(basename), '/etc/shells', :sudo => true }
  }
end

dep 'fish.shell_setup' do
  requires 'fish.src'
end

dep 'fish.src' do
  requires 'ncurses.managed', 'coreutils.managed', 'gettext.managed'
  source "git://github.com/benhoskings/fish.git"
end

dep 'zsh' do
  requires 'zsh.shell_setup'
  met? { sudo('echo \$SHELL', :as => var(:username), :su => true) == which('zsh') }
  meet { sudo("chsh -s '#{which('zsh')}' #{var(:username)}") }
end

dep 'zsh.shell_setup' do
  requires 'zsh.managed'
end

dep 'zsh.managed'
