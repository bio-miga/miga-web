# DKIM global configuration
if Rails.env.production?
  pem_key = File.join(Rails.root, '..', 'dkim_private.pem')
  if File.exist?(pem_key)
    Dkim::domain      = 'microbial-genomes.org'
    Dkim::selector    = 'email'
    Dkim::private_key = open(pem_key).read

    # This will sign all ActionMailer deliveries
    ActionMailer::Base.register_interceptor(Dkim::Interceptor)
  end
end

