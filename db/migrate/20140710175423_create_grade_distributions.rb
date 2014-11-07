class CreateGradeDistributions < ActiveRecord::Migration
  def change
    create_table :grade_distributions do |t|
      t.belongs_to :course, index: true
      t.string :level
      t.string :kind
      t.float :grade

      t.timestamps
    end
  end
end