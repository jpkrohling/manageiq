class AddLivesOnToMiddlewareServer < ActiveRecord::Migration[5.0]
  def up
    add_column :middleware_servers, :lives_on_type, :string
    add_column :middleware_servers, :lives_on_id,   :bigint
  end

  def down
    remove_column :middleware_servers, :lives_on_type
    remove_column :middleware_servers, :lives_on_id
  end
end
