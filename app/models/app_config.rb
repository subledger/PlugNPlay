class AppConfig < ActiveRecord::Base
  validates :key,
            uniqueness: true

  validates :key, :value,
            presence: true

  def self.get_value(key)
    result = AppConfig.find_by_key(key)
    result.present? ? result.value : nil
  end

  def to_s
    "#{key} = #{value}"
  end
end
