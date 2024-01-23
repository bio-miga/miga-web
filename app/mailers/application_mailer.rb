class ApplicationMailer < ActionMailer::Base
  default from: 'no-reply@microbial-genomes.org'
  layout 'mailer'
end
