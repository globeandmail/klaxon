#!/usr/bin/env ruby

# Load env vars before Rails is loaded. Also loading Rails once
# here so that we can use functions like .underscore
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

    # A map for secrets we can't easily change, such as in the case
    # of the "dbname" key if using Amazon RDS with Terraform
    keymap = {
      'dbname': 'name',
      'dbInstanceIdentifier': 'instanceIdentifier'
    }

    secrets.each do |secret_name, secret_json|
      subsecrets = JSON.parse(secret_json)
      subsecrets.each_pair do |k, v|
        unless keymap[k.to_sym].nil?
          k = "#{keymap[k.to_sym]}"
        end
        namespaced_secret_key = "#{secret_name}_#{k}".underscore.upcase
        open('/tmp/secrets.env', 'a') do |f|
          f << "#{namespaced_secret_key}=#{v}\n"
        end
        puts "Loaded env var #{namespaced_secret_key} from secrets."
      end
    end

  rescue => e
    puts "Failed to parse secrets. Error: #{e}."
  end

else

  if ENV['DISABLE_AWS_SECRETS']
    puts "DISABLE_AWS_SECRETS has been set. Secrets will not be loaded from AWS."
  end

  if !ENV['AWS_REGION']
    puts "AWS_REGION not set. Secrets will not be loaded from AWS."
  end

  if !ENV['AWS_SECRETS_PREFIX']
    puts "AWS_SECRETS_PREFIX not set. Secrets will not be loaded from AWS."
  end

end
