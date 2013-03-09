class AddNameHkToCategories < ActiveRecord::Migration
  def change
    add_column :categories, :name_hk, :string
  end
end
