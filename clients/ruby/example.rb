require_relative 'at_pay_client'

client = AtPayClient.new('http://localhost:3000', "pnp", "password")

puts client.payment_successfully_processed(302, 'alex', '100', '90', '5', '5', 'http://testingapi.com/302', 'Testing Client with basic authentocation')
