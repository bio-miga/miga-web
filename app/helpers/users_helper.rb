module UsersHelper

  # Returns the Gravatar for the given user.
  def gravatar_for(user, options = { size: 80 })
    gravatar_id = Digest::MD5::hexdigest(user.email.downcase)
    size = options[:size]
    gravatar_url = "https://secure.gravatar.com/avatar/#{gravatar_id}" +
      "?s=#{size}&d=identicon"
    image_tag(gravatar_url, alt: user.name, class: 'gravatar rounded-circle')
  end

  # Indicates if the logged-in user is allowed to perform the action
  def can?(action, object)
    return false unless logged_in?
    return false unless object.is_a?(ApplicationRecord)
    case object
    when Project
      case action
      when :edit
        object.privileged_user?(current_user)
      else
        false
      end
    when QueryDataset
      case action
      when :edit, :delete
        object.privileged_user?(current_user)
      else
        false
      end
    else
      false
    end
  end
end
