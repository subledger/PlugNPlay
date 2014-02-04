require_relative 'granular_client'

client = GranularClient.new('http://localhost:3000', "pnp", "password")

#puts client.charge_buyer(100, '100', '10', 'referrer1@test.com', '80', 'publisher1@test.com', '10', 'distributor1@test.com', '10', 'http://testingapi.com/100', 'API Client Charge Buyer 100')

#puts client.payout_referrer(200, 'referrer1@test.com', '80', 'http://testingapi.com/200', 'API Client Payout Referrer 200')

#puts client.payout_publisher(300, 'publisher1@test.com', '10', 'http://testingapi.com/300', 'API Client Payout Publisher 300')

puts client.payout_distributor(400, 'distributor1@test.com', '10', 'http://testingapi.com/400', 'API Client Payout Distributor 400')
