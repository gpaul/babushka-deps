dep 'passenger deploy repo' do
  met? { raise UnmeetableDep, "This dep was renamed to 'web repo'." }
end

dep 'web repo' do
  requires [
    'web repo exists',
    'web repo hooks',
    'web repo always receives'
  ]
end

dep 'web repo always receives' do
  requires 'web repo exists'
  met? { in_dir(var(:passenger_repo_root)) { shell("git config receive.denyCurrentBranch") == 'ignore' } }
  meet { in_dir(var(:passenger_repo_root)) { shell("git config receive.denyCurrentBranch ignore") } }
end

dep 'web repo hooks' do
  requires 'web repo exists'
  met? {
    %w[pre-receive post-receive].all? {|hook_name|
      (var(:passenger_repo_root) / ".git/hooks/#{hook_name}").executable? &&
      Babushka::Renderable.new(var(:passenger_repo_root) / ".git/hooks/#{hook_name}").from?(dependency.load_path.parent / "git/deploy-repo-#{hook_name}")
    }
  }
  meet {
    in_dir var(:passenger_repo_root), :create => true do
      %w[pre-receive post-receive].each {|hook_name|
        render_erb "git/deploy-repo-#{hook_name}", :to => ".git/hooks/#{hook_name}"
        shell "chmod +x .git/hooks/#{hook_name}"
      }
    end
  }
end

dep 'web repo exists' do
  requires 'git'
  define_var :passenger_repo_root, :default => "~/current"
  met? { (var(:passenger_repo_root) / '.git').dir? }
  meet {
    in_dir var(:passenger_repo_root), :create => true do
      shell "git init"
    end
  }
end

dep 'github token set' do
  met? { !shell('git config --global github.token').blank? }
  meet { shell("git config --global github.token '#{var(:github_token)}'")}
end

dep 'web repo pushed.repo' do
  requires 'remote exists.repo'
  met? { repo.current_head == repo.repo_shell("git rev-parse --short #{var(:remote_name)}/#{var(:deploy_branch)}") }
  meet { repo.repo_shell "git push #{var(:remote_name)} #{var(:deploy_branch)}", :log => true }
end

dep 'remote exists.repo' do
  def remote_url
    repo.repo_shell("git config remote.#{var(:remote_name)}.url")
  end
  met? { remote_url == var(:remote_url) }
  meet {
    if remote_url.blank?
      repo.repo_shell("git remote add #{var(:remote_name)} '#{var(:remote_url)}'")
    elsif remote_url != var(:remote_url)
      repo.repo_shell("git remote set-url #{var(:remote_name)} '#{var(:remote_url)}'")
    end
  }
end
