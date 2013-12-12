module SubledgerHelper
  def subledger_app_link
    setup = subledger_service.cached_get_setup
    puts setup

   "<a href='http://subledger.com/app/?key=#{setup['key_id']}&secret=#{setup['secret']}&org=#{setup['org_id']}&book=#{setup['book_id']}' target='_blank'>Open Subledger App</a>".html_safe
  end

private
  def subledger_service
    @subledger_service ||= SubledgerService.new
  end
end
