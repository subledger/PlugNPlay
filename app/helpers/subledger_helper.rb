module SubledgerHelper
  def subledger_app_link
   "<a href='https://app.subledger.com' target='_blank'>Open Subledger App</a>".html_safe
  end

private
  def subledger_service
    @subledger_service ||= SubledgerService.new
  end
end
