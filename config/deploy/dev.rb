set :rails_env, 'production'
set :branch, ENV['CAP_BRANCH'] || "develop"

server '10.250.6.20', user: 'ubuntu', roles: %w{web app db}, primary: true

set :ssh_options, {
    keys: %w(~/.ssh/fhlbsf-dev.pem),
    forward_agent: false,
    auth_methods: %w(publickey)
}