begin
  if Rails.env.production?
    ActionMailer::Base.smtp_settings = {
    :address        => 'smtp.sendgrid.net',
    :port           => '587',
    :authentication => :plain,
    :user_name      => Configuration[:sendgrid_user_name],
    :password       => Configuration[:sendgrid],
    :domain         => 'pullwater.com'
    }
    ActionMailer::Base.delivery_method = :smtp
  end
rescue
  nil
end
