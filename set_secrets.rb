#!/usr/bin/env ruby

# Load env vars before Rails is loaded. Also loading Rails once here so that
# we can use functions like .except, .underscore
require 'aws-sdk-secretsmanager'
require 'rails'

if ENV['AWS_REGION'] && ENV['AWS_SECRETS_PREFIX'] && !ENV['DISABLE_AWS_SECRETS']
  secrets_prefix = ENV['AWS_SECRETS_PREFIX']
  client = Aws::SecretsManager::Client.new(region: ENV['AWS_REGION'])

  # Fetch a list of all secrets stored under this AWS account.
  # Requires action "secretsmanager:ListSecrets" for "*" in IAM.
  secrets = client.list_secrets(max_results: 100).secret_list.select do |x|
    /^#{secrets_prefix}/.match(x.name)
  end.map do |x|
    [
      /^#{secrets_prefix}\/(.*)/.match(x.name).captures[0],
      client.get_secret_value(secret_id: x.name).secret_string
    ]
  end.to_h

  begin

    secrets.each do |k, v|
      subsecrets = JSON.parse(v)
      subsecrets.each_pair do |kk, vv|
        open('/tmp/secrets.env', 'a') do |f|
          f << "#{"#{k}_#{kk}".underscore.upcase}=#{vv}\n"
        end
        puts "Loaded env var #{"#{k}_#{kk}".underscore.upcase} from secrets."
      end
    end

  rescue
    puts "Failed to parse secrets."
  end

elsif ENV['DISABLE_AWS_SECRETS']
  puts "DISABLE_AWS_SECRETS has been set. Secrets will not be loaded from AWS."

elsif !ENV['AWS_REGION']
  puts "AWS_REGION not set. Secrets will not be loaded from AWS."

elsif !ENV['AWS_SECRETS_PREFIX']
  puts "AWS_SECRETS_PREFIX not set. Secrets will not be loaded from AWS."

end
