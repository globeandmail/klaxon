module ApplicationHelper

  def cookie_path
    if request.protocol.to_s.include? 'https' || Rails.env.production?
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
    if request.protocol.to_s.include? 'https' || Rails.env.production?
      curr_cookie[:same_site] = :none
      curr_cookie[:secure] = true
    end
    return curr_cookie
  end

end
