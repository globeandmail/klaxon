module ApplicationHelper

  def cookie_path
    if ENV.fetch('USE_SECURE_COOKIES', 'true').to_s.downcase == 'true'
      cookies.signed
    else
      cookies
    end
  end

  def generate_cookie(id)
    curr_cookie = {
      value: id,
      expires: 7.days.from_now,
      httponly: true,
    }
    if ENV.fetch('USE_SECURE_COOKIES', 'true').to_s.downcase == 'true'
      curr_cookie[:same_site] = :none
      curr_cookie[:secure] = true
    end
    return curr_cookie
  end

end
