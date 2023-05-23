class Email
  def is_valid?(email)
    # Regular expression pattern for a valid email address
    pattern = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i

    # Test the email against the pattern
    if email =~ pattern
      true
    else
      false
    end
  end
end