namespace :subledger do
  desc "Subledger Installation"

  # rake subledger:setup["example@test.com","Test Account","Test Org","Test Book"]
  task :setup, [:email, :identity_desc, :org_desc, :book_desc] => :environment do |t, args|
    puts "* Installing Subledger and running initial setup...\n"
    subledger_service = SubledgerService.new
    subledger_service.initial_setup(args)
  end

end
