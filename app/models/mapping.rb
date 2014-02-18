class Mapping < ActiveRecord::Base
  validates :key,
            uniqueness: true

  validates :key, :value,
            presence: true

  after_commit :flush_cache

  def flush_cache
    Rails.cache.delete [self.key, "exists"]
    Rails.cache.delete [self.key, "value"]
  end

  def to_s
    "#{key} = #{value}"
  end

  def self.map_entity(entity, key, value)
    Mapping.create!(key: "#{entity}::#{key}", value: value)
  end

  def self.entity_map_exists?(entity, key)
    entity_key = "#{entity}::#{key}"

    Rails.cache.fetch [entity_key, "exists"] do
      Mapping.exists?(key: entity_key)
    end
  end

  def self.find_entity_map(entity, key)
    Mapping.find_by_key("#{entity}::#{key}")
  end

  def self.entity_map_value(entity, key)
    entity_key = "#{entity}::#{key}"

    Rails.cache.fetch [entity_key, "value"] do
      mapping = find_entity_map(entity, key)
      mapping.present? ? mapping.value : nil
    end
  end
end
