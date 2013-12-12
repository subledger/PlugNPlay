namespace :subledger do
  desc "Subledger Installation"

  # rake subledger:setup["example@test.com","Test Account","Test Org","Test Book"]
  task :setup, [:email, :identity_desc, :org_desc, :book_desc] => :environment do |t, args|
    puts "* Installing Subledger and running initial setup...\n"

    subledger_service = SubledgerService.new
    result = subledger_service.initial_setup(args)

    puts "\n* Subledger API credentails, accounts and report created:!"
    result.each do |key, value|
      puts "#{key}='#{value}'"
    end

    puts "\nEnjoy!"
  end

end
