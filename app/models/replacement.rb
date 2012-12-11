class Replacement < ActiveRecord::Base
  serialize :body
  belongs_to :replaceable, :polymorphic => true

end
