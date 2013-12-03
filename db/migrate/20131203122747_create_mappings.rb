class CreateMappings < ActiveRecord::Migration
  def change
    create_table :mappings do |t|
      t.string :key
      t.string :value

      t.timestamps
    end

    add_index :mappings, :key, unique: true
  end
end
