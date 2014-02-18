class AppConfig < ActiveRecord::Base
  validates :key,
            uniqueness: true

  validates :key, :value,
            presence: true

  after_commit :flush_cache

  def self.get_value(key)
    Rails.cache.fetch key do
      result = AppConfig.find_by_key(key)
      result.present? ? result.value : nil
    end
  end

  def flush_cache
    Rails.cache.delete self.key
  end

  def to_s
    "#{key} = #{value}"
  end
end
