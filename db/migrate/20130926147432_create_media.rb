class CreateMedia < ActiveRecord::Migration
  def change
    create_table :media do |t|
      t.belongs_to :account, index: true
      t.belongs_to :course, :index => true
      t.string :name
      t.string :kind
      t.string :path
      t.string :url
      t.string :content_type
      t.string :file_size
      t.string :slug
      t.string :copyrights
			
      t.timestamps
    end
  end
end
