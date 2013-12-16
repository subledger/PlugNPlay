module SubledgerHelper
  def subledger_app_link
   "<a href='http://subledger.com/app' target='_blank'>Open Subledger App</a>".html_safe
  end

private
  def subledger_service
    @subledger_service ||= SubledgerService.new
  end
end
