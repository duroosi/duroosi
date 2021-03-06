class CreateAccounts < ActiveRecord::Migration[5.0]
  def change
    create_table :accounts do |t|
      t.belongs_to :user, index: true
      t.string :slug, index: true
      t.string :name
      t.text :about
      t.boolean :active, :default => false
      t.boolean :live, :default => false
      t.datetime :live_since

      t.timestamps null: false
    end
  end
end
