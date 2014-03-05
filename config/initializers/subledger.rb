Subledger::Domain.send(:define_method, 'read_attribute_for_serialization') do |n|
  self.attributes[n.to_sym]
end

Subledger::Domain::Value.send(:define_method, 'read_attribute_for_serialization') do |n|
  self.rest_hash[n.to_s]
end
