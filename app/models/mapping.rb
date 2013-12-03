class Mapping < ActiveRecord::Base
  validates :key,
            uniqueness: true

  validates :key, :value,
            presence: true

  def to_s
    "#{key} = #{value}"
  end

  def self.map_entity(entity, key, value)
    Mapping.create!(key: "#{entity}::#{key}", value: value)
  end

  def self.entity_map_exists?(entity, key)
    Mapping.exists?(key: "#{entity}::#{key}")
  end

  def self.find_entity_map(entity, key)
    Mapping.find_by_key("#{entity}::#{key}")
  end

  def self.entity_map_value(entity, key)
    mapping = find_entity_map(entity, key)
    mapping.present? ? mapping.value : nil
  end
end
