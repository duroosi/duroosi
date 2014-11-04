class CreateStudents < ActiveRecord::Migration
  def change
    create_table :students do |t|
      t.belongs_to :user, index: true
      t.string :relationship, :default => 'self'
      t.string :name
      t.string :avatar

      t.timestamps
    end
  end
end
