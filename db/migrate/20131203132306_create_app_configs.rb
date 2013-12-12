class CreateAppConfigs < ActiveRecord::Migration
  def change
    create_table :app_configs do |t|
      t.string :key
      t.string :value

      t.timestamps
    end

    add_index :app_configs, :key, unique: true
  end
end
