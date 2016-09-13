class PageMailer < ApplicationMailer
  def received(email,comments,name)
    @email = email
    @comments = comments
    @name = name
    mail to: @email,subject:'Comments' ,bcc:"agutierrezt@unal.edu.co"
  end
end
